#!/usr/bin/env python3
"""Package the checksum-pinned, validated Linux binary without rebuilding it."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tarfile
import urllib.request

ROOT = Path(__file__).resolve().parents[3]


def run(*args):
    return subprocess.check_output(args, text=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, default=ROOT / 'dist/fedora')
    out = parser.parse_args().output.resolve()
    out.mkdir(parents=True, exist_ok=True)
    release = json.loads((ROOT / 'tool/desktop/fedora/release.json').read_text())
    assert re.fullmatch(r'[0-9]+(?:\.[0-9]+){2}', release['version'])
    assert re.fullmatch(r'[a-f0-9]{40}', release['revision'])
    assert release['url'].startswith('https://heisuca.docaio.com.br/pacotes/linux/')
    archive = out / 'validated-linux.tar.gz'
    with urllib.request.urlopen(release['url'], timeout=60) as response, archive.open('wb') as target:
        shutil.copyfileobj(response, target)
    assert hashlib.sha256(archive.read_bytes()).hexdigest() == release['sha256'], 'Bundle checksum mismatch'
    extracted = out / 'input'
    assert not extracted.exists(), 'Use a fresh output directory'
    with tarfile.open(archive) as tar:
        tar.extractall(extracted, filter='data')
    app = extracted / 'heisuca'
    assert (app / 'heisuca-bin').is_file() and os.access(app / 'heisuca-bin', os.X_OK)
    for link in app.rglob('*'):
        if link.is_symlink():
            assert link.resolve().is_relative_to(app.resolve()), 'External bundle symlink'
    # Derive ABI requirements from every shipped ELF. Remove only capabilities
    # actually provided by this private bundle; do not export them to the OS.
    elfs = []
    for path in app.rglob('*'):
        if path.is_file() and not path.is_symlink():
            with path.open('rb') as source:
                if source.read(4) == b'\x7fELF':
                    elfs.append(str(path))
    assert elfs
    rpmdeps = '/usr/lib/rpm/rpmdeps'
    own = set(run(rpmdeps, '--provides', *elfs).splitlines())
    required = set(run(rpmdeps, '--requires', *elfs).splitlines()) - own
    assert any(item.startswith('libc.so.6(') for item in required), 'Empty ABI scan'
    required.update(['/bin/bash', 'desktop-file-utils', 'hicolor-icon-theme'])
    assert all(re.fullmatch(r'[A-Za-z0-9_./+()=<> :\-]+', item) for item in required)
    (out / 'rpm-requires.txt').write_text('\n'.join(sorted(required)) + '\n')
    (app / 'LEIA-ME.txt').write_text(
        'Heisuca Linux x64 — RPM de teste para Fedora 45 / Wayland\n'
        'Instalar: sudo dnf install ./heisuca-linux-x64.rpm\n'
        'X11 não reproduz vídeo nesta versão. Os dados ficam no perfil do usuário.\n'
        'Conexões usam Secret Service; sem serviço disponível, a sessão é temporária.\n'
        'https://heisuca.docaio.com.br/\n')
    (app / 'source-release.json').write_text(json.dumps(release, indent=2) + '\n')
    top = out / 'rpmbuild'
    top.mkdir()
    desktop = ROOT / 'linux/packaging/app.heisuca.player.desktop.desktop'
    icon = ROOT / 'assets/heisuca/icone_shikkoku_cheio.svg'
    spec = out / 'heisuca.spec'
    # Preserve tested ELF bytes; do not strip/relink them with build helpers.
    spec.write_text('''%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}
%global _binary_payload w9.zstdio
Name: heisuca
Version: ''' + release['version'] + '''
Release: 1%{?dist}
Summary: Heisuca — player Plex e Jellyfin
License: GPL-3.0
URL: https://heisuca.docaio.com.br/
BuildArch: x86_64
AutoReq: no
AutoProv: no
''' + ''.join('Requires: ' + item + '\n' for item in sorted(required)) + '''Recommends: gnome-keyring

%description
Heisuca para Linux x64 em sessão Wayland. Bibliotecas privadas e dados
do usuário separados dos aplicativos do sistema.

%install
mkdir -p "%{buildroot}/opt" "%{buildroot}/usr/bin"
cp -a ''' + shlex.quote(str(app)) + ''' "%{buildroot}/opt/heisuca"
ln -s /opt/heisuca/heisuca "%{buildroot}/usr/bin/heisuca"
install -D -m644 ''' + shlex.quote(str(desktop)) + ''' "%{buildroot}/usr/share/applications/app.heisuca.player.desktop.desktop"
install -D -m644 ''' + shlex.quote(str(icon)) + ''' "%{buildroot}/usr/share/icons/hicolor/scalable/apps/heisuca.svg"
install -D -m644 ''' + shlex.quote(str(app / 'LICENSE.txt')) + ''' "%{buildroot}%{_licensedir}/heisuca/LICENSE.txt"

%files
%defattr(-,root,root,-)
/opt/heisuca
/usr/bin/heisuca
/usr/share/applications/app.heisuca.player.desktop.desktop
/usr/share/icons/hicolor/scalable/apps/heisuca.svg
%license %{_licensedir}/heisuca/LICENSE.txt
''')
    subprocess.run(['rpmbuild', '-bb', '--define', '_topdir ' + str(top),
                    '--define', 'dist .fc45', str(spec)], check=True)
    packages = list((top / 'RPMS/x86_64').glob('*.rpm'))
    assert len(packages) == 1
    package = out / 'heisuca-linux-x64.rpm'
    shutil.copy2(packages[0], package)
    digest = hashlib.sha256(package.read_bytes()).hexdigest()
    (out / 'heisuca-linux-x64.rpm.sha256').write_text(digest + '  ' + package.name + '\n')
    release['rpm_sha256'] = digest
    release['binary_sha256'] = hashlib.sha256((app / 'heisuca-bin').read_bytes()).hexdigest()
    release['elf_sha256'] = {str(Path(item).relative_to(app)): hashlib.sha256(Path(item).read_bytes()).hexdigest() for item in elfs}
    (out / 'provenance.json').write_text(json.dumps(release, indent=2) + '\n')
    print(package.name, package.stat().st_size, digest)


if __name__ == '__main__':
    main()
