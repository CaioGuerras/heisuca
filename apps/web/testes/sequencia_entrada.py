#!/usr/bin/env python3
"""Sessão A: grava a sequência abertura → entrada → transição → home contra o servidor FALSO, em vídeo (MP4) e em quadros.

Pré-requisitos: os mesmos de prints_falso.py (servidor falso em 8097, site em 5173) e ffmpeg para o MP4.
Uso:
  python3 testes/sequencia_entrada.py [--temas roxo,verde] [--perfis cel,desk] [--saida testes/comparacoes/a]
         [--video] [--quadros] [--reduzido] [--chromium CAMINHO]
--quadros: prints em momentos fixos (abertura, voo, entrada vazia, entrada com o ✓, transição em vários pontos, home).
--video:   o vídeo inteiro (Playwright record_video_dir → MP4 H.264, ≤ 8 MB) em <saida>/video_<perfil>_<tema>.mp4.
"""
import argparse, json, os, shutil, subprocess, tempfile, time
from playwright.sync_api import sync_playwright

a = argparse.ArgumentParser()
a.add_argument("--site", default="http://127.0.0.1:5173")
a.add_argument("--falso", default="http://127.0.0.1:8097")
a.add_argument("--temas", default="roxo,verde")
a.add_argument("--perfis", default="cel,desk")
a.add_argument("--saida", default="testes/comparacoes/a")
a.add_argument("--video", action="store_true")
a.add_argument("--quadros", action="store_true")
a.add_argument("--reduzido", action="store_true")
a.add_argument("--salva", action="store_true", help="depois da home, recarrega com a sessão salva: abertura → transição → home")
a.add_argument("--chromium", default=None)
o = a.parse_args()
os.makedirs(o.saida, exist_ok=True)

ANDROID = "Mozilla/5.0 (Linux; Android 16; motorola edge 60 pro) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Mobile Safari/537.36"
PERFIS = {"cel": dict(viewport={"width": 412, "height": 915}, device_scale_factor=2.625, is_mobile=True, has_touch=True, user_agent=ANDROID),
          "desk": dict(viewport={"width": 1440, "height": 900})}
# o vídeo grava no tamanho CSS da janela (maior só põe moldura); o MP4 do celular sai ampliado para 824 px
VIDEO = {"cel": {"width": 412, "height": 915}, "desk": {"width": 1440, "height": 900}}
resumo = {}


def digitar(pg, sel, texto):
    pg.click(sel)
    pg.keyboard.type(texto, delay=55)


with sync_playwright() as p:
    b = p.chromium.launch(executable_path=o.chromium) if o.chromium else p.chromium.launch()
    for perfil in o.perfis.split(","):
        for tema in o.temas.split(","):
            tmp = tempfile.mkdtemp()
            extra = dict(record_video_dir=tmp, record_video_size=VIDEO[perfil]) if o.video else {}
            ctx = b.new_context(**PERFIS[perfil], color_scheme="light" if tema == "verde" else "dark",
                                reduced_motion="reduce" if o.reduzido else "no-preference", **extra)
            ctx.add_init_script(f"""try {{ localStorage.setItem('heisuca.tema','{tema}'); }} catch (e) {{}}""")
            pg = ctx.new_page(); erros = []
            pg.on("console", lambda m: m.type == "error" and erros.append(m.text[:200]))
            pg.on("pageerror", lambda e: erros.append(str(e)[:200]))
            nome = f"{perfil}_{tema}" + ("_reduzido" if o.reduzido else "")
            q = lambda rot: o.quadros and pg.screenshot(path=f"{o.saida}/q_{nome}_{rot}.png")
            t0 = time.time()
            pg.goto(o.site + "/")
            if o.quadros:
                for ms in (350, 700, 1200, 2000):
                    time.sleep(max(0, ms / 1000 - (time.time() - t0))); q(f"abertura_{ms:04d}")
            pg.wait_for_selector(".entrada", timeout=15000)
            if o.quadros:
                time.sleep(0.25); q("voo")
            time.sleep(1.1); q("entrada_vazia")
            digitar(pg, ".entrada input[type=url]", o.falso)
            pg.wait_for_selector(".entrada-servidor:not(.vazia)", timeout=10000)
            time.sleep(0.6)
            digitar(pg, ".entrada input[autocomplete=username]", "caioguerras")
            time.sleep(0.5); q("entrada_cheia")
            pg.click(".entrada-botao")
            t1 = time.time()
            pg.wait_for_selector(".transicao", timeout=5000)
            if o.quadros:
                for ms in (250, 600, 1000, 1500, 2100, 2700, 3200):
                    time.sleep(max(0, ms / 1000 - (time.time() - t1))); q(f"transicao_{ms:04d}")
            pg.wait_for_selector(".transicao", state="detached", timeout=20000)
            dur = round(time.time() - t1, 2)
            time.sleep(1.4); q("home")
            resumo[nome] = {"erros": erros, "transicao_s": dur}
            if o.salva:
                pg.evaluate("sessionStorage.removeItem('heisuca.abriu')")
                t2 = time.time(); pg.reload()
                if o.quadros:
                    for ms in (1500, 2600, 3200, 4200, 5200):
                        time.sleep(max(0, ms / 1000 - (time.time() - t2))); q(f"salva_{ms:04d}")
                pg.wait_for_selector(".transicao", timeout=15000)   # vem depois da abertura
                pg.wait_for_selector(".transicao", state="detached", timeout=20000)
                resumo[nome]["salva_total_s"] = round(time.time() - t2, 2)
                time.sleep(1.2)
            v = pg.video
            ctx.close()
            if o.video and v:
                cru = v.path()
                mp4 = f"{o.saida}/video_{nome}.mp4"
                escala = "scale=824:-2" if perfil == "cel" else "scale=1440:-2"
                subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", cru, "-vf", f"{escala},fps=30", "-c:v", "libx264",
                                "-preset", "slow", "-crf", "26", "-pix_fmt", "yuv420p", "-movflags", "+faststart", mp4], check=True)
                resumo[nome]["mp4_mb"] = round(os.path.getsize(mp4) / 1e6, 2)
            shutil.rmtree(tmp, ignore_errors=True)
    b.close()
print(json.dumps(resumo, ensure_ascii=False, indent=1))
