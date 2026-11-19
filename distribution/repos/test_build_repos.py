#!/usr/bin/env python3
"""Offline unit tests for distribution/repos/build_repos.py."""
import hashlib
import json
import os
from pathlib import Path
import tempfile
import unittest

import build_repos


class BuildReposOfflineTests(unittest.TestCase):
    def test_base_url_validation(self):
        self.assertEqual(
            build_repos.validate_base_url('https://heisuca.docaio.com.br/pacotes/repos/'),
            'https://heisuca.docaio.com.br/pacotes/repos',
        )
        for bad in [
            'http://heisuca.docaio.com.br/pacotes/repos',
            'https://evil.example.com/pacotes/repos',
            'https://heisuca.docaio.com.br/pacotes/repos?x=1',
            'https://heisuca.docaio.com.br/pacotes/repos#frag',
        ]:
            with self.assertRaises(ValueError):
                build_repos.validate_base_url(bad)

    def test_disjoint_output_and_gnupghome(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = Path(tmp)
            gpg_dir = base / 'gnupg'
            gpg_dir.mkdir()
            with self.assertRaises(ValueError):
                build_repos.validate_disjoint_paths(gpg_dir, gpg_dir, False)
            with self.assertRaises(ValueError):
                build_repos.validate_disjoint_paths(gpg_dir / 'sub', gpg_dir, False)
            with self.assertRaises(ValueError):
                build_repos.validate_disjoint_paths(base, gpg_dir, False)
            build_repos.validate_disjoint_paths(base / 'out', gpg_dir, False)

    def test_cpio_entry_validation(self):
        valid = './opt/heisuca/heisuca-bin\nusr/bin/heisuca\n'
        self.assertEqual(len(build_repos.validate_cpio_entries(valid)), 2)
        for bad in ['/opt/heisuca/heisuca', './opt/heisuca/../../etc/passwd', '../heisuca']:
            with self.assertRaises(ValueError):
                build_repos.validate_cpio_entries(bad)

    def test_provenance_and_161_elf_verification(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / 'pkg'
            app = root / 'opt/heisuca'
            (app / 'lib').mkdir(parents=True)
            (root / 'usr/bin').mkdir(parents=True)
            (root / 'usr/share/applications').mkdir(parents=True)
            (root / 'usr/share/icons/hicolor/scalable/apps').mkdir(parents=True)
            (app / 'heisuca').write_text('#!/bin/sh\n', encoding='utf-8')
            os.symlink('/opt/heisuca/heisuca', root / 'usr/bin/heisuca')
            (root / 'usr/share/applications/app.heisuca.player.desktop.desktop').write_text('[Desktop Entry]\n', encoding='utf-8')
            (root / 'usr/share/icons/hicolor/scalable/apps/heisuca.svg').write_text('<svg/>\n', encoding='utf-8')
            elf_map = {}
            for idx in range(build_repos.EXPECTED_ELF_COUNT):
                rel = 'heisuca-bin' if idx == 0 else f'lib/libtest_{idx}.so'
                f_path = app / rel
                payload = b'\x7fELF' + f'binary-{idx}'.encode('utf-8')
                f_path.write_bytes(payload)
                key = f'opt/heisuca/{rel}' if idx % 2 == 0 else rel
                elf_map[key] = hashlib.sha256(payload).hexdigest()
            rpm_sha = 'a' * 64
            rev = '46df8e024029faae2253f9673771fa565d33a819'
            prov_file = Path(tmp) / 'provenance.json'
            prov_file.write_text(json.dumps({
                'version': '2.0.45',
                'revision': rev,
                'rpm_sha256': rpm_sha,
                'binary_sha256': elf_map['opt/heisuca/heisuca-bin'],
                'elf_sha256': elf_map,
            }), encoding='utf-8')
            src_rev, norm_elfs = build_repos.load_provenance(prov_file, '2.0.45', rpm_sha)
            self.assertEqual(src_rev, rev)
            self.assertEqual(len(norm_elfs), 161)
            snap = build_repos.snapshot_and_verify_tree(root, norm_elfs)
            self.assertIn('opt/heisuca/heisuca-bin', snap)
            (app / 'lib/libtest_1.so').write_bytes(b'\x7fELFcorrupted')
            with self.assertRaises(ValueError):
                build_repos.snapshot_and_verify_tree(root, norm_elfs)

    def test_cli_refresh_vs_full_args(self):
        args = build_repos.parse_args([
            '--refresh-metadata', '--output', '/tmp/out', '--gpg-home', '/tmp/gpg', '--key-id', 'ABCD'
        ])
        self.assertTrue(args.refresh_metadata)
        self.assertEqual(args.valid_days, 90)
        with self.assertRaises(ValueError):
            build_repos.parse_args(['--output', '/tmp/out', '--gpg-home', '/tmp/gpg', '--key-id', 'ABCD'])


if __name__ == '__main__':
    unittest.main()
