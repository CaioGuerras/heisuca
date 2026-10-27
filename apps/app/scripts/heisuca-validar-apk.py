#!/usr/bin/env python3
"""Confere o APK efetivo, além do fonte: assinatura, identidade e providers."""
import os
import hashlib
from pathlib import Path
import re
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile


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
# Impressão digital (SHA-256) do certificado de assinatura do Heisuca (chave de envio/teste).
EXPECTED_CERT_SHA256 = 'd415544dae728cd8d402827f1bf17b6af00b2443295b3bad8b463d65d3acd4c1'
certs = subprocess.run([str(tools / 'apksigner'), 'verify', '--print-certs', str(apk)],
                       check=True, capture_output=True, text=True).stdout
print(certs)
digests = re.findall(r'certificate SHA-256 digest: ([0-9a-fA-F]{64})', certs)
assert digests and all(d.lower() == EXPECTED_CERT_SHA256 for d in digests), \
    'APK não está assinado com a chave do Heisuca (certificado inesperado)'
badging = subprocess.check_output([str(tools / 'aapt'), 'dump', 'badging', str(apk)], text=True)
manifest = subprocess.check_output([str(tools / 'aapt'), 'dump', 'xmltree', str(apk), 'AndroidManifest.xml'], text=True)
preview = os.environ.get('GITHUB_REF_NAME', '').startswith(('codex/heisuca-', 'claude/heisuca-'))
package = 'app.heisuca.player.teste.home' if preview else 'app.heisuca.player.teste'
label = 'Heisuca Teste' if preview else 'Heisuca'
assert re.search(r"package: name='" + re.escape(package) + r"'", badging), 'applicationId inesperado'
assert f"application-label:'{label}'" in badging, 'nome do app inesperado'
for suffix in ['fileprovider', 'systemshelf.artwork']:
    assert f'{package}.{suffix}' in manifest, f'provider {suffix} não acompanha applicationId'
assert 'app.heisuca.MainActivity' in manifest, 'activity fora do namespace Heisuca'
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

# M: conferir o manifesto mesclado, incluindo o serviço fornecido pelo plugin.
assert 'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK' in manifest, 'permissão mediaPlayback ausente'
assert 'android.permission.POST_PROMOTED_NOTIFICATIONS' not in manifest, 'Live Updates não se aplicam à mídia'
service_blocks = []
for index, line in enumerate(lines):
    match = re.match(r'(\s*)E: service(?:\s|$)', line)
    if match:
        indent = len(match[1])
        end = index + 1
        while end < len(lines):
            following = re.match(r'(\s*)E:', lines[end])
            if following and len(following[1]) <= indent:
                break
            end += 1
        service_blocks.append('\n'.join(lines[index:end]))
service = next((block for block in service_blocks if 'com.edde746.os_media_controls.MediaPlaybackService' in block), '')
assert re.search(r'android:foregroundServiceType.*0x2\b', service), 'serviço sem tipo mediaPlayback'
assert re.search(r'android:exported.*(?:0x0\b|"false")', service), 'serviço de mídia exportado'
print('Mídia no APK: serviço privado mediaPlayback e nenhuma promoção de Live Update.')
print(f'APK conferido: {package}, {label}, {apk.stat().st_size} bytes')

# O hash do artifact é do ZIP. Registrar também o APK real, sem depender do download.
with apk.open('rb') as content:
    print(f'SHA-256 do APK: {hashlib.file_digest(content, "sha256").hexdigest()}')

with zipfile.ZipFile(apk) as archive:
    license_text = archive.read('assets/flutter_assets/assets/licenses/heisuca_gpl.txt')
    assert b'GNU GENERAL PUBLIC LICENSE' in license_text and b'edde746' in license_text and b'Plezy' in license_text, 'aviso GPL/origem ausente'
    for entry in archive.infolist():
        payload = archive.read(entry).lower()
        assert b'plezy.app' not in payload, f'destino externo legado em {entry.filename}'
        assert b'io/sentry/' not in payload and b'io.sentry.android' not in payload, f'SDK de telemetria em {entry.filename}'
print('Independência conferida no APK: zero plezy.app e zero SDK Sentry.')
