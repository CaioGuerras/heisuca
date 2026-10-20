#!/usr/bin/env python3
"""Roteiro de navegação do CGFLIX no emulador (job "Emulador" do workflow CGFLIX Android).

Instala o APK de debug do app de teste (test/cgflix/emulador/app_navegacao.dart), percorre
Início → Filmes → Séries → Animes → Busca (com "Disponível para pedir") → Pedir → título → Voltar →
menu do usuário → Meus pedidos → Baixados, gira para paisagem e volta em cada tela e guarda as
capturas (retrato e paisagem). Etapa 1E: a barra não tem mais o ícone "Pedir" (o roteiro confere).
Tema 1.4.0: o roteiro roda com o aparelho no modo escuro (Isis), passa por Configurações e pela
tela de entrada, troca o aparelho para o modo claro e captura Início, título, Configurações e
entrada de novo no tema Heitor (capturas "heitor-*").
Refino 2: "Ao assistir" (tela real), a dica de Pular abertura, Dicas do CGFLIX e a dica dos gestos.
Refino 2b: Configurações em lista M3 (peças reais), Estilo das legendas e o Avançado como subtela.
1.5.0: menu do usuário novo, Minha conta, Favoritos, Apoie o CGFLIX e o slogan na entrada, nos
dois temas.
Falha se aparecer tela preta, "RenderFlex overflowed" ou exceção no logcat.

Só usa a biblioteca padrão do Python e o adb do Android SDK.
"""

from __future__ import annotations

import argparse
import re
import struct
import subprocess
import sys
import time
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

APP_ID = "br.com.docaio.cgflix"

# Padrões que reprovam o roteiro quando aparecem no logcat do app.
LOGCAT_FALHAS = (
    re.compile(r"RenderFlex overflowed"),
    re.compile(r"EXCEPTION CAUGHT BY"),
    re.compile(r"FATAL EXCEPTION"),
    re.compile(r"Unhandled Exception"),
    re.compile(r"ANR in " + re.escape(APP_ID)),
)


# ---------------------------------------------------------------------------
# PNG (sem Pillow): decodifica o suficiente para medir se a tela está preta.


def _paeth(a: int, b: int, c: int) -> int:
    p = a + b - c
    pa, pb, pc = abs(p - a), abs(p - b), abs(p - c)
    if pa <= pb and pa <= pc:
        return a
    return b if pb <= pc else c


def decode_png(data: bytes) -> tuple[int, int, int, list[bytearray]]:
    """Devolve (largura, altura, bytes por pixel, linhas) de um PNG RGB/RGBA de 8 bits."""
    if data[:8] != b"\x89PNG\r\n\x1a\n":
        raise ValueError("não é PNG")
    pos, idat = 8, b""
    width = height = bpp = 0
    while pos < len(data):
        (length,) = struct.unpack(">I", data[pos : pos + 4])
        kind = data[pos + 4 : pos + 8]
        body = data[pos + 8 : pos + 8 + length]
        pos += 12 + length
        if kind == b"IHDR":
            width, height, depth, color = struct.unpack(">IIBB", body[:10])
            if depth != 8 or color not in (2, 6):
                raise ValueError(f"PNG sem suporte (profundidade {depth}, cor {color})")
            bpp = 3 if color == 2 else 4
        elif kind == b"IDAT":
            idat += body
        elif kind == b"IEND":
            break
    raw = zlib.decompress(idat)
    stride = width * bpp
    rows: list[bytearray] = []
    prev = bytearray(stride)
    i = 0
    for _ in range(height):
        kind = raw[i]
        line = bytearray(raw[i + 1 : i + 1 + stride])
        i += 1 + stride
        for x in range(stride):
            left = line[x - bpp] if x >= bpp else 0
            up = prev[x]
            up_left = prev[x - bpp] if x >= bpp else 0
            if kind == 1:
                line[x] = (line[x] + left) & 0xFF
            elif kind == 2:
                line[x] = (line[x] + up) & 0xFF
            elif kind == 3:
                line[x] = (line[x] + ((left + up) >> 1)) & 0xFF
            elif kind == 4:
                line[x] = (line[x] + _paeth(left, up, up_left)) & 0xFF
        rows.append(line)
        prev = line
    return width, height, bpp, rows


