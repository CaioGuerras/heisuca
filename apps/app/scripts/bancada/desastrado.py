#!/usr/bin/env python3
"""Usuário desastrado: caixa-preta por adb. Login pela interface, monkey restrito ao pacote, detectores sobre os textos.

Só usa a conta `teste-sem-senha` (senha vazia): nunca tenta senha errada em conta real. Nada de credencial em log ou artifact:
tudo que sai passa por limpar_log. A classificação final é verde / ATENÇÃO / vermelho, como a bancada.
"""
import json
import os
import shlex
import subprocess
import sys
import time
from pathlib import Path

from capturas import APP_ID, adb
from desastre import (VERMELHO, ATENCAO, analisar_logcat, analisar_monkey, app_em_primeiro_plano, assinatura_tela,
                      achar_texto, campos_login, classificar, eventos_injetados, filtrar_pid, marco,
                      parse_uiautomator, pids_do_app, teclado_visivel, tela_presa, texto_tecnico_na_ui)
from servidor import BancadaIndisponivel, Servidor, limpar_log

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.bancada/desastrado'
CONTA = 'teste-sem-senha'
SEMENTE = 20261028
EVENTOS = 5000
APK = ROOT / 'build/app/outputs/flutter-apk/app-debug.apk'


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


def esperar_marco(querido, tempo, passo=3):
    """Espera um marco; também aceita o pedido de permissão do sistema. Devolve (marco, nós)."""
    limite = time.monotonic() + tempo
    nos = []
    while time.monotonic() < limite:
        nos = dump()
        m = marco(nos)
        if m in querido:
            return m, nos
        permitir = achar_texto(nos, 'Permitir', 'Allow', 'While using the app')
        if permitir and 'permission' in permitir['pkg']:
            tocar(permitir)
        time.sleep(passo)
    return marco(nos), nos


def entrar_pela_interface(servidor):
    """Como uma pessoa: acha os campos no dump, digita servidor e conta, toca em Iniciar sessão."""
    m, nos = esperar_marco({'login', 'inicio'}, 90)
    if m == 'inicio':
        return True
    campos = campos_login(nos)
    if not all(campos.get(k) for k in ('servidor', 'usuario', 'botao')):
        return False
    tocar(campos['servidor'])
    digitar(servidor)
    tocar(campos['usuario'])
    digitar(CONTA)
    # Senha vazia: o campo fica como está. O teclado pode cobrir o botão: fecha só se estiver aberto.
    if teclado_visivel(texto('shell', 'dumpsys', 'input_method')):
        adb('shell', 'input', 'keyevent', '4')
        time.sleep(1)
    botao = achar_texto(dump(), 'Iniciar sessão') or campos['botao']
    tocar(botao)
    m, _ = esperar_marco({'inicio'}, 90)
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
    voce = achar_texto(nos, 'Você')
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


