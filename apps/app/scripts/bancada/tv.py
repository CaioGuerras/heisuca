#!/usr/bin/env python3
"""Bancada de TV (TV-0): navegação exclusiva por controle remoto (D-pad).

Mede como o Heisuca fica na TV nos perfis de emulador x86_64 da API 36 (googletv-36, androidtv-36).
Fire TV (API 28/30) só tem imagem x86 de 32 bits, que o Flutter 3.47 não compila: fica para aparelho real.
Navega apenas com teclas do controle (DPAD_UP/DOWN/LEFT/RIGHT, CENTER, BACK, HOME, MENU).
Mede e registra se o FOCO está visível e onde (via uiautomator), e se o BACK retorna.
Gera tv/relatorio.json e capturas PNG, sem dados sensíveis.
"""
import argparse
import io
import json
import os
import re
from pathlib import Path
import subprocess
import sys
import time

from capturas import APP_ID, adb
import desastre
from desastre import (
    achar_texto,
    app_em_primeiro_plano,
    campo_abaixo_do_rotulo,
    campos_login,
    parse_uiautomator,
    reconhecer_anr,
)
from servidor import BancadaIndisponivel, Servidor, limpar_log, selecionar
import ui
from ui import (
    CONTA,
    abrir_app,
    apagar_campo,
    digitar,
    dump,
    fechar_teclado,
    texto,
    tocar,
)

ROOT = Path(__file__).resolve().parents[2]
DEFAULT_OUT = ROOT / '.bancada/tv'
APK = ROOT / 'build/app/outputs/flutter-apk/app-debug.apk'

VERDE = 'verde'
ATENCAO = 'ATENÇÃO'
VERMELHO = 'vermelho'

KEY_HOME = 3
KEY_BACK = 4
KEY_UP = 19
KEY_DOWN = 20
KEY_LEFT = 21
KEY_RIGHT = 22
KEY_CENTER = 23
KEY_MENU = 82
KEY_SEARCH = 84
KEY_MEDIA_PLAY_PAUSE = 85
KEY_MEDIA_FAST_FORWARD = 90


def tecla(codigo, espera=1.0):
    """Envia evento de tecla do controle remoto via adb."""
    adb('shell', 'input', 'keyevent', str(codigo))
    time.sleep(espera)


def dpad_up(espera=1.0):
    tecla(KEY_UP, espera)


def dpad_down(espera=1.0):
    tecla(KEY_DOWN, espera)


def dpad_left(espera=1.0):
    tecla(KEY_LEFT, espera)


def dpad_right(espera=1.0):
    tecla(KEY_RIGHT, espera)


def dpad_center(espera=1.5):
    tecla(KEY_CENTER, espera)


def back(espera=1.5):
    tecla(KEY_BACK, espera)


def home(espera=1.5):
    tecla(KEY_HOME, espera)


def menu(espera=1.5):
    tecla(KEY_MENU, espera)


def capturar_png(destino):
    """Captura a tela nativa por adb screencap e salva em destino. Retorna bytes."""
    destino.parent.mkdir(parents=True, exist_ok=True)
    try:
        r = subprocess.run(['adb', 'exec-out', 'screencap', '-p'],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=20)
        if r.returncode == 0 and r.stdout.startswith(b'\x89PNG'):
            destino.write_bytes(r.stdout)
            return r.stdout
    except (subprocess.TimeoutExpired, OSError):
        pass

    remote = '/sdcard/tv_screenshot.png'
    adb('shell', 'screencap', '-p', remote)
    adb('pull', remote, str(destino))
    adb('shell', 'rm', '-f', remote)
    if destino.exists():
        return destino.read_bytes()
    return b''


def salvar_logcat(destino):
    """Salva dump do logcat em destino sem credenciais."""
    destino.parent.mkdir(parents=True, exist_ok=True)
    try:
        r = subprocess.run(['adb', 'logcat', '-d'], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=10)
        if r.returncode == 0 and r.stdout:
            destino.write_bytes(r.stdout)
    except Exception:
        pass


def dump_tv():
    """Hierarquia atual da tela como lista de nós para TV, com fallback resiliente para arquivo."""
    # 1. Tenta exec-out com /dev/tty e /dev/stdout
    for dev in ('/dev/tty', '/dev/stdout'):
        try:
            r = subprocess.run(['adb', 'exec-out', 'uiautomator', 'dump', dev],
                               stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=6)
            bruto = r.stdout.decode('utf-8', 'replace')
            inicio, fim = bruto.find('<?xml'), bruto.rfind('</hierarchy>')
            if inicio >= 0 and fim > 0:
                xml = bruto[inicio:fim + len('</hierarchy>')]
                nos = parse_uiautomator(xml)
                if nos:
                    return nos
        except Exception:
            pass

    # 2. Fallback universal garantido: dump em arquivo no dispositivo
    try:
        remote = '/sdcard/tv_dump.xml'
        adb('shell', 'uiautomator', 'dump', remote)
        r = subprocess.run(['adb', 'exec-out', 'cat', remote],
                           stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=8)
        adb('shell', 'rm', '-f', remote)
        bruto = r.stdout.decode('utf-8', 'replace')
        inicio, fim = bruto.find('<?xml'), bruto.rfind('</hierarchy>')
        if inicio >= 0 and fim > 0:
            xml = bruto[inicio:fim + len('</hierarchy>')]
            nos = parse_uiautomator(xml)
            if nos:
                return nos
    except Exception:
        pass

    # 3. Fallback final via ui.dump()
    return dump()


def is_tela_inteira(bounds, largura=1920, altura=1080):
    """Retorna True se o bounds ocupa praticamente toda a tela (nó raiz)."""
    if not bounds or len(bounds) != 4:
        return True
    x1, y1, x2, y2 = bounds
    area = max(0, x2 - x1) * max(0, y2 - y1)
    tela_area = largura * altura
    return area >= (tela_area * 0.85) or (x1 <= 10 and y1 <= 10 and x2 >= (largura - 10) and y2 >= (altura - 10))


