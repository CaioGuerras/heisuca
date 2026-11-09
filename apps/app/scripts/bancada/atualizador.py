"""Bancada isolada do atualizador; nenhum servidor de produção é criado."""
import argparse
import hashlib
import http.server
import json
from pathlib import Path
import re
import ssl
import subprocess
import threading
import time
from urllib.parse import urlsplit
import xml.etree.ElementTree as ET

PACOTE = 'app.heisuca.player.teste.home'


def montar_feed(arquivo, build, certificado, origem):
    uri = urlsplit(origem)
    if uri.scheme != 'https' or uri.hostname not in ('10.0.2.2', '127.0.0.1', 'localhost') or uri.username:
        raise ValueError('O feed da bancada deve ser HTTPS e local.')
    if not re.fullmatch('[0-9a-fA-F]{64}', certificado) or build <= 0:
        raise ValueError('Metadados inválidos.')
    arquivo = Path(arquivo)
    with arquivo.open('rb') as entrada:
        resumo = hashlib.file_digest(entrada, 'sha256').hexdigest()
    return {'canal': 'estavel', 'versao': '2.0.34', 'build': build,
            'notas': 'Atualização sintética da bancada de TV.', 'assinatura_sha256': certificado.lower(),
            'apks': [{'abi': 'x86_64', 'url': origem.rstrip('/') + '/upgrade.apk',
                      'bytes': arquivo.stat().st_size, 'sha256': resumo}]}


def confirmar_build(dump, esperado):
    numero = re.search(r'\bversionCode=(\d+)\b', dump)
    assert numero and int(numero.group(1)) == esperado, 'Android não confirmou a versão instalada esperada.'


def achar_rotulo(xml, rotulo):
    for no in ET.fromstring(xml).iter('node'):
        dados = no.attrib
        if any(dados.get(campo, '').strip().casefold() == rotulo.casefold() for campo in ('text', 'content-desc')):
            return dados
    return None


def configuracoes_abertas(janelas):
    return re.search(r'(?im)^.*(?:mCurrentFocus|mFocusedApp)=.*settings', janelas) is not None


def instalador_aberto(janelas):
    return re.search(r'(?im)^.*(?:mCurrentFocus|mFocusedApp)=.*packageinstaller', janelas) is not None


def esperar_dispositivo(segundos=120):
    def pronto():
        try:
            return (adb('get-state').strip() == 'device' and
                    adb('shell', 'getprop', 'sys.boot_completed').strip() == '1' and
                    adb('shell', 'pm', 'path', 'android').strip().startswith('package:'))
        except (subprocess.SubprocessError, RuntimeError):
            return False
    return bool(aguardar(pronto, segundos))


def adb(*args):
    resultado = subprocess.run(['adb', *args], capture_output=True, timeout=120 if args[0] == 'install' else 30)
    if resultado.returncode:
        detalhe = (resultado.stderr or resultado.stdout).decode('utf8', 'replace').strip()[:400]
        raise RuntimeError('ADB falhou: ' + detalhe)
    return resultado.stdout.decode('utf8', 'replace')


def hierarquia():
    for destino in ('/dev/tty', '/dev/stdout'):
        try:
            resposta = adb('exec-out', 'uiautomator', 'dump', destino)
            inicio, fim = resposta.find('<?xml'), resposta.rfind('</hierarchy>')
            if inicio >= 0 and fim > inicio:
                return resposta[inicio:fim + len('</hierarchy>')]
        except (RuntimeError, subprocess.SubprocessError):
            pass
    # A bancada TV existente também precisa do arquivo em alguns emuladores.
    destino = '/sdcard/heisuca_atualizador_dump.xml'
    adb('shell', 'uiautomator', 'dump', destino)
    resposta = adb('exec-out', 'cat', destino)
    inicio, fim = resposta.find('<?xml'), resposta.rfind('</hierarchy>')
    if inicio >= 0 and fim > inicio:
        return resposta[inicio:fim + len('</hierarchy>')]
    raise ET.ParseError('Não foi possível ler a hierarquia da TV.')


