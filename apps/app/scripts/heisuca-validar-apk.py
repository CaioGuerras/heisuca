#!/usr/bin/env python3
"""Confere o APK efetivo, além do fonte: assinatura, identidade e providers."""
import os
import hashlib
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET


def validate_source():
    manifest_path = Path(__file__).resolve().parents[1] / "android/app/src/main/AndroidManifest.xml"
    app = ET.parse(manifest_path).getroot().find("application")
    ns = "{http://schemas.android.com/apk/res/android}"
    assert app is not None
    authorities = [provider.attrib[ns + "authorities"] for provider in app.findall("provider")]
    assert len(authorities) == len(set(authorities)), "providers duplicados"
    for suffix in ["fileprovider", "systemshelf.artwork"]:
        authority = "${applicationId}." + suffix
        provider = next(p for p in app.findall("provider") if p.attrib[ns + "authorities"] == authority)
        assert provider.attrib[ns + "exported"] == "false", "provider exportado sem necessidade"
        assert provider.attrib[ns + "grantUriPermissions"] == "true", "faltam grants individuais"
    assert app.attrib[ns + "label"] == "${heisucaAppLabel}"
    print("Manifesto fonte conferido: providers privados, únicos e por applicationId.")


validate_source()
if sys.argv[1] == "--source-only":
    raise SystemExit(0)

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
lines = manifest.splitlines()
blocks = []
for index, line in enumerate(lines):
    match = re.match(r'(\s*)E: provider(?:\s|$)', line)
    if match:
        indent = len(match[1])
        end = index + 1
        while end < len(lines):
            following = re.match(r'(\s*)E:', lines[end])
            if following and len(following[1]) <= indent:
                break
            end += 1
        blocks.append('\n'.join(lines[index:end]))
for suffix in ['fileprovider', 'systemshelf.artwork']:
    block = next((b for b in blocks if f'{package}.{suffix}' in b), '')
    assert re.search(r'android:exported.*(?:0x0\b|"false")', block), f'{suffix}: exported não é false no APK'
    assert re.search(r'android:grantUriPermissions.*(?:0xffffffff\b|"true")', block), f'{suffix}: faltam grants no APK'

print(f'APK conferido: {package}, {label}, {apk.stat().st_size} bytes')

# O hash do artifact é do ZIP. Registrar também o APK real, sem depender do download.
with apk.open('rb') as content:
    print(f'SHA-256 do APK: {hashlib.file_digest(content, "sha256").hexdigest()}')
