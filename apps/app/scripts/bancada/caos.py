"""Roteiro de caos do desastrado (P6-2): etapas independentes, cada uma com restauração garantida.

Toda etapa que mexe no aparelho (rotação, rede, fonte, modo avião, iptables, atividades) desfaz no `restaurar`,
que roda mesmo se a etapa falhar. Nenhuma etapa derruba as outras: falha de ambiente vira ATENÇÃO com motivo.
Só a conta dedicada e usuários INEXISTENTES gerados (etapa 8) são usados; nunca senha errada em conta real.
"""
import shlex
import socket
import time

from capturas import APP_ID, adb
from desastre import (tela_conhecida, aba_voce, VERMELHO, ATENCAO, EtapaAmbiente, analisar_logcat, botoes_de_toque, comandos_iptables,
                      densidade_atual, densidade_para_dp, escolher_cartao, executar_etapa, filtrar_pid, ips_do_host,
                      marco, mensagem_pt, nos_sem_rotulo, pids_do_app, tamanho_da_tela, texto_tecnico_na_ui,
                      usuario_inexistente)
from servidor import Servidor, BancadaIndisponivel
from ui import (passo_visivel, preencher_campo, CONTA, abrir_app, achar_texto, campos_login, dump, em_primeiro_plano, entrar_pela_interface,
                esperar_marco, pid_do_app, recuperar, sair_pela_interface, texto, tocar, digitar)

PRAZO_TOTAL = 50 * 60  # segundos para todas as etapas; o job tem 90 min.


class Ctx:
    def __init__(self, base, achados, limpo, saida, pids):
        self.base, self.achados, self.limpo, self.saida, self.pids = base, achados, limpo, saida, set(pids)
        self.inicio = time.monotonic()
        self.registros = []
        self.logcat_total = []
        self.diag = []          # visível saneado das telas sem marco
        self.saida_passos = []  # visível saneado de cada passo da saída da conta
        self.aviao = {}
        s = tamanho_da_tela(texto('shell', 'wm', 'size')) or (540, 1200)
        self.largura, self.altura = s

    def prazo_ok(self):
        return time.monotonic() - self.inicio < PRAZO_TOTAL

    def tocar_xy(self, x, y):
        adb('shell', 'input', 'tap', str(int(x)), str(int(y)))

    def abas(self):
        """Toca em cada aba que existir, devolvendo quantas encontrou."""
        n = 0
        for nome in ('Biblioteca', 'Baixados', 'Você', 'Início'):
            nos = dump()
            alvo = aba_voce(nos) if nome == 'Você' else achar_texto(nos, nome)
            if alvo:
                tocar(alvo)
                n += 1
                time.sleep(1.5)
        return n

    def abrir_titulo(self):
        cartao = escolher_cartao(dump(), self.largura, self.altura)
        if cartao:
            tocar(cartao)
            time.sleep(3)
            return True
        return False


def checar_tela(ctx, rotulo):
    """Detectores sobre a tela de agora: inglês técnico = vermelho; sem marco e sem mensagem PT = ATENÇÃO."""
    achados = []
    nos = dump()
    for t in texto_tecnico_na_ui(nos):
        achados.append((VERMELHO, 'texto-tecnico-na-ui', f'{rotulo}: {t}'))
    if tela_conhecida(nos) is None and not mensagem_pt(nos):
        achados.append((ATENCAO, 'sem-marco-nem-mensagem', f'{rotulo}: tela sem marco e sem mensagem em português'))
        passo_visivel(ctx.diag, rotulo, nos)
    return achados


def depois_da_etapa(ctx, nome):
    """Recuperação, marco e detectores (tela e logcat desta etapa)."""
    def passo():
        achados = []
        m, retomou = recuperar(achados, nome)
        ctx.pids.update(pid_do_app())
        achados += checar_tela(ctx, nome)
        log = texto('logcat', '-d', '-v', 'threadtime', tempo=120)
        ctx.pids = pids_do_app(log, APP_ID, ctx.pids)
        achados += [(g, c, f'{nome}: {d}') for g, c, d in analisar_logcat(log, APP_ID, ctx.pids)]
        ctx.logcat_total.append(f'===== {nome} =====\n' + filtrar_pid(log, ctx.pids))
        adb('logcat', '-c')
        return achados
    return passo


