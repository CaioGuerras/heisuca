// Esconder por capacidade: com sessão Plex somem favoritos/senha/foto/em alta/em breve; com Jellyfin nada muda.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { adaptador, pode, type ApiServidor, type Capacidades, type Sessao } from '../src/api/servidor.ts';
import { prepararInicio, carregarSecundario } from '../src/dados/inicio.ts';

const sessao = (tipo: 'jellyfin' | 'plex', n: string): Sessao => ({ tipo, servidor: `https://${n}.example.invalid`, token: 't',
  usuarioId: `u-${n}`, nome: 'Pessoa Fictícia', servidorId: n } as Sessao);
const todas: (keyof Capacidades)[] = ['favoritos', 'trocarSenha', 'foto', 'legendasRemotas', 'capitulos', 'emAlta', 'emBreve'];

test('capacidades: Jellyfin mostra tudo; Plex esconde favoritos, senha, foto, legendas remotas, em alta e em breve', () => {
  const jf = sessao('jellyfin', 'jf'), px = sessao('plex', 'px');
  for (const c of todas) assert.equal(pode(jf, c), true, `jellyfin.${c}`);
  for (const c of ['favoritos', 'trocarSenha', 'foto', 'legendasRemotas', 'emAlta', 'emBreve'] as const) assert.equal(pode(px, c), false, `plex.${c}`);
  assert.equal(pode(px, 'capitulos'), true);
});

// Troca os métodos do adaptador por falsos que contam chamadas (nenhuma rede) e devolve o que o Início pediu.
async function inicioCom(tipo: 'jellyfin' | 'plex') {
  const api = adaptador(tipo) as unknown as Record<string, unknown>;
  const nomes = ['destaque', 'continuar', 'proximos', 'emAlta', 'emBreve', 'bibliotecasDeVideo', 'temArte'] as const;
  const antes = Object.fromEntries(nomes.map(k => [k, api[k]]));
  const pedidos: string[] = [];
  const item = { Id: 'a1', Name: 'Título Fictício', Type: 'Movie' };
  Object.assign(api, {
    destaque: async () => { pedidos.push('destaque'); return []; },
    continuar: async () => { pedidos.push('continuar'); return []; },
    proximos: async () => { pedidos.push('proximos'); return []; },
    emAlta: async () => { pedidos.push('emAlta'); return { titulo: 'Em alta', itens: [item] }; },
    emBreve: async (_s: Sessao, t: string) => { pedidos.push(`emBreve:${t}`); return [{ nome: 'Estreia', tipo: t }]; },
    bibliotecasDeVideo: async () => { pedidos.push('bibliotecas'); return []; },
    temArte: () => false,
  } satisfies Partial<Record<keyof ApiServidor, unknown>>);
  try {
    const s = sessao(tipo, `inicio-${tipo}`);
    const critico = await prepararInicio(s, true);
    const sec = await carregarSecundario(s);
    return { pedidos, critico, sec };
  } finally { Object.assign(api, antes); }
}

test('Início com Plex não pede nem mostra Em alta e Em breve', async () => {
  const { pedidos, critico, sec } = await inicioCom('plex');
  assert.ok(!pedidos.some(p => p.startsWith('emAlta') || p.startsWith('emBreve')), pedidos.join(','));
  assert.deepEqual(critico.emAlta.itens, []);
  assert.deepEqual(sec.emBreve, { tv: [], movie: [] });
  assert.ok(pedidos.includes('destaque') && pedidos.includes('continuar'));
});

test('Início com Jellyfin segue pedindo e mostrando Em alta e Em breve', async () => {
  const { pedidos, critico, sec } = await inicioCom('jellyfin');
  assert.ok(pedidos.includes('emAlta') && pedidos.includes('emBreve:tv') && pedidos.includes('emBreve:movie'), pedidos.join(','));
  assert.equal(critico.emAlta.itens.length, 1);
  assert.equal(sec.emBreve.tv.length + sec.emBreve.movie.length, 2);
});
