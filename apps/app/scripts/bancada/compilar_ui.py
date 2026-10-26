"""Compila a ferramenta de UiAutomation só para o emulador; não modifica o APK."""
import os
import re
from pathlib import Path
import subprocess


def main():
    sdk = Path(os.environ.get('ANDROID_HOME') or os.environ['ANDROID_SDK_ROOT'])
    android = sorted(sdk.glob('platforms/android-*/android.jar'),
                     key=lambda p: tuple(map(int, re.findall(r'\d+', p.parent.name))))[-1]
    d8 = sorted(sdk.glob('build-tools/*/d8'), key=lambda p: tuple(
        int(n) for n in p.parent.name.split('.') if n.isdigit()))[-1]
    output = Path('.bancada/ui')
    output.mkdir(parents=True, exist_ok=True)
    subprocess.run(['javac', '--release', '8', '-cp', str(android), '-d', str(output),
                    'scripts/bancada/HeisucaPipClose.java'], check=True)
    subprocess.run([str(d8), '--lib', str(android), '--output', str(output),
                    str(output / 'HeisucaPipClose.class')], check=True)
    subprocess.run(['jar', 'cf', '.bancada/ui.jar', '-C', str(output), 'classes.dex'], check=True)


if __name__ == '__main__':
    main()
