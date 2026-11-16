"""Provas locais de MediaSession/PiP; nenhum comando de servidor."""
import base64
import json
import shlex
import re
import time
from pathlib import Path
import xml.etree.ElementTree as ET


def analisar_sessao(texto, pacote, titulo, *, estado=3, proximo=False):
    """Exige um registro real do app, não apenas o nome citado no dump."""
    linhas = list(re.finditer(r'(?m)^\s*(?:package|packageName)=' + re.escape(pacote) + r'\s*$', texto))
    if len(linhas) != 1:
        raise RuntimeError('A prova exige exatamente uma sessão do app.')
    inicio = linhas[0].start()
    fim = re.search(r'(?m)^\s*(?:package|packageName)=', texto[linhas[0].end():])
    trecho = texto[inicio:linhas[0].end() + fim.start()] if fim else texto[inicio:]
    estado_lido = re.search(r'PlaybackState\s*\{\s*state=(?:(\d+)|[A-Z_]+\((\d+)\)),.*?position=(-?\d+).*?actions=(\d+)', trecho, re.S)
    if not estado_lido or titulo not in trecho:
        raise RuntimeError('Sessão não contém estado, posição, ações e título esperados.')
    numero, nomeado, posicao, acoes = estado_lido.groups()
    atual, posicao, acoes = int(numero or nomeado), int(posicao), int(acoes)
    obrigatorias = {3: 2, 2: 4}.get(estado, 0) | 512 | 256 | (32 if proximo else 0)
    if estado not in (2, 3) or atual != estado or posicao <= 0 or acoes & obrigatorias != obrigatorias:
        faltantes = obrigatorias & ~acoes
        nomes = ', '.join(f'{nome}=0x{bit:x}' for bit, nome in
                          [(4, 'tocar'), (2, 'pausar'), (512, 'tocar/pausar'), (256, 'buscar'), (32, 'próximo')]
                          if faltantes & bit) or 'nenhum'
        raise RuntimeError(
            f'Estado, posição ou ações da sessão não correspondem ao vídeo: '
            f'estado lido={atual} esperado={estado}; posição={posicao} ms (esperado > 0); '
            f'ações=0x{acoes:x} obrigatórias=0x{obrigatorias:x} faltantes=0x{faltantes:x} ({nomes}).')
    return {'sessoes': 1, 'estado': atual, 'posicao_ms': posicao, 'acoes': acoes, 'tituloConferido': True}


def encontrar_acao_pip(xml, rotulo):
    for no in ET.fromstring(xml).iter('node'):
        if rotulo not in (no.get('text', ''), no.get('content-desc', '')) or no.get('enabled') != 'true':
            continue
        valores = re.fullmatch(r'\[(\d+),(\d+)\]\[(\d+),(\d+)\]', no.get('bounds', ''))
        if valores:
            x1, y1, x2, y2 = map(int, valores.groups())
            if x2 > x1 and y2 > y1:
                return (x1+x2)//2, (y1+y2)//2
    raise RuntimeError('Botão PiP visível e habilitado não encontrado: ' + rotulo)


