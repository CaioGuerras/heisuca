"""Capturas ao vivo: só confirma ao app depois de concluir operações nativas."""
import base64
import json
import re
import subprocess
from foco import coletar_foco
from acoes import perform
from imagem import analisar

APP_ID = 'app.heisuca.player.teste.home'
REMOTE = '/sdcard/heisuca-bancada.mp4'


def adb(*args, check=False, capture_errors=False):
    try:
        result = subprocess.run(['adb', *args], stdout=subprocess.PIPE,
                                stderr=subprocess.STDOUT if capture_errors else subprocess.DEVNULL,
                                timeout=600 if args[0] == 'install' else 30)
    except (subprocess.TimeoutExpired, OSError):
        result = subprocess.CompletedProcess(args, 1, b'')
    if check and result.returncode:
        raise RuntimeError(f'Operação nativa da bancada não foi concluída: adb {args[0]}.')
    return result


class Capturas:
    def __init__(self, output, sanitize=lambda value: value):
        self.output = output
        self.sanitize = sanitize
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

    def focus(self, name, phase):
        state = {'marco': name, **coletar_foco(adb, APP_ID)}
        safe = self.sanitize(json.dumps(state, ensure_ascii=False))
        (self.output / f'{name}-foco-{phase}.json').write_text(safe)
        print(f'BANCADA_FOCO_{phase.upper()}: {safe}', flush=True)

    def poll(self):
        result = adb('exec-out', 'run-as', APP_ID, 'cat', 'files/heisuca-bancada-event.json')
        if result.returncode:
            return
        try:
            event = json.loads(result.stdout)
        except ValueError:
            return  # sem evento ainda: o adb devolve a mensagem de erro com código 0
        if event['seq'] <= self.last:
            return
        self.handle(event)

    def handle(self, event):
        name, seq = event['name'], event['seq']
        if seq != self.last + 1 or not re.fullmatch(r'[0-9]{2}-[a-z0-9-]+', name):
            raise RuntimeError('Marco inválido da bancada.')
        print(f'BANCADA_MARCO: {name}', flush=True)
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
        if event.get('decodedFrame') is True:
            # Caminho fixo, nunca fornecido pelo evento: não pode ler arquivo privado arbitrário.
            decoded = adb('exec-out', 'run-as', APP_ID, 'cat',
                          'files/heisuca-bancada-video-frame.png', check=True).stdout
            if not decoded.startswith(b'\x89PNG\r\n\x1a\n') or len(decoded) < 24:
                raise RuntimeError('Quadro decodificado não é um PNG válido.')
            (self.output / f'{name}-decodificado.png').write_bytes(decoded)
        image = None
        if name in ('06-player', '21-imagem-apos-audio'):
            image = analisar(png)
            (self.output / f'{name}-imagem.json').write_text(json.dumps(image, ensure_ascii=False, indent=2))
            print('BANCADA_IMAGEM: ' + json.dumps({'marco': name, **image}, ensure_ascii=False), flush=True)
            if image['imagem'] == 'não':
                raise RuntimeError('Imagem nativa preta: ' + name)
        if event.get('action'):
            if event.get('back') is True:
                raise RuntimeError('Marco não pode misturar ações.')
            self.focus(name, 'antes')
            perform(event['action'], adb, record=lambda suffix, value:
                    (self.output / f'{name}-{suffix}').write_text(self.sanitize(value)))
            self.focus(name, 'depois')
        if event.get('back') is True:
            self.focus(name, 'antes')
            adb('shell', 'input', 'keyevent', '4', check=True)
            self.focus(name, 'depois')
        elif name.startswith('12-falha'):
            self.focus(name, 'falha')
        # `adb exec-out` não repassa o fim da entrada (um `tee` remoto espera para sempre); o ACK vai no argumento.
        ack = base64.b64encode(json.dumps({'seq': seq, 'ok': True, 'imagem': image}).encode()).decode()
        adb('shell', f"run-as {APP_ID} sh -c 'echo {ack} | base64 -d > files/heisuca-bancada-ack.tmp'", check=True)
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
