"""Prova negativa: quadro nativo preto não pode receber ACK de captura válida."""
import io
import struct
import subprocess
import tempfile
import unittest
import zlib
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch
from capturas import Capturas
from imagem import analisar


def png_preto():
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>2I5B', 64, 36, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress((b'\x00' + b'\x00' * 64 * 3) * 36)) + chunk(b'IEND', b''))


class ImagemNativa(unittest.TestCase):
    def test_png_invalido_nao_produz_prova(self):
        with self.assertRaisesRegex(RuntimeError, 'pixels'):
            analisar(b'arquivo invalido')

    @patch('capturas.adb')
    def test_preto_nao_pode_ser_confirmado_como_imagem_restaurada(self, adb):
        adb.return_value = subprocess.CompletedProcess([], 0, png_preto())
        with tempfile.TemporaryDirectory() as tmp, redirect_stdout(io.StringIO()):
            capture = Capturas(Path(tmp))
            with self.assertRaisesRegex(RuntimeError, 'Imagem nativa preta'):
                capture.handle({'seq': 1, 'name': '21-imagem-apos-audio'})
            self.assertEqual(capture.last, 0)
            self.assertFalse(any('ack' in str(call.args) for call in adb.call_args_list))
