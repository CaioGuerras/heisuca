#!/usr/bin/env python3
"""Build and refresh signed APT and RPM repositories for Heisuca offline."""
import argparse
from datetime import datetime, timedelta, timezone
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tempfile
import urllib.parse

EXPECTED_ELF_COUNT = 161


def run_cmd(cmd, *, cwd=None, env=None, input_bytes=None):
    res = subprocess.run(
        [str(c) for c in cmd],
        cwd=str(cwd) if cwd else None,
        env=env,
        input=input_bytes,
        capture_output=True,
        check=True,
    )
    return res.stdout if input_bytes is not None else res.stdout.decode('utf-8', 'replace')


def digest_file(path: Path, algo: str = 'sha256') -> str:
    h = hashlib.new(algo)
    with path.open('rb') as src:
        for chunk in iter(lambda: src.read(65536), b''):
            h.update(chunk)
    return h.hexdigest()


def parse_sha256_input(raw: str) -> str:
    val = raw.strip()
    if not re.fullmatch(r'[a-fA-F0-9]{64}', val):
        p = Path(val)
        if p.is_file():
            val = p.read_text(encoding='utf-8').strip().split()[0]
    val = val.lower()
    if not re.fullmatch(r'[a-f0-9]{64}', val):
        raise ValueError(f'Invalid SHA-256 digest: {raw}')
    return val


def validate_base_url(url: str) -> str:
    u = urllib.parse.urlsplit(url.strip())
    if u.scheme != 'https' or u.hostname != 'heisuca.docaio.com.br':
        raise ValueError('base-url must use https://heisuca.docaio.com.br')
    if u.query or u.fragment or u.username or u.password:
        raise ValueError('base-url must not contain query, fragment, or credentials')
    clean_path = u.path.rstrip('/')
    if not clean_path.startswith('/') or '..' in Path(clean_path).parts:
        raise ValueError('Invalid base-url path')
    return f'https://{u.netloc}{clean_path}'


def validate_disjoint_paths(out_dir: Path, gpg_dir: Path, refresh: bool) -> None:
    out_res = out_dir.resolve()
    gpg_res = gpg_dir.resolve()
    if not gpg_res.is_dir():
        raise ValueError(f'Missing GNUPGHOME directory: {gpg_res}')
    if out_res == gpg_res or out_res.is_relative_to(gpg_res) or gpg_res.is_relative_to(out_res):
        raise ValueError('Output directory and GNUPGHOME must not contain each other')
    if refresh:
        pool = out_res / 'apt/pool/main/h/heisuca'
        if not pool.is_dir() or not list(pool.glob('*.deb')):
            raise ValueError('Refresh mode requires existing apt/pool/main/h/heisuca/*.deb')
    elif out_res.exists() and any(out_res.iterdir()):
        raise ValueError(f'Output directory must be new or empty: {out_res}')


def normalize_elf_relpath(raw_path: str) -> str:
    clean = raw_path.strip().lstrip('./').lstrip('/')
    if clean.startswith('opt/heisuca/'):
        clean = clean[len('opt/heisuca/'):]
    parts = Path(clean).parts
    if not clean or '..' in parts:
        raise ValueError(f'Invalid ELF relative path: {raw_path}')
    return '/'.join(parts)


def load_provenance(prov_path: Path, expected_version: str, expected_rpm_sha: str):
    data = json.loads(prov_path.read_text(encoding='utf-8'))
    if data.get('version') != expected_version:
        raise ValueError('Provenance version mismatch')
    src_rev = data.get('revision', '')
    if not re.fullmatch(r'[a-f0-9]{40}', src_rev):
        raise ValueError('Invalid source revision in provenance JSON')
    if 'rpm_sha256' in data and data['rpm_sha256'].lower() != expected_rpm_sha:
        raise ValueError('Provenance rpm_sha256 does not match input RPM sha256')
    raw_elfs = data.get('elf_sha256')
    if not isinstance(raw_elfs, dict) or len(raw_elfs) != EXPECTED_ELF_COUNT:
        raise ValueError(f'Provenance must declare exactly {EXPECTED_ELF_COUNT} ELFs')
    elf_map = {}
    for k, v in raw_elfs.items():
        norm_k = normalize_elf_relpath(k)
        digest = str(v).lower()
        if not re.fullmatch(r'[a-f0-9]{64}', digest):
            raise ValueError(f'Invalid ELF digest for {norm_k}')
        elf_map[norm_k] = digest
    if len(elf_map) != EXPECTED_ELF_COUNT:
        raise ValueError('Duplicate normalized ELF paths in provenance')
    if 'binary_sha256' in data and elf_map.get('heisuca-bin') != data['binary_sha256'].lower():
        raise ValueError('Provenance binary_sha256 mismatch with heisuca-bin')
    return src_rev, elf_map


