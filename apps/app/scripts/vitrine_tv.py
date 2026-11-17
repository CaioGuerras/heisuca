#!/usr/bin/env python3
"""Capturas reais da TV com Caminandes: Llamigos, no servidor público do Jellyfin.

Não usa conta privada nem altera a biblioteca. As imagens são screencap do Android;
publicação na Play exige conferência visual posterior, nunca só o estado do roteiro.
"""
import json
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent / 'bancada'))
import tv
from capturas import APP_ID, adb
from desastre import achar_texto
from ui import digitar, fechar_teclado, tocar

OUT = Path(__file__).resolve().parents[1] / '.vitrine-tv'
DEMO = 'https://demo.jellyfin.org/stable'
TITULO = 'Caminandes: Llamigos'


def esperar(predicate, etapa, segundos=90):
    limite = time.monotonic() + segundos
    while time.monotonic() < limite:
        nos = tv.dump_tv()
        if predicate(nos):
            return nos
        time.sleep(2)
    raise RuntimeError(f'Tempo esgotado: {etapa}')


def capturar(nome):
    from PIL import Image, ImageStat
    destino = OUT / f'{nome}.png'
    tv.capturar_png(destino)
    with Image.open(destino) as im:
        assert im.size == (1920, 1080), (nome, im.size)
        assert sum(ImageStat.Stat(im.convert('RGB')).stddev) > 20, 'imagem quase uniforme'
    print(f'CAPTURA {nome}: 1920x1080', flush=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    try:
        apk = Path(__file__).resolve().parents[1] / 'build/app/outputs/flutter-apk/app-debug.apk'
        adb('install', '-r', str(apk), check=True)
        # O emulador é novo e efêmero: não há sessões privadas para reaproveitar.
        adb('shell', 'settings', 'put', 'secure', 'immersive_mode_confirmations', 'confirmed')
        tv.abrir_app_tv()
        if not tv.fazer_login_tv(DEMO, conta='demo', registrar=lambda s: print(s, flush=True)):
            raise RuntimeError('Login na demonstração não concluiu')
        esperar(lambda ns: tv.reconhecer_tela_tv(ns) == 'inicio', 'início')
        _, menu = tv.abrir_destino_tv('Buscar')
        assert menu, 'menu da TV não abriu'
        nos = esperar(lambda ns: any(n['cls'].endswith('EditText') for n in ns), 'campo de busca')
        campo = next(n for n in nos if n['cls'].endswith('EditText'))
        tocar(campo)
        digitar('Llamigos')
        esperar(lambda ns: achar_texto(ns, TITULO, exato=False) is not None, 'resultado Llamigos')
        fechar_teclado()
        time.sleep(5)
        capturar('01-busca-llamigos')
        alvo = achar_texto(tv.dump_tv(), TITULO, exato=False)
        assert alvo is not None, 'resultado desapareceu'
        tocar(alvo)
        esperar(lambda ns: achar_texto(ns, 'Assistir', 'Continuar', exato=False) is not None, 'ficha do filme')
        time.sleep(7)
        capturar('02-ficha-llamigos')
        botao = achar_texto(tv.dump_tv(), 'Assistir', 'Continuar', exato=False)
        assert botao is not None, 'botão de reprodução ausente'
        tocar(botao)
        time.sleep(18)
        nos = tv.dump_tv()
        textos = ' '.join((n.get('text','') + ' ' + n.get('desc','')) for n in nos).lower()
        assert not any(t in textos for t in ['não mandou nenhuma versão', 'não foi possível reproduzir', 'playback failed']), 'player mostrou erro'
        capturar('03-player-llamigos')
        tv.dpad_center(1)
        capturar('04-controles-llamigos')
        (OUT/'relatorio.json').write_text(json.dumps({'estado':'capturas-geradas-conferir-visualmente','servidor':DEMO,'titulo':TITULO,'imagens':sorted(p.name for p in OUT.glob('0*.png'))},ensure_ascii=False,indent=2))
    except Exception:
        tv.capturar_png(OUT/'diagnostico-falha.png')
        raise
    finally:
        # Encerra a reprodução/sessão pelo app, sem mexer na conta pública.
        adb('shell', 'input', 'keyevent', '4')
        adb('shell', 'am', 'force-stop', APP_ID)


if __name__ == '__main__':
    main()
