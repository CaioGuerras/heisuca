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


from desastre import (nos_sem_rotulo, escolher_cartao, botoes_de_toque, densidade_para_dp, tamanho_da_tela,
                      densidade_atual, usuario_inexistente, comandos_iptables, ips_do_host, executar_etapa,
                      EtapaAmbiente, mensagem_pt)


class Caos(unittest.TestCase):
    def test_nos_sem_rotulo(self):
        nos = parse_uiautomator(xml(
            no('android.widget.ImageButton', b='[0,0][100,100]'),
            no('android.view.View', desc='Buscar', b='[100,0][200,100]'),
            no('android.view.View', b='[0,200][400,400]'), no(text='Título', b='[10,210][300,260]')))
        # o grupo [0,200][400,400] está coberto por um filho rotulado; o ImageButton não
        self.assertEqual(nos_sem_rotulo(nos), [('ImageButton', (0, 0, 100, 100))])
        self.assertEqual(nos_sem_rotulo([]), [])

    def test_ingles_de_rede_e_mensagem_pt(self):
        nos = parse_uiautomator(xml(no(text='Connection refused'), no(text='Network is unreachable'),
                                    no(text='Failed to load'), no(text='Sem conexão. Tente novamente.')))
        self.assertEqual(len(texto_tecnico_na_ui(nos)), 3)
        self.assertTrue(mensagem_pt(nos))
        self.assertFalse(mensagem_pt(parse_uiautomator(xml(no(text='Início')))))
        self.assertEqual(texto_tecnico_na_ui(parse_uiautomator(xml(no(text='Não foi possível conectar ao servidor')))), [])

    def test_cartao_e_botoes(self):
        nos = parse_uiautomator(xml(
            no(desc='Início', b='[0,1100][100,1200]'), no(text='Duna', b='[40,400][300,600]'),
            no(text='Assistir', b='[40,700][500,800]')))
        self.assertEqual(escolher_cartao(nos, 540, 1200)['text'], 'Duna')
        alvos = botoes_de_toque(nos, 540, 1200)
        self.assertEqual([a['centro'] for a in alvos], [(170, 500), (270, 750), (50, 1150)])
        self.assertIsNone(escolher_cartao([], 540, 1200))

    def test_tela_e_densidade(self):
        self.assertEqual(densidade_para_dp(540), 270)
        self.assertEqual(densidade_para_dp(1080), 540)
        saida = 'Physical size: 1080x2400\nOverride size: 540x1200\n'
        self.assertEqual(tamanho_da_tela(saida), (540, 1200))
        self.assertIsNone(tamanho_da_tela(''))
        self.assertEqual(densidade_atual('Physical density: 420\nOverride density: 210'), 210)
        self.assertEqual(densidade_atual('Physical density: 420\n'), 420)

    def test_usuario_inexistente_e_iptables(self):
        a, b = usuario_inexistente(), usuario_inexistente()
        self.assertTrue(a.startswith('desastrado-') and a != b)
        self.assertEqual(usuario_inexistente('abc'), 'desastrado-abc')
        cmds = comandos_iptables(['1.2.3.4', '2001:db8::1'])
        self.assertEqual(cmds[0], ['iptables', '-I', 'OUTPUT', '-d', '1.2.3.4', '-j', 'REJECT'])
        self.assertEqual(cmds[1][0], 'ip6tables')
        self.assertEqual(comandos_iptables(['1.2.3.4'], inserir=False)[0][1], '-D')
        self.assertEqual(ips_do_host('https://x.exemplo/abc', lambda h: ['9.9.9.9', '9.9.9.9']), ['9.9.9.9'])
        self.assertEqual(ips_do_host('sem-host', lambda h: ['1']), [])