def validate_cpio_entries(listing_text: str) -> list[str]:
    entries = [line.strip() for line in listing_text.splitlines() if line.strip()]
    if not entries:
        raise ValueError('Empty CPIO archive')
    for item in entries:
        if item.startswith('/') or item.startswith('\\'):
            raise ValueError(f'Absolute path forbidden in CPIO: {item}')
        clean = item[2:] if item.startswith('./') else item
        if clean and '..' in clean.split('/'):
            raise ValueError(f'Parent traversal forbidden in CPIO: {item}')
    return entries


def extract_rpm_payload(rpm_path: Path, dest_dir: Path) -> None:
    cpio_blob = run_cmd(['rpm2cpio', rpm_path], input_bytes=b'')
    listing = run_cmd(['cpio', '-t', '--quiet'], input_bytes=cpio_blob).decode('utf-8', 'replace')
    validate_cpio_entries(listing)
    run_cmd(['cpio', '-idmu', '--no-absolute-filenames', '--quiet'], cwd=dest_dir, input_bytes=cpio_blob)


def snapshot_and_verify_tree(root_dir: Path, expected_elfs: dict[str, str]) -> dict[str, str]:
    root_res = root_dir.resolve()
    app_root = root_res / 'opt/heisuca'
    required = [
        app_root / 'heisuca-bin',
        app_root / 'heisuca',
        root_res / 'usr/bin/heisuca',
        root_res / 'usr/share/applications/app.heisuca.player.desktop.desktop',
        root_res / 'usr/share/icons/hicolor/scalable/apps/heisuca.svg',
    ]
    for req in required:
        if not (req.exists() or req.is_symlink()):
            raise ValueError(f'Missing required package file: {req.relative_to(root_res)}')
    if os.readlink(root_res / 'usr/bin/heisuca') != '/opt/heisuca/heisuca':
        raise ValueError('Unexpected /usr/bin/heisuca symlink target')
    snap, found_elfs = {}, {}
    for path in sorted(root_res.rglob('*')):
        rel = path.relative_to(root_res).as_posix()
        if rel.startswith('DEBIAN'):
            continue
        if path.is_symlink():
            target = os.readlink(path)
            resolved = (root_res / target.lstrip('/')).resolve() if target.startswith('/') else (path.parent / target).resolve()
            if not resolved.is_relative_to(root_res):
                raise ValueError(f'Symlink escapes package root: {rel} -> {target}')
            snap[rel] = f'link:{target}'
        elif path.is_file():
            sha = digest_file(path, 'sha256')
            mode = path.stat().st_mode & 0o777
            snap[rel] = f'file:{mode:o}:{sha}'
            with path.open('rb') as f:
                if f.read(4) == b'\x7fELF':
                    if not path.is_relative_to(app_root):
                        raise ValueError(f'ELF outside /opt/heisuca: {rel}')
                    found_elfs[path.relative_to(app_root).as_posix()] = sha
    if len(found_elfs) != EXPECTED_ELF_COUNT or found_elfs != expected_elfs:
        raise ValueError(f'ELF verification failed: found {len(found_elfs)}, expected {EXPECTED_ELF_COUNT}')
    return snap


