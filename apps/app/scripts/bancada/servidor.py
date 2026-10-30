"""Sessão temporária da bancada. Sem nomes/tokens em mensagens de erro ou logs."""
import json
import re
import urllib.error
import urllib.parse
import urllib.request
import uuid


class BancadaIndisponivel(Exception):
    pass


class RestauracaoFalhou(Exception):
    pass


CAMPOS = ('Played', 'PlaybackPositionTicks', 'PlayCount', 'LastPlayedDate', 'IsFavorite', 'Likes', 'Rating', 'Key')


def estado(data):
    return {key: data.get(key) for key in CAMPOS}


def intacto(data):
    return (data.get('Played') is False and data.get('PlaybackPositionTicks') == 0
            and data.get('PlayCount') == 0 and not data.get('LastPlayedDate'))


def limpar_log(text, nomes, servidor):
    for value in sorted(nomes, key=len, reverse=True):
        if value:
            for encoded in (value, urllib.parse.quote(value), json.dumps(value, ensure_ascii=True)[1:-1]):
                text = re.sub(re.escape(encoded), '[conta omitida]', text, flags=re.IGNORECASE)
    text = re.sub(r'https?://[^\s\]\)"<>]+', '[endereço omitido]', text)
    host = urllib.parse.urlsplit(servidor).hostname
    if host:
        text = re.sub(re.escape(host), '[servidor omitido]', text, flags=re.IGNORECASE)
    return re.sub(r'\b[0-9a-fA-F]{24,}\b', '[identificador omitido]', text)