def lit_fraction(png: bytes, threshold: int = 48, step: int = 4) -> float:
    """Fração de pixels "acesos" (luminância acima de [threshold]), amostrando 1 a cada [step]."""
    width, height, bpp, rows = decode_png(png)
    lit = total = 0
    for y in range(0, height, step):
        row = rows[y]
        for x in range(0, width, step):
            r, g, b = row[x * bpp], row[x * bpp + 1], row[x * bpp + 2]
            total += 1
            if 0.2126 * r + 0.7152 * g + 0.0722 * b > threshold:
                lit += 1
    return lit / total if total else 0.0


def is_black_screen(png: bytes) -> bool:
    """Tela preta = quase nada aceso. O fundo do CGFLIX é #07060a, mas sempre há texto, emblema
    ou botões; a caixa de erro do release (ErrorWidget) é preta lisa."""
    return lit_fraction(png) < 0.002


def device_lost(stderr: str) -> bool:
    """O adb perdeu o aparelho (e não um comando que falhou de verdade)?"""
    return bool(re.search(r"device offline|no devices|device '.*' not found|device not found|closed", stderr))


def logcat_failures(text: str) -> list[str]:
    return [line for line in text.splitlines() if any(p.search(line) for p in LOGCAT_FALHAS)]


# Tempo-limite de cada chamada ao adb (s). install demora mais.
ADB_TIMEOUT = 60
ADB_TIMEOUT_INSTALL = 300

# ---------------------------------------------------------------------------
# adb


