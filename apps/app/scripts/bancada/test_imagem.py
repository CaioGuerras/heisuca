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
from unittest.mock import Mock, patch
from capturas import Capturas
from imagem import analisar


def png_preto(channel=0):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>2I5B', 64, 36, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress((b'\x00' + bytes([channel]) * 64 * 3) * 36)) + chunk(b'IEND', b''))


def geometria(width, height, *, hud=()):
    return {'janela': {'largura': width, 'altura': height},
            'superficie': {'x': 0, 'y': 0, 'largura': width, 'altura': height},
            'video': {'largura': 1920, 'altura': 1080, 'modo': 'conter', 'zoom': 1},
            'barrasSistema': {'topo': 0, 'base': 12, 'esquerda': 0, 'direita': 0},
            'hudOculto': not hud, 'exclusoesHud': list(hud)}


def png_preto_com_interface():
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    rows = bytearray()
    for y in range(180):
        rows.append(0)
        for x in range(320):
            value = 255 if y < 32 or y >= 168 or (140 <= x < 180 and 80 <= y < 110) else 0
            rows.extend([value] * 3)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>2I5B', 320, 180, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))


def png_luma(width, height, light_pixels, level=255):
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind + data))
    rows = bytearray()
    for y in range(height):
        rows.append(0)
        for x in range(width):
            rows.extend([level if y * width + x < light_pixels else 0] * 3)
    return (b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>2I5B', width, height, 8, 2, 0, 0, 0))
            + chunk(b'IDAT', zlib.compress(rows)) + chunk(b'IEND', b''))