def rodar(ctx, nome, etapa, restaurar=None):
    adb('logcat', '-c')
    reg = executar_etapa(nome, etapa, ctx.achados, restaurar, depois_da_etapa(ctx, nome), ctx.prazo_ok)
    ctx.registros.append(reg)
    print(f'  etapa {nome}: {reg["resultado"]}, {len(reg["achados"])} achado(s)', flush=True)


def ajuste(chave, valor, tabela='system'):
    adb('shell', 'settings', 'put', tabela, chave, str(valor))


def ler(chave, tabela='system'):
    return texto('shell', 'settings', 'get', tabela, chave).strip()


def exigir_root():
    if 'uid=0' not in texto('shell', 'id'):
        raise EtapaAmbiente('o aparelho não está em modo root')


# ---------- etapas ----------

def e01_girar(ctx):
    antes = ler('accelerometer_rotation'), ler('user_rotation')
    def etapa():
        ajuste('accelerometer_rotation', 0)
        fim = time.monotonic() + 60
        i = 0
        while time.monotonic() < fim:
            ajuste('user_rotation', i % 4)
            time.sleep(0.8)
            ctx.tocar_xy(ctx.largura / 2, ctx.altura * (0.35 + 0.1 * (i % 4)))
            i += 1
    def restaurar():
        ajuste('user_rotation', antes[1] if antes[1].isdigit() else 0)
        ajuste('accelerometer_rotation', antes[0] if antes[0].isdigit() else 1)
    rodar(ctx, '01-girar-sem-parar', etapa, restaurar)


def e02_voltar(ctx):
    def etapa():
        adb('shell', 'input', 'keyevent', *['4'] * 30)
        time.sleep(1)
        abrir_app()
    rodar(ctx, '02-voltar-30x', etapa)


def e03_toque_multiplo(ctx):
    def etapa():
        for alvo in botoes_de_toque(dump(), ctx.largura, ctx.altura):
            x, y = alvo['centro']
            vezes = 2 + (x + y) % 2
            adb('shell', '; '.join([f'input tap {x} {y}'] * vezes))
            time.sleep(2)
            adb('shell', 'input', 'keyevent', '4')
            time.sleep(1)
    rodar(ctx, '03-toque-duplo-triplo', etapa)


def e04_sem_atividades(ctx):
    antes = ler('always_finish_activities', 'global')
    def etapa():
        ajuste('always_finish_activities', 1, 'global')
        adb('shell', 'input', 'keyevent', '3')
        time.sleep(2)
        abrir_app()
        time.sleep(4)
        ctx.abas()
        adb('shell', 'input', 'keyevent', '3')
        time.sleep(2)
        adb('shell', 'am', 'kill', APP_ID)
        time.sleep(2)
        abrir_app()
        time.sleep(5)
    def restaurar():
        ajuste('always_finish_activities', antes if antes.isdigit() else 0, 'global')
    rodar(ctx, '04-nao-manter-atividades', etapa, restaurar)


def e05_rede_no_video(ctx):
    estado = {}
    def passo(nome, fn):
        """Executa uma chamada ao servidor dizendo QUAL falhou e com que código (sem URL nem token)."""
        estado['passo'] = nome
        try:
            return fn()
        except BancadaIndisponivel as erro:
            cli = estado.get('cli')
            causa = (cli.ultimo_erro if cli and cli.ultimo_erro else str(erro))
            raise EtapaAmbiente(f'{nome}: {causa}') from None

    def etapa():
        cli = Servidor(ctx.base)
        estado['cli'] = cli
        passo('autenticar', lambda: cli.autenticar(CONTA))
        info = passo('System/Info/Public', lambda: cli.request('GET', '/System/Info/Public')) or {}
        sid = info.get('Id')
        if not sid:
            raise EtapaAmbiente('System/Info/Public: sem identificador do servidor')
        video = passo('escolher_video', lambda: cli.escolher_video(min_ticks=0, tipos=None, apenas_intacto=False))
        estado['video'] = video
        estado['anterior'] = video['UserData']
        link = f'plezy://play?content_id=plezy_{sid}_{video["Id"]}'
        adb('shell', f'am start -a android.intent.action.VIEW -p {APP_ID} -d {shlex.quote(link)}')
        time.sleep(15)
        estado['rede'] = True
        adb('shell', 'svc', 'wifi', 'disable')
        adb('shell', 'svc', 'data', 'disable')
        time.sleep(20)
        adb('shell', 'svc', 'wifi', 'enable')
        adb('shell', 'svc', 'data', 'enable')
        estado['rede'] = False
        time.sleep(15)
    def restaurar():
        if estado.get('rede') is not False and estado.get('rede') is not None:
            adb('shell', 'svc', 'wifi', 'enable')
            adb('shell', 'svc', 'data', 'enable')
        adb('shell', 'am', 'force-stop', APP_ID)
        cli, video = estado.get('cli'), estado.get('video')
        if cli and video:
            try:
                passo('restaurar', lambda: cli.restaurar(video['Id'], estado['anterior'], apenas_intacto=False))
            finally:
                try:
                    cli.logout()
                except BancadaIndisponivel:
                    pass
        elif cli and cli.token:
            try:
                cli.logout()
            except BancadaIndisponivel:
                pass
    rodar(ctx, '05-rede-cai-no-video', etapa, restaurar)
    abrir_app()
    esperar_marco({'inicio', 'login'}, 40)