class Device:
    def __init__(self, out_dir: Path) -> None:
        self.out_dir = out_dir
        self.problems: list[str] = []

    def reconnect(self) -> None:
        """O emulador do CI às vezes some do adb no meio do roteiro ("device offline"/"no devices",
        screencap com 255). Reconecta, espera o aparelho voltar e terminar de ligar."""
        print("  (adb perdeu o emulador; reconectando)")
        try:
            subprocess.run(["adb", "reconnect", "offline"], capture_output=True, check=False, timeout=30)
        except subprocess.TimeoutExpired:
            pass
        try:
            subprocess.run(["adb", "wait-for-device"], capture_output=True, check=False, timeout=120)
        except subprocess.TimeoutExpired:
            return
        deadline = time.time() + 120
        while time.time() < deadline:
            try:
                boot = subprocess.run(
                    ["adb", "shell", "getprop", "sys.boot_completed"],
                    capture_output=True,
                    text=True,
                    check=False,
                    timeout=30,
                )
            except subprocess.TimeoutExpired:
                continue
            if boot.stdout.strip() == "1":
                time.sleep(2)
                return
            time.sleep(3)

    def _adb_run(self, args: tuple[str, ...], **kwargs) -> subprocess.CompletedProcess:
        """adb com tempo-limite: um adb pendurado travava o roteiro até o job estourar (1.5.0)."""
        timeout = ADB_TIMEOUT_INSTALL if args[:1] == ("install",) else ADB_TIMEOUT
        for tentativa in range(2):
            try:
                return subprocess.run(["adb", *args], capture_output=True, check=False, timeout=timeout, **kwargs)
            except subprocess.TimeoutExpired:
                print(f"  (adb {' '.join(args[:3])} passou de {timeout} s)")
                if tentativa == 0:
                    self.reconnect()
        raise RuntimeError(f"adb {' '.join(args)} não respondeu em {timeout} s")

    def adb(self, *args: str, check: bool = True) -> str:
        result = self._adb_run(args, text=True)
        if result.returncode != 0 and device_lost(result.stderr):
            self.reconnect()
            result = self._adb_run(args, text=True)
        if check and result.returncode != 0:
            raise RuntimeError(f"adb {' '.join(args)} falhou: {result.stderr.strip()}")
        return result.stdout

    def screencap(self) -> bytes:
        for tentativa in range(2):
            result = self._adb_run(("exec-out", "screencap", "-p"))
            if result.returncode == 0 and result.stdout.startswith(b"\x89PNG"):
                return result.stdout
            if tentativa == 0:
                self.reconnect()
        raise RuntimeError(f"screencap falhou: {result.stderr.decode(errors='replace').strip()}")

    def rotate(self, landscape: bool) -> None:
        self.adb("shell", "settings", "put", "system", "accelerometer_rotation", "0")
        self.adb("shell", "settings", "put", "system", "user_rotation", "1" if landscape else "0")
        time.sleep(2.5)

    def nodes(self) -> list[ET.Element]:
        for _ in range(3):
            self.adb("shell", "uiautomator", "dump", "/sdcard/cgflix.xml", check=False)
            xml = self.adb("shell", "cat", "/sdcard/cgflix.xml", check=False)
            if xml.strip().startswith("<?xml"):
                return list(ET.fromstring(xml).iter("node"))
            time.sleep(1)
        return []

    def find(self, pattern: str, timeout: float = 20) -> tuple[int, int]:
        regex = re.compile(pattern)
        deadline = time.time() + timeout
        while True:
            # Sempre olha a tela ao menos uma vez depois do prazo (uma reconexão pode comer o prazo).
            expired = time.time() >= deadline
            for node in self.nodes():
                label = f"{node.get('content-desc', '')}\n{node.get('text', '')}"
                if regex.search(label):
                    nums = [int(n) for n in re.findall(r"\d+", node.get("bounds", ""))]
                    if len(nums) == 4:
                        return (nums[0] + nums[2]) // 2, (nums[1] + nums[3]) // 2
            if expired:
                break
            time.sleep(1)
        raise RuntimeError(f"não achei na tela: {pattern}")

    def has(self, pattern: str) -> bool:
        """A tela mostra agora algo com esse nome? (sem esperar)"""
        regex = re.compile(pattern)
        return any(
            regex.search(f"{node.get('content-desc', '')}\n{node.get('text', '')}") for node in self.nodes()
        )

    def tap(self, pattern: str, wait: float = 1.5) -> None:
        x, y = self.find(pattern)
        self.adb("shell", "input", "tap", str(x), str(y))
        time.sleep(wait)

    def night(self, dark: bool) -> None:
        """Modo escuro/claro do aparelho (o app de teste segue: escuro = Isis, claro = Heitor)."""
        self.adb("shell", "cmd", "uimode", "night", "yes" if dark else "no")
        time.sleep(2.5)

    def back(self) -> None:
        self.adb("shell", "input", "keyevent", "4")
        time.sleep(1.5)

    def shot(self, name: str) -> None:
        """Captura em retrato, gira para paisagem, captura, volta para retrato e confere."""
        for landscape in (False, True):
            self.rotate(landscape)
            png = self.screencap()
            suffix = "paisagem" if landscape else "retrato"
            path = self.out_dir / f"{name}-{suffix}.png"
            path.write_bytes(png)
            fraction = lit_fraction(png)
            print(f"  {path.name}: {fraction:.1%} da tela acesa")
            if is_black_screen(png):
                self.problems.append(f"tela preta em {path.name}")
        self.rotate(False)