class ProvasSessao:
    def __init__(self, pasta, adb, pacote, sanitizar):
        self.pasta, self.adb, self.pacote, self.sanitizar = Path(pasta), adb, pacote, sanitizar
        self.ultimo = 0
        self.provas = []
        self.leitor_enviado = False
        self.chamadas_pip = 0
        self.ultimo_xml_pip = ''

    def _privado(self, arquivo):
        return self.adb('exec-out', 'run-as', self.pacote, 'cat', 'files/' + arquivo)

    def _helper(self, modo, *argumentos):
        remoto = '/data/local/tmp/heisuca-bancada-ui.jar'
        if not self.leitor_enviado:
            helper = Path(__file__).resolve().parents[2] / '.bancada/ui.jar'
            if not helper.is_file():
                raise RuntimeError('Leitor de janelas vazio: ferramenta nativa não compilada.')
            self.adb('push', str(helper), remoto, check=True)
            self.leitor_enviado = True
        return self.adb('shell', 'CLASSPATH=' + remoto, 'app_process', '/system/bin',
                        'HeisucaPipClose', modo, *argumentos, capture_errors=True)

    def _ler_hierarquia(self, resultado):
        texto = resultado.stdout.decode(errors='replace')
        hierarquia = re.search(r'<hierarchy\b[^>]*(?:/>|>.*?</hierarchy>)', texto, re.S)
        xml = hierarquia.group() if hierarquia else ''
        self.ultimo_xml_pip = xml
        try:
            tem_nos = bool(xml) and any(True for _ in ET.fromstring(xml).iter('node'))
        except ET.ParseError:
            tem_nos = False
        if resultado.returncode != 0 or not tem_nos:
            raise RuntimeError('Leitor de janelas vazio: ' + self.sanitizar(texto).strip())
        return xml

    def _xml(self):
        return self._ler_hierarquia(self._helper('--dump'))

    def _acao_pip(self, rotulo):
        if rotulo not in ('Tocar', 'Pausar', 'Voltar 10 segundos', 'Avançar 10 segundos', 'Próximo'):
            raise RuntimeError('Rótulo PiP inválido.')
        self.chamadas_pip += 1
        self.ultimo_xml_pip = ''
        inicio = time.monotonic()
        resultado = None
        try:
            # Uma conexão, um prazo total de oito segundos, no máximo uma abertura.
            resultado = self._helper('--pip-botao', shlex.quote(rotulo))
        finally:
            texto = resultado.stdout.decode(errors='replace') if resultado is not None else 'Leitor não executou.'
            (self.pasta / f'pip-botao-{self.chamadas_pip}.txt').write_text(self.sanitizar(texto))
            (self.pasta / f'pip-botao-{self.chamadas_pip}-host.json').write_text(json.dumps({
                'duracao_ms': round((time.monotonic() - inicio) * 1000, 3),
                'codigo': resultado.returncode if resultado is not None else None,
            }, ensure_ascii=False))
        xml = self._ler_hierarquia(resultado)
        centro = re.search(r'BANCADA_BOTAO: x=(\d+) y=(\d+)', texto)
        if centro is None:
            if 'BANCADA_BOTAO_AUSENTE: prazo_ms=8000' not in texto:
                raise RuntimeError('Leitor de janelas vazio: resposta sem resultado do botão. ' + self.sanitizar(texto))
            raise RuntimeError('Botão PiP não apareceu em 8 segundos: ' + rotulo)
        try:
            x, y = encontrar_acao_pip(xml, rotulo)
        except RuntimeError:
            raise RuntimeError('Leitor de janelas vazio: centro sem rótulo habilitado no XML. ' + self.sanitizar(texto)) from None
        if (x, y) != tuple(map(int, centro.groups())):
            raise RuntimeError('Leitor de janelas vazio: centro diverge do XML. ' + self.sanitizar(texto))
        return x, y, xml

    def _sessao_convergida(self, nome, dados):
        limite = time.monotonic() + 8
        tentativa = 0
        while True:
            tentativa += 1
            dump = self.adb('shell', 'dumpsys', 'media_session', check=True).stdout.decode(errors='replace')
            sufixo = '' if tentativa == 1 else '-' + str(tentativa)
            # Preservar inclusive o dump que reprovar: um erro do parser não
            # pode apagar a evidência real nem ser confundido com falha do motor.
            (self.pasta / (nome + '-media-session' + sufixo + '.txt')).write_text(self.sanitizar(dump))
            try:
                return analisar_sessao(dump, self.pacote, dados['titulo'],
                    estado=dados.get('estado', 3), proximo=dados.get('proximo', False))
            except RuntimeError as erro:
                if time.monotonic() >= limite:
                    raise RuntimeError('Sessão não convergiu em 8 segundos: ' + str(erro)) from None
                time.sleep(0.2)

    def poll(self):
        evento = self._privado('heisuca-sessao-event.json')
        try:
            dados = json.loads(evento.stdout)
        except (ValueError, UnicodeDecodeError):
            return
        seq = dados.get('seq')
        if type(seq) is not int or seq < 1:
            raise RuntimeError('Sequência de prova deve ser um inteiro positivo.')
        if seq <= self.ultimo:
            return
        nome = dados['nome']
        if not re.fullmatch(r'(mpv|exoplayer)-[a-z0-9-]+', nome):
            raise RuntimeError('Nome de prova inválido.')
        acao = dados['acao']
        resposta = {'seq': seq, 'ok': True}
        if acao == 'sessao':
            prova = self._sessao_convergida(nome, dados)
            resposta['sessao'] = prova
        elif acao == 'encerrada':
            limite = time.monotonic() + 8
            while True:
                dump = self.adb('shell', 'dumpsys', 'media_session', check=True).stdout.decode(errors='replace')
                servicos = self.adb('shell', 'dumpsys', 'activity', 'services', self.pacote, check=True).stdout.decode(errors='replace')
                tem_sessao = re.search(r'(?m)^\s*(?:package|packageName)=' + re.escape(self.pacote) + r'\s*$', dump)
                if not tem_sessao and 'isForeground=true' not in servicos:
                    break
                if time.monotonic() >= limite:
                    raise RuntimeError('Sessão ou serviço foreground ficou preso depois de parar.')
                time.sleep(0.2)
            resposta['sessaoEncerrada'] = True
        elif acao in ('pause', 'play'):
            self.adb('shell', 'cmd', 'media_session', 'dispatch', acao, check=True)
        elif acao == 'pip-botao':
            rotulo = dados['rotulo']
            try:
                x, y, xml = self._acao_pip(rotulo)
            except RuntimeError:
                # A prova segue reprovada; preservar o estado real sem tocar ou repetir a ação.
                (self.pasta / (nome + '-falha.png')).write_bytes(
                    self.adb('exec-out', 'screencap', '-p', check=True).stdout)
                (self.pasta / (nome + '-falha.xml')).write_text(self.sanitizar(
                    self.ultimo_xml_pip or '<!-- Leitor sem XML; veja pip-botao-N.txt. -->'))
                for sufixo, argumentos in [('atividades', ('activity', 'activities')),
                                           ('sessao', ('media_session',))]:
                    texto = self.adb('shell', 'dumpsys', *argumentos, check=True).stdout.decode(errors='replace')
                    (self.pasta / (nome + '-falha-' + sufixo + '.txt')).write_text(self.sanitizar(texto))
                raise
            (self.pasta / (nome + '-menu.png')).write_bytes(self.adb('exec-out', 'screencap', '-p', check=True).stdout)
            (self.pasta / (nome + '-menu.xml')).write_text(self.sanitizar(xml))
            self.adb('shell', 'input', 'tap', str(x), str(y), check=True)
            resposta['botao'] = rotulo
        elif acao == 'restaurar':
            self.adb('shell', 'am', 'start', '-n', self.pacote + '/app.heisuca.MainActivity', check=True)
        elif acao != 'captura':
            raise RuntimeError('Ação de prova desconhecida.')
        if acao == 'captura':
            png = self.adb('exec-out', 'screencap', '-p', check=True).stdout
            if not png.startswith(b'\x89PNG\r\n\x1a\n') or len(png) < 1000:
                raise RuntimeError('Captura de prova inválida.')
            (self.pasta / (nome + '.png')).write_bytes(png)
        self.provas.append({'nome': nome, 'acao': acao, **resposta})
        (self.pasta / 'sessao-provas-host.json').write_text(json.dumps(self.provas, ensure_ascii=False, indent=2))
        encoded = base64.b64encode(json.dumps(resposta).encode()).decode()
        self.adb('shell', f"run-as {self.pacote} sh -c 'echo {encoded} | base64 -d > files/heisuca-sessao-ack.tmp'", check=True)
        self.adb('exec-out', 'run-as', self.pacote, 'mv', 'files/heisuca-sessao-ack.tmp', 'files/heisuca-sessao-ack.json', check=True)
        self.ultimo = seq

    def verificar(self, relatorio):
        if not relatorio.get('concluido') or set(relatorio.get('motores', {})) != {'mpv', 'exoplayer'}:
            raise RuntimeError('Falta prova completa dos dois motores e do HUD.')
        for motor, prova in relatorio['motores'].items():
            for faixa in ['sem-faixas', 'desfoque', 'degrade']:
                medicao = prova['tempos'][faixa]
                if medicao['quadros'] < 30 or medicao['total_ms']['mediana'] <= 0:
                    raise RuntimeError('FrameTiming não mediu quadros suficientes.')
                if not (self.pasta / (motor + '-hud-' + faixa + '.png')).is_file():
                    raise RuntimeError('Falta captura do HUD: ' + motor + '/' + faixa)
            for chave in ['pausaSistema', 'pipPausa', 'pipToca', 'pipVolta10', 'pipAvanca10', 'sessaoUnica', 'sessaoEncerrada']:
                if prova.get(chave) is not True:
                    raise RuntimeError('Falta resposta real da sessão/PiP: ' + motor + '/' + chave)
            if prova.get('pipMaxAcoes', 0) >= 4 and prova.get('pipProximo') is not True:
                raise RuntimeError('Próximo do PiP não foi comprovado apesar do limite disponível.')
        (self.pasta / 'sessao-hud-tempos.json').write_text(json.dumps(relatorio, ensure_ascii=False, indent=2))
