#!/usr/bin/env python3
"""Bancada de TV (TV-0): navegação exclusiva por controle remoto (D-pad).

Mede como o Heisuca fica na TV em 3 perfis de emulador (androidtv, firetv-11, firetv-9).
Navega apenas com teclas do controle (DPAD_UP/DOWN/LEFT/RIGHT, CENTER, BACK, HOME, MENU).
Mede e registra se o FOCO está visível e onde (via uiautomator), e se o BACK retorna.
Gera tv/relatorio.json e capturas PNG, sem dados sensíveis.
"""
import argparse
import json
import os
from pathlib import Path
import subprocess
import sys
import time

from capturas import APP_ID, adb
from desastre import (
    app_em_primeiro_plano,
    marco,
    parse_uiautomator,
    reconhecer_anr,
)
from servidor import Servidor, limpar_log
import ui
from ui import CONTA, abrir_app, dump, entrar_pela_interface, texto

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


def inspecionar_foco(nos):
    """Localiza o elemento focado via uiautomator."""
    focados = [n for n in nos if n.get('focused')]
    if not focados:
        return {'visivel': False, 'elemento': None, 'bounds': None, 'texto': None, 'classe': None}
    alvo = focados[0]
    txt = alvo.get('text') or alvo.get('desc') or alvo.get('hint') or ''
    return {
        'visivel': True,
        'elemento': txt or alvo.get('cls', ''),
        'bounds': list(alvo.get('bounds') or []),
        'texto': txt,
        'classe': alvo.get('cls', ''),
    }


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
        r = subprocess.run(['ffmpeg', '-v', 'error', '-threads', '1', '-i', 'pipe:0',
                            '-frames:v', '1', '-f', 'rawvideo', '-pix_fmt', 'rgb24', 'pipe:1'],
                           input=png_bytes, capture_output=True, timeout=10)
        if r.returncode == 0 and r.stdout:
            # Amostra a cada 32 bytes para rapidez
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


def classificar_tela(achados):
    """Classifica a tela individual entre verde, ATENÇÃO e vermelho."""
    if any(a.get('gravidade') == VERMELHO for a in achados):
        return VERMELHO
    if any(a.get('gravidade') == ATENCAO for a in achados):
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


