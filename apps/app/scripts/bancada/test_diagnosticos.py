import json
import io
from contextlib import redirect_stdout
from pathlib import Path
import subprocess
import tempfile
import unittest
from diagnosticos import coletar
from capturas import APP_ID


class DiagnosticoAndroid(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.output = Path(self.tmp.name)

    def collect(self, last, events, code=0):
        def adb(*args):
            return subprocess.CompletedProcess(args, code, (last if args[0] == 'shell' else events).encode())
        # A simulação de ANR não deve parecer um ANR real nos logs do portão.
        with redirect_stdout(io.StringIO()):
            return coletar(self.output, adb, ['pessoa-privada'], 'https://servidor.invalid')

    def test_anr_com_motivo_e_identificado_antes_da_limpeza_e_redigido(self):
        result = self.collect(f'ANR in {APP_ID}\nReason: Input dispatching timed out pessoa-privada https://servidor.invalid/item', '')
        self.assertTrue(result['anrDoApp'])
        self.assertTrue(result['disponivel'])
        text = (self.output / 'android-anr.log').read_text()
        self.assertIn('Input dispatching timed out', text)
        self.assertNotIn('pessoa-privada', text)
        self.assertNotIn('servidor.invalid', text)

    def test_evento_am_anr_do_app_e_identificado_mesmo_sem_lastanr(self):
        result = self.collect('No ANR has occurred since boot', f'I am_anr: [0,123,{APP_ID},Input dispatching timed out]\nReason: janela')
        self.assertTrue(result['anrDoApp'])
        self.assertIn('Reason: janela', (self.output / 'android-anr.log').read_text())

    def test_anr_de_outro_pacote_nao_e_atribuido_ao_app(self):
        result = self.collect(f'ANR in {APP_ID}.outro\nReason: outro', 'I am_anr: [0,123,com.outro,erro]')
        self.assertFalse(result['anrDoApp'])
        self.assertNotIn('Reason: outro', (self.output / 'android-anr.log').read_text())

    def test_falha_de_coleta_nao_e_interpretada_como_ausencia_de_anr(self):
        result = self.collect('', '', code=1)
        self.assertFalse(result['disponivel'])
        self.assertEqual(json.loads((self.output / 'android-diagnostico.json').read_text())['dumpsysCodigo'], 1)
