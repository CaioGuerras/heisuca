"""Primitivas de adb e de interface do desastrado (usadas por desastrado.py e caos.py)."""
import shlex
import subprocess
import time

from capturas import APP_ID, adb
from desastre import (VERMELHO, campo_abaixo_do_rotulo, foco_no_campo, tamanho_do_campo, aba_voce, achados_de_anr, reconhecer_anr, achar_texto, app_em_primeiro_plano, assinatura_tela, campos_login, marco,
                      parse_uiautomator, teclado_visivel, tela_presa)

CONTA = 'teste-sem-senha'


def texto(*args, tempo=30):
    try:
        r = subprocess.run(['adb', *args], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=tempo)
        return r.stdout.decode(errors='replace')
    except (subprocess.TimeoutExpired, OSError):
        return ''


ANR_VISTOS = set()
ANR_ACHADOS = []  # lista compartilhada com o desastrado (ligar_achados)


def ligar_achados(lista):
    global ANR_ACHADOS
    ANR_ACHADOS = lista


def tratar_anr(nos):
    """Se há diálogo de ANR na tela: registra (uma vez por nome) e toca em Aguardar. Devolve True se tocou."""
    dialogos = reconhecer_anr(nos)
    if not dialogos:
        return False
    ANR_ACHADOS.extend(achados_de_anr(dialogos, ANR_VISTOS))
    botao = next((d['esperar'] for d in dialogos if d['esperar']), None)
    if botao:
        tocar(botao)
        return True
    return False


def dump():
    """Hierarquia atual da tela como lista de nós ([] se o uiautomator falhar).

    Defesa em profundidade: um diálogo de ANR (do launcher do emulador, por exemplo) cobre o app e esconde tudo;
    é tratado aqui, em toda leitura de tela, e a leitura é refeita.
    """
    nos = parse_uiautomator(_xml_do_dump())
    if tratar_anr(nos):
        time.sleep(2)
        nos = parse_uiautomator(_xml_do_dump())
    return nos


def esperar_launcher(tempo=60):
    """Espera até duas leituras seguidas sem diálogo de ANR (launcher do emulador lento no boot)."""
    limpas, fim = 0, time.monotonic() + tempo
    while time.monotonic() < fim and limpas < 2:
        limpas = 0 if reconhecer_anr(dump_cru()) else limpas + 1
        time.sleep(2)


def dump_cru():
    return parse_uiautomator(_xml_do_dump())


def _xml_do_dump():
    bruto = texto('exec-out', 'uiautomator', 'dump', '/dev/stdout')
    inicio, fim = bruto.find('<?xml'), bruto.rfind('</hierarchy>')
    return bruto[inicio:fim + len('</hierarchy>')] if inicio >= 0 and fim > 0 else ''


def tocar(no):
    x, y = no['centro']
    adb('shell', 'input', 'tap', str(x), str(y))


def digitar(valor):
    adb('shell', 'input', 'text', shlex.quote(valor.replace(' ', '%s')))


def pid_do_app():
    return [int(p) for p in texto('shell', 'pidof', APP_ID).split() if p.isdigit()]


def em_primeiro_plano():
    return app_em_primeiro_plano(texto('shell', 'dumpsys', 'activity', 'activities'), APP_ID)


def abrir_app():
    adb('shell', 'monkey', '-p', APP_ID, '-c', 'android.intent.category.LAUNCHER', '1')


def esperar_marco(querido, tempo, passo=3, registrar=None, nome='espera'):
    """Espera um marco; também aceita o pedido de permissão do sistema. Devolve (marco, nós)."""
    limite = time.monotonic() + tempo
    nos = []
    while time.monotonic() < limite:
        nos = dump()
        m = marco(nos)
        if registrar:
            registrar(f'{nome} (marco={m})', nos)
        if m in querido:
            return m, nos
        permitir = achar_texto(nos, 'Permitir', 'Allow', 'While using the app')
        if permitir and 'permission' in permitir['pkg']:
            tocar(permitir)
        time.sleep(passo)
    return marco(nos), nos


def fechar_teclado():
    for _ in range(2):
        if teclado_visivel(texto('shell', 'dumpsys', 'input_method')):
            adb('shell', 'input', 'keyevent', '111')  # ESCAPE; o BACK fecha o teclado, mas pode sair da tela
            time.sleep(1)
            if teclado_visivel(texto('shell', 'dumpsys', 'input_method')):
                adb('shell', 'input', 'keyevent', '4')
                time.sleep(1)
        else:
            return


def apagar_campo():
    adb('shell', 'input', 'keyevent', '123')  # MOVE_END
    adb('shell', 'input', 'keyevent', *['67'] * 80)  # DEL