def e06_aviao(ctx):
    def etapa():
        adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'enable')
        time.sleep(5)
        ctx.abas()
        ctx.abrir_titulo()
        nos = dump()
        passo_visivel(ctx.diag, 'modo avião: tela depois de navegar', nos)
        ctx.aviao['visivel'] = ctx.diag[-1]['visivel']
        (ctx.saida / '06-modo-aviao.png').write_bytes(adb('exec-out', 'screencap', '-p').stdout)
        ctx.achados += [(g, c, '06-modo-aviao: ' + d) for g, c, d in checar_tela(ctx, 'durante o modo avião')]
    def restaurar():
        adb('shell', 'cmd', 'connectivity', 'airplane-mode', 'disable')
        time.sleep(5)
    rodar(ctx, '06-modo-aviao', etapa, restaurar)


def e07_servidor_fora(ctx):
    regras = []
    def etapa():
        exigir_root()
        ips = ips_do_host(ctx.base, lambda h: {i[4][0] for i in socket.getaddrinfo(h, None)})
        if not ips:
            raise EtapaAmbiente('não consegui resolver o servidor no runner')
        for cmd in comandos_iptables(ips, True):
            if adb('shell', *cmd).returncode == 0:
                regras.append(cmd)
        if not regras:
            raise EtapaAmbiente('iptables indisponível no emulador')
        fim = time.monotonic() + 30
        while time.monotonic() < fim:
            ctx.abas()
            ctx.abrir_titulo()
            adb('shell', 'input', 'keyevent', '4')
        ctx.achados += checar_tela(ctx, 'servidor fora do ar')
    def restaurar():
        for cmd in regras:
            adb('shell', *[('-D' if a == '-I' else a) for a in cmd])
    rodar(ctx, '07-servidor-fora-do-ar', etapa, restaurar)


def e08_senha_errada(ctx):
    def etapa():
        if not sair_pela_interface(ctx.saida_passos):
            raise EtapaAmbiente('não consegui sair da conta pela interface')
        for tentativa in range(5):
            m, nos = esperar_marco({'login'}, 20)
            campos = campos_login(nos)
            if m != 'login' or not all(campos.get(k) for k in ('servidor', 'usuario', 'senha', 'botao')):
                raise EtapaAmbiente('campos do login não encontrados')
            for rotulo, valor in (('SERVIDOR', ctx.base), ('USUÁRIO', usuario_inexistente()),
                                  ('SENHA', f'senha-errada-{tentativa}')):
                if not preencher_campo(rotulo, valor):
                    raise EtapaAmbiente(f'campo {rotulo} não ficou com o conteúdo digitado')
            adb('shell', 'input', 'keyevent', '4')
            time.sleep(1)
            botao = achar_texto(dump(), 'Iniciar sessão') or campos['botao']
            tocar(botao)
            time.sleep(8)
            ctx.achados += [(g, c, f'08-senha-errada #{tentativa + 1}: {d}') for g, c, d in checar_tela(ctx, 'senha errada')]
        # volta com a conta dedicada
        esperar_marco({'login'}, 20)
        if not entrar_pela_interface(ctx.base):
            ctx.achados.append((VERMELHO, 'login-depois-das-falhas', 'a conta dedicada não voltou a entrar'))
    rodar(ctx, '08-senha-errada-5x', etapa)


