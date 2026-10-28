"""Primitivas de adb e de interface do desastrado (usadas por desastrado.py e caos.py)."""
import shlex
import subprocess
import time

from capturas import APP_ID, adb
from desastre import (VERMELHO, aba_voce, achar_texto, app_em_primeiro_plano, assinatura_tela, campos_login, marco,
                      parse_uiautomator, teclado_visivel, tela_presa)

CONTA = 'teste-sem-senha'


def texto(*args, tempo=30):
    try:
        r = subprocess.run(['adb', *args], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, timeout=tempo)
        return r.stdout.decode(errors='replace')
    except (subprocess.TimeoutExpired, OSError):
        return ''


def dump():
    """Hierarquia atual da tela como lista de nós ([] se o uiautomator falhar)."""
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


def entrar_pela_interface(servidor, registrar=None):
    """Como uma pessoa: acha os campos no dump, digita servidor e conta, toca em Iniciar sessão.

    [registrar(nome, nos)] recebe cada passo para o diagnóstico (já sanitizado por quem chama).
    O fluxo real (heisuca_login_screen.dart) não tem passo intermediário: um botão só, que sonda o servidor,
    autentica e troca para a sessão. Depois do toque só se espera o marco.
    """
    rec = registrar or (lambda nome, nos: None)
    m, nos = esperar_marco({'login', 'inicio'}, 90, passo=5, registrar=registrar, nome='abertura')
    if m == 'inicio':
        return True
    rec('antes de digitar', nos)
    campos = campos_login(nos)
    if not all(campos.get(k) for k in ('servidor', 'usuario', 'botao')):
        rec('campos do login não encontrados', nos)
        return False
    tocar(campos['servidor'])
    digitar(servidor)
    time.sleep(2)
    rec('após o servidor', dump())
    tocar(campos['usuario'])
    digitar(CONTA)
    time.sleep(1)
    rec('após o usuário', dump())
    # Senha vazia: o campo fica como está. O teclado cobre o botão: fecha antes de procurar.
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