def verify_gpg_and_export(gpg_dir: Path, signing_id: str, out_dir: Path) -> str:
    env = {**os.environ, 'GNUPGHOME': str(gpg_dir)}
    colons = run_cmd(['gpg', '--batch', '--with-colons', '--list-keys', signing_id], env=env)
    fpr, is_rsa4096 = None, False
    for line in colons.splitlines():
        parts = line.split(':')
        if parts[0] in ('pub', 'sub') and len(parts) > 3 and parts[2] == '4096' and parts[3] == '1':
            is_rsa4096 = True
        elif parts[0] == 'fpr' and len(parts) > 9 and fpr is None:
            fpr = parts[9].strip().upper()
    if not is_rsa4096 or not fpr or not re.fullmatch(r'[A-F0-9]{40}', fpr):
        raise ValueError('Configured GPG identity must be a valid RSA 4096 public entry')
    asc = run_cmd(['gpg', '--batch', '--yes', '--armor', '--export', fpr], env=env, input_bytes=b'')
    raw = run_cmd(['gpg', '--batch', '--yes', '--export', fpr], env=env, input_bytes=b'')
    for sub, asc_name, gpg_name in [
        ('apt', 'heisuca-archive-keyring.asc', 'heisuca-archive-keyring.gpg'),
        ('rpm', 'RPM-GPG-KEY-heisuca.asc', 'RPM-GPG-KEY-heisuca.gpg'),
    ]:
        d = out_dir / sub
        d.mkdir(parents=True, exist_ok=True)
        (d / asc_name).write_bytes(asc)
        (d / gpg_name).write_bytes(raw)
        (d / 'KEY-FINGERPRINT.txt').write_text(fpr + '\n', encoding='utf-8')
    return fpr


def rebuild_deb(in_deb: Path, out_deb: Path, version: str, revision: str, elf_map: dict[str, str]) -> str:
    full_ver = f'{version}-{revision}'
    with tempfile.TemporaryDirectory() as tmp:
        stage = Path(tmp) / 'stage'
        run_cmd(['dpkg-deb', '-R', in_deb, stage])
        orig_snap = snapshot_and_verify_tree(stage, elf_map)
        ctrl_path = stage / 'DEBIAN/control'
        ctrl_text = ctrl_path.read_text(encoding='utf-8')
        depends_m = re.search(r'^Depends:\s*(.+)$', ctrl_text, re.M)
        if not depends_m:
            raise ValueError('Input DEB missing Depends field')
        new_ctrl, count = re.subn(r'^Version:\s*.+$', f'Version: {full_ver}', ctrl_text, count=1, flags=re.M)
        if count != 1:
            raise ValueError('Failed to update DEB Version')
        ctrl_path.write_text(new_ctrl, encoding='utf-8')
        out_deb.parent.mkdir(parents=True, exist_ok=True)
        run_cmd(['dpkg-deb', '--build', '--root-owner-group', stage, out_deb])
        check_dir = Path(tmp) / 'verify'
        run_cmd(['dpkg-deb', '-R', out_deb, check_dir])
        if snapshot_and_verify_tree(check_dir, elf_map) != orig_snap:
            raise ValueError('Rebuilt DEB payload changed')
        chk_ctrl = (check_dir / 'DEBIAN/control').read_text(encoding='utf-8')
        if re.search(r'^Depends:\s*(.+)$', chk_ctrl, re.M).group(1) != depends_m.group(1):
            raise ValueError('Rebuilt DEB Depends changed')
    return full_ver