def sessoes_restantes(base):
    """Autentica de novo com a conta dedicada, conta sessões do app e encerra a própria. None = não deu para ver."""
    cliente = Servidor(base)
    try:
        cliente.autenticar(CONTA)
        sessoes = cliente.request('GET', '/Sessions') or []
        # O app se anuncia como "CGFLIX <plataforma>" (lib/services/jellyfin_auth_header.dart, jellyfinClientName).
        restantes = sum(1 for s in sessoes if (s.get('Client') or '').lower().startswith('cgflix')
                        and s.get('DeviceId') != cliente.device)
        return restantes
    except (BancadaIndisponivel, KeyError, TypeError):
        return None
    finally:
        if cliente.token:
            try:
                cliente.logout()
            except BancadaIndisponivel:
                pass


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    base = os.environ.get('HEISUCA_TESTE_SERVIDOR', '').strip()
    contas = [c.strip() for c in os.environ.get('HEISUCA_TESTE_CONTAS', '').splitlines() if c.strip()]
    protegidos = contas + [CONTA]

    def limpo(valor):
        return limpar_log(valor, protegidos, base)

    achados, relatorio = [], {'semente': SEMENTE, 'eventos_pedidos': EVENTOS, 'pacote': APP_ID, 'estado': 'vermelho'}
    codigo = 1
    try:
        if not base.startswith(('https://', 'http://')) or CONTA.lower() not in [c.lower() for c in contas]:
            raise BancadaIndisponivel('Segredos ou a conta dedicada não foram disponibilizados ao job.')
        if adb('get-state').stdout.strip() != b'device':
            raise BancadaIndisponivel('Emulador não ficou pronto.')
        adb('install', '-r', str(APK), check=True)
        pacotes = texto('shell', 'pm', 'list', 'packages', 'heisuca')
        if f'package:{APP_ID}' not in pacotes.split():
            raise BancadaIndisponivel('O pacote esperado não ficou instalado.')
        adb('shell', 'pm', 'grant', APP_ID, 'android.permission.POST_NOTIFICATIONS')
        adb('shell', 'settings', 'put', 'secure', 'immersive_mode_confirmations', 'confirmed')
        adb('logcat', '-G', '16M')
        adb('logcat', '-c')
        abrir_app()
        pids = set(pid_do_app())
        if not entrar_pela_interface(base):
            raise RuntimeError('Login pela interface não chegou à tela inicial.')
        relatorio['login_pela_interface'] = True
        png = adb('exec-out', 'screencap', '-p').stdout
        (OUT / '01-inicio.png').write_bytes(png)

        pids.update(pid_do_app())
        saida = texto('shell', 'monkey', '-p', APP_ID, '-s', str(SEMENTE), '--throttle', '120', '--pct-syskeys', '0',
                      '--pct-appswitch', '0', '--pct-anyevent', '0', '-v', '-v', str(EVENTOS), tempo=1500)
        (OUT / 'monkey.log').write_text(limpo(saida)[-200000:])
        achados += analisar_monkey(saida)
        relatorio['eventos_injetados'] = eventos_injetados(saida)

        pids.update(pid_do_app())
        m, retomou = recuperar(achados, 'após o monkey')
        pids.update(pid_do_app())
        nos = dump()
        for t in texto_tecnico_na_ui(nos):
            achados.append((VERMELHO, 'texto-tecnico-na-ui', t))
        (OUT / '02-final.png').write_bytes(adb('exec-out', 'screencap', '-p').stdout)
        relatorio['marco_final'] = m
        if m is None:
            achados.append((ATENCAO, 'sem-marco', 'nem tela inicial nem login depois de relançar'))

        logcat = texto('logcat', '-d', '-v', 'threadtime', tempo=120)
        pids = pids_do_app(logcat, APP_ID, pids)
        achados += analisar_logcat(logcat, APP_ID, pids)
        (OUT / 'logcat-app.log').write_text(limpo(filtrar_pid(logcat, pids))[-1500000:])
        relatorio['pids_do_app'] = len(pids)

        # Sessão: sair pela interface (se o monkey não deixou deslogado) e conferir no servidor.
        if marco(dump()) == 'inicio' and not sair_pela_interface():
            achados.append((ATENCAO, 'sair-pela-ui', 'não consegui sair pela interface'))
        restantes = sessoes_restantes(base)
        relatorio['sessoes_do_app_restantes'] = restantes
        if restantes:
            achados.append((ATENCAO, 'sessao-aberta', f'{restantes} sessão(ões) do app seguem abertas no servidor'))
        relatorio['estado'] = classificar(achados, m, retomou)
        codigo = 1 if relatorio['estado'] == 'vermelho' else 0
    except BancadaIndisponivel as erro:
        relatorio.update({'estado': 'vermelho', 'motivo': str(erro)})
        codigo = 75
    except Exception as erro:
        detalhe = str(erro) if isinstance(erro, RuntimeError) else ''
        relatorio.update({'motivo': 'O percurso do desastrado não foi concluído.',
                          'erro': f'{type(erro).__name__}: {detalhe}'.rstrip(': ')})
        codigo = 1
    finally:
        adb('shell', 'am', 'force-stop', APP_ID)
        adb('shell', 'pm', 'clear', APP_ID)
        relatorio['achados'] = [{'gravidade': g, 'codigo': c, 'detalhe': limpo(d)} for g, c, d in achados]
        (OUT / 'relatorio.json').write_text(limpo(json.dumps(relatorio, ensure_ascii=False, indent=2)))
        print(f'Desastrado: {relatorio["estado"]}; {len(achados)} achado(s).')
        for g, c, d in achados:
            print(f'  [{g}] {c}: {limpo(d)}')
    return codigo


if __name__ == '__main__':
    sys.exit(main())
