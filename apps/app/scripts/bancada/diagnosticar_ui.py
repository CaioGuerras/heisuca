"""Sonda UiAutomation isolado, sem APK/credenciais e sem injetar eventos."""
from pathlib import Path
import subprocess


def main():
    out = Path('.bancada/ui-diagnostico')
    out.mkdir(parents=True, exist_ok=True)
    command = ('CLASSPATH=/data/local/tmp/heisuca-bancada-ui.jar '
               'app_process /system/bin --nice-name=heisuca-bancada-ui HeisucaPipClose --probe')
    result = subprocess.run(['adb', 'shell', command], stdout=subprocess.PIPE,
                            stderr=subprocess.STDOUT, timeout=30)
    text = result.stdout.decode(errors='replace')
    print('Código do helper:', result.returncode)
    print(text)
    (out / 'helper.log').write_text(text)
    diagnostics = {
        'android.log': ['adb', 'logcat', '-d', '-b', 'main', '-b', 'system', '-b', 'crash', '-b', 'events', '-t', '1500'],
        'kernel.log': ['adb', 'shell', 'dmesg'],
        'memoria.log': ['adb', 'shell', 'cat', '/proc/meminfo', '/proc/pressure/cpu', '/proc/pressure/memory'],
    }
    # Emulador descartável sem app, login ou acesso ao servidor; não contém dados da família.
    for name, args in diagnostics.items():
        data = subprocess.run(args, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=20)
        (out / name).write_bytes(data.stdout)
        if name == 'android.log':
            print('\n'.join(line for line in data.stdout.decode(errors='replace').splitlines()
                            if any(key in line for key in ['AndroidRuntime', 'heisuca-bancada-ui',
                                    'HeisucaPipClose', 'lmkd', 'denied', 'dex file', 'FATAL'])))
    return result.returncode


if __name__ == '__main__':
    raise SystemExit(main())
