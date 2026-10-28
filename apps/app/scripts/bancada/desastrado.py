#!/usr/bin/env python3
"""Usuário desastrado: caixa-preta por adb. Login pela interface, monkey restrito ao pacote, detectores sobre os textos.

Só usa a conta `teste-sem-senha` (senha vazia). A etapa de senha errada usa usuários INEXISTENTES gerados: nunca conta real. Nada de credencial em log ou artifact:
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
from desastre import (VERMELHO, ATENCAO, analisar_logcat, analisar_monkey, classificar, eventos_injetados,
                      filtrar_pid, listar_visivel, marco, pids_do_app, texto_tecnico_na_ui)
from servidor import BancadaIndisponivel, Servidor, limpar_log
from ui import (CONTA, abrir_app, dump, esperar_launcher, ligar_achados, entrar_pela_interface, pid_do_app, recuperar, sair_pela_interface, texto)
import caos

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / '.bancada/desastrado'
SEMENTE = 20261028
EVENTOS = 5000
APK = ROOT / 'build/app/outputs/flutter-apk/app-debug.apk'


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
    passos, t0 = [], time.monotonic()
    relatorio['login_passos'] = passos
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
        # Diálogos de erro do sistema cobrem o app no emulador lento (run 40700645544: ANR do launcher). Nossos ANRs
        # seguem no logcat. Restaurado no finally.
        ligar_achados(achados)
        adb('shell', 'settings', 'put', 'global', 'hide_error_dialogs', '1')
        esperar_launcher(60)
        adb('logcat', '-G', '16M')
        adb('logcat', '-c')
        abrir_app()
        pids = set(pid_do_app())
        def registrar(nome, nos):
            passos.append({'passo': nome, 'segundos': round(time.monotonic() - t0), 'visivel': listar_visivel(nos, base, protegidos)})

        if not entrar_pela_interface(base, registrar):
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

        # Roteiro de caos (P6-2): etapas independentes; cada uma recupera, confere marco e roda os detectores.
        adb('logcat', '-c')
        ctx = caos.Ctx(base, achados, limpo, OUT, pids)
        try:
            relatorio['etapas'] = caos.roteiro(ctx)
        finally:
            (OUT / 'logcat-caos.log').write_text(limpo('\n'.join(ctx.logcat_total))[-1500000:])
            pids = ctx.pids
        m, retomou = recuperar(achados, 'depois do caos')
        relatorio['marco_final'] = m
        if m is None:
            achados.append((ATENCAO, 'sem-marco-final', 'nem tela inicial nem login depois do caos'))

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
        adb('shell', 'settings', 'put', 'global', 'hide_error_dialogs', '0')
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