class Etapa(unittest.TestCase):
    def rodar(self, etapa, **kw):
        achados, chamadas = [], []
        reg = executar_etapa('t', etapa, achados, restaurar=lambda: chamadas.append('r'), **kw)
        return reg, achados, chamadas

    def test_restauracao_sempre_chamada(self):
        def falha(): raise ValueError('x')
        for etapa in (lambda: None, falha, lambda: (_ for _ in ()).throw(EtapaAmbiente('sem root'))):
            _, _, chamadas = self.rodar(etapa)
            self.assertEqual(chamadas, ['r'])

    def test_falha_de_ambiente_vira_atencao_com_motivo(self):
        def sem_root(): raise EtapaAmbiente('sem root')
        reg, achados, _ = self.rodar(sem_root)
        self.assertEqual(reg['resultado'], 'ambiente')
        self.assertEqual(achados, [('atenção', 'etapa-ambiente', 't: sem root')])

    def test_excecao_nao_propaga_e_so_leva_o_tipo(self):
        def falha(): raise ValueError('segredo-no-texto')
        reg, achados, _ = self.rodar(falha)
        self.assertEqual(reg['resultado'], 'erro')
        self.assertNotIn('segredo', str(achados))

    def test_falha_na_restauracao_e_registrada(self):
        achados = []
        def ruim(): raise OSError('x')
        executar_etapa('t', lambda: None, achados, restaurar=ruim)
        self.assertEqual(achados[0][1], 'restauracao-falhou')

    def test_depois_roda_apos_restauracao_e_soma_achados(self):
        ordem = []
        achados = []
        executar_etapa('t', lambda: ordem.append('e'), achados, restaurar=lambda: ordem.append('r'),
                       depois=lambda: (ordem.append('d'), [('vermelho', 'x', 'y')])[1])
        self.assertEqual(ordem, ['e', 'r', 'd'])
        self.assertEqual(achados, [('vermelho', 'x', 'y')])

    def test_prazo_esgotado_pula_sem_rodar(self):
        ordem = []
        reg, achados, chamadas = self.rodar(lambda: ordem.append('e'), prazo_ok=lambda: False)
        self.assertEqual((reg['resultado'], ordem, chamadas), ('pulada', [], []))
        self.assertEqual(achados[0][1], 'etapa-pulada')


from desastre import sanear_texto, listar_visivel, pedacos_do_servidor, aba_voce

SERVIDOR = 'https://filmes.exemplo-casa.com.br:8443/'


class DiagnosticoLogin(unittest.TestCase):
    def test_servidor_e_pedacos_nunca_aparecem(self):
        texto = ('Falha em https://filmes.exemplo-casa.com.br:8443/System/Info; host filmes.exemplo-casa.com.br; '
                 'sem esquema filmes.exemplo-casa.com.br:8443; pedaço exemplo-casa e FILMES')
        saida = sanear_texto(texto, SERVIDOR, ['teste-sem-senha'])
        for proibido in ('filmes', 'exemplo-casa', 'exemplo', '8443', 'https://'):
            self.assertNotIn(proibido.lower(), saida.lower())
        self.assertIn('<servidor>', saida)

    def test_servidor_sem_esquema_e_vazio(self):
        self.assertNotIn('casa', sanear_texto('abra minha-casa.com', 'minha-casa.com'))
        self.assertEqual(sanear_texto('nada aqui', ''), 'nada aqui')
        self.assertEqual(pedacos_do_servidor(''), [])

    def test_conta_tambem_some(self):
        self.assertNotIn('teste-sem-senha', sanear_texto('Olá teste-sem-senha', SERVIDOR, ['teste-sem-senha']))

    def test_edittext_mascarado_e_dica_preservada(self):
        nos = parse_uiautomator(xml(
            no('android.widget.EditText', text='https://filmes.exemplo-casa.com.br:8443', hint='https://seuservidor.com'),
            no('android.widget.EditText', text='teste-sem-senha', hint='Nome de usuário'),
            no('android.widget.EditText', hint='Nome de usuário vazio'),
            no(text='Iniciar sessão'),
            no(desc='Erro em filmes.exemplo-casa.com.br')))
        linhas = listar_visivel(nos, SERVIDOR, ['teste-sem-senha'])
        junto = '\n'.join(linhas)
        self.assertIn('EditText[[endereço omitido]] <digitado:39 caracteres>', linhas)
        self.assertIn('EditText[Nome de usuário] <digitado:15 caracteres>', linhas)
        self.assertIn('EditText[Nome de usuário vazio] <vazio>', linhas)
        self.assertIn('Iniciar sessão', linhas)
        for proibido in ('filmes', 'exemplo-casa', 'teste-sem-senha', '8443'):
            self.assertNotIn(proibido, junto)

    def test_texto_igual_a_dica_conta_como_vazio(self):
        nos = parse_uiautomator(xml(no('android.widget.EditText', text='Nome de usuário', hint='Nome de usuário')))
        self.assertEqual(listar_visivel(nos, SERVIDOR), ['EditText[Nome de usuário] <vazio>'])

    def test_sem_bounds_na_saida(self):
        nos = parse_uiautomator(xml(no(text='Início', b='[1,2][3,4]')))
        self.assertNotIn('[1,2]', str(listar_visivel(nos, SERVIDOR)))