def bounds_area(bounds):
    """Calcula a área de um retângulo [x1, y1, x2, y2]."""
    if not bounds or len(bounds) != 4:
        return float('inf')
    return max(0, bounds[2] - bounds[0]) * max(0, bounds[3] - bounds[1])


def inspecionar_foco(nos, largura_tela=1920, altura_tela=1080):
    """Localiza o nó com focused=true mais interno (menor área, ignorando a raiz/tela inteira)."""
    focados = [n for n in nos if n.get('focused')]
    candidatos = [n for n in focados if not is_tela_inteira(n.get('bounds'), largura_tela, altura_tela)]
    if not candidatos:
        return {'visivel': False, 'elemento': None, 'bounds': None, 'texto': None, 'classe': None, 'raiz': bool(focados)}
    alvo = min(candidatos, key=lambda n: bounds_area(n.get('bounds')))
    txt = alvo.get('text') or alvo.get('desc') or alvo.get('hint') or ''
    return {
        'visivel': True,
        'elemento': txt or alvo.get('cls', ''),
        'bounds': list(alvo.get('bounds') or []),
        'texto': txt,
        'classe': alvo.get('cls', ''),
        'raiz': False,
    }


def diferenca_na_regiao(png_antes, png_depois, bounds):
    """Verifica se houve alteração visual na região do bounds entre duas capturas PNG."""
    if not png_antes or not png_depois or not bounds or len(bounds) != 4:
        return False
    try:
        from PIL import Image, ImageChops
        img_a = Image.open(io.BytesIO(png_antes))
        img_b = Image.open(io.BytesIO(png_depois))
        w, h = img_a.size
        box = (max(0, bounds[0]), max(0, bounds[1]), min(w, bounds[2]), min(h, bounds[3]))
        if box[2] <= box[0] or box[3] <= box[1]:
            return False
        crop_a = img_a.crop(box)
        crop_b = img_b.crop(box)
        diff = ImageChops.difference(crop_a, crop_b)
        return diff.getbbox() is not None
    except Exception:
        pass
    return False


def captura_mudou(png_a, png_b, limiar_diferenca=0.005):
    """Verifica se duas capturas de tela inteira são perceptivelmente diferentes."""
    if not png_a or not png_b:
        return False
    if png_a == png_b:
        return False
    try:
        from PIL import Image, ImageChops, ImageStat
        img_a = Image.open(io.BytesIO(png_a))
        img_b = Image.open(io.BytesIO(png_b))
        if img_a.size != img_b.size:
            return True
        diff = ImageChops.difference(img_a, img_b)
        stat = ImageStat.Stat(diff)
        media_diff = sum(stat.mean) / (len(stat.mean) * 255.0)
        return media_diff > limiar_diferenca
    except Exception:
        return png_a != png_b


def verificar_texto_pequeno(nos, altura_minima=18):
    """Detecta nós com texto legível com altura em pixels inferior ao aceitável em 1080p."""
    pequenos = []
    for n in nos:
        txt = (n.get('text') or n.get('desc') or '').strip()
        b = n.get('bounds')
        if txt and b:
            h = b[3] - b[1]
            if len(txt) > 2 and 0 < h < altura_minima:
                pequenos.append({'texto': txt[:40], 'altura': h, 'bounds': list(b)})
    return pequenos


def verificar_player_preto(png_bytes):
    """Verifica se a captura de vídeo é totalmente preta."""
    if len(png_bytes) < 24 or not png_bytes.startswith(b'\x89PNG\r\n\x1a\n'):
        return False
    try:
        r = subprocess.run(['ffmpeg', '-v', 'error', '-i', 'pipe:0',
                            '-threads', '1', '-filter_threads', '1',
                            '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgb24', 'pipe:1'],
                           input=png_bytes, capture_output=True, timeout=10)
        if r.returncode == 0 and r.stdout:
            return max(r.stdout[::32]) < 16
    except Exception:
        pass
    return False


def achar_apk(candidatos=None):
    """Encontra o caminho do APK de depuração entre os candidatos."""
    candidatos = candidatos if candidatos is not None else [
        APK,
        ROOT / 'build/app/outputs/flutter-apk/app-debug.apk',
        ROOT / 'build/app/outputs/apk/debug/app-debug.apk',
        Path('build/app/outputs/flutter-apk/app-debug.apk'),
        Path('app-debug.apk'),
    ]
    return next((Path(c) for c in candidatos if Path(c).exists()), None)


def classificar_tela(achados, cap_mudou=True, elementos_presentes=True):
    """Classifica a tela individual entre verde, ATENÇÃO e vermelho."""
    if any(a.get('gravidade') == VERMELHO for a in achados):
        return VERMELHO
    if not cap_mudou or not elementos_presentes or any(a.get('gravidade') == ATENCAO for a in achados):
        return ATENCAO
    return VERDE


def classificar_geral(telas, achados_globais):
    """Classifica o relatório geral baseado nas telas e achados globais."""
    todos = achados_globais + [a for t in telas for a in t.get('achados', [])]
    if any(t.get('estado') == VERMELHO for t in telas) or any(a.get('gravidade') == VERMELHO for a in todos):
        return VERMELHO
    if any(t.get('estado') == ATENCAO for t in telas) or any(a.get('gravidade') == ATENCAO for a in todos):
        return ATENCAO
    return VERDE


def checar_saude(nos, rotulo):
    """Checa se o app travou (ANR) ou saiu de primeiro plano."""
    dialogos = reconhecer_anr(nos)
    if dialogos:
        return {'gravidade': VERMELHO, 'codigo': 'anr', 'detalhe': f'{rotulo}: diálogo de ANR visível na tela'}
    atividades = texto('shell', 'dumpsys', 'activity', 'activities')
    if not app_em_primeiro_plano(atividades, APP_ID):
        return {'gravidade': VERMELHO, 'codigo': 'crash', 'detalhe': f'{rotulo}: app fechou ou perdeu primeiro plano'}
    return None


