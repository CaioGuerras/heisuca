import subprocess
import unittest
from unittest.mock import Mock
from acoes import perform, pip_bounds


class AcoesNativas(unittest.TestCase):
    def test_fechar_pip_recusa_task_de_outro_app_antes_de_tocar(self):
        adb = Mock(return_value=subprocess.CompletedProcess([], 0,
            b'* Task{123 mode=pinned outro.app}\n mBounds=Rect(10, 10 - 100, 100)'))
        with self.assertRaisesRegex(RuntimeError, 'Task PiP deste app'):
            perform('pip_close', adb)
        self.assertEqual([('shell', 'dumpsys', 'activity', 'activities')],
                         [call.args for call in adb.call_args_list])

    def test_sessao_usa_transporte_do_android_e_nao_mexe_no_back(self):
        adb = Mock()
        perform('media_pause', adb)
        perform('media_play', adb)
        self.assertEqual([('shell', 'cmd', 'media_session', 'dispatch', 'pause'),
                          ('shell', 'cmd', 'media_session', 'dispatch', 'play')],
                         [call.args for call in adb.call_args_list])

    def test_reabrir_exige_alias_do_pacote_de_avaliacao(self):
        adb = Mock(return_value=subprocess.CompletedProcess([], 0, b'outro.app/.Main'))
        with self.assertRaises(RuntimeError):
            perform('reopen', adb)
        self.assertEqual(1, adb.call_count)

    def test_retangulo_vem_do_task_pip_do_app_e_nao_do_launcher(self):
        dump = """  * Task{123 #1 type=home mode=fullscreen}
    mBounds=Rect(0, 0 - 1080, 2400)
  * Task{456 #8 I=app.heisuca.player.teste.home/app.heisuca.IconeIsis mode=pinned}
    mBounds=Rect(700, 1600 - 1050, 1800)
"""
        self.assertEqual((700, 1600, 1050, 1800), pip_bounds(dump))
        self.assertIsNone(pip_bounds(dump.replace('mode=pinned', 'mode=fullscreen')))

    def test_acao_desconhecida_nao_envia_comando(self):
        adb = Mock()
        with self.assertRaises(RuntimeError):
            perform('back_extra', adb)
        adb.assert_not_called()
