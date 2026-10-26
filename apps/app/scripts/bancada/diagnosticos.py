"""Evidência do Android antes de parar o app; nenhuma classificação automática de infra."""
import json
import re
from servidor import limpar_log
from capturas import APP_ID

PACKAGE = re.escape(APP_ID) + r'(?![\w.])'
ANR = re.compile(r'\bANR in ' + PACKAGE + r'|\bam_anr\b.*' + PACKAGE, re.IGNORECASE)


def contexto_eventos(log):
    lines = log.splitlines()
    selected = set()
    for index, line in enumerate(lines):
        if ANR.search(line):
            selected.update(range(index, min(index + 100, len(lines))))
    return '\n'.join(lines[i] for i in sorted(selected))


def coletar(output, adb, protected, base):
    """Só grava texto após redação. Falta de diagnóstico não vira aprovação."""
    report = {'disponivel': False, 'anrDoApp': False}
    try:
        last = adb('shell', 'dumpsys', 'activity', 'lastanr')
        events = adb('logcat', '-d', '-b', 'events', '-b', 'system', '-v', 'threadtime')
        last_text = last.stdout.decode(errors='replace')
        event_text = contexto_eventos(events.stdout.decode(errors='replace'))
        own_last = bool(ANR.search(last_text))
        report.update({'disponivel': last.returncode == 0 and events.returncode == 0 and bool(last_text.strip()),
                       'anrDoApp': own_last or bool(event_text),
                       'dumpsysCodigo': last.returncode, 'logcatCodigo': events.returncode})
        selected = (last_text if own_last else 'Nenhum ANR deste app no lastanr.\n')
        selected += '\nEventos/system_server do ANR deste app:\n' + (event_text or 'Nenhum encontrado.\n')
        safe = limpar_log(selected, protected, base)[:64000]
        (output / 'android-anr.log').write_text(safe)
        (output / 'android-diagnostico.json').write_text(json.dumps(report, ensure_ascii=False, indent=2))
        print('Diagnóstico Android: ' + json.dumps(report, ensure_ascii=False))
        if report['anrDoApp']:
            print('ANR registrado pelo Android (já redigido):')
            print('\n'.join(safe.splitlines()[:100]))
    except Exception:
        # Uma coleta que falha não deve impedir logout/restauração.
        report['disponivel'] = False
        print('Diagnóstico Android indisponível; a limpeza continua e a bancada não fica verde.')
    return report
