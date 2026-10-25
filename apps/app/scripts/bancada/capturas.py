"""Capturas ao vivo: só confirma ao app depois de concluir operações nativas."""
import json
import re
import subprocess

APP_ID = 'app.heisuca.player.teste.home'
REMOTE = '/sdcard/heisuca-bancada.mp4'


def adb(*args, check=False):
    try:
        result = subprocess.run(['adb', *args], stdout=subprocess.PIPE,
                                stderr=subprocess.DEVNULL, timeout=600 if args[0] == 'install' else 30)
    except (subprocess.TimeoutExpired, OSError):
        result = subprocess.CompletedProcess(args, 1, b'')
    if check and result.returncode:
        raise RuntimeError(f'Operação nativa da bancada não foi concluída: adb {args[0]}.')
    return result


class Capturas:
    def __init__(self, output):
        self.output = output
        self.recording = None
        self.last = 0

    def start(self):
        if self.recording is not None:
            raise RuntimeError('Já existe uma gravação ativa.')
        adb('shell', 'rm', '-f', REMOTE, check=True)
        self.recording = subprocess.Popen(['adb', 'shell', 'screenrecord', '--time-limit', '180', REMOTE],
                                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)

    def stop(self, name):
        if self.recording is None:
            raise RuntimeError('Não existe gravação para encerrar.')
        adb('shell', 'pkill', '-INT', 'screenrecord')
        self.recording.wait(timeout=15)
        self.recording = None
        adb('pull', REMOTE, str(self.output / f'{name}.mp4'), check=True)
        adb('shell', 'rm', '-f', REMOTE, check=True)

    def poll(self):
        result = adb('exec-out', 'run-as', APP_ID, 'cat', 'files/heisuca-bancada-event.json')
        if result.returncode:
            return
        event = json.loads(result.stdout)
        if event['seq'] <= self.last:
            return
        self.handle(event)

    def handle(self, event):
        name, seq = event['name'], event['seq']
        if seq != self.last + 1 or not re.fullmatch(r'[0-9]{2}-[a-z0-9-]+', name):
            raise RuntimeError('Marco inválido da bancada.')
        stops = {'01-login': '01-abertura-login', '04-ficha': '02-acervo-busca-ficha',
                 '06-player': '03-player-nativo', '11-voce': '04-retorno-abas'}
        if name in stops:
            self.stop(stops[name])
        if name in ('02-inicio', '05-player-inicio', '07-ficha-retorno'):
            self.start()
        png = adb('exec-out', 'screencap', '-p', check=True).stdout
        if not png.startswith(b'\x89PNG\r\n\x1a\n') or len(png) < 24:
            raise RuntimeError('Captura nativa inválida.')
        (self.output / f'{name}.png').write_bytes(png)
        if event.get('back') is True:
            adb('shell', 'input', 'keyevent', '4', check=True)
        ack = subprocess.run(['adb', 'exec-out', 'run-as', APP_ID, 'tee', 'files/heisuca-bancada-ack.tmp'],
            input=json.dumps({'seq': seq, 'ok': True}).encode(), stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL, timeout=30)
        if ack.returncode:
            raise RuntimeError('Confirmação não chegou ao app.')
        adb('exec-out', 'run-as', APP_ID, 'chmod', '600', 'files/heisuca-bancada-ack.tmp', check=True)
        adb('exec-out', 'run-as', APP_ID, 'mv', 'files/heisuca-bancada-ack.tmp',
            'files/heisuca-bancada-ack.json', check=True)
        self.last = seq

    def close(self):
        if self.recording is not None:
            try:
                self.stop('video-interrompido')
            except Exception:
                if self.recording is not None:
                    self.recording.kill()
                    self.recording = None
