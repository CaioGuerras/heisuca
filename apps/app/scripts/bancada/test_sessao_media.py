"""O protocolo de prova recusa sessões duplicadas e ações sem efeito."""
import unittest
from unittest.mock import Mock, patch
from types import SimpleNamespace
from sessao_media import analisar_sessao, encontrar_acao_pip, ProvasSessao as Coletor

PKG = 'app.heisuca.player.teste.home'


def dump(estado=3, acoes=295, posicao=12000):
    return f'''Sessions Stack - have 1 sessions:
  Heisuca (userId=0)
    package={PKG}
    active=true
    state=PlaybackState {{state={estado}, position={posicao}, speed=1.0, actions={acoes}}}
    metadata: description=Filme de prova, Episódio 1
'''


class ProvasSessao(unittest.TestCase):
    def test_uma_sessao_tocando_com_posicao_titulo_e_acoes(self):
        prova = analisar_sessao(dump(), PKG, 'Filme de prova', estado=3, proximo=True)
        self.assertEqual(prova['sessoes'], 1)
        self.assertEqual(prova['posicao_ms'], 12000)

    def test_duas_sessoes_nao_sao_aprovadas(self):
        with self.assertRaisesRegex(RuntimeError, 'exatamente uma'):
            analisar_sessao(dump() + dump(), PKG, 'Filme de prova', estado=3)

    def test_sessao_errada_ou_ausente_nao_e_aprovada(self):
        for valor in [dump().replace(PKG, 'outro.app'), '', dump().replace('Filme de prova', 'Outro')]:
            with self.subTest(valor=valor), self.assertRaises(RuntimeError):
                analisar_sessao(valor, PKG, 'Filme de prova', estado=3)

    def test_estado_posicao_e_acoes_sao_obrigatorios(self):
        for valor in [dump(estado=2), dump(posicao=0), dump(acoes=4)]:
            with self.subTest(valor=valor), self.assertRaises(RuntimeError):
                analisar_sessao(valor, PKG, 'Filme de prova', estado=3, proximo=True)

    def test_botao_pip_precisa_existir_visivel_e_habilitado(self):
        xml = '<hierarchy><node text="" content-desc="Pausar" enabled="true" bounds="[10,20][50,60]" /></hierarchy>'
        self.assertEqual(encontrar_acao_pip(xml, 'Pausar'), (30, 40))
        for valor in [xml.replace('Pausar', 'Tocar'), xml.replace('true', 'false'), xml.replace('[10,20][50,60]', '[0,0][0,0]')]:
            with self.subTest(valor=valor), self.assertRaises(RuntimeError):
                encontrar_acao_pip(valor, 'Pausar')


class MenuPip(unittest.TestCase):
    @staticmethod
    def xml(rotulo):
        return '<hierarchy><node text="" content-desc="' + rotulo + '" enabled="true" bounds="[10,20][50,60]" /></hierarchy>'

    def coletor(self):
        alvo = Coletor('.', Mock(), PKG, lambda texto: texto)
        alvo._abrir_menu_pip = Mock()
        return alvo

    def test_menu_ja_aberto_nao_recebe_toque_que_o_fecharia(self):
        alvo = self.coletor()
        alvo._xml = Mock(return_value=self.xml('Tocar'))
        self.assertEqual(alvo._acao_pip('Tocar'), (30, 40, self.xml('Tocar')))
        alvo._abrir_menu_pip.assert_not_called()

    @patch('sessao_media.time.sleep')
    def test_menu_aberto_aguarda_rotulo_atualizar_sem_fechar(self, _sleep):
        alvo = self.coletor()
        alvo._xml = Mock(side_effect=[self.xml('Pausar'), self.xml('Tocar')])
        self.assertEqual(alvo._acao_pip('Tocar'), (30, 40, self.xml('Tocar')))
        alvo._abrir_menu_pip.assert_not_called()

    @patch('sessao_media.time.sleep')
    def test_menu_fechado_abre_uma_vez_e_consulta_de_novo(self, _sleep):
        alvo = self.coletor()
        alvo._xml = Mock(side_effect=['<hierarchy/>', self.xml('Pausar')])
        self.assertEqual(alvo._acao_pip('Pausar'), (30, 40, self.xml('Pausar')))
        alvo._abrir_menu_pip.assert_called_once()

    @patch('sessao_media.time.sleep')
    @patch('sessao_media.time.monotonic', side_effect=[0, 0, 9])
    def test_botao_ausente_falha_em_oito_segundos_sem_tentar_tocar(self, _clock, _sleep):
        alvo = self.coletor()
        alvo._xml = Mock(return_value='<hierarchy/>')
        with self.assertRaisesRegex(RuntimeError, '8 segundos'):
            alvo._acao_pip('Pausar')
        alvo._abrir_menu_pip.assert_called_once()
        alvo.adb.assert_not_called()

    def test_sequencia_do_ack_exige_inteiro_positivo_sem_converter_booleano(self):
        import json
        for seq in ['1', True, 1.0, -1, 0, None]:
            with self.subTest(seq=seq):
                alvo = self.coletor()
                alvo._privado = Mock(return_value=SimpleNamespace(stdout=json.dumps({
                    'seq': seq, 'nome': 'mpv-pausa', 'acao': 'desconhecida'}).encode()))
                with self.assertRaisesRegex(RuntimeError, 'Sequência'):
                    alvo.poll()
                alvo.adb.assert_not_called()
