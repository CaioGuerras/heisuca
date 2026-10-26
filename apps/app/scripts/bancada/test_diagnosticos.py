import json
import io
from contextlib import redirect_stdout
from pathlib import Path
import subprocess
import tempfile
import unittest
from diagnosticos import resumo_trace
from diagnosticos import coletar, processo_proprio, coletar_traces
from capturas import APP_ID


class ResumoTrace(unittest.TestCase):
    def test_java_nao_some_depois_de_mil_frames_do_interpretador(self):
        trace = '"main" prio=5 tid=1 Native\n' + ('  native: art::interpreter\n' * 1000)
        trace += '  at io.flutter.embedding.engine.FlutterJNI.onSurfaceCreated(Native method)\n'
        trace += '"1.raster" prio=5 tid=2 Native\n  native: aguarda_buffer\n'
        summary = resumo_trace(trace)
        self.assertIn('FlutterJNI.onSurfaceCreated', summary)
        self.assertIn('"1.raster"', summary)
        self.assertIn('aguarda_buffer', summary)
        self.assertLess(len(summary), 3000)


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
        self.assertTrue(result['disponivel'])

    def test_falha_de_coleta_nao_e_interpretada_como_ausencia_de_anr(self):
        result = self.collect('', '', code=1)
        self.assertFalse(result['disponivel'])
        self.assertEqual(json.loads((self.output / 'android-diagnostico.json').read_text())['dumpsysCodigo'], 1)

    def test_trace_so_conserva_o_processo_correto(self):
        text = ('----- pid 1 at 2026 -----\nCmd line: com.outro\n"main" dados\n'
                f'----- pid 2 at 2026 -----\nCmd line: {APP_ID}\n"main" tid=1 Native\n  at app.heisuca.Player.dispose()\n'
                '----- pid 3 at 2026 -----\nCmd line: com.sistema\n"main" outros\n')
        selected = processo_proprio(text)
        self.assertIn('Player.dispose', selected)
        self.assertNotIn('com.outro', selected)
        self.assertNotIn('com.sistema', selected)

    def test_trace_main_e_salvo_redigido_sem_mudar_a_classificacao(self):
        trace = f'----- pid 2 at 2026 -----\nCmd line: {APP_ID}\n"main" tid=1 Native pessoa-privada\n  at app.heisuca.Player.wait()\n"outro" tid=2\n'
        def adb(*args):
            value = 'anr_2026-10-26-01-02-03\n' if args[0] == 'shell' else trace
            return subprocess.CompletedProcess(args, 0, value.encode())
        with redirect_stdout(io.StringIO()):
            report = coletar_traces(self.output, adb, ['pessoa-privada'], '')
        self.assertEqual(report, {'tracesDoApp': 1, 'mainColetada': True})
        self.assertNotIn('pessoa-privada', (self.output / 'android-trace-app-1.log').read_text())

    def test_sem_permissao_de_trace_nao_inventa_stack(self):
        def adb(*args): return subprocess.CompletedProcess(args, 1, b'')
        self.assertEqual(coletar_traces(self.output, adb, [], ''), {'tracesDoApp': 0, 'mainColetada': False})
