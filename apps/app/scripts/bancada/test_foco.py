import subprocess
import unittest
from foco import coletar_foco, linhas_de_foco, janela_do_app


class FocoAndroid(unittest.TestCase):
    def test_conserva_apenas_os_campos_de_foco_incluindo_null(self):
        lines = linhas_de_foco('topResumedActivity=app.heisuca/MainActivity\nemail=privado\nmCurrentFocus=null\nmFocusedApp=ActivityRecord{app.heisuca}\n')
        self.assertEqual(len(lines), 3)
        self.assertNotIn('privado', '\n'.join(lines))
        self.assertIn('mCurrentFocus=null', lines)

    def test_consulta_activity_e_window_sem_enviar_evento(self):
        calls = []
        def adb(*args):
            calls.append(args)
            text = 'mResumedActivity=app.heisuca/MainActivity' if 'activities' in args else 'mCurrentFocus=Window{app.heisuca}'
            return subprocess.CompletedProcess(args, 0, text.encode())
        state = coletar_foco(adb, 'app.heisuca')
        self.assertTrue(state['disponivel'])
        self.assertEqual(len(state['atividade']), 1)
        self.assertEqual(len(state['janela']), 1)
        self.assertEqual(calls, [('shell', 'dumpsys', 'activity', 'activities'), ('shell', 'dumpsys', 'window')])

    def test_falha_na_consulta_nao_significa_ausencia_de_foco(self):
        state = coletar_foco(lambda *args: subprocess.CompletedProcess(args, 1, b''), 'app.heisuca')
        self.assertFalse(state['disponivel'])

    def test_janela_do_app_mantem_flags_callback_e_dono(self):
        text = (' Window #0 Window{001 u0 com.launcher/Main}:\n mAttrs=launcher\n'
                ' Window #1 Window{002 u0 app.heisuca/Main}:\n mAttrs=FOCUSABLE\n'
                ' mOnBackInvokedCallbackInfo=callback\n privateOtherData=segredo\n'
                ' Window #2 Window{003 u0 com.sistema/Main}:\n mAttrs=outro\n')
        selected = '\n'.join(janela_do_app(text, 'app.heisuca'))
        self.assertIn('mAttrs=FOCUSABLE', selected)
        self.assertIn('mOnBackInvokedCallbackInfo=callback', selected)
        self.assertNotIn('segredo', selected)
        self.assertNotIn('mAttrs=launcher', selected)
        self.assertNotIn('mAttrs=outro', selected)

    def test_janela_ausente_nao_e_inventada(self):
        self.assertEqual(janela_do_app('mCurrentFocus=null', 'app.heisuca'), [])
