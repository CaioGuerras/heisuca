import unittest
from desastre import (parse_uiautomator, campos_login, marco, texto_tecnico_na_ui, analisar_monkey, eventos_injetados,
                      analisar_logcat, pids_do_app, filtrar_pid, app_em_primeiro_plano, teclado_visivel, tela_presa,
                      assinatura_tela, classificar, achar_texto)

PKG = 'app.heisuca.player.teste.home'


def xml(*nos):
    return '<?xml version="1.0"?><hierarchy rotation="0">' + ''.join(nos) + '</hierarchy>'


def no(cls='android.widget.TextView', text='', desc='', hint='', b='[0,0][100,50]'):
    return (f'<node class="{cls}" text="{text}" content-desc="{desc}" hint="{hint}" bounds="{b}" '
            f'clickable="true" enabled="true" package="{PKG}"/>')


LOGIN = xml(
    no(text='SERVIDOR'),
    no('android.widget.EditText', hint='https://seuservidor.com', b='[40,300][1040,420]'),
    no('android.widget.EditText', hint='Nome de usuário', b='[40,500][1040,620]'),
    no('android.widget.EditText', text='••••••••', b='[40,700][1040,820]'),
    no('android.widget.Button', desc='Iniciar sessão', b='[40,900][1040,1020]'))
LOGIN_SEM_DICA = xml(
    no('android.widget.EditText', b='[40,300][1040,420]'),
    no('android.widget.EditText', b='[40,500][1040,620]'),
    no('android.widget.EditText', b='[40,700][1040,820]'),
    no(text='Iniciar sessão', b='[40,900][1040,1020]'))
INICIO = xml(no(desc='Início'), no(desc='Biblioteca'), no(desc='Baixados'), no(desc='Você'))


class Uiautomator(unittest.TestCase):
    def test_campos_pela_dica(self):
        c = campos_login(parse_uiautomator(LOGIN))
        self.assertEqual(c['servidor']['centro'], (540, 360))
        self.assertEqual(c['usuario']['centro'], (540, 560))
        self.assertEqual(c['senha']['centro'], (540, 760))
        self.assertEqual(c['botao']['centro'], (540, 960))

    def test_campos_pela_ordem_quando_nao_ha_dica(self):
        c = campos_login(parse_uiautomator(LOGIN_SEM_DICA))
        self.assertEqual([c[k]['centro'][1] for k in ('servidor', 'usuario', 'senha')], [360, 560, 760])
        self.assertEqual(c['botao']['centro'], (540, 960))

    def test_marcos(self):
        self.assertEqual(marco(parse_uiautomator(LOGIN)), 'login')
        self.assertEqual(marco(parse_uiautomator(INICIO)), 'inicio')
        self.assertIsNone(marco(parse_uiautomator(xml(no(text='Carregando')))))

    def test_xml_invalido_ou_vazio(self):
        self.assertEqual(parse_uiautomator('UI hierarchy dumped to: /dev/stdout'), [])
        self.assertEqual(parse_uiautomator(''), [])
        self.assertIsNone(marco([]))

    def test_no_sem_area_nao_e_tocavel(self):
        nos = parse_uiautomator(xml(no(text='Iniciar sessão', b='[0,0][0,0]')))
        self.assertIsNone(achar_texto(nos, 'Iniciar sessão'))

    def test_texto_tecnico(self):
        nos = parse_uiautomator(xml(
            no(text='Exception: Falha ao carregar'), no(text='SocketException: Connection refused'),
            no(text='Failed host lookup: x'), no(text='null'), no(text='Error: 500'), no(text='Quer mesmo sair?'),
            no(text='Sem conexão com o servidor. Tente novamente.'), no(text='Nullidade é rara')))
        achados = texto_tecnico_na_ui(nos)
        self.assertEqual(len(achados), 5)
        self.assertNotIn('Quer mesmo sair?', achados)

    def test_tela_presa(self):
        a = assinatura_tela(parse_uiautomator(INICIO))
        b = assinatura_tela(parse_uiautomator(LOGIN))
        self.assertTrue(tela_presa([a, a, a]))
        self.assertFalse(tela_presa([a, b, a]))
        self.assertFalse(tela_presa([a]))
        self.assertFalse(tela_presa([(), ()]))


MONKEY_CRASH = '''// CRASH: app.heisuca.player.teste.home (pid 4321)
// Short Msg: java.lang.IllegalStateException
// NOT RESPONDING: app.heisuca.player.teste.home (pid 4400)
Events injected: 1830
** Monkey aborted due to error.
'''
MONKEY_OK = ':Monkey: seed=20261028 count=5000\nEvents injected: 5000\n// Monkey finished\n'


