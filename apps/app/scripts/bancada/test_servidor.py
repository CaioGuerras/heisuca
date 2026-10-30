import io
import unittest
from copy import deepcopy
from unittest import mock

from servidor import BancadaIndisponivel, RestauracaoFalhou, Servidor, estado, intacto, limpar_log, selecionar

PRISTINO = {'Played': False, 'PlaybackPositionTicks': 0, 'PlayCount': 0, 'LastPlayedDate': None,
            'IsFavorite': True, 'Likes': True, 'Key': 'filme'}


class ServidorFalso(Servidor):
    def __init__(self, base='https://exemplo.invalid', sessions=None, data=None, reset=True):
        super().__init__(base, 'token-falso', 'abc-def')
        self.sessions = sessions or []
        self.data = deepcopy(data if data is not None else PRISTINO)
        self.calls = []
        self.reset = reset

    def request(self, method, path, body=None, query=None):
        self.calls.append((method, path))
        if path == '/Sessions': return self.sessions
        if method == 'DELETE':
            if self.reset:
                self.data.update({'Played': False, 'PlaybackPositionTicks': 0, 'PlayCount': 0, 'LastPlayedDate': None})
            return deepcopy(self.data)
        return {'Id': 'filme', 'Name': 'Filme de teste', 'UserData': deepcopy(self.data)}


