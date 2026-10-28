"""Ajudas puras do usuário desastrado (caixa-preta por adb): parser do uiautomator e detectores de texto.

Nada aqui fala com o emulador: tudo recebe texto e devolve achados, para ser testado sem aparelho.
Achado = (gravidade, código, detalhe curto). Gravidades: 'vermelho' ou 'atenção'.
"""
import re
import time
import uuid
import xml.etree.ElementTree as ET
from urllib.parse import urlsplit

from servidor import limpar_log

VERMELHO = 'vermelho'
ATENCAO = 'atenção'

# Mesmos arquivos da exceção do HUD do PiP em integration_test/support/pip_overflow_policy.dart.
# Aqui não há como saber a fase nem a largura da janela, então o overflow continua vermelho; a origem só é anotada.
ORIGEM_PIP = re.compile(r'video_controls_header\.dart:59:12|mobile_video_controls\.dart:(?:387:16|237:14)')

TEXTO_TECNICO = re.compile(
    r"\b[A-Z][A-Za-z]*Exception\b|\bException:|Failed host lookup|\bTypeError\b|\bNull check operator|type 'Null'|"
    r"Connection (?:refused|closed|reset)|\btimed out\b|Network is unreachable|No address associated|"
    r"HandshakeException|\bUnable to\b|\bFailed to\b|\bClientException\b|"
    r"\bNoSuchMethodError\b|\bStateError\b|\bRangeError\b|\bnull\b|\bError:|\bStack ?trace\b")


# ---------- uiautomator ----------

def _limites(valor):
    m = re.fullmatch(r'\[(-?\d+),(-?\d+)\]\[(-?\d+),(-?\d+)\]', valor or '')
    return tuple(int(x) for x in m.groups()) if m else None