class Monkey(unittest.TestCase):
    def test_crash_anr_e_abortado(self):
        codigos = [c for _, c, _ in analisar_monkey(MONKEY_CRASH)]
        self.assertEqual(codigos, ['monkey-crash', 'monkey-anr', 'monkey-abortado'])
        self.assertEqual(eventos_injetados(MONKEY_CRASH), 1830)

    def test_limpo(self):
        self.assertEqual(analisar_monkey(MONKEY_OK), [])
        self.assertEqual(eventos_injetados(MONKEY_OK), 5000)
        self.assertIsNone(eventos_injetados('nada'))


LOGCAT = f'''10-28 10:00:00.100  1000  1000 I ActivityManager: Start proc 4321:{PKG}/u0a123 for top-activity
10-28 10:00:01.000  4321  4321 I flutter : tudo bem
10-28 10:00:02.000  4321  4321 E flutter : [ERROR:flutter/runtime/dart_vm_initializer.cc(40)] Unhandled Exception: Bad state: x
10-28 10:00:03.000  4321  4321 E flutter : A RenderFlex overflowed by 12 pixels on the right.
10-28 10:00:03.001  4321  4321 E flutter : The relevant error-causing widget was: Row  mobile_video_controls.dart:237:14
10-28 10:00:04.000  4321  4400 E AndroidRuntime: FATAL EXCEPTION: main
10-28 10:00:04.001  4321  4400 E AndroidRuntime: Process: {PKG}, PID: 4321
10-28 10:00:05.000  1000  1010 E ActivityManager: ANR in {PKG} (app.heisuca.player.teste.home/.MainActivity)
10-28 10:00:06.000  9999  9999 E flutter : Unhandled Exception: de outro app
10-28 10:00:07.000  9999  9999 E AndroidRuntime: FATAL EXCEPTION: main
10-28 10:00:07.001  9999  9999 E AndroidRuntime: Process: com.outro.app, PID: 9999
10-28 10:00:08.000  1000  1010 E ActivityManager: ANR in {PKG}.outro (x)
'''


class Logcat(unittest.TestCase):
    def test_pids(self):
        self.assertEqual(pids_do_app(LOGCAT, PKG), {4321})
        self.assertEqual(pids_do_app(LOGCAT, PKG, conhecidos=[77]), {77, 4321})

    def test_achados_so_do_app(self):
        achados = analisar_logcat(LOGCAT, PKG, {4321})
        codigos = [c for _, c, _ in achados]
        self.assertEqual(codigos, ['flutter-unhandled', 'renderflex-overflow', 'fatal-exception', 'anr'])
        self.assertTrue(all(g == 'vermelho' for g, _, _ in achados))
        self.assertIn('origem do HUD do PiP', achados[1][2])

    def test_logcat_limpo(self):
        limpo = f'10-28 10:00:01.000  4321  4321 I flutter : ok\n10-28 10:00:02.000  4321  4321 W flutter : aviso\n'
        self.assertEqual(analisar_logcat(limpo, PKG, {4321}), [])
        self.assertEqual(analisar_logcat('', PKG, set()), [])

    def test_filtro_por_pid(self):
        filtrado = filtrar_pid(LOGCAT, {4321})
        self.assertIn('Unhandled Exception: Bad state', filtrado)
        self.assertNotIn('de outro app', filtrado)
        self.assertNotIn('com.outro.app', filtrado)


class Plano(unittest.TestCase):
    def test_primeiro_plano(self):
        dentro = f'  topResumedActivity=ActivityRecord{{abc u0 {PKG}/.MainActivity t12}}'
        fora = '  topResumedActivity=ActivityRecord{abc u0 com.android.launcher3/.Launcher t1}'
        self.assertTrue(app_em_primeiro_plano(dentro, PKG))
        self.assertFalse(app_em_primeiro_plano(fora, PKG))
        self.assertFalse(app_em_primeiro_plano('', PKG))
        self.assertFalse(app_em_primeiro_plano(dentro.replace('.MainActivity', '.X').replace(PKG, PKG + '.outro'), PKG))

    def test_teclado(self):
        self.assertTrue(teclado_visivel('  mInputShown=true'))
        self.assertFalse(teclado_visivel('  mInputShown=false'))

    def test_classificar(self):
        self.assertEqual(classificar([], 'inicio'), 'verde')
        self.assertEqual(classificar([], 'login'), 'verde')
        self.assertEqual(classificar([], None), 'ATENÇÃO')
        self.assertEqual(classificar([('atenção', 'x', '')], 'inicio'), 'ATENÇÃO')
        self.assertEqual(classificar([('vermelho', 'anr', '')], 'inicio'), 'vermelho')
        self.assertEqual(classificar([], 'inicio', retomou=False), 'vermelho')


if __name__ == '__main__':
    unittest.main()
