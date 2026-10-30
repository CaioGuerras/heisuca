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
    captura_mudou,
    checar_leanback,
    checar_saude,
    classificar_geral,
    classificar_tela,
    diferenca_na_regiao,
    inspecionar_foco,
    is_tela_inteira,
    reconhecer_tela_tv,
    tamanho_do_campo_tv,
    verificar_inicio_vazio,
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

    def test_inspecionar_foco_ignora_raiz_tela_inteira(self):
        nos = [
            # Nó raiz da janela ou view que cobre 1080p
            {'text': '', 'cls': 'android.widget.FrameLayout', 'focused': True, 'bounds': (0, 0, 1920, 1080)},
            # Nó filho interno realmente focado
            {'text': 'Reproduzir', 'cls': 'android.widget.Button', 'focused': True, 'bounds': (200, 500, 400, 560)},
        ]
        info = inspecionar_foco(nos)
        self.assertTrue(info['visivel'])
        self.assertEqual(info['elemento'], 'Reproduzir')
        self.assertEqual(info['bounds'], [200, 500, 400, 560])

    def test_inspecionar_foco_apenas_raiz_focada(self):
        nos = [
            {'text': '', 'cls': 'android.widget.FrameLayout', 'focused': True, 'bounds': (0, 0, 1920, 1080)},
        ]
        info = inspecionar_foco(nos)
        self.assertFalse(info['visivel'])
        self.assertTrue(info['raiz'])
        self.assertIsNone(info['elemento'])

    def test_inspecionar_foco_ausente(self):
        nos = [
            {'text': 'Início', 'cls': 'android.view.View', 'focused': False, 'bounds': (0, 0, 100, 50)},
            {'text': 'Filme A', 'cls': 'android.widget.Button', 'focused': False, 'bounds': (100, 200, 300, 400)},
        ]
        info = inspecionar_foco(nos)
        self.assertFalse(info['visivel'])
        self.assertIsNone(info['elemento'])
        self.assertIsNone(info['bounds'])

    def test_is_tela_inteira(self):
        self.assertTrue(is_tela_inteira([0, 0, 1920, 1080]))
        self.assertTrue(is_tela_inteira([5, 5, 1915, 1075]))
        self.assertFalse(is_tela_inteira([100, 200, 400, 300]))

    def test_diferenca_na_regiao_com_pillow(self):
        try:
            from PIL import Image
            img1 = Image.new('RGB', (100, 100), color=(0, 0, 0))
            img2 = Image.new('RGB', (100, 100), color=(0, 0, 0))
            img2.putpixel((50, 50), (255, 255, 255))
            b1 = io.BytesIO()
            img1.save(b1, format='PNG')
            b2 = io.BytesIO()
            img2.save(b2, format='PNG')

            self.assertTrue(diferenca_na_regiao(b1.getvalue(), b2.getvalue(), [40, 40, 60, 60]))
            self.assertFalse(diferenca_na_regiao(b1.getvalue(), b2.getvalue(), [0, 0, 20, 20]))
        except ImportError:
            pass

    def test_captura_mudou(self):
        try:
            from PIL import Image
            img1 = Image.new('RGB', (100, 100), color=(0, 0, 0))
            img2 = Image.new('RGB', (100, 100), color=(255, 255, 255))
            b1 = io.BytesIO()
            img1.save(b1, format='PNG')
            b2 = io.BytesIO()
            img2.save(b2, format='PNG')

            self.assertFalse(captura_mudou(b1.getvalue(), b1.getvalue()))
            self.assertTrue(captura_mudou(b1.getvalue(), b2.getvalue()))
        except ImportError:
            pass

    def test_verificar_texto_pequeno(self):
        nos = [
            {'text': 'Texto minúsculo', 'bounds': (0, 0, 100, 12)},
            {'text': 'Texto normal', 'bounds': (0, 0, 100, 24)},
            {'text': '·', 'bounds': (0, 0, 10, 8)},
        ]
        pequenos = verificar_texto_pequeno(nos, altura_minima=18)
        self.assertEqual(len(pequenos), 1)
        self.assertEqual(pequenos[0]['texto'], 'Texto minúsculo')
        self.assertEqual(pequenos[0]['altura'], 12)

    def test_classificar_tela_criterios_completos(self):
        self.assertEqual(classificar_tela([]), VERDE)
        self.assertEqual(classificar_tela([{'gravidade': ATENCAO, 'codigo': 'foco-invisivel'}]), ATENCAO)
        self.assertEqual(classificar_tela([
            {'gravidade': ATENCAO, 'codigo': 'foco-invisivel'},
            {'gravidade': VERMELHO, 'codigo': 'player-preto'},
        ]), VERMELHO)
        # Se captura não mudou ou elementos esperados não apareceram, é ATENCAO (toque obrigatório)
        self.assertEqual(classificar_tela([], cap_mudou=False), ATENCAO)
        self.assertEqual(classificar_tela([], elementos_presentes=False), ATENCAO)
        # Achados críticos forçam VERMELHO
        self.assertEqual(classificar_tela([{'gravidade': VERMELHO, 'codigo': 'crash'}]), VERMELHO)

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
    def test_checar_leanback(self, mock_texto):
        mock_texto.return_value = 'true\n'
        self.assertTrue(checar_leanback())

        mock_texto.return_value = 'false\n'
        self.assertFalse(checar_leanback())

    def test_reconhecer_tela_tv(self):
        nos_login = [
            {'text': 'Iniciar sessão', 'cls': 'android.widget.Button'},
            {'text': '', 'cls': 'android.widget.EditText'},
        ]
        self.assertEqual(reconhecer_tela_tv(nos_login), 'login')

        nos_inicio = [
            {'text': 'Início', 'cls': 'android.widget.TextView'},
            {'text': 'Buscar', 'cls': 'android.widget.TextView'},
            {'text': 'Configurações', 'cls': 'android.widget.TextView'},
        ]
        self.assertEqual(reconhecer_tela_tv(nos_inicio), 'inicio')

        self.assertIsNone(reconhecer_tela_tv([{'text': 'Outra tela'}]))

    def test_verificar_inicio_vazio(self):
        nos_vazio = [
            # Trilho lateral esquerdo
            {'text': 'Início', 'bounds': (0, 100, 150, 150), 'centro': (75, 125)},
            {'text': 'Buscar', 'bounds': (0, 160, 150, 210), 'centro': (75, 185)},
        ]
        self.assertTrue(verificar_inicio_vazio(nos_vazio))

        nos_nenhum_conteudo = [
            {'text': 'Início', 'bounds': (0, 100, 150, 150), 'centro': (75, 125)},
            {'text': 'Nenhum conteúdo disponível', 'bounds': (600, 500, 1300, 560), 'centro': (950, 530)},
            {'text': 'Adicione filmes e séries às suas bibliotecas', 'bounds': (600, 570, 1300, 620), 'centro': (950, 595)},
        ]
        self.assertTrue(verificar_inicio_vazio(nos_nenhum_conteudo))

        nos_com_linhas = [
            # Trilho lateral
            {'text': 'Início', 'bounds': (0, 100, 150, 150), 'centro': (75, 125)},
            # Conteúdo na área central (x >= 200)
            {'text': 'Continuar assistindo', 'bounds': (220, 100, 600, 150), 'centro': (410, 125), 'clickable': False},
            {'text': 'Filme A', 'bounds': (220, 160, 420, 460), 'centro': (320, 310), 'clickable': True, 'focusable': True},
        ]
        self.assertFalse(verificar_inicio_vazio(nos_com_linhas))

    def test_tamanho_do_campo_tv(self):
        nos = [
            {'text': 'USUÁRIO', 'desc': '', 'hint': '', 'cls': 'android.widget.TextView', 'bounds': (40, 100, 200, 140), 'centro': (120, 120)},
            {'text': 'usuario_teste', 'desc': '', 'hint': '', 'cls': 'android.widget.EditText', 'bounds': (40, 150, 400, 200), 'centro': (220, 175)},
        ]
        self.assertEqual(tamanho_do_campo_tv(nos, 'USUÁRIO'), len('usuario_teste'))
        self.assertIsNone(tamanho_do_campo_tv([], 'USUÁRIO'))

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

    @patch('tv.checar_leanback')
    def test_percorrer_tv_sem_leanback(self, mock_leanback):
        mock_leanback.return_value = False
        res = tv.percorrer_tv('http://teste:8096', perfil='firetv-11')
        self.assertEqual(res['estado'], VERMELHO)
        self.assertEqual(res['achados'][0]['codigo'], 'sem-leanback')

    @patch('tv.checar_leanback')
    @patch('tv.achar_apk')
    @patch('tv.adb')
    def test_percorrer_tv_falha_instalacao_apk(self, mock_adb, mock_achar_apk, mock_leanback):
        mock_leanback.return_value = True
        mock_achar_apk.return_value = Path('/tmp/app.apk')
        mock_res = Mock()
        mock_res.returncode = 1
        mock_res.stdout = b'Failure [INSTALL_FAILED_NO_MATCHING_ABIS]'
        mock_adb.return_value = mock_res
        res = tv.percorrer_tv('http://teste:8096', perfil='firetv-9')
        self.assertEqual(res['estado'], VERMELHO)
        self.assertEqual(res['achados'][0]['codigo'], 'falha-instalacao-apk')
        self.assertIn('INSTALL_FAILED_NO_MATCHING_ABIS', res['motivo'])


if __name__ == '__main__':
    unittest.main()