def rebuild_and_sign_rpm(in_rpm: Path, out_rpm: Path, version: str, revision: str, elf_map: dict[str, str], gpg_dir: Path, fpr: str) -> str:
    meta = run_cmd(['rpm', '-qp', '--qf', '%{NAME}|%{VERSION}|%{RELEASE}|%{ARCH}\n', in_rpm]).strip().split('|')
    if meta[0] != 'heisuca' or meta[1] != version or meta[3] != 'x86_64':
        raise ValueError(f'Unexpected input RPM header: {meta}')
    reqs = sorted({
        line.strip() for line in run_cmd(['rpm', '-qp', '--requires', in_rpm]).splitlines()
        if line.strip() and not line.strip().startswith('rpmlib(')
    })
    if not any(r.startswith('libc.so.6(') for r in reqs):
        raise ValueError('Input RPM missing libc ABI requirements')
    with tempfile.TemporaryDirectory() as tmp:
        tmp_p = Path(tmp)
        extracted = tmp_p / 'extracted'
        extracted.mkdir()
        extract_rpm_payload(in_rpm, extracted)
        orig_snap = snapshot_and_verify_tree(extracted, elf_map)
        topdir = tmp_p / 'rpmbuild'
        topdir.mkdir()
        spec = tmp_p / 'heisuca.spec'
        q_ext = shlex.quote(str(extracted))
        spec.write_text(
            '%global debug_package %{nil}\n%global _build_id_links none\n'
            '%global __os_install_post %{nil}\n%global _binary_payload w9.zstdio\n'
            f'Name: heisuca\nVersion: {version}\nRelease: {revision}%{{?dist}}\n'
            'Summary: Heisuca — player Plex e Jellyfin\nLicense: GPL-3.0\n'
            'URL: https://heisuca.docaio.com.br/\nBuildArch: x86_64\nAutoReq: no\nAutoProv: no\n'
            + ''.join(f'Requires: {r}\n' for r in reqs)
            + 'Recommends: gnome-keyring\n\n%description\n'
            'Heisuca para Linux x64 em sessão Wayland. Bibliotecas privadas e dados\n'
            'do usuário separados dos aplicativos do sistema.\n\n%install\n'
            'mkdir -p "%{buildroot}/opt" "%{buildroot}/usr/bin" "%{buildroot}/usr/share/applications" '
            '"%{buildroot}/usr/share/icons/hicolor/scalable/apps" "%{buildroot}%{_licensedir}/heisuca"\n'
            f'cp -a {q_ext}/opt/heisuca "%{{buildroot}}/opt/heisuca"\n'
            'ln -s /opt/heisuca/heisuca "%{buildroot}/usr/bin/heisuca"\n'
            f'install -D -m644 {q_ext}/usr/share/applications/app.heisuca.player.desktop.desktop '
            '"%{buildroot}/usr/share/applications/app.heisuca.player.desktop.desktop"\n'
            f'install -D -m644 {q_ext}/usr/share/icons/hicolor/scalable/apps/heisuca.svg '
            '"%{buildroot}/usr/share/icons/hicolor/scalable/apps/heisuca.svg"\n'
            f'install -D -m644 {q_ext}/usr/share/licenses/heisuca/LICENSE.txt '
            '"%{buildroot}%{_licensedir}/heisuca/LICENSE.txt"\n\n%files\n%defattr(-,root,root,-)\n'
            '/opt/heisuca\n/usr/bin/heisuca\n/usr/share/applications/app.heisuca.player.desktop.desktop\n'
            '/usr/share/icons/hicolor/scalable/apps/heisuca.svg\n%license %{_licensedir}/heisuca/LICENSE.txt\n',
            encoding='utf-8',
        )
        run_cmd(['rpmbuild', '-bb', '--define', f'_topdir {topdir}', '--define', 'dist .fc45', spec])
        built = list((topdir / 'RPMS/x86_64').glob('*.rpm'))
        if len(built) != 1:
            raise ValueError('Expected exactly one built RPM')
        out_rpm.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(built[0], out_rpm)
        chk_ext = tmp_p / 'verify'
        chk_ext.mkdir()
        extract_rpm_payload(out_rpm, chk_ext)
        if snapshot_and_verify_tree(chk_ext, elf_map) != orig_snap:
            raise ValueError('Rebuilt RPM payload differs from input RPM')
        new_reqs = sorted({
            line.strip() for line in run_cmd(['rpm', '-qp', '--requires', out_rpm]).splitlines()
            if line.strip() and not line.strip().startswith('rpmlib(')
        })
        if new_reqs != reqs:
            raise ValueError('Rebuilt RPM requires changed')
    gpg_bin = shutil.which('gpg') or '/usr/bin/gpg'
    env = {**os.environ, 'GNUPGHOME': str(gpg_dir)}
    run_cmd([
        'rpmsign', '--addsign',
        '--define', '_openpgp_sign gpg',
        '--define', f'_openpgp_sign_id {fpr}',
        '--define', '_signature gpg',
        '--define', f'_gpg_name {fpr}',
        '--define', f'_gpg_path {gpg_dir}',
        '--define', f'__gpg {gpg_bin}',
        out_rpm,
    ], env=env)
    return f'{version}-{revision}.fc45'


