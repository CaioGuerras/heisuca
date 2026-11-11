"""O protocolo de prova recusa sessões duplicadas e ações sem efeito."""
import unittest
import tempfile
from pathlib import Path
from unittest.mock import Mock, patch
from types import SimpleNamespace
from sessao_media import analisar_sessao, encontrar_acao_pip, ProvasSessao as Coletor

PKG = 'app.heisuca.player.teste.home'


def dump(estado=3, acoes=None, posicao=12000):
    if acoes is None:
        acoes = (4 if estado == 2 else 2) | 512 | 256 | 32
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

    def test_estado_nomeado_do_android_15_preserva_numero_exato(self):
        for nome, numero in [('PLAYING', 3), ('PAUSED', 2)]:
            with self.subTest(nome=nome):
                texto = dump(estado=numero).replace('state=' + str(numero) + ',', 'state=' + nome + '(' + str(numero) + '),')
                self.assertEqual(analisar_sessao(texto, PKG, 'Filme de prova', estado=numero)['estado'], numero)
        with self.assertRaises(RuntimeError):
            analisar_sessao(dump().replace('state=3,', 'state=PAUSED(2),'), PKG, 'Filme de prova', estado=3)

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

    def test_diagnostico_informa_estado_lido_e_esperado(self):
        with self.assertRaises(RuntimeError) as falha:
            analisar_sessao(dump(estado=2, acoes=0x322), PKG, 'Filme de prova', estado=3, proximo=True)
        self.assertIn('estado lido=2 esperado=3', str(falha.exception))
        self.assertIn('posição=12000 ms (esperado > 0)', str(falha.exception))
        self.assertIn('ações=0x322 obrigatórias=0x322 faltantes=0x0', str(falha.exception))

    def test_diagnostico_informa_posicao_zero(self):
        with self.assertRaises(RuntimeError) as falha:
            analisar_sessao(dump(posicao=0), PKG, 'Filme de prova', estado=3, proximo=True)
        self.assertIn('estado lido=3 esperado=3', str(falha.exception))
        self.assertIn('posição=0 ms (esperado > 0)', str(falha.exception))
        self.assertIn('faltantes=0x0', str(falha.exception))

    def test_diagnostico_identifica_bits_obrigatorios_ausentes(self):
        with self.assertRaises(RuntimeError) as falha:
            analisar_sessao(dump(acoes=4), PKG, 'Filme de prova', estado=3, proximo=True)
        texto = str(falha.exception)
        self.assertIn('ações=0x4 obrigatórias=0x322 faltantes=0x322', texto)
        for campo in ['pausar=0x2', 'tocar/pausar=0x200', 'buscar=0x100', 'próximo=0x20']:
            self.assertIn(campo, texto)
        self.assertNotIn('tocar=0x4', texto)

    def test_dump_real_da_run_e_aprovado_tocando_sem_bit_tocar(self):
        texto = (Path(__file__).parent / 'fixtures/media_session_android15_42886090476.txt').read_text()
        prova = analisar_sessao(texto, PKG, 'Vídeo de amostra', estado=3, proximo=True)
        self.assertEqual(prova['estado'], 3)
        self.assertEqual(prova['posicao_ms'], 2462)
        self.assertEqual(prova['acoes'], 4452347)
        self.assertEqual(prova['sessoes'], 1)

    def test_tocando_sem_tocar_e_pausado_sem_pausar_sao_aprovados(self):
        for estado, acoes in [(3, 0x322), (2, 0x324)]:
            with self.subTest(estado=estado):
                prova = analisar_sessao(dump(estado=estado, acoes=acoes), PKG, 'Filme de prova',
                                       estado=estado, proximo=True)
                self.assertEqual(prova['acoes'], acoes)

    def test_tocando_sem_pausar_reprova(self):
        with self.assertRaisesRegex(RuntimeError, r'faltantes=0x2 \(pausar=0x2\)'):
            analisar_sessao(dump(acoes=0x320), PKG, 'Filme de prova', estado=3, proximo=True)

    def test_pausado_sem_tocar_reprova(self):
        with self.assertRaisesRegex(RuntimeError, r'faltantes=0x4 \(tocar=0x4\)'):
            analisar_sessao(dump(estado=2, acoes=0x320), PKG, 'Filme de prova', estado=2, proximo=True)

    def test_sem_tocar_pausar_reprova_nos_dois_estados(self):
        for estado, acoes in [(3, 0x122), (2, 0x124)]:
            with self.subTest(estado=estado), self.assertRaisesRegex(RuntimeError, 'faltantes=0x200.*tocar/pausar=0x200'):
                analisar_sessao(dump(estado=estado, acoes=acoes), PKG, 'Filme de prova', estado=estado, proximo=True)

    def test_sem_buscar_reprova_nos_dois_estados(self):
        for estado, acoes in [(3, 0x222), (2, 0x224)]:
            with self.subTest(estado=estado), self.assertRaisesRegex(RuntimeError, 'faltantes=0x100.*buscar=0x100'):
                analisar_sessao(dump(estado=estado, acoes=acoes), PKG, 'Filme de prova', estado=estado, proximo=True)

    def test_sem_proximo_reprova_quando_existe_proximo(self):
        for estado, acoes in [(3, 0x302), (2, 0x304)]:
            with self.subTest(estado=estado), self.assertRaisesRegex(RuntimeError, 'faltantes=0x20.*próximo=0x20'):
                analisar_sessao(dump(estado=estado, acoes=acoes), PKG, 'Filme de prova', estado=estado, proximo=True)

    def test_sem_proximo_aprova_quando_nao_existe_proximo(self):
        for estado, acoes in [(3, 0x302), (2, 0x304)]:
            with self.subTest(estado=estado):
                analisar_sessao(dump(estado=estado, acoes=acoes), PKG, 'Filme de prova', estado=estado, proximo=False)

    def test_estados_diferentes_de_dois_e_tres_reprovam(self):
        for estado in [0, 1, 4, 5, 6, 7, 8, 99]:
            for esperado in [2, 3, estado]:
                with self.subTest(estado=estado, esperado=esperado), self.assertRaises(RuntimeError):
                    analisar_sessao(dump(estado=estado, acoes=0x326), PKG, 'Filme de prova', estado=esperado)

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

    @patch('sessao_media.Path.is_file', return_value=True)
    def test_leitor_pip_usa_janelas_sem_esperar_idle_e_envia_helper_uma_vez(self, _arquivo):
        xml = self.xml('Pausar')
        alvo = self.coletor()
        alvo.adb.return_value = SimpleNamespace(stdout=('BANCADA_PIP: conectado\n' + xml + '\nencerrando').encode())
        self.assertEqual(alvo._xml(), xml)
        self.assertEqual(alvo._xml(), xml)
        chamadas = alvo.adb.call_args_list
        self.assertEqual(sum(c.args[0] == 'push' for c in chamadas), 1)
        self.assertEqual(sum('--dump' in c.args for c in chamadas), 2)
        self.assertFalse(any('uiautomator' in c.args for c in chamadas))

    @patch('sessao_media.Path.is_file', return_value=True)
    def test_leitor_aceita_hierarquia_vazia_valida_sem_repetir_consulta(self, _arquivo):
        alvo = self.coletor()
        alvo.adb.return_value = SimpleNamespace(stdout=b'conectado\n<hierarchy />\nencerrando')
        self.assertEqual(alvo._xml(), '<hierarchy />')
        self.assertEqual(sum('--dump' in c.args for c in alvo.adb.call_args_list), 1)

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

    def test_falha_pip_preserva_tela_janelas_e_sessao_sem_ack(self):
        import json
        with tempfile.TemporaryDirectory() as pasta:
            alvo = Coletor(pasta, Mock(return_value=SimpleNamespace(stdout=b'diagnostico')), PKG, lambda t: t)
            alvo._privado = Mock(return_value=SimpleNamespace(stdout=json.dumps({
                'seq': 1, 'nome': 'mpv-pip-pausa', 'acao': 'pip-botao', 'rotulo': 'Pausar'}).encode()))
            alvo._acao_pip = Mock(side_effect=RuntimeError('Botão PiP não apareceu em 8 segundos: Pausar'))
            alvo._xml = Mock(return_value='<hierarchy/>')
            with self.assertRaisesRegex(RuntimeError, '8 segundos'):
                alvo.poll()
            for sufixo in ['falha.png', 'falha.xml', 'falha-atividades.txt', 'falha-sessao.txt']:
                self.assertTrue((Path(pasta) / ('mpv-pip-pausa-' + sufixo)).is_file(), sufixo)
            self.assertEqual(alvo.ultimo, 0)
            self.assertEqual(alvo.provas, [])
            self.assertFalse(any('input' in chamada.args or 'mv' in chamada.args for chamada in alvo.adb.call_args_list))

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


