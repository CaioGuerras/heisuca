"""Ações reais do sistema para PiP e MediaSession; sem caminho alternativo para Back."""
import re
from pathlib import Path

PACKAGE = 'app.heisuca.player.teste.home'


def pip_bounds(dump):
    # TaskFragment.dumpInner imprime o retângulo físico do task pinned.
    blocks = re.split(r'(?m)(?=^\s*\* Task\{)', dump)
    for block in blocks:
        header = block.splitlines()[0] if block.splitlines() else ''
        if 'mode=pinned' not in header or PACKAGE not in block:
            continue
        match = re.search(r'mBounds=Rect\((\d+),\s*(\d+) - (\d+),\s*(\d+)\)', block)
        if match:
            left, top, right, bottom = map(int, match.groups())
            if right > left and bottom > top:
                return left, top, right, bottom
    return None


def perform(action, adb, record=lambda name, value: None):
    if action == 'home':
        adb('shell', 'input', 'keyevent', '3', check=True)
    elif action == 'reopen':
        result = adb('shell', 'cmd', 'package', 'resolve-activity', '--brief', PACKAGE, check=True)
        component = result.stdout.decode().strip().splitlines()[-1]
        if not re.fullmatch(re.escape(PACKAGE) + r'/app\.heisuca\.Icone(?:Isis|Heitor)', component):
            raise RuntimeError('Activity de avaliação não encontrada.')
        adb('shell', 'am', 'start', '-n', component, check=True)
    elif action in {'media_pause', 'media_play'}:
        adb('shell', 'cmd', 'media_session', 'dispatch', action.removeprefix('media_'), check=True)
    elif action == 'pip_close':
        tasks = adb('shell', 'dumpsys', 'activity', 'activities', check=True).stdout.decode(errors='replace')
        record('pip-tasks.txt', tasks)
        rectangle = pip_bounds(tasks)
        if rectangle is None:
            raise RuntimeError('Task PiP deste app não encontrado; não toca em outro app.')
        helper = Path(__file__).resolve().parents[2] / '.bancada/ui.jar'
        if not helper.is_file():
            raise RuntimeError('Ferramenta nativa da bancada não compilada.')
        remote = '/data/local/tmp/heisuca-bancada-ui.jar'
        adb('push', str(helper), remote, check=True)
        result = adb('shell', 'CLASSPATH=' + remote, 'app_process', '/system/bin',
                     'HeisucaPipClose', *(str(v) for v in rectangle), capture_errors=True)
        record('pip-automation.log', result.stdout.decode(errors='replace'))
        if result.returncode:
            raise RuntimeError('Clique nativo de fechar PiP falhou; consulte pip-automation.log.')
    else:
        raise RuntimeError('Ação nativa inválida.')