def e09_texto_enorme(ctx):
    def etapa():
        # `input text` só aceita ASCII; emoji vai pela área de transferência quando o aparelho permitir.
        copiou = 'Unknown' not in texto('shell', 'cmd', 'clipboard', 'set-text', shlex.quote('🎬🔥😀'))
        # A busca é o ícone 'Buscar' do topo da Início (heisuca_home_chrome.dart); a Biblioteca tem outro campo próprio.
        inicio = achar_texto(dump(), 'Início')
        if inicio:
            tocar(inicio)
            time.sleep(2)
        busca = achar_texto(dump(), 'Buscar', 'Busca', 'Pesquisar', 'Search')
        if busca:
            tocar(busca)
            time.sleep(3)
        nos = dump()
        campo = next((n for n in nos if n['cls'].endswith('EditText') and n['centro']), None)
        if not campo:
            passo_visivel(ctx.diag, '09 busca não achada', nos)
            raise EtapaAmbiente('campo de busca não encontrado (visível gravado em visivel_sem_marco)')
        tocar(campo)
        if copiou:
            adb('shell', 'input', 'keyevent', '279')
        for _ in range(5):
            digitar('Acao-cao_AE&<>"\'%' + 'x' * 380)
        time.sleep(2)
        if not copiou:
            ctx.achados.append((ATENCAO, 'emoji-nao-digitavel', '09: sem área de transferência pelo adb; testado só ASCII longo'))
    rodar(ctx, '09-emoji-e-texto-enorme', etapa)


def e10_fonte_e_tela(ctx):
    original = {'font': ler('font_scale'), 'dens': densidade_atual(texto('shell', 'wm', 'density'))}
    def etapa():
        tam = tamanho_da_tela(texto('shell', 'wm', 'size')) or (ctx.largura, ctx.altura)
        ajuste('font_scale', 2.0)
        adb('shell', 'wm', 'density', str(densidade_para_dp(min(tam))))
        time.sleep(5)
        ctx.abas()
        ctx.abrir_titulo()
    def restaurar():
        ajuste('font_scale', original['font'] if original['font'] not in ('', 'null') else 1.0)
        if original.get('dens'):
            adb('shell', 'wm', 'density', str(original['dens']))
        else:
            adb('shell', 'wm', 'density', 'reset')
    rodar(ctx, '10-fonte-200-e-tela-maxima', etapa, restaurar)


def e11_leitor_de_tela(ctx):
    pacote = 'com.google.android.marvin.talkback'
    tem = pacote in texto('shell', 'pm', 'list', 'packages', pacote)
    anterior = ler('enabled_accessibility_services', 'secure'), ler('accessibility_enabled', 'secure')
    def etapa():
        if tem:
            ajuste('enabled_accessibility_services', f'{pacote}/{pacote}.TalkBackService', 'secure')
            ajuste('accessibility_enabled', 1, 'secure')
            time.sleep(5)
            for i in range(10):
                adb('shell', 'input', 'keyevent', '61' if i % 2 == 0 else '20')
                time.sleep(1)
        else:
            ctx.achados.append((ATENCAO, 'talkback-ausente', 'TalkBack ausente na imagem; só a checagem de semântica'))
        sem = []
        for nome in ('Início', 'Biblioteca', 'Você'):
            nos = dump()
            alvo = aba_voce(nos) if nome == 'Você' else achar_texto(nos, nome)
            if alvo:
                tocar(alvo)
                time.sleep(2)
            sem += [(nome, c, b) for c, b in nos_sem_rotulo(dump())]
        if sem:
            lista = '; '.join(f'{t}:{c}{b}' for t, c, b in sem[:15])
            ctx.achados.append((ATENCAO, 'clicavel-sem-rotulo', f'{len(sem)} nó(s) clicável(is) sem texto nem descrição: {lista}'))
    def restaurar():
        if tem:
            valor = anterior[0] if anterior[0] not in ('', 'null') else ''
            if valor:
                ajuste('enabled_accessibility_services', valor, 'secure')
            else:
                adb('shell', 'settings', 'delete', 'secure', 'enabled_accessibility_services')
            ajuste('accessibility_enabled', anterior[1] if anterior[1].isdigit() else 0, 'secure')
    rodar(ctx, '11-leitor-de-tela', etapa, restaurar)


ETAPAS = (e01_girar, e02_voltar, e03_toque_multiplo, e04_sem_atividades, e05_rede_no_video, e06_aviao,
          e07_servidor_fora, e08_senha_errada, e09_texto_enorme, e10_fonte_e_tela, e11_leitor_de_tela)


def roteiro(ctx):
    for etapa in ETAPAS:
        etapa(ctx)
    return ctx.registros