def verify_rpm_signature(rpm_path: Path, pub_asc: Path, fpr: str) -> None:
    short_id = fpr[-8:].lower()
    with tempfile.TemporaryDirectory() as tmp:
        db = Path(tmp) / 'rpmdb'
        db.mkdir()
        run_cmd(['rpmkeys', '--dbpath', db, '--import', pub_asc])
        chk = run_cmd(['rpmkeys', '--checksig', '--dbpath', db, rpm_path])
        if 'signatures OK' not in chk or 'NOT OK' in chk:
            raise ValueError(f'RPM signature check failed: {chk}')
        v_chk = run_cmd(['rpmkeys', '--checksig', '-v', '--dbpath', db, rpm_path])
        hdr_sig = run_cmd(['rpm', '-qp', '--qf', '%{RSAHEADER:pgpsig}|%{SIGPGP:pgpsig}\n', rpm_path])
        combined = (v_chk + '\n' + hdr_sig).lower()
        if 'rsa' not in combined or short_id not in combined or ': ok' not in v_chk.lower():
            raise ValueError('RPM lacks verified RSA signature for expected GPG fingerprint')


def update_rpm_repo(out_dir: Path, gpg_dir: Path, fpr: str, base_url: str) -> None:
    rpm_dir = out_dir / 'rpm'
    run_cmd(['createrepo_c', '--general-compress-type=gz', rpm_dir])
    repomd = rpm_dir / 'repodata/repomd.xml'
    repomd_asc = rpm_dir / 'repodata/repomd.xml.asc'
    env = {**os.environ, 'GNUPGHOME': str(gpg_dir)}
    run_cmd(['gpg', '--batch', '--yes', '--armor', '--detach-sign', '--digest-algo', 'SHA256', '-u', fpr, '-o', repomd_asc, repomd], env=env)
    run_cmd(['gpgv', '--keyring', rpm_dir / 'RPM-GPG-KEY-heisuca.gpg', repomd_asc, repomd])
    (rpm_dir / 'heisuca.repo').write_text(
        f'[heisuca]\nname=Heisuca Fedora 45 x86_64\nbaseurl={base_url}/rpm\n'
        f'enabled=1\ngpgcheck=1\nrepo_gpgcheck=1\ngpgkey={base_url}/rpm/RPM-GPG-KEY-heisuca.asc\n',
        encoding='utf-8',
    )