def checar_leanback():
    """Confere se o emulador/dispositivo possui o recurso android.software.leanback."""
    try:
        out = texto('shell', 'pm', 'has-feature', 'android.software.leanback').strip().lower()
        return out == 'true'
    except Exception:
        return False


TERMOS_LOGIN = {
    'iniciar sessão', 'iniciar sessao', 'iniciar', 'iniciando sessão...', 'iniciando sessao...',
    'sign in', 'log in', 'login'
}
TERMOS_INICIO = {'início', 'inicio', 'home', 'descobrir', 'explore'}
DESTINOS_NAV_TV = {
    'bibliotecas', 'biblioteca', 'libraries', 'library',
    'buscar', 'pesquisar', 'search',
    'configurações', 'configuracoes', 'ajustes', 'settings',
    'live tv', 'ao vivo', 'live',
    'você', 'voce', 'you',
    'baixados', 'downloads', 'download',
    'filmes', 'séries', 'series', 'movies', 'shows'
}
# Modelo A da TV (Heisuca TV-1, 30/10): sem trilho lateral; a Início é o destaque com [Assistir]/[Detalhes]
# e o menu sai do avatar no topo (Início, Filmes, Séries, Animes, Buscar, Ajustes).
TERMOS_INICIO_MODELO_A = ('em alta no brasil', 'continuar assistindo')
ITENS_MENU_TV = ('Início', 'Filmes', 'Séries', 'Animes', 'Buscar', 'Ajustes')
TERMOS_VAZIO = (
    'nenhum item', 'sem conteúdo', 'sem conteudo', 'vazio', 'nada aqui',
    'nenhum conteúdo', 'nenhum conteudo', 'adicione filmes', 'adicione séries',
    'adicione series', 'no items', 'no content', 'empty'
)


def abrir_app_tv(registrar=None):
    """Abre o aplicativo Heisuca na TV com múltiplos mecanismos resilientes."""
    rec = registrar or (lambda msg: None)
    rec('Iniciando app Heisuca via am start direto na MainActivity...')
    adb('shell', 'am', 'force-stop', APP_ID)
    time.sleep(1)
    adb('shell', 'am', 'start', '-n', f'{APP_ID}/app.heisuca.MainActivity')
    time.sleep(3)
    atividades = texto('shell', 'dumpsys', 'activity', 'activities')
    if not app_em_primeiro_plano(atividades, APP_ID):
        rec('Tentando iniciar via alias Leanback (.IconeIsis)...')
        adb('shell', 'am', 'start', '-a', 'android.intent.action.MAIN',
            '-c', 'android.intent.category.LEANBACK_LAUNCHER', '-n', f'{APP_ID}/.IconeIsis')
        time.sleep(3)
    atividades = texto('shell', 'dumpsys', 'activity', 'activities')
    if not app_em_primeiro_plano(atividades, APP_ID):
        rec('Tentando iniciar via monkey...')
        abrir_app()
        time.sleep(3)


def reconhecer_tela_tv(nos):
    """Identifica se a tela atual de TV é 'inicio', 'login' ou None."""
    if not nos:
        return None
    rotulos = {r.strip().lower() for n in nos for r in (n.get('text'), n.get('desc'), n.get('hint')) if r}
    tem_editores = any(n.get('cls', '').endswith('EditText') for n in nos)

    # 1. Login: campos de texto (EditText) presentes na tela
    if tem_editores:
        return 'login'

    # 2. Início do modelo A: destaque com [Assistir] + [Detalhes] ou faixa "Em alta no Brasil"
    if any(t in r for r in rotulos for t in TERMOS_INICIO_MODELO_A):
        return 'inicio'
    if 'detalhes' in rotulos and any('assistir' in r for r in rotulos):
        return 'inicio'

    # 3. Início no trilho antigo: menu lateral com destinos ou termo de início
    tem_inicio = bool(rotulos & TERMOS_INICIO)
    tem_destinos = bool(rotulos & DESTINOS_NAV_TV)
    if tem_inicio and tem_destinos:
        return 'inicio'
    if len(rotulos & (TERMOS_INICIO | DESTINOS_NAV_TV)) >= 2:
        return 'inicio'
    if tem_inicio and len(nos) > 3:
        return 'inicio'
    if tem_destinos and len(nos) >= 2:
        return 'inicio'

    return None


def menu_tv_aberto(nos):
    """O menu do avatar está na tela (cartão com Trocar perfil e os destinos)."""
    rotulos = {r.strip().lower() for n in nos for r in (n.get('text'), n.get('desc')) if r}
    return any('trocar perfil' in r for r in rotulos) and 'ajustes' in rotulos and 'buscar' in rotulos


def tocar_avatar_tv():
    """Plano B: toca o avatar (48+29, 36+29 na tela de referência 1920×1080, escalada para a tela real)."""
    m = re.search(r'(\d+)x(\d+)', texto('shell', 'wm', 'size') or '')
    largura = int(m.group(1)) if m else 1920
    escala = largura / 1920
    adb('shell', 'input', 'tap', str(round(77 * escala)), str(round(65 * escala)))
    time.sleep(1.5)


def abrir_destino_tv(destino, rec=None):
    """Abre um destino pelo menu do avatar só com D-Pad: sobe até o avatar, OK, desce até o item, OK.
    Devolve (abriu_por_dpad, menu_abriu). O menu abre sempre focado em Início."""
    rec = rec or (lambda msg: None)
    por_dpad = False
    for _ in range(6):
        dpad_up(espera=0.6)
    dpad_center(espera=1.5)
    if menu_tv_aberto(dump_tv()):
        por_dpad = True
    else:
        rec(f'{destino}: menu do avatar não abriu por D-Pad; tentando pelo toque no avatar')
        tocar_avatar_tv()
        if not menu_tv_aberto(dump_tv()):
            return False, False
    for _ in range(ITENS_MENU_TV.index(destino)):
        dpad_down(espera=0.5)
    dpad_center(espera=2.5)
    return por_dpad, True


