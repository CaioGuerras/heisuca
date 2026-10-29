import io
import json
from pathlib import Path
import unittest
from unittest.mock import patch, Mock

import tv
from tv import (
    ATENCAO,
    VERDE,
    VERMELHO,
    achar_apk,
    checar_saude,
    classificar_geral,
    classificar_tela,
    inspecionar_foco,
    verificar_player_preto,
    verificar_texto_pequeno,
)
from servidor import limpar_log

PNG_HEADER = b'\x89PNG\r\n\x1a\n' + b'0' * 24


class TestTvBancada(unittest.TestCase):
    def test_inspecionar_foco_presente(self):
        nos = [
            {'text': 'Início', 'cls': 'android.view.View', 'focused': False, 'bounds': (0, 0, 100, 50)},
            {'text': 'Filme A', 'cls': 'android.widget.Button', 'focused': True, 'bounds': (100, 200, 300, 400)},
        ]
        info = inspecionar_foco(nos)
        self.assertTrue(info['visivel'])
        self.assertEqual(info['elemento'], 'Filme A')
        self.assertEqual(info['classe'], 'android.widget.Button')
        self.assertEqual(info['bounds'], [100, 200, 300, 400])

    def test_inspecionar_foco_ausente(self):
        nos = [
            {'text': 'Início', 'cls': 'android.view.View', 'focused': False, 'bounds': (0, 0, 100, 50)},
            {'text': 'Filme A', 'cls': 'android.widget.Button', 'focused': False, 'bounds': (100, 200, 300, 400)},
        ]
        info = inspecionar_foco(nos)
        self.assertFalse(info['visivel'])
        self.assertIsNone(info['elemento'])
        self.assertIsNone(info['bounds'])

    def test_verificar_texto_pequeno(self):
        nos = [
            # Texto pequeno (altura 12px < 18px)
            {'text': 'Texto minúsculo', 'bounds': (0, 0, 100, 12)},
            # Texto normal (altura 24px)
            {'text': 'Texto normal', 'bounds': (0, 0, 100, 24)},
            # Ponto ou hífen curto (deve ser ignorado)
            {'text': '·', 'bounds': (0, 0, 10, 8)},
        ]
        pequenos = verificar_texto_pequeno(nos, altura_minima=18)
        self.assertEqual(len(pequenos), 1)
        self.assertEqual(pequenos[0]['texto'], 'Texto minúsculo')
        self.assertEqual(pequenos[0]['altura'], 12)

    def test_classificar_tela(self):
        self.assertEqual(classificar_tela([]), VERDE)
        self.assertEqual(classificar_tela([{'gravidade': ATENCAO, 'codigo': 'foco-invisivel'}]), ATENCAO)
        self.assertEqual(classificar_tela([
            {'gravidade': ATENCAO, 'codigo': 'foco-invisivel'},
            {'gravidade': VERMELHO, 'codigo': 'player-preto'},
        ]), VERMELHO)

    def test_classificar_geral(self):
        telas_verdes = [
            {'nome': 'inicio', 'estado': VERDE, 'achados': []},
            {'nome': 'filme', 'estado': VERDE, 'achados': []},
        ]
        self.assertEqual(classificar_geral(telas_verdes, []), VERDE)

        telas_com_atencao = [
            {'nome': 'inicio', 'estado': ATENCAO, 'achados': [{'gravidade': ATENCAO}]},
            {'nome': 'filme', 'estado': VERDE, 'achados': []},
        ]
        self.assertEqual(classificar_geral(telas_com_atencao, []), ATENCAO)

        telas_com_vermelho = [
            {'nome': 'inicio', 'estado': ATENCAO, 'achados': [{'gravidade': ATENCAO}]},
            {'nome': 'player', 'estado': VERMELHO, 'achados': [{'gravidade': VERMELHO}]},
        ]
        self.assertEqual(classificar_geral(telas_com_vermelho, []), VERMELHO)

    @patch('tv.texto')
    def test_checar_saude_app_fechado(self, mock_texto):
        mock_texto.return_value = 'mResumedActivity=com.android.launcher/MainActivity\n'
        erro = checar_saude([], 'Tela')
        self.assertIsNotNone(erro)
        self.assertEqual(erro['gravidade'], VERMELHO)
        self.assertEqual(erro['codigo'], 'crash')

    @patch('tv.reconhecer_anr')
    @patch('tv.texto')
    def test_checar_saude_anr(self, mock_texto, mock_anr):
        mock_anr.return_value = [{'texto': 'App parou', 'esperar': None}]
        erro = checar_saude([], 'Tela')
        self.assertIsNotNone(erro)
        self.assertEqual(erro['gravidade'], VERMELHO)
        self.assertEqual(erro['codigo'], 'anr')

    def test_achar_apk_candidatos(self):
        with patch('pathlib.Path.exists') as mock_exists:
            mock_exists.side_effect = [False, True]
            achado = achar_apk([Path('/nao/existe/a.apk'), Path('/existe/b.apk')])
            self.assertEqual(achado, Path('/existe/b.apk'))

        with patch('pathlib.Path.exists') as mock_exists:
            mock_exists.return_value = False
            self.assertIsNone(achar_apk([Path('/nao/existe/a.apk')]))

    def test_sanitizacao_relatorio(self):
        servidor = 'https://jellyfin.segredo.org:8096'
        contas = ['admin_secreto', 'teste-sem-senha']
        relatorio = {
            'perfil': 'androidtv',
            'estado': 'verde',
            'motivo': 'Conectado em https://jellyfin.segredo.org:8096 com o usuário admin_secreto',
            'telas': []
        }
        json_limpo = limpar_log(json.dumps(relatorio), contas, servidor)
        self.assertNotIn('jellyfin.segredo.org', json_limpo)
        self.assertNotIn('admin_secreto', json_limpo)
        self.assertIn('[endereço omitido]', json_limpo)
        self.assertIn('[conta omitida]', json_limpo)


if __name__ == '__main__':
    unittest.main()