def update_apt_repo(out_dir: Path, gpg_dir: Path, fpr: str, base_url: str, valid_days: int = 90) -> str:
    apt_dir = out_dir / 'apt'
    dist_dir = apt_dir / 'dists/stable'
    bin_dir = dist_dir / 'main/binary-amd64'
    bin_dir.mkdir(parents=True, exist_ok=True)
    pkgs_raw = run_cmd(['apt-ftparchive', 'packages', 'pool/main'], cwd=apt_dir).encode('utf-8')
    if b'Package: heisuca' not in pkgs_raw:
        raise ValueError('Generated APT Packages index is missing heisuca')
    pkgs_file = bin_dir / 'Packages'
    pkgs_gz = bin_dir / 'Packages.gz'
    pkgs_file.write_bytes(pkgs_raw)
    with pkgs_gz.open('wb') as raw_f:
        with gzip.GzipFile(filename='', mode='wb', fileobj=raw_f, mtime=0) as gz_f:
            gz_f.write(pkgs_raw)
    by_hash = bin_dir / 'by-hash'
    with tempfile.TemporaryDirectory() as tmp_rel:
        tmp_bin = Path(tmp_rel) / 'dists/stable/main/binary-amd64'
        tmp_bin.mkdir(parents=True, exist_ok=True)
        for idx_file in (pkgs_file, pkgs_gz):
            shutil.copy2(idx_file, tmp_bin / idx_file.name)
        rel_out = run_cmd([
            'apt-ftparchive',
            '-o', 'APT::FTPArchive::Release::Origin=Heisuca',
            '-o', 'APT::FTPArchive::Release::Label=Heisuca',
            '-o', 'APT::FTPArchive::Release::Suite=stable',
            '-o', 'APT::FTPArchive::Release::Codename=stable',
            '-o', 'APT::FTPArchive::Release::Architectures=amd64',
            '-o', 'APT::FTPArchive::Release::Components=main',
            '-o', 'APT::FTPArchive::Release::Acquire-By-Hash=true',
            'release', 'dists/stable',
        ], cwd=Path(tmp_rel))
    for algo, folder in [('sha256', 'SHA256'), ('sha512', 'SHA512')]:
        target_dir = by_hash / folder
        target_dir.mkdir(parents=True, exist_ok=True)
        for idx_file in (pkgs_file, pkgs_gz):
            shutil.copy2(idx_file, target_dir / digest_file(idx_file, algo))
    valid_str = (datetime.now(timezone.utc) + timedelta(days=valid_days)).strftime('%a, %d %b %Y %H:%M:%S UTC')
    lines = [l for l in rel_out.splitlines() if not l.startswith(('Valid-Until:', 'Acquire-By-Hash:'))]
    header_extra = [f'Valid-Until: {valid_str}', 'Acquire-By-Hash: yes']
    split_idx = next((i for i, l in enumerate(lines) if l.startswith('MD5Sum:') or l.startswith('SHA')), len(lines))
    rel_text = '\n'.join(lines[:split_idx] + header_extra + lines[split_idx:]) + '\n'
    rel_file = dist_dir / 'Release'
    inrel_file = dist_dir / 'InRelease'
    rel_gpg = dist_dir / 'Release.gpg'
    env = {**os.environ, 'GNUPGHOME': str(gpg_dir)}
    keyring = apt_dir / 'heisuca-archive-keyring.gpg'
    with tempfile.TemporaryDirectory(dir=dist_dir) as tmp_stage:
        stage_dir = Path(tmp_stage)
        tmp_rel_file = stage_dir / 'Release'
        tmp_inrel_file = stage_dir / 'InRelease'
        tmp_rel_gpg = stage_dir / 'Release.gpg'
        tmp_rel_file.write_text(rel_text, encoding='utf-8')
        run_cmd(['gpg', '--batch', '--yes', '--clearsign', '--digest-algo', 'SHA256', '-u', fpr, '-o', tmp_inrel_file, tmp_rel_file], env=env)
        run_cmd(['gpg', '--batch', '--yes', '--armor', '--detach-sign', '--digest-algo', 'SHA256', '-u', fpr, '-o', tmp_rel_gpg, tmp_rel_file], env=env)
        run_cmd(['gpgv', '--keyring', keyring, tmp_inrel_file])
        run_cmd(['gpgv', '--keyring', keyring, tmp_rel_gpg, tmp_rel_file])
        os.replace(tmp_rel_file, rel_file)
        os.replace(tmp_rel_gpg, rel_gpg)
        os.replace(tmp_inrel_file, inrel_file)
    (apt_dir / 'heisuca.sources').write_text(
        f'Types: deb\nURIs: {base_url}/apt\nSuites: stable\nComponents: main\n'
        'Architectures: amd64\nSigned-By: /etc/apt/keyrings/heisuca-archive-keyring.gpg\n',
        encoding='utf-8',
    )
    return valid_str

def assert_no_gpg_path_leak(out_dir: Path, gpg_dir: Path) -> None:
    for forbidden in {str(gpg_dir), str(gpg_dir.resolve())}:
        for p in out_dir.rglob('*'):
            if p.is_file() and p.suffix in ('.json', '.txt', '.repo', '.sources', '.asc', '.xml', ''):
                text = p.read_text(encoding='utf-8', errors='ignore')
                if forbidden in text:
                    raise ValueError(f'GNUPGHOME path leaked in {p}')