def verificar_inicio_vazio(nos):
    """Detecta se a tela de Início na TV está vazia (sem linhas de conteúdo fora do trilho lateral).

    Modelo A: o destaque com [Assistir] + [Detalhes] já é conteúdo do servidor, e a fileira Continuar
    assistindo sem itens ("Nenhum item em andamento") é estado normal de conta nova, não Início vazio."""
    rotulos = [(n.get('text') or n.get('desc') or '').strip().lower() for n in nos]
    if 'detalhes' in rotulos and any('assistir' in r and r != 'continuar assistindo' for r in rotulos):
        return False
    conteudo = [
        n for n in nos
        if n.get('centro') and n['centro'][0] >= 200
        and not is_tela_inteira(n.get('bounds'))
        and 'em andamento' not in (n.get('text') or n.get('desc') or '').lower()
    ]
    for n in conteudo:
        txt = (n.get('text') or n.get('desc') or '').lower()
        if any(termo in txt for termo in TERMOS_VAZIO):
            return True
    itens_validos = [
        n for n in conteudo
        if (n.get('text') or n.get('desc')) or n.get('clickable') or n.get('focusable')
    ]
    return len(itens_validos) < 2


def focar_destaque_tv(alvo, registrar=None):
    """Leva o foco ao botão `alvo` ('assistir' ou 'detalhes') do destaque do Início modelo A.

    Sobe até achar um dos dois botões (no máximo 4 vezes) e anda para o lado certo; devolve True se o foco
    terminou no alvo. Evita o percurso às cegas por contagem de teclas, que dependia de onde o foco estava."""
    rec = registrar or (lambda msg, nos=None: None)
    for _ in range(5):
        texto = (inspecionar_foco(dump_tv()).get('texto') or '').lower()
        if alvo in texto:
            return True
        if 'detalhes' in texto:
            dpad_left()
        elif 'assistir' in texto and 'continuar' not in texto:
            dpad_right()
        else:
            dpad_up()
    rec(f'foco não chegou ao botão {alvo} do destaque')
    return False


def tamanho_do_campo_tv(nos, rotulo):
    """Quantidade de caracteres no campo sob o rótulo com fallback para campos_login."""
    campo = campo_abaixo_do_rotulo(nos, rotulo)
    if campo is None:
        chave = {'SERVIDOR': 'servidor', 'USUÁRIO': 'usuario', 'SENHA': 'senha'}.get(rotulo)
        campo = campos_login(nos).get(chave) if chave else None
    return None if campo is None else len(campo.get('text', ''))


def preencher_campo_tv(rotulo, valor, registrar=None):
    """Preenche campo na TV fechando teclado para evitar sobreposição."""
    rec = registrar or (lambda msg, nos: None)
    for tentativa in (1, 2):
        fechar_teclado()
        time.sleep(0.5)
        nos_atual = dump_tv()
        campo = campo_abaixo_do_rotulo(nos_atual, rotulo)
        if campo is None:
            chave = {'SERVIDOR': 'servidor', 'USUÁRIO': 'usuario', 'SENHA': 'senha'}.get(rotulo)
            campo = campos_login(nos_atual).get(chave) if chave else None
        if campo is None:
            rec(f'campo {rotulo} não achado', nos_atual)
            return False
        tocar(campo)
        time.sleep(1)
        nos = dump_tv()
        campo = campo_abaixo_do_rotulo(nos, rotulo)
        if campo is None:
            chave = {'SERVIDOR': 'servidor', 'USUÁRIO': 'usuario', 'SENHA': 'senha'}.get(rotulo)
            campo = campos_login(nos).get(chave) if chave else None
        apagar_campo()
        if valor:
            digitar(valor)
        time.sleep(1.5)
        fechar_teclado()
        time.sleep(0.5)
        nos = dump_tv()
        rec(f'após {rotulo} (tentativa {tentativa})', nos)
        tam = tamanho_do_campo_tv(nos, rotulo)
        if tam == len(valor):
            return True
        rec(f'tentativa {tentativa} de {rotulo} falhou (tamanho={tam})', nos)
    return False


def fazer_login_tv(base, conta=CONTA, registrar=None):
    """Realiza autenticação completa na TV com fechamento de teclado e espera pelo menu lateral."""
    rec = registrar or (lambda msg: None)
    for tentativa in range(1, 26):
        nos = dump_tv()
        tela = reconhecer_tela_tv(nos)
        if tela == 'inicio':
            rec(f'Tentativa {tentativa}: App já estava autenticado na tela Início')
            return True
        if tela == 'login':
            rec(f'Tentativa {tentativa}: Tela de login detectada')
            break
        rec(f'Aguardando tela de login ou início (tentativa {tentativa}/25, nós={len(nos)})...')
        time.sleep(2)
    else:
        rec('Tela de login ou início não apareceu após abertura')
        return False

    rec('Preenchendo campos de login...')
    if not preencher_campo_tv('SERVIDOR', base, registrar=lambda step, n: rec(f'login: {step}')):
        return False
    if not preencher_campo_tv('USUÁRIO', conta, registrar=lambda step, n: rec(f'login: {step}')):
        return False
    if not preencher_campo_tv('SENHA', '', registrar=lambda step, n: rec(f'login: {step}')):
        return False

    fechar_teclado()
    time.sleep(1)
    nos = dump_tv()
    botao = achar_texto(nos, 'Iniciar sessão', 'iniciar sessao', 'sign in', 'login', exato=False)
    if botao is None:
        dpad_down()
        time.sleep(1)
        nos = dump_tv()
        botao = achar_texto(nos, 'Iniciar sessão', 'iniciar sessao', 'sign in', 'login', exato=False)
    if botao is None:
        rec('Botão Iniciar sessão não encontrado')
        return False
    tocar(botao)

    rec('Aguardando transição para tela Início da TV...')
    for tentativa in range(1, 36):
        time.sleep(2)
        nos = dump_tv()
        if reconhecer_tela_tv(nos) == 'inicio':
            rec(f'Login bem-sucedido: tela Início detectada após {tentativa * 2}s')
            return True
        rec(f'Aguardando Início após login ({tentativa}/35, nós={len(nos)})...')
    return False


