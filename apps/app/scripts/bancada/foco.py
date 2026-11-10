"""Recortes de estado do Android, sem enviar eventos nem corrigir foco."""
import re
import time


def linhas_de_foco(text):
    return [line.strip() for line in text.splitlines()
            if re.search(r'\b(?:topResumedActivity|mResumedActivity|mFocusedApp|mCurrentFocus)\b', line)]


def janela_do_app(text, package):
    selected = []
    own = False
    for line in text.splitlines():
        if re.match(r'\s*Window #[0-9]+ Window\{', line):
            own = package in line
            if own: selected.append(line.strip())
        elif own and re.search(r'\b(?:mAttrs|mViewVisibility|mHasSurface|mOnBackInvokedCallbackInfo|mActivityRecord|isOnScreen|isVisible)\b', line):
            selected.append(line.strip())
    return selected


def coletar_foco(adb, package):
    started = time.monotonic()
    activity = adb('shell', 'dumpsys', 'activity', 'activities')
    window = adb('shell', 'dumpsys', 'window')
    return {'disponivel': activity.returncode == 0 and window.returncode == 0,
            'atividade': linhas_de_foco(activity.stdout.decode(errors='replace')),
            'janela': linhas_de_foco(window.stdout.decode(errors='replace')),
            'janelaDoApp': janela_do_app(window.stdout.decode(errors='replace'), package),
            'coletaMs': round((time.monotonic() - started) * 1000)}