class AbaVoce(unittest.TestCase):
    def test_ultima_aba_da_linha_mesmo_com_o_nome_do_usuario(self):
        nos = parse_uiautomator(xml(
            no(desc='Início', b='[0,1100][100,1200]'), no(desc='Biblioteca', b='[100,1100][200,1200]'),
            no(desc='Baixados', b='[200,1100][300,1200]'), no(desc='teste', b='[300,1100][400,1200]'),
            no(text='Duna', b='[40,400][300,600]')))
        self.assertEqual(aba_voce(nos)['desc'], 'teste')

    def test_tela_com_titulo_baixados_no_topo_acha_aba_voce_na_barra_inferior(self):
        # Na tela de Baixados, o título do topo também se chama 'Baixados';
        # a barra de navegação fica na parte inferior da tela.
        nos = parse_uiautomator(xml(
            no(text='Baixados', b='[40,100][300,200]'),
            no(desc='Início', b='[0,1100][100,1200]'), no(desc='Biblioteca', b='[100,1100][200,1200]'),
            no(desc='Baixados', b='[200,1100][300,1200]'), no(desc='teste', b='[300,1100][400,1200]'),
            no(text='Downloads automáticos', b='[40,300][400,380]')))
        self.assertEqual(aba_voce(nos)['desc'], 'teste')

    def test_sem_barra_usa_voce_ou_nada(self):
        self.assertEqual(aba_voce(parse_uiautomator(xml(no(desc='Você')))) ['desc'], 'Você')
        self.assertIsNone(aba_voce(parse_uiautomator(xml(no(text='Duna')))))


from desastre import reconhecer_anr, achados_de_anr


def dialogo(titulo, botao='Wait'):
    return xml(no(text=titulo, b='[100,500][900,600]'), no('android.widget.Button', text='Close app', b='[100,700][400,800]'),
               no('android.widget.Button', text=botao, b='[500,700][900,800]'))


class AnrDeOutroApp(unittest.TestCase):
    def test_launcher_em_ingles_e_portugues(self):
        for titulo, nome in (("Pixel Launcher isn't responding", 'Pixel Launcher'),
                             ('O Pixel Launcher não está respondendo', 'Pixel Launcher'),
                             ('System UI is not responding', 'System UI')):
            d = reconhecer_anr(parse_uiautomator(dialogo(titulo, 'Aguardar' if 'não' in titulo else 'Wait')))
            self.assertEqual([(x['nome'], x['nosso']) for x in d], [(nome, False)])
            self.assertEqual(d[0]['esperar']['centro'], (700, 750))

    def test_nosso_app(self):
        for titulo in ("Heisuca Teste isn't responding", 'Heisuca não está respondendo', "CGFLIX isn't responding"):
            d = reconhecer_anr(parse_uiautomator(dialogo(titulo)))
            self.assertTrue(d[0]['nosso'], titulo)

    def test_tela_normal_nao_e_anr(self):
        self.assertEqual(reconhecer_anr(parse_uiautomator(INICIO)), [])
        self.assertEqual(reconhecer_anr(parse_uiautomator(xml(no(text='Servidor não está respondendo, tente de novo')))), [])
        self.assertEqual(reconhecer_anr([]), [])

    def test_achados_uma_vez_por_nome(self):
        vistos = set()
        d = reconhecer_anr(parse_uiautomator(dialogo("Pixel Launcher isn't responding")))
        self.assertEqual(achados_de_anr(d, vistos), [('atenção', 'anr-de-outro-app', 'Pixel Launcher')])
        self.assertEqual(achados_de_anr(d, vistos), [])
        nosso = reconhecer_anr(parse_uiautomator(dialogo("Heisuca Teste isn't responding")))
        self.assertEqual(achados_de_anr(nosso, vistos), [('vermelho', 'anr-do-app', 'Heisuca Teste')])

    def test_sem_botao_esperar(self):
        d = reconhecer_anr(parse_uiautomator(xml(no(text="Pixel Launcher isn't responding"))))
        self.assertIsNone(d[0]['esperar'])


from desastre import campo_abaixo_do_rotulo, tamanho_do_campo, foco_no_campo


def edit(texto='', b='[0,0][10,10]', focado=False):
    return (f'<node class="android.widget.EditText" text="{texto}" content-desc="" bounds="{b}" '
            f'clickable="true" enabled="true" focused="{"true" if focado else "false"}" package="{PKG}"/>')


