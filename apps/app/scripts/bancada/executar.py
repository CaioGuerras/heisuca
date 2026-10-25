#!/usr/bin/env python3
"""Executa o teste no emulador e sempre encerra sessões/restaura o item do teste."""
import json
import os
from pathlib import Path
import subprocess
import sys
import signal
import threading
import time

from servidor import BancadaIndisponivel, RestauracaoFalhou, Servidor, selecionar, estado, limpar_log

APP_ID = 'app.heisuca.player.teste.home'
ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.bancada/evidencias'


def adb(*args, check=False):
    result = subprocess.run(['adb', *args], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    if check and result.returncode:
        raise BancadaIndisponivel('Emulador indisponível para uma operação da bancada.')
    return result


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    base = os.environ.get('HEISUCA_TESTE_SERVIDOR', '').strip()
    names = [n.strip() for n in os.environ.get('HEISUCA_TESTE_CONTAS', '').splitlines() if n.strip()]
    names.sort(key=lambda n: n.lower() != 'teste-sem-senha')
    report = {'status': 'instável', 'restauracao': 'não necessária'}
    client = video = name = None
    playback_possible = False
    recording = None
    result_code = 75
    def stop_group(pid):
        try: os.killpg(pid, signal.SIGTERM)
        except ProcessLookupError: pass
    def interrupted(_signal, _frame):
        raise KeyboardInterrupt
    signal.signal(signal.SIGTERM, interrupted)
    try:
        if not base.startswith(('https://', 'http://')) or not names:
            raise BancadaIndisponivel('Segredos da bancada não foram disponibilizados ao job.')
        if adb('get-state').stdout.strip() != b'device':
            raise BancadaIndisponivel('Emulador não ficou pronto.')
        client, name, video = selecionar(base, names)
        previous = video['UserData']
        report.update({'conta': 'dedicada' if name.lower() == 'teste-sem-senha' else 'rodízio',
            'duracao_arquivo_segundos': video.get('RunTimeTicks', 0) / 10_000_000})
        # O APK não contém credenciais. Configuração vai por stdin ao diretório privado.
        adb('install', '-r', str(ROOT / 'build/app/outputs/flutter-apk/app-debug.apk'), check=True)
        config = json.dumps({'server': base, 'user': name, 'item': video['Id'], 'title': video['Name']}).encode()
        injected = subprocess.run(['adb', 'exec-out', 'run-as', APP_ID, 'sh', '-c',
            'mkdir -p files\numask 077\ncat > files/heisuca-bancada-config.json'],
            input=config, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
        if injected.returncode:
            raise BancadaIndisponivel('Configuração privada não chegou ao emulador.')
        env = dict(os.environ)
        env.pop('HEISUCA_TESTE_SERVIDOR', None)
        env.pop('HEISUCA_TESTE_CONTAS', None)
        env['HEISUCA_BANCADA_EVIDENCIAS'] = str(OUT)
        protected = names + [client.token]
        adb('shell', 'rm', '-f', '/sdcard/heisuca-bancada.mp4')
        recording = subprocess.Popen(['adb', 'shell', 'screenrecord', '--time-limit', '180', '/sdcard/heisuca-bancada.mp4'],
            stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        playback_possible = True
        command = ['flutter', 'drive', '--driver', 'test_driver/bancada_android_test.dart',
            '--target', 'integration_test/bancada_android_test.dart', '--use-application-binary',
            'build/app/outputs/flutter-apk/app-debug.apk']
        with (OUT / 'execucao.log').open('w') as log:
            process = subprocess.Popen(command, cwd=ROOT, env=env, stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT, text=True, errors='replace', start_new_session=True)
            deadline = threading.Timer(900, stop_group, args=(process.pid,))
            deadline.daemon = True
            deadline.start()
            try:
                for line in process.stdout:
                    if line.startswith('result {'):
                        line = 'Resposta do driver recebida.\n'
                    safe = limpar_log(line, protected, base)
                    if 'BANCADA_OCUPADA' in safe: report['ocupada'] = True
                    log.write(safe[:2000])
                    log.flush()
                code = process.wait()
            finally:
                deadline.cancel()
                if process.poll() is None: stop_group(process.pid)
        if code:
            result_code = 75 if report.get('ocupada') else 1
            report['status'] = 'instável' if result_code == 75 else 'falhou'
        else:
            details = json.loads((OUT / 'resultado-teste.json').read_text())
            if not details.get('testeEncerrado') or not details.get('video', {}).get('quadroNativo'):
                raise RuntimeError('O driver não confirmou o percurso completo e o quadro nativo.')
            for required in ('01-login.png', '02-inicio.png', '03-busca.png', '04-ficha.png', '06-player.png',
                             '09-biblioteca.png', '10-baixados.png', '11-voce.png', '01-abertura-login.mp4',
                             '02-acervo-busca-ficha.mp4', '03-player-nativo.mp4', '04-retorno-abas.mp4'):
                if not (OUT / required).is_file() or (OUT / required).stat().st_size < 100:
                    raise RuntimeError('Falta uma captura ou vídeo obrigatório.')
            for capture in OUT.glob('*.mp4'):
                probe = subprocess.run(['ffprobe', '-v', 'error', '-select_streams', 'v:0',
                    '-show_entries', 'stream=width,height', '-show_entries', 'format=duration',
                    '-of', 'json', str(capture)], capture_output=True, text=True)
                metadata = json.loads(probe.stdout) if probe.returncode == 0 else {}
                if not metadata.get('streams') or float(metadata.get('format', {}).get('duration', 0)) <= 0:
                    raise RuntimeError('Uma captura de vídeo não tem faixa de imagem e duração válidas.')
            report.update({'status': 'aprovado', 'video': details['video'], 'passos': details['passos']})
            result_code = 0
    except BancadaIndisponivel as error:
        report.update({'status': 'instável', 'motivo': str(error)})
        result_code = 75
    except Exception:
        report.update({'status': 'falhou', 'motivo': 'O percurso da bancada não foi concluído; consulte o log sem dados privados.'})
        result_code = 1
    finally:
        # Nenhum produtor do app pode escrever depois da restauração.
        adb('shell', 'am', 'force-stop', APP_ID)
        adb('shell', 'pkill', '-INT', 'screenrecord')
        if recording:
            try: recording.wait(timeout=10)
            except subprocess.TimeoutExpired: recording.kill()
        if result_code != 0:
            adb('pull', '/sdcard/heisuca-bancada.mp4', str(OUT / 'video-interrompido.mp4'))
        app_session = adb('exec-out', 'run-as', APP_ID, 'cat', 'files/heisuca-bancada-session.json')
        try:
            if client and video:
                if app_session.returncode == 0:
                    session = json.loads(app_session.stdout)
                    if session.get('user', '').replace('-', '').lower() != client.user.replace('-', '').lower():
                        raise RestauracaoFalhou('Sessão do emulador não pertence à conta selecionada.')
                    Servidor(base, session['token'], session['user'], session['device']).logout()
                elif playback_possible and (OUT / '02-inicio.png').exists():
                    raise RestauracaoFalhou('Não foi possível encerrar com segurança a sessão do emulador.')
                if estado(client.item(video['Id'])['UserData']) != estado(video['UserData']):
                    client.restaurar(video['Id'], video['UserData'])
                report['restauracao'] = 'confirmada: progresso, assistido, contagem, data e preferências preservados'
        except Exception:
            report.update({'status': 'restauração pendente', 'restauracao': 'não confirmada',
                'motivo': 'A bancada recusou marcar verde sem confirmar a limpeza do que criou.',
                'conta_posicao': names.index(name) + 1 if name in names else None,
                'item_id': video.get('Id') if video else None})
            result_code = 1
        finally:
            if client:
                try: client.logout()
                except BancadaIndisponivel: pass
            adb('shell', 'pm', 'clear', APP_ID)
        (OUT / 'relatorio.json').write_text(json.dumps(report, ensure_ascii=False, indent=2))
        print(f'Bancada: {report["status"]}. Restauração: {report["restauracao"]}.')
        if report.get('video'):
            print('Prova do player: ' + json.dumps(report['video'], ensure_ascii=False))
    return result_code


if __name__ == '__main__': sys.exit(main())