class SegurancaDaBancada(unittest.TestCase):
    def test_midia_curta_demais_nao_termina_no_meio_do_percurso_ampliado(self):
        class Videos(ServidorFalso):
            def request(self, method, path, body=None, query=None):
                if path.endswith('/Items'):
                    return {'Items': [
                        {'Id': 'curto', 'RunTimeTicks': 30 * 10_000_000, 'UserData': PRISTINO},
                        {'Id': 'suficiente', 'RunTimeTicks': 360 * 10_000_000, 'UserData': PRISTINO}]}
                return {'Id': path.rsplit('/', 1)[-1], 'UserData': PRISTINO}
        self.assertEqual('suficiente', Videos().escolher_video()['Id'])

    def test_busca_proxima_pagina_quando_os_primeiros_filmes_sao_curtos(self):
        offsets = []
        class Videos(ServidorFalso):
            def request(self, method, path, body=None, query=None):
                if path.endswith('/Items'):
                    offsets.append(query['StartIndex'])
                    if query['StartIndex'] == 0:
                        return {'Items': [{'Id': f'curto-{i}', 'RunTimeTicks': 30 * 10_000_000,
                                           'UserData': PRISTINO} for i in range(200)]}
                    return {'Items': [{'Id': 'adequado', 'RunTimeTicks': 360 * 10_000_000,
                                       'UserData': PRISTINO}]}
                return {'Id': path.rsplit('/', 1)[-1], 'UserData': PRISTINO}
        self.assertEqual('adequado', Videos().escolher_video()['Id'])
        self.assertEqual([0, 200], offsets)

    def test_rodizio_nao_autentica_kids_e_pula_conta_ocupada(self):
        authenticated, logged_out = [], []
        class Fake:
            def __init__(self, base): self.token = None
            def autenticar(self, name):
                self.name, self.token = name, 'token'
                authenticated.append(name)
            def ocupado(self): return self.name == 'ocupada'
            def logout(self): logged_out.append(self.name)
            def escolher_video(self): return {'Id': 'filme', 'UserData': PRISTINO}
        client, name, video = selecionar('https://exemplo.invalid', ['crianca-kids', 'ocupada', 'livre'], Fake)
        self.assertEqual(authenticated, ['ocupada', 'livre'])
        self.assertEqual(logged_out, ['ocupada'])
        self.assertEqual(name, 'livre')
        self.assertEqual(video['Id'], 'filme')

    def test_falha_na_sondagem_nao_significa_conta_livre(self):
        class Fake:
            token = 'token'
            def __init__(self, base): pass
            def autenticar(self, name): pass
            def ocupado(self): raise BancadaIndisponivel('Sem resposta')
            def logout(self): pass
        with self.assertRaises(BancadaIndisponivel): selecionar('https://exemplo.invalid', ['teste'], Fake)

    def test_token_vai_no_authorization_porque_o_servidor_recusa_o_cabecalho_legado(self):
        # 30/10: EnableLegacyAuthorization=false; só X-Emby-Token dava 401 em todas as contas.
        enviados = []
        def urlopen(request, timeout):
            enviados.append(dict(request.header_items()))
            return io.BytesIO(b'[]')
        client = Servidor('https://exemplo.invalid', 'token-falso', 'abc-def', 'aparelho')
        with mock.patch('servidor.urllib.request.urlopen', side_effect=urlopen):
            client.request('GET', '/Sessions')
        self.assertIn('Token="token-falso"', enviados[0]['Authorization'])
        self.assertIn('DeviceId="aparelho"', enviados[0]['Authorization'])

    def test_login_sem_token_nao_manda_token_vazio(self):
        enviados = []
        def urlopen(request, timeout):
            enviados.append(dict(request.header_items()))
            return io.BytesIO(b'{}')
        with mock.patch('servidor.urllib.request.urlopen', side_effect=urlopen):
            Servidor('https://exemplo.invalid', device='aparelho').request('POST', '/Users/AuthenticateByName', {})
        self.assertNotIn('Token=', enviados[0]['Authorization'])
        self.assertNotIn('X-emby-token', enviados[0])

    def test_rodizio_esgotado_mostra_o_ultimo_erro_do_servidor(self):
        class Fake:
            token = 'token'
            def __init__(self, base): self.ultimo_erro = None
            def autenticar(self, name): pass
            def ocupado(self):
                self.ultimo_erro = 'GET /Sessions -> HTTP 401'
                raise BancadaIndisponivel('Sem resposta')
            def logout(self): pass
        with self.assertRaises(BancadaIndisponivel) as erro:
            selecionar('https://exemplo.invalid', ['teste'], Fake)
        self.assertIn('GET /Sessions -> HTTP 401', str(erro.exception))
        self.assertNotIn('token', str(erro.exception))

    def test_sessao_pausada_tambem_faz_conta_ser_poupada(self):
        client = ServidorFalso(sessions=[{'UserId': 'ABCDEF', 'DeviceId': 'outro',
            'NowPlayingItem': {'Id': 'filme'}, 'PlayState': {'IsPaused': True}}])
        self.assertTrue(client.ocupado())
        self.assertFalse(client.ocupado(exceto_device='outro'))

    def test_qualquer_historico_impede_escolha_do_item(self):
        self.assertTrue(intacto(PRISTINO))
        for key, value in [('Played', True), ('PlaybackPositionTicks', 1), ('PlayCount', 1), ('LastPlayedDate', '2026-01-01')]:
            changed = {**PRISTINO, key: value}
            self.assertFalse(intacto(changed), key)
            client = ServidorFalso()
            with self.assertRaises(RestauracaoFalhou): client.restaurar('filme', changed)
            self.assertEqual(client.calls, [])

    def test_reset_oficial_restaura_quatro_campos_e_preserva_favorito(self):
        after = {**PRISTINO, 'Played': True, 'PlayCount': 1, 'PlaybackPositionTicks': 30, 'LastPlayedDate': '2026-10-25'}
        client = ServidorFalso(data=after)
        client.restaurar('filme', PRISTINO)
        self.assertEqual(estado(client.data), estado(PRISTINO))
        self.assertEqual([c for c in client.calls if c[0] == 'DELETE'], [('DELETE', '/Users/abc-def/PlayedItems/filme')])

    def test_nao_declara_restaurado_quando_servidor_nao_confirma(self):
        client = ServidorFalso(data={**PRISTINO, 'PlaybackPositionTicks': 15}, reset=False)
        with self.assertRaises(RestauracaoFalhou): client.restaurar('filme', PRISTINO)

    def test_nao_apaga_uso_de_outra_sessao_no_mesmo_item(self):
        client = ServidorFalso(sessions=[{'UserId': 'abcdef', 'DeviceId': 'externo', 'NowPlayingItem': {'Id': 'filme'}}])
        with self.assertRaises(RestauracaoFalhou): client.restaurar('filme', PRISTINO)
        self.assertFalse(any(method == 'DELETE' for method, _ in client.calls))

    def test_log_omite_nome_cru_codificado_token_e_endereco(self):
        text = 'Pessoa-á PESSOA-Á Pessoa-%C3%A1 Pessoa-\\u00e1 https://exemplo.invalid/a 0123456789abcdef0123456789abcdef'
        result = limpar_log(text, ['Pessoa-á'], 'https://exemplo.invalid')
        for forbidden in ['Pessoa', 'PESSOA', 'exemplo.invalid', '0123456789abcdef']:
            self.assertNotIn(forbidden, result)

    def test_escolher_video_caos_aceita_episodio_e_item_com_historico(self):
        class Midias(ServidorFalso):
            def request(self, method, path, body=None, query=None):
                if path.endswith('/Items'):
                    return {'Items': [
                        {'Id': 'ep-1', 'RunTimeTicks': 60 * 10_000_000,
                         'UserData': {**PRISTINO, 'Played': True},
                         'MediaStreams': [{'Type': 'Video', 'Codec': 'h264'}]}]}
                return {'Id': path.rsplit('/', 1)[-1], 'UserData': {**PRISTINO, 'Played': True}}
        m = Midias()
        video = m.escolher_video(min_ticks=50 * 10_000_000, tipos='Movie,Episode', apenas_intacto=False)
        self.assertEqual(video['Id'], 'ep-1')

    def test_escolher_video_caos_aceita_tipos_none_e_duracao_zero(self):
        class Midias(ServidorFalso):
            def request(self, method, path, body=None, query=None):
                if path.endswith('/Items'):
                    return {'Items': [
                        {'Id': 'video-qualquer', 'RunTimeTicks': 10 * 10_000_000,
                         'UserData': {**PRISTINO, 'Played': True}}]}
                return {'Id': path.rsplit('/', 1)[-1], 'UserData': {**PRISTINO, 'Played': True}}
        m = Midias()
        video = m.escolher_video(min_ticks=0, tipos=None, apenas_intacto=False)
        self.assertEqual(video['Id'], 'video-qualquer')

    def test_escolher_video_fallback_sem_include_item_types(self):
        consultas = []
        class Midias(ServidorFalso):
            def request(self, method, path, body=None, query=None):
                if path.endswith('/Items'):
                    consultas.append(dict(query))
                    if 'IncludeItemTypes' in query:
                        return {'Items': []}
                    return {'Items': [{'Id': 'salvo', 'RunTimeTicks': 20 * 10_000_000, 'UserData': PRISTINO}]}
                return {'Id': path.rsplit('/', 1)[-1], 'UserData': PRISTINO}
        m = Midias()
        video = m.escolher_video(min_ticks=0, tipos='Movie,Episode', apenas_intacto=False)
        self.assertEqual(video['Id'], 'salvo')
        self.assertEqual(len(consultas), 2)
        self.assertNotIn('IncludeItemTypes', consultas[1])

    def test_escolher_video_acha_streams_em_media_sources(self):
        class Midias(ServidorFalso):
            def request(self, method, path, body=None, query=None):
                if path.endswith('/Items'):
                    return {'Items': [{
                        'Id': 'midia-sources',
                        'RunTimeTicks': 60 * 10_000_000,
                        'UserData': PRISTINO,
                        'MediaSources': [{'MediaStreams': [{'Type': 'Video', 'Codec': 'h264'}]}]
                    }]}
                return {'Id': path.rsplit('/', 1)[-1], 'UserData': PRISTINO}
        m = Midias()
        video = m.escolher_video(min_ticks=0, tipos=None, apenas_intacto=False)
        self.assertEqual(video['Id'], 'midia-sources')

    def test_restaurar_item_com_historico_nao_lanca_quando_apenas_intacto_falso(self):
        client = ServidorFalso(data={**PRISTINO, 'Played': True, 'PlaybackPositionTicks': 500})
        client.restaurar('filme', {**PRISTINO, 'Played': True, 'PlaybackPositionTicks': 500}, apenas_intacto=False)
        self.assertTrue(any(method == 'POST' for method, _ in client.calls))


if __name__ == '__main__': unittest.main()