def tela_login(servidor='x' * 29, usuario='', senha='', versao=True, foco=None):
    """Login real: rótulos em maiúsculas, EditText sem dica e, com o servidor digitado, a linha da versão empurra os campos."""
    deslocamento = 60 if versao else 0
    return xml(
        no(text='SERVIDOR', b='[40,250][400,300]'),
        edit(servidor, '[40,300][1040,420]', foco == 'servidor'),
        no(text='Jellyfin 10.11.11 · CGFLIX', b='[40,425][700,470]') if versao else '',
        no(text='USUÁRIO', b=f'[40,{460 + deslocamento}][400,{510 + deslocamento}]'),
        edit(usuario, f'[40,{510 + deslocamento}][1040,{630 + deslocamento}]', foco == 'usuario'),
        no(text='SENHA', b=f'[40,{680 + deslocamento}][400,{730 + deslocamento}]'),
        edit(senha, f'[40,{730 + deslocamento}][1040,{850 + deslocamento}]', foco == 'senha'),
        no('android.widget.Button', desc='Iniciar sessão', b='[40,1000][1040,1120]'))


class CampoPeloRotulo(unittest.TestCase):
    def test_acha_cada_campo_pela_posicao_com_a_linha_da_versao(self):
        nos = parse_uiautomator(tela_login())
        self.assertEqual(campo_abaixo_do_rotulo(nos, 'SERVIDOR')['bounds'], (40, 300, 1040, 420))
        self.assertEqual(campo_abaixo_do_rotulo(nos, 'USUÁRIO')['bounds'], (40, 570, 1040, 690))
        self.assertEqual(campo_abaixo_do_rotulo(nos, 'SENHA')['bounds'], (40, 790, 1040, 910))
        c = campos_login(nos)
        self.assertEqual([c[k]['bounds'][1] for k in ('servidor', 'usuario', 'senha')], [300, 570, 790])

    def test_o_defeito_do_run_usuario_nao_cai_no_campo_da_senha(self):
        # Posição calculada ANTES da linha da versão (usuário em y=560) cairia no campo errado depois dela.
        antes = campos_login(parse_uiautomator(tela_login(versao=False)))
        depois = campos_login(parse_uiautomator(tela_login(versao=True)))
        self.assertNotEqual(antes['usuario']['centro'], depois['usuario']['centro'])
        self.assertEqual(depois['usuario']['centro'][1], 630)

    def test_tamanho_do_campo_confere_onde_o_texto_foi(self):
        errado = parse_uiautomator(tela_login(usuario='', senha='teste-sem-senha'))   # o que aconteceu no run
        certo = parse_uiautomator(tela_login(usuario='teste-sem-senha', senha=''))
        self.assertEqual((tamanho_do_campo(errado, 'USUÁRIO'), tamanho_do_campo(errado, 'SENHA')), (0, 15))
        self.assertEqual((tamanho_do_campo(certo, 'USUÁRIO'), tamanho_do_campo(certo, 'SENHA')), (15, 0))
        self.assertIsNone(tamanho_do_campo([], 'USUÁRIO'))

    def test_foco(self):
        nos = parse_uiautomator(tela_login(foco='usuario'))
        usuario, senha = campo_abaixo_do_rotulo(nos, 'USUÁRIO'), campo_abaixo_do_rotulo(nos, 'SENHA')
        self.assertTrue(foco_no_campo(nos, usuario))
        self.assertFalse(foco_no_campo(nos, senha))
        sem_foco = parse_uiautomator(tela_login())
        self.assertIsNone(foco_no_campo(sem_foco, usuario))

    def test_rotulo_ausente_ou_sem_campo_abaixo(self):
        self.assertIsNone(campo_abaixo_do_rotulo(parse_uiautomator(INICIO), 'USUÁRIO'))
        so_rotulo = parse_uiautomator(xml(no(text='USUÁRIO', b='[40,460][400,510]')))
        self.assertIsNone(campo_abaixo_do_rotulo(so_rotulo, 'USUÁRIO'))
        # campo ACIMA do rótulo não vale
        acima = parse_uiautomator(xml(edit('', '[40,100][1040,200]'), no(text='USUÁRIO', b='[40,460][400,510]')))
        self.assertIsNone(campo_abaixo_do_rotulo(acima, 'USUÁRIO'))

    def test_cai_na_ordem_quando_nao_ha_rotulos(self):
        c = campos_login(parse_uiautomator(LOGIN_SEM_DICA))
        self.assertEqual([c[k]['centro'][1] for k in ('servidor', 'usuario', 'senha')], [360, 560, 760])


import urllib.error
from unittest import mock
from desastre import tela_conhecida
from servidor import Servidor, BancadaIndisponivel