def percorrer_tv(base, perfil='googletv-36', out_dir=None, registrar=None, conta=CONTA):
    """Executa o roteiro completo de TV navegando somente via controle remoto."""
    rec = registrar or (lambda msg: print(f'[TV-0] {msg}', flush=True))
    out = Path(out_dir or (DEFAULT_OUT / perfil))
    out.mkdir(parents=True, exist_ok=True)

    telas = []
    achados_globais = []

    rec(f'Iniciando bancada TV no perfil {perfil}...')

    # 0. Verifica leanback feature
    if not checar_leanback():
        rec('Falha: o dispositivo não possui o recurso android.software.leanback!')
        achados_globais.append({
            'gravidade': VERMELHO,
            'codigo': 'sem-leanback',
            'detalhe': f'Perfil {perfil} não possui a feature android.software.leanback (pm has-feature retornou falso)'
        })
        salvar_logcat(out / 'logcat-tv.log')
        return {
            'perfil': perfil,
            'estado': VERMELHO,
            'motivo': 'Dispositivo/emulador não possui android.software.leanback',
            'telas': [],
            'achados': achados_globais,
        }

    # 1. Instala APK se disponível
    apk_alvo = achar_apk()
    if apk_alvo:
        rec(f'Instalando APK {apk_alvo}...')
        res = adb('install', '-r', '-g', str(apk_alvo), capture_errors=True)
        if res.returncode != 0 or b'Failure' in (res.stdout or b''):
            out_err = res.stdout.decode('utf-8', 'replace').strip() if res.stdout else 'código de retorno diferente de zero'
            rec(f'Falha na instalação do APK: {out_err}')
            salvar_logcat(out / 'logcat-tv.log')
            achados_globais.append({
                'gravidade': VERMELHO,
                'codigo': 'falha-instalacao-apk',
                'detalhe': f'Falha ao instalar APK ({out_err})'
            })
            return {
                'perfil': perfil,
                'estado': VERMELHO,
                'motivo': f'Falha na instalação do APK: {out_err}',
                'telas': [],
                'achados': achados_globais,
            }
    else:
        rec('APK não encontrado nos caminhos padrão; assumindo que já está instalado.')

    # 2. Abre o app
    abrir_app_tv(registrar=rec)
    time.sleep(3)

    # 3. Login pela interface com a conta escolhida (sem senha)
    rec('Autenticando via tela com a conta de teste...')
    sucesso_login = fazer_login_tv(base, conta=conta, registrar=rec)
    if not sucesso_login:
        cap_fail = out / '00_falha_login.png'
        capturar_png(cap_fail)
        salvar_logcat(out / 'logcat-tv.log')
        achados_globais.append({
            'gravidade': VERMELHO,
            'codigo': 'falha-login',
            'detalhe': 'Não conseguiu completar login pela interface na TV'
        })
        return {
            'perfil': perfil,
            'estado': VERMELHO,
            'motivo': 'Falha no login pela interface na TV',
            'telas': telas,
            'achados': achados_globais,
        }

    rec('Login concluído com sucesso. Iniciando navegação exclusivamente por D-pad...')
    time.sleep(3)

    # ==========================================
    # TELA 1: Início (linhas)
    # ==========================================
    rec('1. Início (linhas)')
    nos = dump_tv()
    erro = checar_saude(nos, 'Início')
    achados_inicio = [erro] if erro else []

    cap_inicio = out / '01_inicio.png'
    raw_inicio = capturar_png(cap_inicio)

    vazio = verificar_inicio_vazio(nos)
    if vazio:
        achados_inicio.append({
            'gravidade': VERMELHO,
            'codigo': 'inicio-vazio',
            'detalhe': 'Início sem linhas de conteúdo (Início vazio)'
        })

    foco_inicio = inspecionar_foco(nos)
    if not foco_inicio['visivel']:
        # Tenta acordar foco com DPAD_DOWN
        dpad_down()
        raw_inicio_dpad = capturar_png(out / '01_inicio_foco.png')
        nos = dump_tv()
        foco_inicio = inspecionar_foco(nos)
        if foco_inicio['visivel']:
            foco_inicio['mudanca_visual'] = diferenca_na_regiao(raw_inicio, raw_inicio_dpad, foco_inicio['bounds'])
            if not foco_inicio['mudanca_visual']:
                achados_inicio.append({
                    'gravidade': ATENCAO,
                    'codigo': 'foco-sem-destaque',
                    'detalhe': f'Elemento focado {foco_inicio["elemento"]} não alterou a imagem na região'
                })
        else:
            achados_inicio.append({
                'gravidade': ATENCAO,
                'codigo': 'foco-invisivel',
                'detalhe': 'Nenhum elemento interno focado identificado na Início'
            })

    pequenos = verificar_texto_pequeno(nos)
    if pequenos:
        achados_inicio.append({
            'gravidade': ATENCAO,
            'codigo': 'texto-pequeno',
            'detalhe': f'{len(pequenos)} textos com altura inferior a 18px na Início'
        })

    estado_inicio = classificar_tela(achados_inicio, cap_mudou=True, elementos_presentes=not vazio)
    telas.append({
        'nome': 'inicio',
        'titulo': 'Início (linhas)',
        'estado': estado_inicio,
        'foco': foco_inicio,
        'back_retorna': True,
        'captura': '01_inicio.png',
        'achados': achados_inicio,
    })

    if vazio:
        rec('Início está vazio. Percurso não pode prosseguir para filmes/séries/player.')
        achados_globais.append({
            'gravidade': VERMELHO,
            'codigo': 'percurso-incompleto',
            'detalhe': 'Percurso interrompido pois a tela Início não carregou linhas de conteúdo'
        })
        salvar_logcat(out / 'logcat-tv.log')
        return {
            'perfil': perfil,
            'estado': VERMELHO,
            'motivo': 'Início vazio na conta de teste',
            'telas': telas,
            'achados': achados_globais + achados_inicio,
        }

    # ==========================================
    # TELA 2: Detalhe de filme
    # ==========================================
    rec('2. Detalhe de filme')
    # Abre o detalhe pelo botão [Detalhes] do destaque
    focar_destaque_tv('detalhes', registrar=rec)
    dpad_center(espera=3.0)

    nos = dump_tv()
    erro = checar_saude(nos, 'Detalhe de filme')
    achados_filme = [erro] if erro else []

    cap_filme = out / '02_detalhe_filme.png'
    raw_filme = capturar_png(cap_filme)
    mudou_filme = captura_mudou(raw_inicio, raw_filme)
    if not mudou_filme:
        achados_filme.append({
            'gravidade': ATENCAO,
            'codigo': 'toque-obrigatorio',
            'detalhe': 'Detalhe de filme: tela esperada não abriu com D-Pad (requer toque)'
        })

    rotulos_filme = {r.strip().lower() for n in nos for r in desastre._rotulos(n)}
    elementos_filme = bool(rotulos_filme & {'reproduzir', 'assistir', 'trailer', 'sinopse', 'detalhes', 'informações', 'play', 'watch', 'details', 'info', 'overview'})
    if not elementos_filme and mudou_filme:
        achados_filme.append({
            'gravidade': ATENCAO,
            'codigo': 'elemento-esperado-ausente',
            'detalhe': 'Detalhe de filme: botão Reproduzir ou informações não identificados'
        })

    foco_filme = inspecionar_foco(nos)
    if not foco_filme['visivel']:
        achados_filme.append({
            'gravidade': ATENCAO,
            'codigo': 'foco-invisivel',
            'detalhe': 'Foco invisível no detalhe de filme'
        })

    pequenos = verificar_texto_pequeno(nos)
    if pequenos:
        achados_filme.append({
            'gravidade': ATENCAO,
            'codigo': 'texto-pequeno',
            'detalhe': f'{len(pequenos)} textos pequenos no detalhe de filme'
        })

    # Teste de BACK
    back(espera=2.0)
    nos_pos_back = dump_tv()
    erro_back = checar_saude(nos_pos_back, 'BACK no detalhe de filme')
    if erro_back:
        achados_filme.append(erro_back)
        back_retorna_filme = False
    else:
        back_retorna_filme = (reconhecer_tela_tv(nos_pos_back) == 'inicio')
        if not back_retorna_filme:
            achados_filme.append({
                'gravidade': ATENCAO,
                'codigo': 'toque-obrigatorio',
                'detalhe': 'BACK não retornou para Início após detalhe de filme'
            })

    telas.append({
        'nome': 'detalhe_filme',
        'titulo': 'Detalhe de filme',
        'estado': classificar_tela(achados_filme, cap_mudou=mudou_filme, elementos_presentes=elementos_filme),
        'foco': foco_filme,
        'back_retorna': back_retorna_filme,
        'captura': '02_detalhe_filme.png',
        'achados': achados_filme,
    })

    # ==========================================
    # TELA 3: Detalhe de série/temporada
    # ==========================================
    rec('3. Detalhe de série/temporada')
    dpad_down()
    dpad_right()
    dpad_center(espera=3.0)

    nos = dump_tv()
    erro = checar_saude(nos, 'Detalhe de série')
    achados_serie = [erro] if erro else []

    cap_serie = out / '03_detalhe_serie.png'
    raw_serie = capturar_png(cap_serie)
    mudou_serie = captura_mudou(raw_inicio, raw_serie)
    if not mudou_serie:
        achados_serie.append({
            'gravidade': ATENCAO,
            'codigo': 'toque-obrigatorio',
            'detalhe': 'Detalhe de série: tela esperada não abriu com D-Pad (requer toque)'
        })

    rotulos_serie = {r.strip().lower() for n in nos for r in desastre._rotulos(n)}
    elementos_serie = bool(rotulos_serie & {'temporada', 'temporadas', 'episódio', 'episódios', 'série', 'reproduzir', 'season', 'seasons', 'episode', 'episodes', 'series', 'play'})
    if not elementos_serie and mudou_serie:
        achados_serie.append({
            'gravidade': ATENCAO,
            'codigo': 'elemento-esperado-ausente',
            'detalhe': 'Detalhe de série: seções de episódios ou temporadas não identificadas'
        })

    foco_serie = inspecionar_foco(nos)
    if not foco_serie['visivel']:
        achados_serie.append({
            'gravidade': ATENCAO,
            'codigo': 'foco-invisivel',
            'detalhe': 'Foco invisível no detalhe de série'
        })

    pequenos = verificar_texto_pequeno(nos)
    if pequenos:
        achados_serie.append({
            'gravidade': ATENCAO,
            'codigo': 'texto-pequeno',
            'detalhe': f'{len(pequenos)} textos pequenos no detalhe de série'
        })

    # Teste de BACK
    back(espera=2.0)
    nos_pos_back = dump_tv()
    erro_back = checar_saude(nos_pos_back, 'BACK no detalhe de série')
    if erro_back:
        achados_serie.append(erro_back)
        back_retorna_serie = False
    else:
        back_retorna_serie = (reconhecer_tela_tv(nos_pos_back) == 'inicio')
        if not back_retorna_serie:
            achados_serie.append({
                'gravidade': ATENCAO,
                'codigo': 'toque-obrigatorio',
                'detalhe': 'BACK não retornou para Início após detalhe de série'
            })

    telas.append({
        'nome': 'detalhe_serie',
        'titulo': 'Detalhe de série/temporada',
        'estado': classificar_tela(achados_serie, cap_mudou=mudou_serie, elementos_presentes=elementos_serie),
        'foco': foco_serie,
        'back_retorna': back_retorna_serie,
        'captura': '03_detalhe_serie.png',
        'achados': achados_serie,
    })

    # ==========================================
    # TELA 4: Player (reproduzir, pausar, avançar 10s, áudio/legenda, sair)
    # ==========================================
    rec('4. Player')
    # Toca o destaque pelo botão [Assistir]
    focar_destaque_tv('assistir', registrar=rec)
    dpad_center(espera=6.0)

    nos = dump_tv()
    erro = checar_saude(nos, 'Player')
    achados_player = [erro] if erro else []

    cap_player = out / '05_player.png'
    raw_player = capturar_png(cap_player)
    mudou_player = captura_mudou(raw_filme, raw_player) and captura_mudou(raw_inicio, raw_player)

    if not mudou_player:
        achados_player.append({
            'gravidade': ATENCAO,
            'codigo': 'toque-obrigatorio',
            'detalhe': 'Player: vídeo não iniciou com D-Pad (requer toque)'
        })

    if raw_player and mudou_player and verificar_player_preto(raw_player):
        achados_player.append({
            'gravidade': VERMELHO,
            'codigo': 'player-preto',
            'detalhe': 'Vídeo iniciado com tela totalmente preta'
        })

    # Pausar
    rec('Player: pausando com DPAD_CENTER...')
    dpad_center(espera=1.5)
    capturar_png(out / '06_player_pausado.png')

    # Avançar 10 s
    rec('Player: avançando 10 s com DPAD_RIGHT...')
    dpad_right(espera=1.5)
    capturar_png(out / '07_player_avanco.png')

    # Abrir áudio/legenda
    rec('Player: abrindo controles de áudio/legenda...')
    dpad_up(espera=1.0)
    menu(espera=1.5)
    capturar_png(out / '08_player_audio_legenda.png')

    # Sair do player com BACK
    rec('Player: saindo com BACK...')
    back(espera=1.5)
    back(espera=2.5)

    nos_pos_player = dump_tv()
    erro_sair = checar_saude(nos_pos_player, 'Saída do player')
    if erro_sair:
        achados_player.append(erro_sair)
        back_retorna_player = False
    else:
        back_retorna_player = True

    telas.append({
        'nome': 'player',
        'titulo': 'Player',
        'estado': classificar_tela(achados_player, cap_mudou=mudou_player, elementos_presentes=mudou_player),
        'foco': inspecionar_foco(nos),
        'back_retorna': back_retorna_player,
        'captura': '05_player.png',
        'achados': achados_player,
    })

    if reconhecer_tela_tv(dump_tv()) != 'inicio':
        back(espera=2.0)

    # ==========================================
    # TELA 5: Busca
    # ==========================================
    rec('5. Busca')
    busca_dpad, menu_ok = abrir_destino_tv('Buscar', rec)

    nos = dump_tv()
    erro = checar_saude(nos, 'Busca')
    achados_busca = [erro] if erro else []
    if not busca_dpad:
        achados_busca.append({
            'gravidade': ATENCAO if menu_ok else VERMELHO,
            'codigo': 'menu-avatar',
            'detalhe': 'Busca: o menu do avatar não abriu por D-Pad' + ('' if menu_ok else ' nem por toque')
        })

    cap_busca = out / '04_busca.png'
    raw_busca = capturar_png(cap_busca)
    mudou_busca = captura_mudou(raw_inicio, raw_busca)
    if not mudou_busca:
        achados_busca.append({
            'gravidade': ATENCAO,
            'codigo': 'toque-obrigatorio',
            'detalhe': 'Busca: tela não abriu com D-Pad (requer toque)'
        })

    foco_busca = inspecionar_foco(nos)
    if not foco_busca['visivel']:
        achados_busca.append({
            'gravidade': ATENCAO,
            'codigo': 'foco-invisivel',
            'detalhe': 'Foco invisível na tela de Busca'
        })

    pequenos = verificar_texto_pequeno(nos)
    if pequenos:
        achados_busca.append({
            'gravidade': ATENCAO,
            'codigo': 'texto-pequeno',
            'detalhe': f'{len(pequenos)} textos pequenos na Busca'
        })

    back(espera=2.0)
    nos_pos_back = dump_tv()
    erro_back = checar_saude(nos_pos_back, 'BACK na Busca')
    if erro_back:
        achados_busca.append(erro_back)
        back_retorna_busca = False
    else:
        back_retorna_busca = True

    telas.append({
        'nome': 'busca',
        'titulo': 'Busca',
        'estado': classificar_tela(achados_busca, cap_mudou=mudou_busca, elementos_presentes=mudou_busca),
        'foco': foco_busca,
        'back_retorna': back_retorna_busca,
        'captura': '04_busca.png',
        'achados': achados_busca,
    })

    # ==========================================
    # TELA 6: Configurações
    # ==========================================
    rec('6. Configurações')
    if reconhecer_tela_tv(dump_tv()) != 'inicio':
        back(espera=2.0)
    config_dpad, menu_ok = abrir_destino_tv('Ajustes', rec)

    nos = dump_tv()
    erro = checar_saude(nos, 'Configurações')
    achados_config = [erro] if erro else []
    if not config_dpad:
        achados_config.append({
            'gravidade': ATENCAO if menu_ok else VERMELHO,
            'codigo': 'menu-avatar',
            'detalhe': 'Ajustes: o menu do avatar não abriu por D-Pad' + ('' if menu_ok else ' nem por toque')
        })

    cap_config = out / '09_configuracoes.png'
    raw_config = capturar_png(cap_config)
    mudou_config = captura_mudou(raw_inicio, raw_config)
    if not mudou_config:
        achados_config.append({
            'gravidade': ATENCAO,
            'codigo': 'toque-obrigatorio',
            'detalhe': 'Configurações: tela não abriu com D-Pad (requer toque)'
        })

    foco_config = inspecionar_foco(nos)
    if not foco_config['visivel']:
        achados_config.append({
            'gravidade': ATENCAO,
            'codigo': 'foco-invisivel',
            'detalhe': 'Foco invisível em Configurações'
        })

    pequenos = verificar_texto_pequeno(nos)
    if pequenos:
        achados_config.append({
            'gravidade': ATENCAO,
            'codigo': 'texto-pequeno',
            'detalhe': f'{len(pequenos)} textos pequenos em Configurações'
        })

    telas.append({
        'nome': 'configuracoes',
        'titulo': 'Configurações',
        'estado': classificar_tela(achados_config, cap_mudou=mudou_config, elementos_presentes=mudou_config),
        'foco': foco_config,
        'back_retorna': True,
        'captura': '09_configuracoes.png',
        'achados': achados_config,
    })

    # ==========================================
    # TELA 7: Sobre
    # ==========================================
    rec('7. Sobre')
    # Ajustes da TV: foco inicial em Perfil; Sobre é a 6ª linha (Perfil, Áudio, Legenda, Tamanho, Ainda está aí?, Sobre).
    for _ in range(5):
        dpad_down(espera=0.5)
    dpad_center(espera=2.0)

    nos = dump_tv()
    erro = checar_saude(nos, 'Sobre')
    achados_sobre = [erro] if erro else []

    cap_sobre = out / '10_sobre.png'
    raw_sobre = capturar_png(cap_sobre)
    mudou_sobre = captura_mudou(raw_config, raw_sobre)
    if not mudou_sobre:
        achados_sobre.append({
            'gravidade': ATENCAO,
            'codigo': 'toque-obrigatorio',
            'detalhe': 'Sobre: tela não abriu com D-Pad (requer toque)'
        })

    foco_sobre = inspecionar_foco(nos)
    if not foco_sobre['visivel']:
        achados_sobre.append({
            'gravidade': ATENCAO,
            'codigo': 'foco-invisivel',
            'detalhe': 'Foco invisível na tela Sobre'
        })

    pequenos = verificar_texto_pequeno(nos)
    if pequenos:
        achados_sobre.append({
            'gravidade': ATENCAO,
            'codigo': 'texto-pequeno',
            'detalhe': f'{len(pequenos)} textos pequenos na tela Sobre'
        })

    back(espera=2.0)
    nos_pos_back = dump_tv()
    erro_back = checar_saude(nos_pos_back, 'BACK na tela Sobre')
    if erro_back:
        achados_sobre.append(erro_back)
        back_retorna_sobre = False
    else:
        back_retorna_sobre = True

    telas.append({
        'nome': 'sobre',
        'titulo': 'Sobre',
        'estado': classificar_tela(achados_sobre, cap_mudou=mudou_sobre, elementos_presentes=mudou_sobre),
        'foco': foco_sobre,
        'back_retorna': back_retorna_sobre,
        'captura': '10_sobre.png',
        'achados': achados_sobre,
    })

    back(espera=1.5)

    # ==========================================
    # Consolidação do Relatório
    # ==========================================
    estado_final = classificar_geral(telas, achados_globais)
    motivo = ''
    if estado_final == VERMELHO:
        motivo = 'Falhas críticas identificadas durante percurso de TV.'
    elif estado_final == ATENCAO:
        motivo = 'Achados de atenção na TV (foco invisível, texto pequeno ou tela que requer toque).'

    relatorio = {
        'perfil': perfil,
        'estado': estado_final,
        'motivo': motivo,
        'telas': telas,
        'achados': achados_globais + [a for t in telas for a in t.get('achados', [])]
    }

    salvar_logcat(out / 'logcat-tv.log')
    rec(f'Percurso concluído no perfil {perfil}. Estado: {estado_final}')
    for t in telas:
        rec(f"  - Tela {t.get('titulo', t.get('nome'))}: {t.get('estado')}")
        for a in t.get('achados', []):
            rec(f"      [{a.get('gravidade')}] {a.get('codigo')}: {a.get('detalhe')}")
    return relatorio