class ImagemNativa(unittest.TestCase):
    def setUp(self):
        intervalo = patch('capturas.INTERVALO_IMAGEM', 0)
        intervalo.start()
        self.addCleanup(intervalo.stop)

    def test_limiar_mede_fracao_e_nao_um_pixel_isolado(self):
        geometry = geometria(100, 100)
        geometry['video'].update({'largura': 100, 'altura': 100})
        geometry['barrasSistema']['base'] = 0
        for count, expected in [(1, 'não'), (199, 'não'), (200, 'sim')]:
            with self.subTest(pixels=count):
                image = analisar(png_luma(100, 100, count, level=17), geometry)
                self.assertEqual(image['imagem'], expected)
                self.assertEqual(image['pixelsNaoEscuros'], count)
                self.assertEqual(image['fracaoNaoEscura'], count / 10000)
                self.assertEqual(image['areaMedida']['pixels'], 10000)
        self.assertEqual(analisar(png_luma(100, 100, 10000, level=16), geometry)['imagem'], 'não')

    def test_pillarbox_e_barra_do_sistema_ficam_fora_da_area_medida(self):
        geometry = geometria(64, 36)
        geometry['video'].update({'largura': 1, 'altura': 1})
        image = analisar(png_preto(127), geometry)
        self.assertEqual(image['areaMedida'], {'pixels': 36 * 24,
            'retangulos': [{'x': 14, 'y': 0, 'largura': 36, 'altura': 24}]})

    def test_exclusoes_sobrepostas_nao_descontam_a_area_duas_vezes(self):
        geometry = geometria(64, 36, hud=[
            {'x': 0, 'y': 0, 'largura': 64, 'altura': 8},
            {'x': 0, 'y': 4, 'largura': 64, 'altura': 8}])
        image = analisar(png_preto(127), geometry)
        self.assertEqual(image['areaMedida']['pixels'], 64 * 12)
        self.assertEqual(image['pixelsNaoEscuros'], 64 * 12)

    def test_sem_geometria_ou_com_hud_desconhecido_nao_libera_captura(self):
        for geometry in [None, {}, {**geometria(64, 36), 'hudOculto': False}, geometria(65, 36)]:
            with self.subTest(geometria=geometry), self.assertRaises(RuntimeError):
                analisar(png_preto(255), geometry)

    @patch('capturas.adb')
    def test_video_preto_com_barra_branca_e_hud_claro_nao_recebe_ack(self, adb):
        adb.return_value = subprocess.CompletedProcess([], 0, png_preto_com_interface())
        geometry = geometria(320, 180, hud=[
            {'x': 0, 'y': 0, 'largura': 320, 'altura': 32},
            {'x': 140, 'y': 80, 'largura': 40, 'altura': 30}])
        with tempfile.TemporaryDirectory() as tmp, redirect_stdout(io.StringIO()):
            capture = Capturas(Path(tmp))
            capture.recording = Mock()
            with patch.object(capture, 'focus'), self.assertRaisesRegex(RuntimeError, 'Imagem nativa preta'):
                capture.handle({'seq': 1, 'name': '06-player', 'geometriaVideo': geometry, 'back': True})
            self.assertEqual(capture.last, 0)
            self.assertFalse(any('ack' in str(call.args) for call in adb.call_args_list))
            self.assertFalse(any('keyevent' in str(call.args) for call in adb.call_args_list))

    @patch('capturas.adb')
    def test_quadro_real_do_run_p2_tem_imagem(self, adb):
        # Frame nativo de 40482536078; o log do motor registra 1920×1080.
        frame = Path(__file__).resolve().parents[4] / 'docs/evidencias/p2_21_final_2026-10-27.png'
        adb.return_value = subprocess.CompletedProcess([], 0, frame.read_bytes())
        with tempfile.TemporaryDirectory() as tmp, redirect_stdout(io.StringIO()):
            capture = Capturas(Path(tmp))
            capture.handle({'seq': 1, 'name': '21-imagem-apos-audio', 'geometriaVideo': geometria(1200, 540)})
            image = json.loads((Path(tmp) / '21-imagem-apos-audio-imagem.json').read_text())
            self.assertEqual(image['imagem'], 'sim')

    def test_png_invalido_nao_produz_prova(self):
        with self.assertRaisesRegex(RuntimeError, 'pixels'):
            analisar(b'arquivo invalido')

    @patch('capturas.adb')
    def test_ack_carrega_prova_da_captura_e_nao_uma_flag_anterior(self, adb):
        adb.return_value = subprocess.CompletedProcess([], 0, png_preto(127))
        with tempfile.TemporaryDirectory() as tmp, redirect_stdout(io.StringIO()):
            capture = Capturas(Path(tmp))
            capture.handle({'seq': 1, 'name': '21-imagem-apos-audio', 'geometriaVideo': geometria(64, 36)})
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
                capture.handle({'seq': 1, 'name': '21-imagem-apos-audio', 'geometriaVideo': geometria(64, 36)})
            self.assertEqual(capture.last, 0)
            self.assertFalse(any('ack' in str(call.args) for call in adb.call_args_list))

    @patch('capturas.adb')
    def test_preto_em_todas_as_tentativas_continua_vermelho(self, adb):
        adb.return_value = subprocess.CompletedProcess([], 0, png_preto())
        with tempfile.TemporaryDirectory() as tmp, redirect_stdout(io.StringIO()):
            capture = Capturas(Path(tmp))
            with self.assertRaisesRegex(RuntimeError, 'Imagem nativa preta'):
                capture.handle({'seq': 1, 'name': '21-imagem-apos-audio', 'geometriaVideo': geometria(64, 36)})
            screencaps = [call for call in adb.call_args_list if call.args[:2] == ('exec-out', 'screencap')]
            self.assertEqual(len(screencaps), 6)
            self.assertFalse(any('ack' in str(call.args) for call in adb.call_args_list))

    @patch('capturas.adb')
    def test_cena_escura_do_filme_recebe_nova_captura(self, adb):
        # Run 40984981192: letreiro da abertura em fundo preto (1,8%); o quadro seguinte tem imagem.
        quadros = iter([png_preto(), png_preto(127)])
        def responder(*args, **kwargs):
            if args[:2] == ('exec-out', 'screencap'):
                return subprocess.CompletedProcess([], 0, next(quadros))
            return subprocess.CompletedProcess([], 0, b'')
        adb.side_effect = responder
        with tempfile.TemporaryDirectory() as tmp, redirect_stdout(io.StringIO()):
            capture = Capturas(Path(tmp))
            capture.handle({'seq': 1, 'name': '21-imagem-apos-audio', 'geometriaVideo': geometria(64, 36)})
            image = json.loads((Path(tmp) / '21-imagem-apos-audio-imagem.json').read_text())
            self.assertEqual(image['imagem'], 'sim')
            self.assertEqual(image['tentativas'], 2)
            self.assertTrue((Path(tmp) / '21-imagem-apos-audio-escura-1.png').exists())
            self.assertEqual(capture.last, 1)
