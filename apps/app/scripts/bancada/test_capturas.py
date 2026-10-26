import io
from contextlib import redirect_stdout
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch, Mock
from capturas import Capturas

PNG = b'\x89PNG\r\n\x1a\n' + b'0' * 24


class CapturaAoVivo(unittest.TestCase):
    def setUp(self):
        self.enterContext(redirect_stdout(io.StringIO()))
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.c = Capturas(Path(self.tmp.name))

    @patch('capturas.subprocess.run')
    @patch('capturas.adb')
    def test_login_so_e_confirmado_apos_video_parado_e_captura(self, adb, run):
        events = []
        recording = Mock()
        recording.wait.side_effect = lambda **_: events.append('parado')
        self.c.recording = recording
        def native(*args, **kwargs):
            if args[0] == 'shell' and 'heisuca-bancada-ack.tmp' in args[1]:
                events.append('ack')
                self.assertIn('parado', events)
                self.assertTrue((self.c.output / '01-login.png').exists())
                return subprocess.CompletedProcess(args, 0, b'')
            events.append(args[0])
            return subprocess.CompletedProcess(args, 0, PNG)
        adb.side_effect = native
        self.c.handle({'seq': 1, 'name': '01-login', 'back': False})
        run.assert_not_called()  # nada de `tee` por stdin: o adb não repassa o fim da entrada
        self.assertIsNone(self.c.recording)
        self.assertLess(events.index('parado'), events.index('pull'))
        self.assertLess(events.index('exec-out'), events.index('ack'))
        self.assertEqual(self.c.last, 1)

    @patch('capturas.subprocess.run')
    @patch('capturas.adb')
    def test_captura_invalida_nao_confirma_nem_avanca(self, adb, run):
        adb.return_value = subprocess.CompletedProcess([], 0, b'erro')
        with self.assertRaises(RuntimeError):
            self.c.handle({'seq': 1, 'name': '03-busca'})
        run.assert_not_called()
        self.assertFalse(any('ack' in str(c.args) for c in adb.call_args_list))
        self.assertEqual(self.c.last, 0)

    @patch('capturas.subprocess.run')
    @patch('capturas.adb')
    def test_back_nativo_antes_da_confirmacao_e_so_quando_pedido(self, adb, run):
        adb.return_value = subprocess.CompletedProcess([], 0, PNG)
        run.return_value = subprocess.CompletedProcess([], 0)
        self.c.handle({'seq': 1, 'name': '08-busca-retorno-0', 'back': True})
        adb.assert_any_call('shell', 'input', 'keyevent', '4', check=True)
        adb.reset_mock()
        self.c.handle({'seq': 2, 'name': '09-biblioteca'})
        self.assertFalse(any(c.args[:2] == ('shell', 'input') for c in adb.call_args_list))

    @patch('capturas.adb')
    def test_marco_fora_de_ordem_ou_caminho_nao_executa_operacao(self, adb):
        for event in ({'seq': 2, 'name': '01-login'}, {'seq': 1, 'name': '../privado'}):
            with self.assertRaises(RuntimeError): self.c.handle(event)
        adb.assert_not_called()

    @patch('capturas.adb')
    def test_falha_ao_salvar_video_nao_interrompe_limpeza_do_servidor(self, adb):
        self.c.recording = Mock()
        def native(*args, **kwargs):
            if args[0] == 'pull': raise RuntimeError('dispositivo perdeu conexão')
            return subprocess.CompletedProcess(args, 0, b'')
        adb.side_effect = native
        self.c.close()
        self.assertIsNone(self.c.recording)


class EventoAusente(unittest.TestCase):
    @patch('capturas.adb')
    def test_sem_evento_o_adb_responde_texto_e_nao_derruba(self, adb):
        adb.return_value = subprocess.CompletedProcess([], 0, b'cat: files/heisuca-bancada-event.json: No such file')
        with tempfile.TemporaryDirectory() as tmp:
            c = Capturas(Path(tmp))
            c.poll()
            self.assertEqual(c.last, 0)

    @patch('capturas.adb')
    def test_foco_antes_e_depois_reflete_o_lugar_exato_do_back(self, adb):
        self.enterContext(redirect_stdout(io.StringIO()))
        temporary = tempfile.TemporaryDirectory()
        self.addCleanup(temporary.cleanup)
        self.c = Capturas(Path(temporary.name))
        focused = 'app.heisuca'
        def native(*args, **kwargs):
            nonlocal focused
            if args[:3] == ('shell', 'input', 'keyevent'): focused = 'launcher'
            if args[:2] == ('shell', 'dumpsys'):
                payload = f'mCurrentFocus={focused}\ntopResumedActivity={focused}'.encode()
            else: payload = PNG
            return subprocess.CompletedProcess(args, 0, payload)
        adb.side_effect = native
        self.c.handle({'seq': 1, 'name': '08-busca-retorno-0', 'back': True})
        before = (self.c.output / '08-busca-retorno-0-foco-antes.json').read_text()
        after = (self.c.output / '08-busca-retorno-0-foco-depois.json').read_text()
        self.assertIn('mCurrentFocus=app.heisuca', before)
        self.assertIn('mCurrentFocus=launcher', after)