def main():
    parser = argparse.ArgumentParser(description='Bancada de TV Heisuca (TV-0)')
    parser.add_argument('--perfil', default='googletv-36',
                        choices=['googletv-36', 'androidtv-36'],
                        help='Perfil de emulador')
    parser.add_argument('--saida', default=None,
                        help='Diretório de saída para evidências e relatório')
    args = parser.parse_args()

    base = os.environ.get('HEISUCA_TESTE_SERVIDOR', '').strip()
    contas = [c.strip() for c in os.environ.get('HEISUCA_TESTE_CONTAS', '').splitlines() if c.strip()]
    protegidos = contas + [CONTA]

    def limpo(valor):
        return limpar_log(valor, protegidos, base)

    out = Path(args.saida) if args.saida else (DEFAULT_OUT / args.perfil)
    out.mkdir(parents=True, exist_ok=True)

    # A `teste-sem-senha` não tem bibliotecas (de propósito): o Início fica vazio e o percurso para.
    # Mesma regra da bancada do celular: conta do rodízio livre e com vídeo seguro (run 41073856934).
    try:
        cliente, conta, _video = selecionar(base, contas)
        cliente.logout()
    except BancadaIndisponivel as erro:
        relatorio = {'perfil': args.perfil, 'estado': VERMELHO, 'motivo': str(erro), 'telas': [], 'achados': []}
    else:
        relatorio = percorrer_tv(base, perfil=args.perfil, out_dir=out, conta=conta)
        relatorio['conta'] = 'dedicada' if conta.lower() == CONTA else 'rodízio'

    json_str = limpo(json.dumps(relatorio, ensure_ascii=False, indent=2))
    (out / 'relatorio.json').write_text(json_str)

    tv_dir = ROOT / 'tv'
    tv_dir.mkdir(parents=True, exist_ok=True)
    (tv_dir / 'relatorio.json').write_text(json_str)

    print(f'Relatório gravado em {out / "relatorio.json"}. Estado: {relatorio["estado"]}')


if __name__ == '__main__':
    main()