class TelasConhecidas(unittest.TestCase):
    def nome(self, *nos_):
        return tela_conhecida(parse_uiautomator(xml(*nos_)))

    def test_inicio_e_login_seguem_como_marcos(self):
        self.assertEqual(tela_conhecida(parse_uiautomator(INICIO)), 'inicio')
        self.assertEqual(tela_conhecida(parse_uiautomator(LOGIN)), 'login')

    def test_titulo_e_player(self):
        self.assertEqual(self.nome(no(text='Duna'), no(text='Assistir T1:E3'), no(desc='Fechar')), 'titulo')
        self.assertEqual(self.nome(no(text='Continuar'), no(desc='Fechar')), 'titulo')
        self.assertEqual(self.nome(no(desc='Pausar'), no(desc='Legendas'), no(desc='Voltar 10 segundos')), 'player')
        self.assertEqual(self.nome(no(desc='Carregando vídeo'), no(desc='Mostrar os botões')), 'player')

    def test_tela_do_final_do_run_novo_perfil_com_pin(self):
        self.assertEqual(self.nome(no(text='Novo perfil'), no(text='Proteção por PIN (opcional)'),
                                   no(text='Confirmar PIN'), no(text='Cancelar')), 'perfil')
        self.assertEqual(self.nome(no(text='Sair da conta Encerrar a sessão neste dispositivo')), 'perfil')

    def test_busca(self):
        self.assertEqual(self.nome(no('android.widget.EditText', hint='Buscar', b='[0,0][500,100]'), no(text='Buscar')), 'busca')

    def test_tela_desconhecida_e_vazia(self):
        self.assertIsNone(self.nome(no(text='Carregando')))
        self.assertIsNone(self.nome(no(text='Assistir')))   # só o verbo solto não basta
        self.assertIsNone(tela_conhecida([]))
        self.assertIsNone(self.nome(no(desc='Pausar')))     # um rótulo de player só não basta


class CausaDoErro(unittest.TestCase):
    def test_http_e_caminho_sem_id_nem_token(self):
        s = Servidor('https://x.exemplo', token='XXXX-falso')
        erro = urllib.error.HTTPError('https://x.exemplo/Users/aaaaaaaabbbbbbbbccccccccdddddddd/Items?chave=XXXX-falso', 401, 'x', {}, None)
        with mock.patch('servidor.urllib.request.urlopen', side_effect=erro):
            with self.assertRaises(BancadaIndisponivel):
                s.request('GET', '/Users/aaaaaaaabbbbbbbbccccccccdddddddd/Items', query={'chave': 'XXXX-falso'})
        self.assertEqual(s.ultimo_erro, 'GET /Users/<id>/Items -> HTTP 401')
        for proibido in ('XXXX-falso', 'exemplo', 'chave', 'aaaaaaaabbbb'):
            self.assertNotIn(proibido, s.ultimo_erro)

    def test_timeout_e_rede(self):
        s = Servidor('https://x.exemplo')
        with mock.patch('servidor.urllib.request.urlopen', side_effect=urllib.error.URLError(TimeoutError())):
            with self.assertRaises(BancadaIndisponivel):
                s.request('GET', '/System/Info/Public')
        self.assertEqual(s.ultimo_erro, 'GET /System/Info/Public -> TimeoutError')


class RunReal(unittest.TestCase):
    def test_confirmacao_sair_com_rotulo_em_descricao(self):
        # Rótulos do run: título e botão 'Sair', texto de confirmação, Cancelar e a barreira 'Dispensar'.
        nos = parse_uiautomator(xml(no(desc='Sair', b='[100,500][900,560]'), no(text='Quer mesmo sair?', b='[100,560][900,640]'),
                                    no('android.widget.Button', desc='Cancelar', b='[100,700][400,800]'),
                                    no('android.widget.Button', desc='Sair', b='[500,700][900,800]')))
        com_rotulo = [n for n in nos if n['centro'] and any(r.strip().lower() == 'sair' for r in (n['text'], n['desc']))]
        self.assertEqual(com_rotulo[-1]['centro'], (700, 750))

    def test_tela_downloads_automaticos_e_configuracoes(self):
        for rotulos in (('Voltar', 'Downloads automáticos', 'Nenhum download automático'),
                        ('Configurações Heisuca\nReprodução, vídeo, áudio, legendas e fontes',),
                        ('Voltar', 'Adicionar servidor Jellyfin', 'Servidores Jellyfin na sua rede', 'Encontrar servidor')):
            nos = parse_uiautomator(xml(*[no(text=r) for r in rotulos]))
            self.assertEqual(tela_conhecida(nos), 'configuracoes', rotulos)
