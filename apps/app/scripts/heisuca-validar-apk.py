#!/usr/bin/env python3
"""Confere o APK efetivo, além do fonte: assinatura, identidade e providers."""
import os
from pathlib import Path
import re
import subprocess
import sys

apk = Path(sys.argv[1]).resolve()
sdk = Path(os.environ.get('ANDROID_HOME') or os.environ['ANDROID_SDK_ROOT'])
tools = sdk / 'build-tools' / '36.1.0'
subprocess.run([str(tools / 'apksigner'), 'verify', '--print-certs', str(apk)], check=True)
badging = subprocess.check_output([str(tools / 'aapt'), 'dump', 'badging', str(apk)], text=True)
manifest = subprocess.check_output([str(tools / 'aapt'), 'dump', 'xmltree', str(apk), 'AndroidManifest.xml'], text=True)
preview = os.environ.get('GITHUB_REF_NAME', '').startswith('codex/heisuca-')
package = 'app.heisuca.player.teste.home' if preview else 'app.heisuca.player.teste'
label = 'Heisuca Teste' if preview else 'Heisuca'
assert re.search(r"package: name='" + re.escape(package) + r"'", badging), 'applicationId inesperado'
assert f"application-label:'{label}'" in badging, 'nome do app inesperado'
for suffix in ['fileprovider', 'systemshelf.artwork']:
    assert f'{package}.{suffix}' in manifest, f'provider {suffix} não acompanha applicationId'
assert 'br.com.docaio.cgflix.fileprovider' not in manifest, 'provider legado conflita com outro app'
print(f'APK conferido: {package}, {label}, {apk.stat().st_size} bytes')
