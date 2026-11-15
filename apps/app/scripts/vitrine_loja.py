#!/usr/bin/env python3
"""Vitrine da loja: roda integration_test/vitrine_loja_test.dart no emulador e tira as capturas pelo host.

Sem segredos: o teste usa o servidor PÚBLICO de demonstração do Jellyfin. As capturas são adb screencap
(incluem o quadro nativo do vídeo), com a barra de status em modo demonstração (12:00, bateria cheia,
sem notificações). Saída: .vitrine/capturas/01-inicio.png … 08-fontes.png.
"""
import base64
import json
import os
from pathlib import Path
import struct
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / '.vitrine/capturas'
APP_ID = 'app.heisuca.player.teste.home'  # pacote do APK de avaliação (heisucaPreview); não muda o applicationId
APK = ROOT / 'build/app/outputs/flutter-apk/app-debug.apk'
EVENTO = 'files/heisuca-vitrine-event.json'
ESPERADAS = {  # nome -> orientação
    '01-inicio': 'retrato', '02-ficha': 'retrato', '03-busca': 'retrato', '04-explorar': 'retrato',
    '05-aparencia': 'retrato', '06-voce': 'retrato', '07-player': 'paisagem', '08-fontes': 'retrato',
}


def adb(*args, check=False):
    try:
        r = subprocess.run(['adb', *args], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                           timeout=600 if args[0] == 'install' else 30)
    except (subprocess.TimeoutExpired, OSError):
        r = subprocess.CompletedProcess(args, 1, b'')
    if check and r.returncode:
        raise RuntimeError(f'adb {args[0]} falhou.')
    return r


def sh(cmd):
    adb('shell', cmd)


def barra_de_status_limpa():
    sh('settings put global sysui_demo_allowed 1')
    demo = 'am broadcast -a com.android.systemui.demo -e command'
    for extra in ('enter', 'clock -e hhmm 1200', 'battery -e level 100 -e plugged false',
                  'network -e wifi show -e level 4 -e fully true', 'network -e mobile show -e datatype none -e level 4',
                  'notifications -e visible false'):
        sh(f'{demo} {extra}')


def tamanho_png(png):
    if not png.startswith(b'\x89PNG\r\n\x1a\n') or len(png) < 24:
        raise RuntimeError('Captura inválida.')
    return struct.unpack('>II', png[16:24])


def responder(seq):
    ack = base64.b64encode(json.dumps({'seq': seq, 'ok': True}).encode()).decode()
    sh(f"run-as {APP_ID} sh -c 'echo {ack} | base64 -d > files/heisuca-vitrine-ack.tmp'")
    adb('exec-out', 'run-as', APP_ID, 'mv', 'files/heisuca-vitrine-ack.tmp', 'files/heisuca-vitrine-ack.json',
        check=True)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    if adb('get-state').stdout.strip() != b'device':
        raise SystemExit('Emulador não ficou pronto.')
    adb('install', '-r', str(APK), check=True)
    # Aviso "Viewing full screen" do sistema cobriria o player na 1ª tela cheia.
    sh('settings put secure immersive_mode_confirmations confirmed')
    for chave in ('window_animation_scale', 'transition_animation_scale', 'animator_duration_scale'):
        sh(f'settings put global {chave} 0')
    sh('settings put global hide_error_dialogs 1')
    barra_de_status_limpa()
    adb('exec-out', 'run-as', APP_ID, 'rm', '-f', EVENTO, 'files/heisuca-vitrine-ack.json')

    env = dict(os.environ, HEISUCA_BANCADA_EVIDENCIAS=str(OUT.parent))  # driver da Bancada: só grava resultado-teste.json
    cmd = ['flutter', 'drive', '--driver', 'test_driver/bancada_android_test.dart',
           '--target', 'integration_test/vitrine_loja_test.dart', '--use-application-binary', str(APK)]
    feitos, ultimo = [], 0
    with (OUT.parent / 'execucao.log').open('w') as log:
        proc = subprocess.Popen(cmd, cwd=ROOT, env=env, stdout=log, stderr=subprocess.STDOUT)
        limite = time.time() + 1200
        while proc.poll() is None:
            if time.time() > limite:
                proc.kill()
                break
            r = adb('exec-out', 'run-as', APP_ID, 'cat', EVENTO)
            try:
                evento = json.loads(r.stdout)
            except ValueError:
                evento = None
            if evento and evento['seq'] > ultimo:
                ultimo = evento['seq']
                nome = evento.get('nome')
                if nome:
                    barra_de_status_limpa()  # o sistema pode sair do modo demonstração ao girar a tela
                    time.sleep(0.5)
                    png = adb('exec-out', 'screencap', '-p', check=True).stdout
                    largura, altura = tamanho_png(png)
                    (OUT / f'{nome}.png').write_bytes(png)
                    feitos.append(nome)
                    print(f'Captura {nome}.png: {largura}x{altura}', flush=True)
                if evento.get('voltar') is True:
                    sh('input keyevent 4')
                    time.sleep(0.8)
                responder(ultimo)
            time.sleep(0.25)
        codigo = proc.wait()
    sh('am broadcast -a com.android.systemui.demo -e command exit')

    erros = []
    for nome, orientacao in ESPERADAS.items():
        arquivo = OUT / f'{nome}.png'
        if not arquivo.is_file():
            erros.append(f'falta {nome}.png')
            continue
        largura, altura = tamanho_png(arquivo.read_bytes())
        if (largura > altura) != (orientacao == 'paisagem'):
            erros.append(f'{nome}.png em orientação errada ({largura}x{altura})')
    if codigo:
        erros.append(f'flutter drive saiu com {codigo} (ver execucao.log)')
    for erro in erros:
        print(f'::error::{erro}', flush=True)
    sys.exit(1 if erros else 0)


if __name__ == '__main__':
    main()