def parse_uiautomator(xml_text):
    """Lista de nós com texto, descrição, dica, classe, limites e centro. XML inválido devolve []."""
    try:
        raiz = ET.fromstring(xml_text.strip())
    except ET.ParseError:
        return []
    nos = []
    for el in raiz.iter('node'):
        b = _limites(el.get('bounds'))
        nos.append({
            'text': el.get('text') or '', 'desc': el.get('content-desc') or '', 'hint': el.get('hint') or '',
            'cls': el.get('class') or '', 'pkg': el.get('package') or '', 'bounds': b,
            'clickable': el.get('clickable') == 'true', 'enabled': el.get('enabled') != 'false',
            'focused': el.get('focused') == 'true',
            'centro': ((b[0] + b[2]) // 2, (b[1] + b[3]) // 2) if b and b[2] > b[0] and b[3] > b[1] else None,
        })
    return nos


def _rotulos(no):
    return [v for v in (no['text'], no['desc'], no['hint']) if v]


def achar_texto(nos, *textos, exato=True):
    """Primeiro nó com algum dos textos (texto, descrição ou dica), com centro tocável."""
    alvos = [t.lower() for t in textos]
    for no in nos:
        if not no['centro']:
            continue
        for rotulo in _rotulos(no):
            r = rotulo.strip().lower()
            if any(r == a if exato else a in r for a in alvos):
                return no
    return None


def campo_abaixo_do_rotulo(nos, rotulo):
    """EditText imediatamente abaixo do rótulo (ex.: 'USUÁRIO'), pela posição e não pela ordem.

    O uiautomator não expõe a dica dos campos do Flutter, e linhas novas (ex.: versão do servidor) deslocam tudo:
    a única âncora estável é o rótulo em maiúsculas logo acima do campo.
    """
    alvo = rotulo.strip().lower()
    rotulos = [n for n in nos if n['centro'] and not n['cls'].endswith('EditText')
               and any(r.strip().lower() == alvo for r in _rotulos(n))]
    editores = [n for n in nos if n['cls'].endswith('EditText') and n['centro']]
    melhor = None
    for r in rotulos:
        base = r['bounds'][3]
        abaixo = [e for e in editores if e['bounds'][1] >= base - 8
                  and e['bounds'][0] < r['bounds'][2] + 400 and e['bounds'][2] > r['bounds'][0]]
        if abaixo:
            e = min(abaixo, key=lambda n: n['bounds'][1])
            if melhor is None or e['bounds'][1] < melhor['bounds'][1]:
                melhor = e
    return melhor


def tamanho_do_campo(nos, rotulo):
    """Quantidade de caracteres no campo sob o rótulo (None se o campo não existe)."""
    campo = campo_abaixo_do_rotulo(nos, rotulo)
    return None if campo is None else len(campo['text'])


def foco_no_campo(nos, campo):
    """True se [campo] tem o foco; False se outro EditText tem; None se o aparelho não informa foco nenhum."""
    editores = [n for n in nos if n['cls'].endswith('EditText')]
    if not any(e['focused'] for e in editores):
        return None
    return any(e['focused'] and e['bounds'] == campo['bounds'] for e in editores)


def campos_login(nos):
    """Servidor, usuário, senha e botão da tela de login, achados pelos rótulos SERVIDOR, USUÁRIO e SENHA.

    Sem rótulos (outra versão da tela), cai na dica e, por último, na ordem dos EditText.
    """
    editores = [n for n in nos if n['cls'].endswith('EditText') and n['centro']]
    achados = {
        'servidor': campo_abaixo_do_rotulo(nos, 'SERVIDOR'),
        'usuario': campo_abaixo_do_rotulo(nos, 'USUÁRIO'),
        'senha': campo_abaixo_do_rotulo(nos, 'SENHA'),
    }
    if achados['servidor'] is None:
        achados['servidor'] = achar_texto(editores, 'https://seu.servidor.com', 'https://seuservidor.com', exato=False)
    if achados['usuario'] is None:
        achados['usuario'] = achar_texto(editores, 'Nome de usuário', exato=False)
    restantes = [n for n in editores if n not in achados.values()]
    for chave in ('servidor', 'usuario', 'senha'):
        if achados[chave] is None and restantes and len(editores) >= 3:
            achados[chave] = restantes.pop(0)
    achados['botao'] = achar_texto(nos, 'Iniciar sessão')
    return achados


def marco(nos):
    """'inicio' (barra de abas), 'login' ou None."""
    rotulos = {r.strip().lower() for n in nos for r in _rotulos(n)}
    if {'início', 'biblioteca'} <= rotulos and ({'você', 'baixados'} & rotulos):
        return 'inicio'
    if 'iniciar sessão' in rotulos and any(n['cls'].endswith('EditText') for n in nos):
        return 'login'
    return None


def assinatura_tela(nos):
    """Impressão da tela para comparar dois dumps: classe, texto e limites, sem relógio nem animação de contagem."""
    return tuple((n['cls'], n['text'], n['desc'], n['bounds']) for n in nos)


def tela_presa(dumps):
    """True se os dumps (já lidos) são todos iguais e há pelo menos dois."""
    return len(dumps) >= 2 and all(d and d == dumps[0] for d in dumps)


def texto_tecnico_na_ui(nos):
    """Textos em inglês técnico visíveis ao usuário (Exception, SocketException, Failed host lookup, null, Error:)."""
    saida = []
    for n in nos:
        for r in _rotulos(n):
            if len(r) <= 400 and TEXTO_TECNICO.search(r):
                saida.append(r[:120])
    return saida


# ---------- monkey ----------

def analisar_monkey(texto):
    achados = []
    for m in re.finditer(r'^// (CRASH|NOT RESPONDING)\b[^\n]*', texto, re.M):
        achados.append((VERMELHO, 'monkey-' + ('crash' if m.group(1) == 'CRASH' else 'anr'), m.group(0)[:160]))
    if re.search(r'\*\* Monkey aborted due to error', texto):
        achados.append((VERMELHO, 'monkey-abortado', 'Monkey abortou por erro'))
    return achados


def eventos_injetados(texto):
    m = re.search(r'Events injected:\s*(\d+)', texto)
    return int(m.group(1)) if m else None


# ---------- logcat (-v threadtime) ----------

LINHA = re.compile(r'^\s*\d\d-\d\d\s+\d\d:\d\d:\d\d\.\d+\s+(\d+)\s+(\d+)\s+([VDIWEFA])\s+(\S+?)\s*:\s?(.*)$')


def pids_do_app(texto, pacote, conhecidos=()):
    """Todos os pids que o app teve: os já vistos por pidof, 'Start proc N:pacote' e 'Process: pacote, PID: N'."""
    pids = {int(p) for p in conhecidos}
    p = re.escape(pacote)
    for m in re.finditer(r'Start proc (\d+):' + p + r'(?![\w.])', texto):
        pids.add(int(m.group(1)))
    for m in re.finditer(r'Process: ' + p + r'(?![\w.]),\s*PID:\s*(\d+)', texto):
        pids.add(int(m.group(1)))
    return pids


def filtrar_pid(texto, pids):
    pids = {int(p) for p in pids}
    saida = []
    for linha in texto.splitlines():
        m = LINHA.match(linha)
        if m and int(m.group(1)) in pids:
            saida.append(linha)
    return '\n'.join(saida)


def analisar_logcat(texto, pacote, pids):
    """Achados vermelhos de um logcat completo (threadtime)."""
    achados = []
    p = re.escape(pacote)
    pids = {int(x) for x in pids}
    linhas = texto.splitlines()
    for i, linha in enumerate(linhas):
        m = LINHA.match(linha)
        pid = int(m.group(1)) if m else None
        msg = m.group(5) if m else linha
        tag = m.group(4) if m else ''
        if 'FATAL EXCEPTION' in msg:
            contexto = '\n'.join(linhas[i:i + 6])
            if (pid in pids) or re.search(r'Process: ' + p + r'(?![\w.])', contexto):
                achados.append((VERMELHO, 'fatal-exception', msg[:160]))
        elif re.search(r'\bANR in ' + p + r'(?![\w.])', msg):
            achados.append((VERMELHO, 'anr', msg[:160]))
        elif tag == 'flutter' and pid in pids and m.group(3) == 'E' and 'Unhandled Exception' in msg:
            achados.append((VERMELHO, 'flutter-unhandled', msg[:160]))
        elif pid in pids and 'A RenderFlex overflowed by' in msg:
            contexto = '\n'.join(linhas[i:i + 40])
            origem = 'origem do HUD do PiP' if ORIGEM_PIP.search(contexto) else 'origem desconhecida'
            achados.append((VERMELHO, 'renderflex-overflow', f'{msg[:110]} ({origem})'))
    return achados


# ---------- primeiro plano ----------

def app_em_primeiro_plano(dumpsys_activity, pacote):
    p = re.escape(pacote)
    for linha in dumpsys_activity.splitlines():
        if re.search(r'\b(?:topResumedActivity|mResumedActivity)\b', linha):
            return bool(re.search(r'\b' + p + r'/', linha))
    return False


def teclado_visivel(dumpsys_ime):
    return 'mInputShown=true' in dumpsys_ime


# ---------- classificação ----------

def classificar(achados, marco_final=None, retomou=True):
    """'vermelho' se houver achado vermelho ou o app não voltou; 'ATENÇÃO' sem nenhum marco; senão 'verde'."""
    if not retomou or any(g == VERMELHO for g, _, _ in achados):
        return 'vermelho'
    if achados or marco_final is None:
        return 'ATENÇÃO'
    return 'verde'


# ---------- caos (P6-2) ----------

PT_MENSAGEM = re.compile(
    r'sem conex|conexão|conexao|internet|offline|tente novamente|não foi possível|nao foi possivel|servidor|'
    r'indisponível|usuário ou senha|senha incorreta|incorret|inválid', re.I)
ABAS = ('início', 'biblioteca', 'baixados', 'você', 'favoritos')


def mensagem_pt(nos):
    """True se algum rótulo visível parece mensagem de erro/aviso em português."""
    return any(PT_MENSAGEM.search(r) for n in nos for r in _rotulos(n) if len(r) <= 300)


def nos_sem_rotulo(nos):
    """Nós clicáveis e visíveis sem texto nem descrição (leitor de tela não saberia dizer o que são).

    Devolve lista de (classe, limites). O nó 'pai' que só agrupa filhos rotulados não entra: se algum
    descendente por limites tem rótulo, o nó está coberto.
    """
    sem = []
    for n in nos:
        if not n['clickable'] or not n['centro'] or _rotulos(n):
            continue
        b = n['bounds']
        coberto = any(o is not n and o['bounds'] and _rotulos(o)
                      and o['bounds'][0] >= b[0] and o['bounds'][1] >= b[1]
                      and o['bounds'][2] <= b[2] and o['bounds'][3] <= b[3] for o in nos)
        if not coberto:
            sem.append((n['cls'].rsplit('.', 1)[-1], b))
    return sem


def escolher_cartao(nos, largura, altura):
    """Primeiro nó clicável com rótulo, no miolo da tela e que não seja aba nem botão de navegação."""
    for n in nos:
        if not (n['clickable'] and n['centro'] and _rotulos(n)):
            continue
        if n['text'].strip().lower() in ABAS or n['desc'].strip().lower() in ABAS:
            continue
        x, y = n['centro']
        if 0.15 * altura <= y <= 0.8 * altura and 0 < x < largura:
            return n
    return None


def botoes_de_toque(nos, largura, altura, limite=6):
    """Alvos para toque duplo/triplo: cartão, Play/Assistir e abas, no máximo [limite]."""
    alvos = []
    for rotulos in (('assistir', 'play', 'reproduzir'), ABAS):
        for n in nos:
            if n['clickable'] and n['centro'] and any(r.strip().lower() in rotulos for r in _rotulos(n)):
                alvos.append(n)
    cartao = escolher_cartao(nos, largura, altura)
    if cartao:
        alvos.insert(0, cartao)
    vistos, saida = set(), []
    for n in alvos:
        if n['centro'] not in vistos:
            vistos.add(n['centro'])
            saida.append(n)
    return saida[:limite]


def densidade_para_dp(largura_px, dp_menor=320):
    """Densidade (dpi) que deixa a menor largura em [dp_menor] dp: o 'tamanho de tela maior' do Android."""
    return max(120, int(round(largura_px * 160 / dp_menor)))


def tamanho_da_tela(saida_wm):
    """Último 'WxH' de `wm size` (o override vence o físico)."""
    achados = re.findall(r'(\d+)x(\d+)', saida_wm)
    return (int(achados[-1][0]), int(achados[-1][1])) if achados else None


def densidade_atual(saida_wm):
    achados = re.findall(r'density:\s*(\d+)', saida_wm)
    return int(achados[-1]) if achados else None


def usuario_inexistente(sufixo=None):
    return 'desastrado-' + (sufixo or uuid.uuid4().hex[:8])


def comandos_iptables(ips, inserir=True):
    """Comandos (sem 'adb shell') que bloqueiam/liberam a saída para [ips]; IPv6 usa ip6tables."""
    saida = []
    for ip in ips:
        ferramenta = 'ip6tables' if ':' in ip else 'iptables'
        saida.append([ferramenta, '-I' if inserir else '-D', 'OUTPUT', '-d', ip, '-j', 'REJECT'])
    return saida


def ips_do_host(url, resolver):
    """IPs do host da URL, resolvidos por [resolver(host) -> lista de IPs]; sem duplicar."""
    from urllib.parse import urlsplit
    host = urlsplit(url).hostname
    if not host:
        return []
    return sorted(set(resolver(host)))


class EtapaAmbiente(Exception):
    """A etapa não pôde rodar por causa do ambiente (sem root, sem pacote...): vira ATENÇÃO, não derruba as outras."""


def executar_etapa(nome, etapa, achados, restaurar=None, depois=None, prazo_ok=lambda: True, relogio=time.monotonic):
    """Roda uma etapa de caos de forma independente.

    [restaurar] roda SEMPRE (finally), mesmo se a etapa falhar. [depois] (recuperação, marco e detectores)
    roda depois da restauração e devolve achados. Nada propaga: exceção da etapa vira ATENÇÃO com o motivo.
    Devolve o registro da etapa: nome, início/fim em segundos, resultado e achados.
    """
    registro = {'nome': nome, 'inicio': round(relogio(), 1), 'resultado': 'ok', 'achados': []}
    mine = []
    if not prazo_ok():
        mine.append((ATENCAO, 'etapa-pulada', f'{nome}: prazo do job esgotado'))
        registro['resultado'] = 'pulada'
    else:
        try:
            try:
                etapa()
            except EtapaAmbiente as erro:
                registro['resultado'] = 'ambiente'
                mine.append((ATENCAO, 'etapa-ambiente', f'{nome}: {erro}'))
            except Exception as erro:  # noqa: BLE001 - uma etapa nunca derruba as outras
                registro['resultado'] = 'erro'
                mine.append((ATENCAO, 'etapa-falhou', f'{nome}: {type(erro).__name__}'))
        finally:
            if restaurar:
                try:
                    restaurar()
                except Exception as erro:  # noqa: BLE001
                    mine.append((ATENCAO, 'restauracao-falhou', f'{nome}: {type(erro).__name__}'))
        if depois:
            try:
                mine += depois()
            except Exception as erro:  # noqa: BLE001
                mine.append((ATENCAO, 'checagem-falhou', f'{nome}: {type(erro).__name__}'))
    registro['fim'] = round(relogio(), 1)
    registro['achados'] = [{'gravidade': g, 'codigo': c, 'detalhe': d} for g, c, d in mine]
    achados.extend(mine)
    return registro


# ---------- diagnóstico seguro do login (P6-3) ----------

def pedacos_do_servidor(servidor):
    """Tudo que identifica o servidor: URL, host, host:porta, host sem 'www.' e cada rótulo do host com 4+ letras."""
    if not servidor:
        return []
    partes = urlsplit(servidor if '://' in servidor else 'https://' + servidor)
    host = partes.hostname or ''
    pedacos = {servidor.rstrip('/'), servidor.split('://', 1)[-1].rstrip('/')}
    if host:
        pedacos.update({host, host.removeprefix('www.')})
        if partes.port:
            pedacos.add(f'{host}:{partes.port}')
        pedacos.update(r for r in host.split('.') if len(r) >= 4)
    return sorted((p for p in pedacos if p), key=len, reverse=True)


def sanear_texto(valor, servidor, nomes=()):
    """Troca o servidor (inclusive pedaços e host sem esquema) por <servidor> e passa por limpar_log."""
    for pedaco in pedacos_do_servidor(servidor):
        valor = re.sub(re.escape(pedaco), '<servidor>', valor, flags=re.IGNORECASE)
    return limpar_log(valor, list(nomes), servidor)


def listar_visivel(nos, servidor, nomes=()):
    """Textos e content-desc visíveis (sem bounds) para diagnóstico. EditText vira só a contagem de caracteres digitados."""
    saida = []
    for n in nos:
        if n['cls'].endswith('EditText'):
            dica = sanear_texto(n['hint'], servidor, nomes) if n['hint'] else ''
            # Sem atributo hint, o texto pode ser a própria dica: só é "digitado" se o conteúdo não for a dica.
            digitado = n['text'] if n['text'] and n['text'] != n['hint'] else ''
            saida.append(f'EditText[{dica}] ' + (f'<digitado:{len(digitado)} caracteres>' if digitado else '<vazio>'))
            continue
        for r in (n['text'], n['desc']):
            if r.strip():
                saida.append(sanear_texto(r.strip(), servidor, nomes)[:200])
    return saida


def aba_voce(nos):
    """Última aba da barra. O rótulo dela é o primeiro nome do usuário, não 'Você': acha pela linha de 'Baixados'."""
    ref = None
    for n in nos:
        if n['centro'] and any(r.strip().lower() in ('baixados', 'favoritos') for r in _rotulos(n)):
            ref = n
            break
    if ref is None:
        return achar_texto(nos, 'Você')
    linha = [n for n in nos if n['clickable'] and n['centro'] and abs(n['centro'][1] - ref['centro'][1]) <= 40]
    return max(linha, key=lambda n: n['centro'][0]) if linha else None


# ---------- diálogo de ANR de outro app (P6-4) ----------

ANR_DIALOGO = re.compile(r"^(?:o |a )?(.+?) (?:isn't responding|is not responding|não está respondendo|nao esta respondendo)\.?$",
                         re.I)
BOTOES_ESPERAR = ('wait', 'aguardar', 'esperar')
NOSSO_APP = ('heisuca', 'cgflix')


def reconhecer_anr(nos):
    """Diálogos de ANR na tela: lista de {nome, nosso, esperar}. 'nome' é só o rótulo do app, sem dados do aparelho."""
    achados, botao = [], None
    for n in nos:
        if n['centro'] and any(r.strip().lower() in BOTOES_ESPERAR for r in _rotulos(n)):
            botao = n
            break
    for n in nos:
        for r in _rotulos(n):
            m = ANR_DIALOGO.match(r.strip())
            if m and len(r) <= 120:
                nome = m.group(1).strip()
                achados.append({'nome': nome, 'nosso': any(k in nome.lower() for k in NOSSO_APP), 'esperar': botao})
    return achados


def achados_de_anr(dialogos, vistos):
    """Achados novos (uma vez por nome): ANR do nosso app = vermelho; de outro app = ATENÇÃO. Atualiza [vistos]."""
    saida = []
    for d in dialogos:
        chave = d['nome'].lower()
        if chave in vistos:
            continue
        vistos.add(chave)
        if d['nosso']:
            saida.append((VERMELHO, 'anr-do-app', d['nome']))
        else:
            saida.append((ATENCAO, 'anr-de-outro-app', d['nome']))
    return saida


# ---------- telas reconhecidas além do início e do login (P6-6) ----------

ROTULOS_PLAYER = re.compile(r'^(pausar|mostrar os botões|esconder os botões|carregando vídeo|legendas|áudio|tocando|pausado|'
                            r'ajustar à tela|preencher a tela|esticar|travar rotação|destravar rotação|'
                            r'voltar \d+ segundos|avançar \d+ segundos|episódio anterior|próximo episódio)$', re.I)


def tela_conhecida(nos):
    """Nome da tela legítima reconhecida por rótulos estáveis do app, ou None.

    'inicio' e 'login' vêm de [marco]; além deles: 'player', 'titulo' (ficha com Assistir/Continuar e Fechar),
    'perfil' (Você, Novo perfil, PIN), 'busca' e 'configuracoes'.
    """
    m = marco(nos)
    if m:
        return m
    rotulos = [r.strip() for n in nos for r in _rotulos(n) if len(r) <= 200]
    baixos = {r.lower() for r in rotulos}
    if sum(1 for r in rotulos if ROTULOS_PLAYER.match(r)) >= 2:
        return 'player'
    tem_play = any(r.lower().split(' ')[0] in ('assistir', 'continuar') for r in rotulos)
    if tem_play and ({'fechar', 'minha lista', 'trailer'} & baixos):
        return 'titulo'
    if baixos & {'novo perfil', 'confirmar pin', 'definir pin', 'sair da conta', 'você'} \
            or any(r.lower().startswith('sair da conta') for r in rotulos):
        return 'perfil'
    if baixos & {'buscar', 'configurações'} and any(n['cls'].endswith('EditText') for n in nos):
        return 'busca'
    if baixos & {'configurações', 'downloads automáticos', 'nenhum download automático', 'configurações heisuca'} \
            or any(r.lower().startswith(('configurações heisuca', 'downloads automáticos')) for r in rotulos):
        return 'configuracoes'
    return None