class ConvergenciaSessao(unittest.TestCase):
    def coletor(self, dumps):
        alvo = Coletor('.', Mock(side_effect=[SimpleNamespace(stdout=valor.encode()) for valor in dumps]), PKG, lambda t: t)
        alvo.pasta = unittest.mock.MagicMock()
        return alvo

    @patch('sessao_media.time.sleep')
    def test_guarda_dump_antes_de_validar_e_aguarda_metadados(self, _sleep):
        inicial = dump().replace('Filme de prova', 'Item anterior')
        pronto = dump().replace('state=3,', 'state=PLAYING(3),')
        alvo = self.coletor([inicial, pronto])
        prova = alvo._sessao_convergida('mpv-sessao-tocando', {'titulo': 'Filme de prova', 'estado': 3, 'proximo': True})
        self.assertEqual(prova['estado'], 3)
        gravacoes = alvo.pasta.__truediv__.return_value.write_text.call_args_list
        self.assertEqual([chamada.args[0] for chamada in gravacoes], [inicial, pronto])
        _sleep.assert_called_once_with(0.2)

    @patch('sessao_media.time.sleep')
    @patch('sessao_media.time.monotonic', side_effect=[0, 0, 9])
    def test_nao_aprova_estado_errado_apos_oito_segundos_e_preserva_dump(self, _clock, _sleep):
        errado = dump(estado=2)
        alvo = self.coletor([errado, errado])
        with self.assertRaisesRegex(RuntimeError, '8 segundos'):
            alvo._sessao_convergida('mpv-sessao-tocando', {'titulo': 'Filme de prova', 'estado': 3})
        self.assertEqual(alvo.pasta.__truediv__.return_value.write_text.call_count, 2)
