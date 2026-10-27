"""Prova negativa: quadro nativo preto não pode receber ACK de captura válida."""
import io
import base64
import json
import re
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


def png_preto(channel=0):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>2I5B', 64, 36, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress((b'\x00' + bytes([channel]) * 64 * 3) * 36)) + chunk(b'IEND', b''))


class ImagemNativa(unittest.TestCase):
    def test_png_invalido_nao_produz_prova(self):
        with self.assertRaisesRegex(RuntimeError, 'pixels'):
            analisar(b'arquivo invalido')

    @patch('capturas.adb')
    def test_ack_carrega_prova_da_captura_e_nao_uma_flag_anterior(self, adb):
        adb.return_value = subprocess.CompletedProcess([], 0, png_preto(127))
        with tempfile.TemporaryDirectory() as tmp, redirect_stdout(io.StringIO()):
            capture = Capturas(Path(tmp))
            capture.handle({'seq': 1, 'name': '21-imagem-apos-audio'})
            command = next(call.args[1] for call in adb.call_args_list
                           if call.args[0] == 'shell' and 'ack.tmp' in call.args[1])
            encoded = re.search(r'echo ([A-Za-z0-9+/=]+) \|', command).group(1)
            ack = json.loads(base64.b64decode(encoded))
            self.assertIn('imagem', ack)
            self.assertEqual(ack['imagem']['imagem'], 'sim')
            self.assertEqual(ack['imagem']['maiorCanalRGB'], 127)
            self.assertEqual(capture.last, 1)

    @patch('capturas.adb')
    def test_preto_nao_pode_ser_confirmado_como_imagem_restaurada(self, adb):
        adb.return_value = subprocess.CompletedProcess([], 0, png_preto())
        with tempfile.TemporaryDirectory() as tmp, redirect_stdout(io.StringIO()):
            capture = Capturas(Path(tmp))
            with self.assertRaisesRegex(RuntimeError, 'Imagem nativa preta'):
                capture.handle({'seq': 1, 'name': '21-imagem-apos-audio'})
            self.assertEqual(capture.last, 0)
            self.assertFalse(any('ack' in str(call.args) for call in adb.call_args_list))
