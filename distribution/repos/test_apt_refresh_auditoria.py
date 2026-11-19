import gzip
import hashlib
import os
import shutil
import tempfile
import unittest
from datetime import datetime, timedelta, timezone
from pathlib import Path
from unittest import mock

import build_repos as mod


class TestUpdateAptRepoAtomicRollback(unittest.TestCase):
    def test_signing_failure_preserves_old_inrelease_and_old_by_hash(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            out_dir = Path(tmp) / 'out'
            gpg_dir = Path(tmp) / 'gpg'
            gpg_dir.mkdir(parents=True, exist_ok=True)
            dist_dir = out_dir / 'apt/dists/stable'
            bin_dir = dist_dir / 'main/binary-amd64'
            sha256_dir = bin_dir / 'by-hash/SHA256'
            sha512_dir = bin_dir / 'by-hash/SHA512'
            sha256_dir.mkdir(parents=True, exist_ok=True)
            sha512_dir.mkdir(parents=True, exist_ok=True)

            old_inrelease = dist_dir / 'InRelease'
            old_release = dist_dir / 'Release'
            old_release_gpg = dist_dir / 'Release.gpg'
            old_inrelease.write_text('OLD_INRELEASE_V1\n', encoding='utf-8')
            old_release.write_text('OLD_RELEASE_V1\n', encoding='utf-8')
            old_release_gpg.write_text('OLD_RELEASE_GPG_V1\n', encoding='utf-8')

            old_pkg_bytes = b'Package: heisuca\nVersion: 0.9.0\nArchitecture: amd64\n\n'
            old_sha256 = hashlib.sha256(old_pkg_bytes).hexdigest()
            old_sha512 = hashlib.sha512(old_pkg_bytes).hexdigest()
            (sha256_dir / old_sha256).write_bytes(old_pkg_bytes)
            (sha512_dir / old_sha512).write_bytes(old_pkg_bytes)

            def fake_run_cmd(cmd, cwd=None, env=None):
                prog = str(cmd[0])
                if prog == 'apt-ftparchive' and cmd[1] == 'packages':
                    return 'Package: heisuca\nVersion: 1.0.0\nArchitecture: amd64\n\n'
                if prog == 'apt-ftparchive' and 'release' in cmd:
                    rel_root = Path(cwd) / 'dists/stable'
                    rel_files = sorted(p.relative_to(rel_root).as_posix() for p in rel_root.rglob('*') if p.is_file())
                    assert rel_files == ['main/binary-amd64/Packages', 'main/binary-amd64/Packages.gz']
                    return (
                        'Origin: Heisuca\nSuite: stable\nCodename: stable\n'
                        'SHA256:\n deadbeef 42 main/binary-amd64/Packages\n'
                    )
                if prog == 'gpg':
                    raise RuntimeError('Simulated GPG failure during signing')
                raise AssertionError(f'Unexpected command: {cmd}')

            with mock.patch.object(mod, 'run_cmd', side_effect=fake_run_cmd):
                with self.assertRaises(RuntimeError):
                    mod.update_apt_repo(out_dir, gpg_dir, '0123456789ABCDEF', 'https://repo.example.test', 90)

            self.assertEqual(old_inrelease.read_text(encoding='utf-8'), 'OLD_INRELEASE_V1\n')
            self.assertEqual(old_release.read_text(encoding='utf-8'), 'OLD_RELEASE_V1\n')
            self.assertEqual(old_release_gpg.read_text(encoding='utf-8'), 'OLD_RELEASE_GPG_V1\n')
            self.assertEqual((sha256_dir / old_sha256).read_bytes(), old_pkg_bytes)
            self.assertEqual((sha512_dir / old_sha512).read_bytes(), old_pkg_bytes)


if __name__ == '__main__':
    unittest.main()