def aguardar(condicao, segundos=60):
    limite = time.monotonic() + segundos
    while time.monotonic() < limite:
        try:
            resultado = condicao()
        except (ET.ParseError, RuntimeError, subprocess.SubprocessError):
            resultado = False
        if resultado:
            return resultado
        time.sleep(.5)
    raise AssertionError('Tempo esgotado na etapa da bancada do atualizador.')


def tecla(codigo):
    adb('shell', 'input', 'keyevent', str(codigo))
    time.sleep(.3)


def centro(dados):
    numeros = list(map(int, re.findall(r'\d+', dados.get('bounds', ''))))
    return ((numeros[0] + numeros[2]) // 2, (numeros[1] + numeros[3]) // 2) if len(numeros) == 4 else (0, 0)


def acionar(rotulos):
    """Chega ao alvo com D-pad e só confirma quando o foco estiver no rótulo certo."""
    for tentativa in range(24):
        xml = aguardar(hierarquia)
        alvo = next((no for r in rotulos if (no := achar_rotulo(xml, r)) is not None), None)
        nos = [n.attrib for n in ET.fromstring(xml).iter('node')]
        foco = next((n for n in nos if n.get('focused') == 'true' and centro(n) != (0, 0)), None)
        if alvo and alvo.get('focused') == 'true':
            tecla(23)
            return
        if alvo and foco:
            x, y = centro(alvo)
            fx, fy = centro(foco)
            tecla((22 if x > fx else 21) if abs(x-fx) > abs(y-fy) else (20 if y > fy else 19))
        else:
            tecla(20 if tentativa % 3 != 2 else 22)
    raise AssertionError('O D-pad não alcançou o botão: ' + '/'.join(rotulos))


def servidor(pasta, feed, certificado, chave):
    contador = {'downloads': 0}

    class Local(http.server.BaseHTTPRequestHandler):
        def log_message(self, *_):
            pass

        def do_GET(self):
            if self.path == '/estavel/latest.json':
                corpo = json.dumps(feed).encode()
                self.send_response(200)
                self.send_header('Content-Type', 'application/json')
                self.send_header('Content-Length', str(len(corpo)))
                self.end_headers()
                self.wfile.write(corpo)
            elif self.path == '/upgrade.apk':
                contador['downloads'] += 1
                lenta = contador['downloads'] == 1
                self.send_response(200)
                self.send_header('Content-Type', 'application/vnd.android.package-archive')
                self.send_header('Content-Length', str((pasta / 'upgrade.apk').stat().st_size))
                self.end_headers()
                try:
                    with (pasta / 'upgrade.apk').open('rb') as entrada:
                        while parte := entrada.read(64 * 1024 if lenta else 1024 * 1024):
                            self.wfile.write(parte)
                            if lenta:
                                time.sleep(.1)
                except (BrokenPipeError, ConnectionResetError, ssl.SSLError):
                    pass  # Cancelamento esperado no primeiro percurso.
            else:
                self.send_error(404)

    httpd = http.server.ThreadingHTTPServer(('127.0.0.1', 8443), Local)
    contexto = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    contexto.load_cert_chain(certificado, chave)
    httpd.socket = contexto.wrap_socket(httpd.socket, server_side=True)
    threading.Thread(target=httpd.serve_forever, daemon=True).start()
    return httpd


def executar(args):
    pasta = Path(args.pasta).resolve()
    evidencias = pasta / 'evidencias'
    evidencias.mkdir(parents=True, exist_ok=True)
    feed = montar_feed(pasta / 'upgrade.apk', args.build + 1, args.assinatura, 'https://10.0.2.2:8443')
    local = servidor(pasta, feed, pasta / 'localhost.crt', pasta / 'localhost.key')
    etapas = []

    def registrar(nome):
        etapas.append(nome)
        (evidencias / (str(len(etapas)) + '.xml')).write_text(hierarquia())
        captura = subprocess.run(['adb', 'exec-out', 'screencap', '-p'], check=True, capture_output=True, timeout=15)
        (evidencias / (str(len(etapas)) + '.png')).write_bytes(captura.stdout)

    try:
        esperar_dispositivo()
        adb('install', '-r', str(pasta / 'base.apk'))
        adb('shell', 'appops', 'set', PACOTE, 'REQUEST_INSTALL_PACKAGES', 'deny')
        adb('shell', 'am', 'start', '-W', '-n', PACOTE + '/app.heisuca.MainActivity')
        aguardar(lambda: achar_rotulo(hierarquia(), 'Baixar'), 90)
        confirmar_build(adb('shell', 'dumpsys', 'package', PACOTE), args.build)
        registrar('Versão nova anunciada pelo feed HTTPS local')
        acionar(['Baixar'])
        aguardar(lambda: achar_rotulo(hierarquia(), 'Cancelar'))
        acionar(['Cancelar'])
        aguardar(lambda: achar_rotulo(hierarquia(), 'Baixar'))
        restos = adb('shell', 'run-as', PACOTE, 'ls', '-A', 'cache/updates').strip()
        assert not restos, 'Cancelamento deixou arquivo no cache do atualizador.'
        registrar('Download cancelado por D-pad; cache vazio')
        acionar(['Baixar'])
        aguardar(lambda: achar_rotulo(hierarquia(), 'Instalar'), 180)
        registrar('Download íntegro e certificado conferido; instalar continua explícito')
        acionar(['Instalar'])
        # Pode abrir a tela do sistema ou explicar o caminho manual, como pede a spec.
        aguardar(lambda: configuracoes_abertas(adb('shell', 'dumpsys', 'window')) or
                 'Nas configurações do aparelho' in hierarquia(), 45)
        confirmar_build(adb('shell', 'dumpsys', 'package', PACOTE), args.build)
        registrar('Permissão negada não instala nem altera a versão')
        if configuracoes_abertas(adb('shell', 'dumpsys', 'window')):
            tecla(4)
        adb('shell', 'appops', 'set', PACOTE, 'REQUEST_INSTALL_PACKAGES', 'allow')
        aguardar(lambda: achar_rotulo(hierarquia(), 'Instalar'))
        acionar(['Instalar'])
        aguardar(lambda: instalador_aberto(adb('shell', 'dumpsys', 'window')), 60)
        aguardar(lambda: any(achar_rotulo(hierarquia(), r) for r in ['Install', 'Instalar', 'Update', 'Atualizar']), 60)
        acionar(['Install', 'Instalar', 'Update', 'Atualizar'])
        def nova_instalada():
            try:
                confirmar_build(adb('shell', 'dumpsys', 'package', PACOTE), args.build + 1)
                return True
            except AssertionError:
                return False
        aguardar(nova_instalada, 120)
        etapas.append('Android confirmou o build novo; reabertura não exigida')
        (evidencias / 'relatorio.json').write_text(json.dumps({'estado': 'verde', 'etapas': etapas,
            'build_anterior': args.build, 'build_instalado': args.build + 1, 'reabertura_exigida': False}, ensure_ascii=False, indent=2))
    except Exception as erro:
        # Ambiente sintético sem conta/acervo: preservar a causa, inclusive app que não abriu.
        for nome, comando in [('janelas.txt', ['shell', 'dumpsys', 'window']),
                              ('atividade.txt', ['shell', 'dumpsys', 'activity', 'activities']),
                              ('flutter.txt', ['logcat', '-d', '-s', 'flutter:E', 'AndroidRuntime:E'])]:
            try:
                (evidencias / nome).write_text(adb(*comando)[-100000:])
            except (RuntimeError, subprocess.SubprocessError):
                pass
        (evidencias / 'relatorio.json').write_text(json.dumps({'estado': 'vermelho', 'etapas': etapas,
            'falha': type(erro).__name__ + ': ' + str(erro)}, ensure_ascii=False, indent=2))
        raise
    finally:
        local.shutdown()
        local.server_close()


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--pasta', required=True)
    parser.add_argument('--build', type=int, required=True)
    parser.add_argument('--assinatura', required=True)
    executar(parser.parse_args())
