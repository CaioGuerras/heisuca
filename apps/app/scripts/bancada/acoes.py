"""Ações reais do sistema para PiP e MediaSession; sem caminho alternativo para Back."""
import re
import xml.etree.ElementTree as ET

PACKAGE = 'app.heisuca.player.teste.home'
REMOTE = '/sdcard/heisuca-pip-ui.xml'


def bounds(node):
    match = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', node.get('bounds', ''))
    if not match:
        return None
    left, top, right, bottom = map(int, match.groups())
    return (left, top, right, bottom) if right > left and bottom > top else None


def close_button(root):
    for node in root.iter('node'):
        label = node.get('content-desc', '').strip().casefold()
        resource = node.get('resource-id', '').rsplit('/', 1)[-1]
        if node.get('package') == 'com.android.systemui' and (
            label in {'close', 'dismiss', 'fechar', 'dispensar'} or resource in {'dismiss', 'pip_dismiss'}
        ):
            rectangle = bounds(node)
            if rectangle:
                return rectangle
    return None


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


def perform(action, adb):
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
        def ui():
            adb('shell', 'uiautomator', 'dump', REMOTE, check=True)
            raw = adb('exec-out', 'cat', REMOTE, check=True).stdout
            adb('shell', 'rm', '-f', REMOTE, check=True)
            return ET.fromstring(raw)
        root = ui()
        rectangle = close_button(root)
        if rectangle is None:
            # O dump clássico do UiAutomator só contém a janela ativa (AOSP DumpCommand).
            # A janela PiP pode estar sem foco; usa o retângulo real do task para abrir seu menu.
            tasks = adb('shell', 'dumpsys', 'activity', 'activities', check=True).stdout.decode(errors='replace')
            rectangle = pip_bounds(tasks)
            if rectangle is None:
                raise RuntimeError('Task PiP deste app não encontrado; não toca em outro app.')
            left, top, right, bottom = rectangle
            adb('shell', 'input', 'tap', str((left+right)//2), str((top+bottom)//2), check=True)
            rectangle = close_button(ui())
        if rectangle is None:
            raise RuntimeError('Botão de fechar PiP não encontrado; nenhuma saída simulada.')
        left, top, right, bottom = rectangle
        adb('shell', 'input', 'tap', str((left+right)//2), str((top+bottom)//2), check=True)
    else:
        raise RuntimeError('Ação nativa inválida.')
