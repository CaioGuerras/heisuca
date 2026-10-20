#!/usr/bin/env python3
"""Testes do roteiro do emulador: detector de tela preta e filtro do logcat (sem emulador)."""

from __future__ import annotations

import struct
import sys
import unittest
import zlib
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import emulador_navegacao as nav  # noqa: E402


def _png(width: int, height: int, pixel, filter_type: int = 0) -> bytes:
    raw = b""
    for y in range(height):
        raw += bytes([filter_type]) + b"".join(bytes(pixel(x, y)) for x in range(width))

    def chunk(kind: bytes, body: bytes) -> bytes:
        return struct.pack(">I", len(body)) + kind + body + struct.pack(">I", zlib.crc32(kind + body))

    ihdr = struct.pack(">IIBBBBB", width, height, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw)) + chunk(b"IEND", b"")


class BlackScreenTest(unittest.TestCase):
    def test_preto_liso_e_tela_preta(self) -> None:
        self.assertTrue(nav.is_black_screen(_png(64, 64, lambda x, y: (0, 0, 0, 255))))

    def test_fundo_cgflix_vazio_tambem(self) -> None:
        self.assertTrue(nav.is_black_screen(_png(64, 64, lambda x, y: (7, 6, 10, 255))))

    def test_fundo_cgflix_com_texto_nao_e(self) -> None:
        def pixel(x: int, y: int):
            return (255, 255, 255, 255) if 10 <= y < 14 and 8 <= x < 40 else (7, 6, 10, 255)

        self.assertFalse(nav.is_black_screen(_png(64, 64, pixel)))

    def test_filtro_up_e_decodificado(self) -> None:
        # Filtro 2 (Up) com deltas zero repete a primeira linha: tudo branco.
        data = _png(8, 8, lambda x, y: (255, 255, 255, 255) if y == 0 else (0, 0, 0, 0), filter_type=2)
        self.assertGreater(nav.lit_fraction(data, step=1), 0.99)


class LogcatTest(unittest.TestCase):
    def test_pega_overflow_e_excecao(self) -> None:
        log = "\n".join(
            [
                "I/flutter ( 123): tudo certo",
                "I/flutter ( 123): A RenderFlex overflowed by 12 pixels on the right.",
                "E/AndroidRuntime( 99): FATAL EXCEPTION: main",
            ]
        )
        self.assertEqual(len(nav.logcat_failures(log)), 2)

    def test_adb_perdeu_o_aparelho(self) -> None:
        self.assertTrue(nav.device_lost("error: device offline"))
        self.assertTrue(nav.device_lost("adb: no devices/emulators found"))
        self.assertTrue(nav.device_lost("error: device 'emulator-5554' not found"))
        self.assertFalse(nav.device_lost("Error: Activity class does not exist"))
        self.assertFalse(nav.device_lost(""))

    def test_log_limpo(self) -> None:
        self.assertEqual(nav.logcat_failures("I/flutter: Início pronta"), [])


if __name__ == "__main__":
    unittest.main()
