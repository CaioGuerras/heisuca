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


def processo_proprio(trace):
    """Mantém só blocos do processo do app, sem atribuir stacks de outros apps."""
    blocks = re.split(r'(?m)(?=^----- pid [0-9]+ )', trace)
    return '\n'.join(block for block in blocks if re.search(r'(?m)^Cmd line: ' + PACKAGE, block))


def coletar_traces(output, adb, protected, base):
    listing = adb('shell', 'ls', '-1t', '/data/anr')
    count = 0
    main = False
    if listing.returncode:
        return {'tracesDoApp': 0, 'mainColetada': False}
    filenames = [name for name in listing.stdout.decode(errors='replace').splitlines()
                 if re.fullmatch(r'anr_[0-9TZa-z_.:-]+', name)][:3]
    for filename in filenames:
        result = adb('exec-out', 'cat', '/data/anr/' + filename)
        if result.returncode:
            break
        own = processo_proprio(result.stdout.decode(errors='replace'))
        if not own:
            continue
        safe = limpar_log(own, protected, base)[:300000]
        count += 1
        (output / f'android-trace-app-{count}.log').write_text(safe)
        main_trace = re.search(r'(?ms)^"main".*?(?=\n"|\Z)', safe)
        if main_trace:
            main = True
            print('Thread main no trace do Android (já redigido):')
            print(main_trace.group(0)[:12000])
    return {'tracesDoApp': count, 'mainColetada': main}


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
        selected = 'dumpsys activity lastanr (texto do Android):\n' + last_text
        selected += '\nEventos/system_server do ANR deste app:\n' + (event_text or 'Nenhum encontrado.\n')
        safe = limpar_log(selected, protected, base)[:64000]
        (output / 'android-anr.log').write_text(safe)
        if report['anrDoApp']:
            report.update(coletar_traces(output, adb, protected, base))
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
