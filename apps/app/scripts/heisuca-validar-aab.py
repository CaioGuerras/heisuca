#!/usr/bin/env python3
"""Confere o AAB da Play: assinatura com a chave do Heisuca e pacote da loja (app.heisuca.player)."""
import hashlib
import re
import subprocess
import sys
import zipfile
from pathlib import Path

# Mesmo certificado do APK de teste (heisuca-validar-apk.py): chave de envio do Heisuca.
EXPECTED_CERT_SHA256 = 'd415544dae728cd8d402827f1bf17b6af00b2443295b3bad8b463d65d3acd4c1'
PACKAGE = 'app.heisuca.player'

aab = Path(sys.argv[1]).resolve()
# O AAB é assinado no esquema JAR (v1): o apksigner não lê, o keytool sim.
certs = subprocess.run(['keytool', '-printcert', '-jarfile', str(aab)],
                       check=True, capture_output=True, text=True).stdout
digests = [d.replace(':', '').lower() for d in re.findall(r'SHA256: ([0-9A-Fa-f:]{95})', certs)]
assert digests and all(d == EXPECTED_CERT_SHA256 for d in digests), \
    f'AAB não está assinado com a chave do Heisuca: {digests}'
print('Assinatura do AAB: chave do Heisuca (d415544d…).')

with zipfile.ZipFile(aab) as z:
    # O manifesto do AAB é protobuf; as strings ficam em UTF-8 puro.
    manifest = z.read('base/manifest/AndroidManifest.xml')
    nomes = z.namelist()
assert PACKAGE.encode() in manifest, 'pacote da loja ausente no manifesto'
assert b'app.heisuca.player.teste' not in manifest, 'AAB com pacote de teste'
assert b'br.com.docaio.cgflix' not in manifest, 'provider legado no manifesto'


def abis(lib):
    return sorted({n.split('/')[2] for n in nomes if re.fullmatch(rf'base/lib/[^/]+/{lib}', n)})


assert 'arm64-v8a' in abis('libapp.so'), f'AAB sem código Dart arm64-v8a: {abis("libapp.so")}'
print('ABIs do app:', ', '.join(abis('libapp.so')), '| libmpv:', ', '.join(abis('libmpv.so')) or 'nenhuma')
print(f'SHA-256 do AAB: {hashlib.sha256(aab.read_bytes()).hexdigest()}')