def parse_args(argv=None):
    ap = argparse.ArgumentParser(description='Build or refresh signed Heisuca repositories.')
    ap.add_argument('--deb', type=Path)
    ap.add_argument('--rpm', type=Path)
    ap.add_argument('--deb-sha256')
    ap.add_argument('--rpm-sha256')
    ap.add_argument('--provenance', type=Path)
    ap.add_argument('--output', type=Path, required=True)
    ap.add_argument('--version', default='2.0.45')
    ap.add_argument('--revision', default='2')
    ap.add_argument('--gpg-home', type=Path, required=True)
    ap.add_argument('--key-id', dest='signing_id', required=True)
    ap.add_argument('--base-url', default='https://heisuca.docaio.com.br/pacotes/repos')
    ap.add_argument('--valid-days', type=int, default=90)
    ap.add_argument('--refresh-metadata', action='store_true')
    args = ap.parse_args(argv)
    if not re.fullmatch(r'[0-9]+(?:\.[0-9]+){2}', args.version) or not re.fullmatch(r'[1-9][0-9]*', args.revision):
        raise ValueError('Invalid version or revision format')
    if args.valid_days < 30:
        raise ValueError('valid-days must be at least 30')
    if not args.refresh_metadata:
        missing = [k for k, v in [('deb', args.deb), ('rpm', args.rpm), ('deb-sha256', args.deb_sha256), ('rpm-sha256', args.rpm_sha256), ('provenance', args.provenance)] if not v]
        if missing:
            raise ValueError(f'Missing required arguments: {missing}')
    return args


def main(argv=None) -> int:
    args = parse_args(argv)
    base_url = validate_base_url(args.base_url)
    out_dir, gpg_dir = args.output.resolve(), args.gpg_home.resolve()
    validate_disjoint_paths(out_dir, gpg_dir, args.refresh_metadata)
    fpr = verify_gpg_and_export(gpg_dir, args.signing_id, out_dir)
    manifest_path = out_dir / 'manifest.json'
    if args.refresh_metadata:
        valid_until = update_apt_repo(out_dir, gpg_dir, fpr, base_url, args.valid_days)
        if (out_dir / 'rpm/packages').is_dir():
            update_rpm_repo(out_dir, gpg_dir, fpr, base_url)
        meta = json.loads(manifest_path.read_text(encoding='utf-8')) if manifest_path.is_file() else {}
        meta.update({'signing_fingerprint': fpr, 'valid_until': valid_until, 'valid_days': args.valid_days})
    else:
        deb_in, rpm_in = args.deb.resolve(), args.rpm.resolve()
        deb_sha = parse_sha256_input(args.deb_sha256)
        rpm_sha = parse_sha256_input(args.rpm_sha256)
        if digest_file(deb_in) != deb_sha or digest_file(rpm_in) != rpm_sha:
            raise ValueError('Input DEB or RPM SHA-256 mismatch')
        src_rev, elf_map = load_provenance(args.provenance.resolve(), args.version, rpm_sha)
        deb_out = out_dir / f'apt/pool/main/h/heisuca/heisuca_{args.version}-{args.revision}_amd64.deb'
        rpm_out = out_dir / f'rpm/packages/heisuca-{args.version}-{args.revision}.fc45.x86_64.deb'.replace('.deb', '.rpm')
        deb_ver = rebuild_deb(deb_in, deb_out, args.version, args.revision, elf_map)
        rpm_ver = rebuild_and_sign_rpm(rpm_in, rpm_out, args.version, args.revision, elf_map, gpg_dir, fpr)
        verify_rpm_signature(rpm_out, out_dir / 'rpm/RPM-GPG-KEY-heisuca.asc', fpr)
        update_rpm_repo(out_dir, gpg_dir, fpr, base_url)
        valid_until = update_apt_repo(out_dir, gpg_dir, fpr, base_url, args.valid_days)
        meta = {
            'version': args.version,
            'source_revision': src_rev,
            'deb_version': deb_ver,
            'rpm_version': rpm_ver,
            'input_deb_sha256': deb_sha,
            'input_rpm_sha256': rpm_sha,
            'deb_sha256': digest_file(deb_out),
            'rpm_sha256': digest_file(rpm_out),
            'elf_count': len(elf_map),
            'signing_fingerprint': fpr,
            'valid_until': valid_until,
            'valid_days': args.valid_days,
        }
    manifest_path.write_text(json.dumps(meta, indent=2) + '\n', encoding='utf-8')
    assert_no_gpg_path_leak(out_dir, gpg_dir)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
