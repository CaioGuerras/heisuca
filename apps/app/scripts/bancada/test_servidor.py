import unittest
from copy import deepcopy

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


if __name__ == '__main__': unittest.main()