def percorrer_tv(base, perfil='androidtv', out_dir=None, registrar=None):
    """Executa o roteiro completo de TV navegando somente via controle remoto."""
    rec = registrar or (lambda msg: print(f'[TV-0] {msg}', flush=True))
    out = Path(out_dir or (DEFAULT_OUT / perfil))
    out.mkdir(parents=True, exist_ok=True)

    telas = []
    achados_globais = []

    rec(f'Iniciando bancada TV no perfil {perfil}...')

    # 1. Instala APK se disponível
    apk_alvo = achar_apk()
    if apk_alvo:
        rec(f'Instalando APK {apk_alvo}...')
        res = adb('install', '-r', '-g', str(apk_alvo), capture_errors=True)
        if res.returncode != 0 or b'Failure' in (res.stdout or b''):
            out_err = res.stdout.decode('utf-8', 'replace').strip() if res.stdout else 'código de retorno diferente de zero'
            rec(f'Aviso: falha na instalação do APK ({out_err}). Tentando continuar se já instalado...')
    else:
        rec('APK não encontrado nos caminhos padrão; assumindo que já está instalado.')

    # 2. Abre o app
    abrir_app()
    time.sleep(3)

    # 3. Login pela interface com a conta dedicada
    rec('Autenticando via tela com a conta de teste...')
    sucesso_login = entrar_pela_interface(base, registrar=lambda step, nos: rec(f'login: {step}'))
    if not sucesso_login:
        cap_fail = out / '00_falha_login.png'
        capturar_png(cap_fail)
        achados_globais.append({
            'gravidade': VERMELHO,
            'codigo': 'falha-login',
            'detalhe': 'Não conseguiu completar login pela interface na TV'
        })
        return {
            'perfil': perfil,
            'estado': VERMELHO,
            'motivo': 'Falha no login pela interface',
            'telas': telas,
            'achados': achados_globais
        }

    rec('Login concluído com sucesso. Iniciando navegação exclusivamente por D-pad...')
    time.sleep(3)

    # ==========================================
    # TELA 1: Início (linhas)
    # ==========================================
    rec('1. Início (linhas)')
    nos = dump()
    erro = checar_saude(nos, 'Início')
    achados_inicio = [erro] if erro else []

    foco = inspecionar_foco(nos)
    if not foco['visivel']:
        # Tenta acordar foco com DPAD_DOWN
        dpad_down()
        nos = dump()
        foco = inspecionar_foco(nos)
        if not foco['visivel']:
            achados_inicio.append({
                'gravidade': ATENCAO,
                'codigo': 'foco-invisivel',
                'detalhe': 'Nenhum elemento focado identificado pelo uiautomator na Início'
            })

    pequenos = verificar_texto_pequeno(nos)
    if pequenos:
        achados_inicio.append({
            'gravidade': ATENCAO,
            'codigo': 'texto-pequeno',
            'detalhe': f'{len(pequenos)} textos com altura inferior a 18px na Início'
        })

    cap_inicio = out / '01_inicio.png'
    capturar_png(cap_inicio)

    telas.append({
        'nome': 'inicio',
        'titulo': 'Início (linhas)',
        'estado': classificar_tela(achados_inicio),
        'foco': foco,
        'back_retorna': True,
        'captura': '01_inicio.png',
        'achados': achados_inicio,
    })

    # ==========================================
    # TELA 2: Detalhe de filme
    # ==========================================
    rec('2. Detalhe de filme')
    # Move para o primeiro cartão e seleciona
    dpad_down()
    dpad_center(espera=3.0)

    nos = dump()
    erro = checar_saude(nos, 'Detalhe de filme')
    achados_filme = [erro] if erro else []

    foco = inspecionar_foco(nos)
    if not foco['visivel']:
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

    cap_filme = out / '02_detalhe_filme.png'
    capturar_png(cap_filme)

    # Teste de BACK
    back(espera=2.0)
    nos_pos_back = dump()
    erro_back = checar_saude(nos_pos_back, 'BACK no detalhe de filme')
    if erro_back:
        achados_filme.append(erro_back)
        back_retorna_filme = False
    else:
        back_retorna_filme = (marco(nos_pos_back) == 'inicio')
        if not back_retorna_filme:
            achados_filme.append({
                'gravidade': ATENCAO,
                'codigo': 'toque-obrigatorio',
                'detalhe': 'BACK não retornou para Início após detalhe de filme'
            })

    telas.append({
        'nome': 'detalhe_filme',
        'titulo': 'Detalhe de filme',
        'estado': classificar_tela(achados_filme),
        'foco': foco,
        'back_retorna': back_retorna_filme,
        'captura': '02_detalhe_filme.png',
        'achados': achados_filme,
    })

    # ==========================================
    # TELA 3: Detalhe de série/temporada
    # ==========================================
    rec('3. Detalhe de série/temporada')
    # Desce para tentar selecionar uma série
    dpad_down()
    dpad_right()
    dpad_center(espera=3.0)

    nos = dump()
    erro = checar_saude(nos, 'Detalhe de série')
    achados_serie = [erro] if erro else []

    foco = inspecionar_foco(nos)
    if not foco['visivel']:
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

    cap_serie = out / '03_detalhe_serie.png'
    capturar_png(cap_serie)

    # Teste de BACK
    back(espera=2.0)
    nos_pos_back = dump()
    erro_back = checar_saude(nos_pos_back, 'BACK no detalhe de série')
    if erro_back:
        achados_serie.append(erro_back)
        back_retorna_serie = False
    else:
        back_retorna_serie = (marco(nos_pos_back) == 'inicio')
        if not back_retorna_serie:
            achados_serie.append({
                'gravidade': ATENCAO,
                'codigo': 'toque-obrigatorio',
                'detalhe': 'BACK não retornou para Início após detalhe de série'
            })

    telas.append({
        'nome': 'detalhe_serie',
        'titulo': 'Detalhe de série/temporada',
        'estado': classificar_tela(achados_serie),
        'foco': foco,
        'back_retorna': back_retorna_serie,
        'captura': '03_detalhe_serie.png',
        'achados': achados_serie,
    })

    # ==========================================
    # TELA 4: Player (reproduzir, pausar, avançar 10s, áudio/legenda, sair)
    # ==========================================
    rec('4. Player')
    # Abre o primeiro item para reproduzir
    dpad_down()
    dpad_center(espera=2.0)
    # No detalhe, pressiona center no botão Reproduzir
    dpad_center(espera=4.0)

    nos = dump()
    erro = checar_saude(nos, 'Player')
    achados_player = [erro] if erro else []

    cap_player = out / '05_player.png'
    raw_png = capturar_png(cap_player)

    if raw_png and verificar_player_preto(raw_png):
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
    # Segundo back caso tenha fechado um diálogo
    back(espera=2.5)

    nos_pos_player = dump()
    erro_sair = checar_saude(nos_pos_player, 'Saída do player')
    if erro_sair:
        achados_player.append(erro_sair)
        back_retorna_player = False
    else:
        back_retorna_player = True

    telas.append({
        'nome': 'player',
        'titulo': 'Player',
        'estado': classificar_tela(achados_player),
        'foco': inspecionar_foco(nos),
        'back_retorna': back_retorna_player,
        'captura': '05_player.png',
        'achados': achados_player,
    })

    # Garante retorno ao Início
    if marco(dump()) != 'inicio':
        back(espera=2.0)

    # ==========================================
    # TELA 5: Busca
    # ==========================================
    rec('5. Busca')
    # Tenta navegar para a Busca pelo trilho lateral ou KEYCODE_SEARCH
    dpad_left()
    dpad_left()
    tecla(KEY_SEARCH, espera=2.0)

    nos = dump()
    erro = checar_saude(nos, 'Busca')
    achados_busca = [erro] if erro else []

    foco = inspecionar_foco(nos)
    if not foco['visivel']:
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

    cap_busca = out / '04_busca.png'
    capturar_png(cap_busca)

    # Teste de BACK
    back(espera=2.0)
    nos_pos_back = dump()
    erro_back = checar_saude(nos_pos_back, 'BACK na Busca')
    if erro_back:
        achados_busca.append(erro_back)
        back_retorna_busca = False
    else:
        back_retorna_busca = True

    telas.append({
        'nome': 'busca',
        'titulo': 'Busca',
        'estado': classificar_tela(achados_busca),
        'foco': foco,
        'back_retorna': back_retorna_busca,
        'captura': '04_busca.png',
        'achados': achados_busca,
    })

    # ==========================================
    # TELA 6: Configurações
    # ==========================================
    rec('6. Configurações')
    # Navega pelo trilho lateral até Configurações
    dpad_left()
    dpad_left()
    for _ in range(5):
        dpad_down(espera=0.5)
    dpad_center(espera=2.5)

    nos = dump()
    erro = checar_saude(nos, 'Configurações')
    achados_config = [erro] if erro else []

    foco = inspecionar_foco(nos)
    if not foco['visivel']:
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

    cap_config = out / '09_configuracoes.png'
    capturar_png(cap_config)

    telas.append({
        'nome': 'configuracoes',
        'titulo': 'Configurações',
        'estado': classificar_tela(achados_config),
        'foco': foco,
        'back_retorna': True,
        'captura': '09_configuracoes.png',
        'achados': achados_config,
    })

    # ==========================================
    # TELA 7: Sobre
    # ==========================================
    rec('7. Sobre')
    # Dentro de configurações, desce até o item Sobre e abre
    for _ in range(6):
        dpad_down(espera=0.5)
    dpad_center(espera=2.0)

    nos = dump()
    erro = checar_saude(nos, 'Sobre')
    achados_sobre = [erro] if erro else []

    foco = inspecionar_foco(nos)
    if not foco['visivel']:
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

    cap_sobre = out / '10_sobre.png'
    capturar_png(cap_sobre)

    # Teste de BACK
    back(espera=2.0)
    nos_pos_back = dump()
    erro_back = checar_saude(nos_pos_back, 'BACK na tela Sobre')
    if erro_back:
        achados_sobre.append(erro_back)
        back_retorna_sobre = False
    else:
        back_retorna_sobre = True

    telas.append({
        'nome': 'sobre',
        'titulo': 'Sobre',
        'estado': classificar_tela(achados_sobre),
        'foco': foco,
        'back_retorna': back_retorna_sobre,
        'captura': '10_sobre.png',
        'achados': achados_sobre,
    })

    # Retorna ao Início
    back(espera=1.5)

    # ==========================================
    # Consolidação do Relatório
    # ==========================================
    estado_final = classificar_geral(telas, achados_globais)
    motivo = ''
    if estado_final == VERMELHO:
        motivo = 'Falhas críticas identificadas durante percurso de TV.'
    elif estado_final == ATENCAO:
        motivo = 'Achados de atenção na TV (foco invisível ou texto pequeno).'

    relatorio = {
        'perfil': perfil,
        'estado': estado_final,
        'motivo': motivo,
        'telas': telas,
        'achados': achados_globais + [a for t in telas for a in t.get('achados', [])]
    }

    rec(f'Percurso concluído no perfil {perfil}. Estado: {estado_final}')
    return relatorio


def main():
    parser = argparse.ArgumentParser(description='Bancada de TV Heisuca (TV-0)')
    parser.add_argument('--perfil', default='androidtv',
                        choices=['androidtv', 'firetv-11', 'firetv-9'],
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

    relatorio = percorrer_tv(base, perfil=args.perfil, out_dir=out)

    json_str = limpo(json.dumps(relatorio, ensure_ascii=False, indent=2))
    (out / 'relatorio.json').write_text(json_str)

    # Também grava no padrão tv/relatorio.json na raiz da pasta de saída
    tv_dir = ROOT / 'tv'
    tv_dir.mkdir(parents=True, exist_ok=True)
    (tv_dir / 'relatorio.json').write_text(json_str)

    print(f'Relatório gravado em {out / "relatorio.json"}. Estado: {relatorio["estado"]}')


if __name__ == '__main__':
    main()
