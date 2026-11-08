import { test } from 'node:test';
import assert from 'node:assert/strict';
import { apiDe, buscar, quandoExpirar, type Sessao } from '../src/api/servidor.ts';
import { bancada, nos } from './visual7-harness.ts';

const inicial: Sessao = { tipo: 'jellyfin', servidor: 'https://antigo.example.invalid', servidorId: 'antigo',
  usuarioId: 'pessoa', nome: 'Teste', token: 'ficticio-antigo' };

for (const tipo of ['jellyfin', 'plex'] as const) {
  for (const paginada of [false, true]) {
    test(`Revisão9: 401 ${tipo}${paginada ? ' na busca paginada' : ''} da sessão antiga não encerra a nova`, async () => {
      const antiga = { ...inicial, tipo }, nova = { ...antiga, token: 'ficticio-novo' };
      let esquecidas = 0;
      const b = bancada('../src/app.tsx', 'App', {
        './api/servidor.ts': { quandoExpirar, pode: () => true },
        './api/contas.ts': { sessaoAtual: () => antiga, esquecerSessao: () => { esquecidas++; } },
        './sobDemanda': { sobDemanda: () => ({ pre() {} }) },
      }, { sessionStorage: { getItem: () => '1' } });
      const anterior = globalThis.fetch;
      let responder!: (r: Response) => void;
      globalThis.fetch = () => new Promise(r => { responder = r; });
      try {
        const v = b.render('App', {}); b.efeitos();
        const pedido = paginada ? buscar(antiga, 'lua', 'b', 0) : apiDe(antiga).item(antiga, 'i');
        const rejeitada = assert.rejects(pedido);
        nos(v).find(n => n.props.trocar).props.trocar(nova);
        b.render('App', {}); b.efeitos();
        responder(new Response(null, { status: 401 })); await rejeitada;
        assert.equal(esquecidas, 0, 'o 401 antigo não pode apagar a sessão atual');
        assert.equal(nos(b.render('App', {})).find(n => n.props.trocar)?.props.s.token, nova.token);

        globalThis.fetch = async () => new Response(null, { status: 401 });
        await assert.rejects(paginada ? buscar(nova, 'lua', 'b', 0) : apiDe(nova).item(nova, 'i'));
        assert.equal(esquecidas, 1, 'o 401 da sessão atual continua encerrando a sessão');
      } finally { b.desmontar(); quandoExpirar(null); globalThis.fetch = anterior; }
    });
  }
}