def preencher_campo(rotulo, valor, registrar=None):
    """Toca no EditText sob [rotulo], confere o foco, digita e confere o tamanho. Uma repetição se algo não bater.

    Refaz o dump a cada passo: a tela muda depois de digitar (linha de versão do servidor, teclado) e a posição
    calculada antes cairia no campo de baixo. Devolve True se o campo ficou com len(valor) caracteres.
    """
    rec = registrar or (lambda nome, nos: None)
    for tentativa in (1, 2):
        campo = campo_abaixo_do_rotulo(dump(), rotulo)
        if campo is None:
            rec(f'campo {rotulo} não achado', dump())
            return False
        tocar(campo)
        time.sleep(1)
        nos = dump()
        campo = campo_abaixo_do_rotulo(nos, rotulo)
        if campo is None or foco_no_campo(nos, campo) is False:
            continue  # o foco foi para outro campo: toca de novo
        apagar_campo()
        if valor:
            digitar(valor)
        time.sleep(1.5)
        nos = dump()
        rec(f'após {rotulo} (tentativa {tentativa})', nos)
        if tamanho_do_campo(nos, rotulo) == len(valor):
            return True
    return False


def entrar_pela_interface(servidor, registrar=None):
    """Como uma pessoa: acha cada campo pelo rótulo na hora, digita servidor e conta, toca em Iniciar sessão.

    [registrar(nome, nos)] recebe cada passo para o diagnóstico (já sanitizado por quem chama).
    O fluxo real (heisuca_login_screen.dart) não tem passo intermediário: um botão só, que sonda o servidor,
    autentica e troca para a sessão. Depois do toque só se espera o marco.
    """
    rec = registrar or (lambda nome, nos: None)
    m, nos = esperar_marco({'login', 'inicio'}, 90, passo=5, registrar=registrar, nome='abertura')
    if m == 'inicio':
        return True
    rec('antes de digitar', nos)
    if campo_abaixo_do_rotulo(nos, 'SERVIDOR') is None and not campos_login(nos).get('servidor'):
        rec('campos do login não encontrados', nos)
        return False
    for rotulo, valor in (('SERVIDOR', servidor), ('USUÁRIO', CONTA), ('SENHA', '')):
        if not preencher_campo(rotulo, valor, registrar):
            rec(f'falha: {rotulo} não ficou com o conteúdo certo', dump())
            return False
    # O teclado cobre o botão: fecha antes de procurar.
    fechar_teclado()
    nos = dump()
    botao = achar_texto(nos, 'Iniciar sessão')
    if botao is None:
        adb('shell', 'input', 'swipe', '270', '900', '270', '400')  # rola, caso o botão esteja abaixo da dobra
        time.sleep(1)
        nos = dump()
        botao = achar_texto(nos, 'Iniciar sessão')
    rec('antes de tocar em Iniciar sessão', nos)
    if botao is None:
        rec('botão Iniciar sessão não achado', nos)
        return False
    tocar(botao)
    time.sleep(2)
    rec('após tocar em Iniciar sessão', dump())
    m, nos = esperar_marco({'inicio'}, 90, passo=5, registrar=registrar, nome='espera do marco')
    if m != 'inicio':
        rec('falha: marco não apareceu', nos)
    return m == 'inicio'


def recuperar(achados, rotulo):
    """Volta a um estado utilizável. Devolve (marco, retomou). Três ações: Voltar, relançar, Home+relançar."""
    acoes = [lambda: adb('shell', 'input', 'keyevent', '4'), abrir_app,
             lambda: (adb('shell', 'input', 'keyevent', '3'), time.sleep(1), abrir_app())]
    nos = dump()
    dumps = [assinatura_tela(nos)]
    if em_primeiro_plano() and marco(nos):
        return marco(nos), True
    for acao in acoes:
        acao()
        time.sleep(4)
        nos = dump()
        dumps.append(assinatura_tela(nos))
        if em_primeiro_plano() and marco(nos):
            return marco(nos), True
    retomou = em_primeiro_plano()
    # Tela estática com marco conhecido não é "presa"; só tela desconhecida e idêntica nas quatro leituras.
    if retomou and marco(nos) is None and tela_presa(dumps):
        achados.append((VERMELHO, 'tela-presa', f'{rotulo}: tela desconhecida igual após Voltar, relançar e Home+relançar'))
        retomou = False
    elif not retomou:
        achados.append((VERMELHO, 'app-fora-do-primeiro-plano', f'{rotulo}: não voltou após relançar'))
    return marco(nos), retomou


def sair_pela_interface():
    """Sair da conta pelo menu Você; devolve True se o app voltou ao login."""
    nos = dump()
    if marco(nos) != 'inicio':
        return False
    voce = aba_voce(nos)
    if not voce:
        return False
    tocar(voce)
    time.sleep(2)
    sair = achar_texto(dump(), 'Sair da conta')
    if not sair:
        return False
    tocar(sair)
    time.sleep(2)
    confirmar = [n for n in dump() if n['centro'] and n['text'].strip() == 'Sair']
    if not confirmar:
        return False
    tocar(confirmar[-1])
    m, _ = esperar_marco({'login'}, 30)
    return m == 'login'