def run(apk: Path, out_dir: Path) -> int:
    out_dir.mkdir(parents=True, exist_ok=True)
    dev = Device(out_dir)
    dev.adb("install", "-r", "-t", str(apk))
    dev.adb("logcat", "-c")
    dev.rotate(False)
    dev.night(True)
    dev.adb("shell", "monkey", "-p", APP_ID, "-c", "android.intent.category.LAUNCHER", "1")

    def sem_pedir_na_barra() -> None:
        dev.find(r"^Menu do CGFLIX", timeout=90)
        if dev.has(r"^Pedir um título"):
            raise RuntimeError("a barra do topo ainda tem o ícone Pedir")

    def categoria(nome: str, marca: str):
        def acao() -> None:
            if dev.has(r"^Voltar para Tudo"):
                dev.tap(r"^Voltar para Tudo")
            dev.tap(rf"^Mostrar só {nome}")
            dev.find(marca)
        return acao

    def pedido_feito() -> None:
        deadline = time.time() + 20
        while time.time() < deadline:
            if dev.has(r"Pedido feito") or (dev.has(r"(^|\n)Pedido(\n|$)") and not dev.has(r"^Pedir Duna: Parte Três")):
                return
            time.sleep(0.5)
        raise RuntimeError("não achei na tela: Pedido feito (nem o selo Pedido no lugar do botão)")

    steps = [
        ("01-inicio", sem_pedir_na_barra),
        ("02-filmes", categoria("Filmes", r"^Bacurau")),
        ("03-series", categoria("Séries", r"^Sintonia")),
        ("04-animes", categoria("Animes", r"^Jujutsu Kaisen")),
        (
            "05-busca-pedidos",
            lambda: (dev.tap(r"^Voltar para Tudo"), dev.tap(r"^Buscar$"), dev.find(r"Disponível para pedir")),
        ),
        # O aviso "Pedido feito" some em ~4 s e a leitura da tela pode passar disso num emulador lento
        # (refino 2): vale o aviso ou o botão "Pedir" virando o selo "Pedido".
        ("06-pedido-feito", lambda: (dev.tap(r"^Pedir Duna: Parte Três", wait=0), pedido_feito())),
        ("07-titulo", lambda: dev.tap(r"^Duna\nFilme")),
        ("08-voltar-inicio", lambda: (dev.back(), dev.back(), dev.find(r"^Menu do CGFLIX"))),
        ("09-menu-usuario", lambda: dev.tap(r"^Menu do CGFLIX")),
        ("10-meus-pedidos", lambda: (dev.tap(r"^Meus pedidos$"), dev.find(r"Aguardando aprovação"))),
        ("11-baixados", lambda: (dev.back(), dev.tap(r"^Menu do CGFLIX"), dev.tap(r"^Baixados$"))),
        ("12-voltar", lambda: (dev.back(), dev.find(r"^Menu do CGFLIX"))),
        # 1.5.0: menu novo, Minha conta, Favoritos e Apoie o CGFLIX
        ("15-menu", lambda: (dev.tap(r"^Menu do CGFLIX"), dev.find(r"Minha conta: foto e senha"), dev.find(r"^Apoie o CGFLIX$"))),
        ("16-minha-conta", lambda: (dev.tap(r"Minha conta: foto e senha"), dev.find(r"^Trocar senha$"))),
        ("17-favoritos", lambda: (dev.back(), dev.tap(r"^Menu do CGFLIX"), dev.tap(r"^Favoritos$"), dev.find(r"Nenhum favorito ainda"))),
        ("18-apoie", lambda: (dev.back(), dev.tap(r"^Menu do CGFLIX"), dev.tap(r"^Apoie o CGFLIX$"), dev.find(r"^Copiar chave$"))),
        ("19-voltar", lambda: (dev.back(), dev.find(r"^Menu do CGFLIX"))),
        ("13-configuracoes", lambda: (dev.tap(r"^Menu do CGFLIX"), dev.tap(r"^Configurações$"), dev.find(r"Isis"))),
        # Refino 2: "Ao assistir" real (Pular abertura em cima, com o "?"), Dicas e a dica dos gestos
        # Refino 2b: o item da lista M3 lê "título\nresumo" (por isso o "\n" no padrão).
        ("20-ao-assistir", lambda: (dev.tap(r"^Ao assistir\n"), dev.find(r"Pular abertura e próximo episódio"))),
        ("21-dica-pular-abertura", lambda: (dev.tap(r"^Saiba mais: Pular abertura"), dev.find(r"^Entendi$"))),
        # Refino 2b: Estilo das legendas (prévia ao vivo) e Avançado como subtela (fechado no fim)
        (
            "24-estilo-legendas",
            lambda: (dev.back(), dev.back(), dev.tap(r"^Estilo das legendas"), dev.find(r"Prévia da legenda")),
        ),
        ("25-avancado", lambda: (dev.back(), dev.tap(r"^Avançado"), dev.find(r"Recursos extras"))),
        ("22-dicas", lambda: (dev.back(), dev.tap(r"^Dicas do CGFLIX"), dev.find(r"Gestos na tela do vídeo"))),
        ("23-dica-gestos", lambda: (dev.back(), dev.tap(r"^Ver a tela de vídeo$", wait=0.5), dev.find(r"Toque duas vezes nos lados"))),
        ("14-entrada", lambda: (dev.back(), dev.tap(r"^Ver a tela de entrada"), dev.find(r"Aperte o play"))),
    ]

    def para_o_heitor() -> None:
        dev.back()
        dev.back()
        dev.night(False)
        dev.find(r"^Menu do CGFLIX")

    steps += [
        ("heitor-01-inicio", para_o_heitor),
        (
            "heitor-07-titulo",
            lambda: (dev.tap(r"^Buscar$"), dev.find(r"Disponível para pedir"), dev.tap(r"^Duna\nFilme")),
        ),
        ("heitor-13-configuracoes", lambda: (dev.back(), dev.back(), dev.tap(r"^Menu do CGFLIX"), dev.tap(r"^Configurações$"), dev.find(r"^Tema"))),
        ("heitor-20-ao-assistir", lambda: (dev.tap(r"^Ao assistir\n"), dev.find(r"Pular abertura e próximo episódio"))),
        ("heitor-24-estilo-legendas", lambda: (dev.back(), dev.tap(r"^Estilo das legendas"), dev.find(r"Prévia da legenda"))),
        ("heitor-25-avancado", lambda: (dev.back(), dev.tap(r"^Avançado"), dev.find(r"Recursos extras"))),
        ("heitor-22-dicas", lambda: (dev.back(), dev.tap(r"^Dicas do CGFLIX"), dev.find(r"Gestos na tela do vídeo"))),
        ("heitor-14-entrada", lambda: (dev.back(), dev.tap(r"^Ver a tela de entrada"), dev.find(r"Aperte o play"))),
        (
            "heitor-15-menu",
            lambda: (dev.back(), dev.back(), dev.tap(r"^Menu do CGFLIX"), dev.find(r"^Apoie o CGFLIX$")),
        ),
        ("heitor-16-minha-conta", lambda: (dev.tap(r"Minha conta: foto e senha"), dev.find(r"^Trocar senha$"))),
        ("heitor-18-apoie", lambda: (dev.back(), dev.tap(r"^Menu do CGFLIX"), dev.tap(r"^Apoie o CGFLIX$"), dev.find(r"^Copiar chave$"))),
    ]
    for name, action in steps:
        print(f"• {name}")
        try:
            action()
        except RuntimeError as error:
            dev.problems.append(f"{name}: {error}")
            try:
                dev.out_dir.joinpath(f"{name}-erro.png").write_bytes(dev.screencap())
            except RuntimeError as falha:
                dev.problems.append(f"{name}: sem captura do erro ({falha})")
            break
        dev.shot(name)

    log = dev.adb("logcat", "-d", "-v", "brief")
    (out_dir / "logcat.txt").write_text(log, encoding="utf-8")
    dev.problems.extend(f"logcat: {line}" for line in logcat_failures(log))

    if dev.problems:
        print("\nFALHOU:")
        for problem in dev.problems:
            print(f"  - {problem}")
        return 1
    print("\nOK: navegação, giro e capturas sem tela preta, overflow ou exceção.")
    return 0


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--apk", type=Path, required=True)
    parser.add_argument("--out", type=Path, default=Path("build/cgflix-capturas"))
    args = parser.parse_args(argv)
    return run(args.apk, args.out)


if __name__ == "__main__":
    sys.exit(main())