class Servidor:
    def __init__(self, base, token=None, user=None, device=None):
        self.base = base.rstrip('/')
        self.token = token
        self.user = user
        self.device = device or f'heisuca-bancada-{uuid.uuid4()}'
        self.ultimo_erro = None  # 'GET /Users -> HTTP 401' ou 'timeout': nunca URL completa nem token

    def request(self, method, path, body=None, query=None):
        url = self.base + path
        if query:
            url += '?' + urllib.parse.urlencode(query, doseq=True, safe=',')
        autorizacao = f'MediaBrowser Client="Heisuca bancada", Device="Bancada Android", DeviceId="{self.device}", Version="1"'
        # Desde 30/10 o servidor está com EnableLegacyAuthorization=false: só o Token dentro do
        # Authorization vale; X-Emby-Token sozinho dá 401. O cabeçalho legado fica para servidores antigos.
        if self.token:
            autorizacao += f', Token="{self.token}"'
        headers = {'Authorization': autorizacao, 'Content-Type': 'application/json'}
        if self.token:
            headers['X-Emby-Token'] = self.token
        request = urllib.request.Request(url, method=method, headers=headers,
            data=json.dumps(body).encode() if body is not None else None)
        try:
            with urllib.request.urlopen(request, timeout=30) as response:
                content = response.read()
                return json.loads(content) if content else None
        except (urllib.error.URLError, ValueError, TimeoutError) as error:
            motivo = (f'HTTP {error.code}' if isinstance(error, urllib.error.HTTPError)
                      else type(getattr(error, 'reason', error)).__name__)
            secoes = [x for x in path.split("/") if x][:3]
            self.ultimo_erro = f'{method} /{"/".join(re.sub(r"[0-9a-fA-F-]{20,}", "<id>", x) for x in secoes)} -> {motivo}'
            raise BancadaIndisponivel('Servidor não respondeu à operação da bancada.') from None

    def autenticar(self, name):
        result = self.request('POST', '/Users/AuthenticateByName', {'Username': name, 'Pw': ''})
        self.token, self.user = result['AccessToken'], result['User']['Id']

    def ocupado(self, exceto_device=None, item=None):
        sessions = self.request('GET', '/Sessions')
        return any((s.get('UserId') or '').replace('-', '').lower() == self.user.replace('-', '').lower()
            and s.get('NowPlayingItem') and s.get('DeviceId') != exceto_device
            and (item is None or s['NowPlayingItem'].get('Id') == item) for s in sessions)

    def item(self, item_id):
        return self.request('GET', f'/Users/{self.user}/Items/{item_id}')

    def escolher_video(self, min_ticks=5 * 60 * 10_000_000, tipos='Movie', apenas_intacto=True):
        # M acrescenta Home/PiP/áudio/MediaSession: 30 s já não cobrem o percurso.
        # O contrato Jellyfin não tem filtro de duração; pagina sem inventar parâmetro.
        offset = 0
        candidatos = []
        while True:
            query = {
                'Recursive': 'true',
                'MediaTypes': 'Video',
                'IsFolder': 'false',
                'IsVirtualItem': 'false',
                'SortBy': 'Runtime',
                'SortOrder': 'Ascending',
                'Fields': 'MediaSources,MediaStreams',
                'EnableUserData': 'true',
                'StartIndex': offset,
                'Limit': 200,
            }
            if tipos:
                item_types = [t.strip() for t in tipos.split(',')] if isinstance(tipos, str) else list(tipos)
                query['IncludeItemTypes'] = item_types
            if apenas_intacto:
                query['IsPlayed'] = 'false'
            result = self.request('GET', f'/Users/{self.user}/Items', query=query)
            rows = result.get('Items', []) if result else []
            if not rows and offset == 0 and 'IncludeItemTypes' in query and not apenas_intacto:
                del query['IncludeItemTypes']
                result = self.request('GET', f'/Users/{self.user}/Items', query=query)
                rows = result.get('Items', []) if result else []
            for row in rows:
                ticks = row.get('RunTimeTicks') or 0
                if ticks < min_ticks:
                    continue
                is_intacto = intacto(row.get('UserData', {}))
                if apenas_intacto and not is_intacto:
                    continue
                streams = row.get('MediaStreams', [])
                if not streams and row.get('MediaSources'):
                    streams = row['MediaSources'][0].get('MediaStreams', [])
                avc = any(stream.get('Type') == 'Video' and stream.get('Codec', '').lower() in ('h264', 'avc')
                          for stream in streams)
                candidatos.append((not is_intacto, ticks < 30 * 10_000_000, not avc, -ticks, row))
            for _, _, _, _, row in sorted(candidatos, key=lambda choice: choice[:4]):
                video = self.item(row['Id'])
                if not apenas_intacto or intacto(video.get('UserData', {})):
                    return video
            if len(rows) < 200:
                break
            offset += len(rows)
        raise BancadaIndisponivel('Nenhum filme sem histórico com duração suficiente para o percurso.'
                                  if apenas_intacto else 'Nenhum vídeo disponível no servidor com os critérios informados.')

    def logout(self):
        self.request('POST', '/Sessions/Logout')

    def restaurar(self, item_id, anterior, apenas_intacto=True):
        if apenas_intacto and not intacto(anterior):
            raise RestauracaoFalhou('Restauração recusada: o item já tinha histórico antes do teste.')
        if self.ocupado(item=item_id):
            raise RestauracaoFalhou('Restauração pendente: outra sessão está usando o item.')
        if intacto(anterior):
            self.request('DELETE', f'/Users/{self.user}/PlayedItems/{item_id}')
            atual = self.item(item_id)['UserData']
            if estado(atual) != estado(anterior):
                raise RestauracaoFalhou('O servidor não confirmou a restauração exata do estado anterior.')
        else:
            if anterior.get('Played') is False and anterior.get('PlaybackPositionTicks', 0) == 0:
                self.request('DELETE', f'/Users/{self.user}/PlayedItems/{item_id}')
            elif anterior.get('Played') is True:
                self.request('POST', f'/Users/{self.user}/PlayedItems/{item_id}')
            corpo = {k: anterior[k] for k in ('PlaybackPositionTicks', 'PlayCount', 'Played', 'IsFavorite', 'Likes', 'Rating')
                     if k in anterior and anterior[k] is not None}
            for path in (f'/UserItems/{item_id}/UserData', f'/Users/{self.user}/Items/{item_id}/UserData'):
                try:
                    self.request('POST', path, body=corpo, query={'userId': self.user})
                    break
                except BancadaIndisponivel:
                    pass


def selecionar(base, names, factory=Servidor):
    ultimo = None  # 'GET /Sessions -> HTTP 401': sem isto a causa some atrás de "nenhuma conta livre"
    for name in names:
        name = name.strip()
        if not name or name.lower().endswith('-kids'):
            continue
        client = factory(base)
        try:
            client.autenticar(name)
            if client.ocupado():
                client.logout()
                continue
            video = client.escolher_video()
            return client, name, video
        except BancadaIndisponivel:
            ultimo = getattr(client, 'ultimo_erro', None) or ultimo
            if client.token:
                try:
                    client.logout()
                except BancadaIndisponivel:
                    pass
    motivo = f' Último erro do servidor: {ultimo}.' if ultimo else ''
    raise BancadaIndisponivel('Nenhuma conta livre com vídeo seguro disponível.' + motivo)
