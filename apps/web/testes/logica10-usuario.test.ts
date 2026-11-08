import { test } from 'node:test';
import assert from 'node:assert/strict';
import { alternarFavorito, alternarVisto, dadosDe } from '../src/estado/usuario.ts';
import type { Item, Sessao } from '../src/api/tipos.ts';
import { resolver } from './visual7-harness.ts';

function adiada<T>() {
  let concluir!: (v: T) => void;
  const promessa = new Promise<T>(r => { concluir = r; });
  return { promessa, concluir };
}
const s: Sessao = { tipo: 'jellyfin', servidor: 'https://logica10.example.invalid',
  token: 'ficticio', usuarioId: 'u', nome: 'Teste', servidorId: 'logica10' };
let sequencia = 0;
function item(inicial = false): Item {
  return { Id: String(++sequencia), Name: 'Teste', Type: 'Movie',
    UserData: { IsFavorite: inicial, Played: inicial, PlaybackPositionTicks: 123, PlayedPercentage: 25 } };
}
const resultado = (p: Promise<boolean>) => p.then(valor => ({ valor }), erro => ({ erro }));

for (const [campo, alternar] of [['IsFavorite', alternarFavorito], ['Played', alternarVisto]] as const) {
  for (const inicial of [false, true]) for (const ordem of [[0, 1], [1, 0]]) {
    for (const falhas of [[false, false], [true, false], [false, true], [true, true]]) {
      test(`Lógica10: ${campo} inicial=${inicial}; respostas ${ordem.map(n => n + 1).join('→')}; falhas=${falhas}`, async () => {
        const i = item(inicial), respostas = [adiada<number>(), adiada<number>()];
        const chamadas: boolean[] = [], anterior = globalThis.fetch;
        let confirmado = inicial;
        globalThis.fetch = async (_u, init) => {
          const n = chamadas.length, valor = init?.method === 'POST';
          chamadas.push(valor);
          const status = await respostas[n].promessa;
          if (status === 200) confirmado = valor;
          return new Response(JSON.stringify({ ...i.UserData, [campo]: confirmado }), { status });
        };
        try {
          const p1 = resultado(alternar(s, i));
          assert.equal(dadosDe(s, i)[campo], !inicial, 'primeiro clique é otimista');
          const p2 = resultado(alternar(s, i));
          assert.equal(dadosDe(s, i)[campo], inicial, 'último clique aparece imediatamente');
          await resolver();
          const primeirosEnvios = [...chamadas];
          respostas[ordem[0]].concluir(falhas[ordem[0]] ? 500 : 200);
          await resolver();
          const estadoIntermediario = dadosDe(s, i)[campo], enviosIntermediarios = chamadas.length;
          respostas[ordem[1]].concluir(falhas[ordem[1]] ? 500 : 200);
          const resultados = await Promise.all([p1, p2]);
          resultados.forEach((r, n) => {
            if (falhas[n]) assert.match(String((r as { erro: unknown }).erro), /500/);
            else assert.equal((r as { valor: boolean }).valor, n ? inicial : !inicial);
          });
          const esperado = falhas[1] ? (falhas[0] ? inicial : !inicial) : inicial;
          assert.equal(dadosDe(s, i)[campo], esperado, 'rollback usa somente o último estado confirmado');
          assert.equal(confirmado, esperado, 'servidor e UI terminam iguais');
          assert.equal(estadoIntermediario, inicial, 'resposta antiga não sobrescreve o último clique');
          assert.deepEqual(primeirosEnvios, [!inicial], 'segunda mutação espera a confirmação da primeira');
          if (ordem[0] === 1) assert.equal(enviosIntermediarios, 1, 'resposta 2 antecipada não permite inverter os envios');
          assert.deepEqual(chamadas, [!inicial, inicial]);
          assert.equal(dadosDe(s, i).PlaybackPositionTicks, 123);
          assert.equal(dadosDe(s, i).PlayedPercentage, 25);
          assert.equal(dadosDe(s, i)[campo === 'Played' ? 'IsFavorite' : 'Played'], inicial);
        } finally { globalThis.fetch = anterior; }
      });
    }
  }
}

test('Lógica10: favorito/visto compartilham fila; rollback não ressuscita o otimismo falho do outro campo', async () => {
  const i = item(), respostas = [adiada<number>(), adiada<number>(), adiada<number>()];
  const anterior = globalThis.fetch, metodos: string[] = [];
  globalThis.fetch = async (u, init) => {
    const n = metodos.length; metodos.push(new URL(String(u)).pathname + ':' + init?.method);
    return new Response('{}', { status: await respostas[n].promessa });
  };
  try {
    const a = resultado(alternarFavorito(s, i)), b = resultado(alternarVisto(s, i));
    await resolver(); assert.equal(metodos.length, 1);
    assert.equal(dadosDe(s, i).IsFavorite, true); assert.equal(dadosDe(s, i).Played, true);
    respostas[0].concluir(500); await a; await resolver();
    assert.equal(dadosDe(s, i).IsFavorite, false); assert.equal(dadosDe(s, i).Played, true);
    respostas[1].concluir(200); await b;
    assert.equal(dadosDe(s, i).IsFavorite, false); assert.equal(dadosDe(s, i).Played, true);
    const c = resultado(alternarFavorito(s, i)); await resolver();
    respostas[2].concluir(500); await c;
    assert.equal(dadosDe(s, i).IsFavorite, false); assert.equal(dadosDe(s, i).Played, true);
    assert.equal(metodos.length, 3, 'fila volta a funcionar depois de falhas e de esvaziar');
  } finally { globalThis.fetch = anterior; }
});

test('Lógica10: três cliques e três falhas restauram o estado original sem reaplicar ações falhas', async () => {
  const i = item(), respostas = [adiada<number>(), adiada<number>(), adiada<number>()];
  const anterior = globalThis.fetch; let chamadas = 0;
  globalThis.fetch = async () => new Response('{}', { status: await respostas[chamadas++].promessa });
  try {
    const ps = [resultado(alternarFavorito(s, i)), resultado(alternarFavorito(s, i)), resultado(alternarFavorito(s, i))];
    assert.equal(dadosDe(s, i).IsFavorite, true);
    for (let n = 0; n < 3; n++) {
      respostas[n].concluir(500); await ps[n];
      assert.equal(dadosDe(s, i).IsFavorite, n < 2, `após a falha ${n + 1}`);
    }
    assert.equal(chamadas, 3);
  } finally { globalThis.fetch = anterior; }
});

test('Lógica10: filas de itens, usuários e servidores distintos não se bloqueiam', async () => {
  const i = item(), outro = item(), respostas = Array.from({ length: 4 }, () => adiada<number>());
  const anterior = globalThis.fetch; let chamadas = 0;
  globalThis.fetch = async () => new Response('{}', { status: await respostas[chamadas++].promessa });
  const b = { ...s, servidorId: 'outro' }, c = { ...s, usuarioId: 'outro' };
  try {
    const ps = [resultado(alternarFavorito(s, i)), resultado(alternarFavorito(s, outro)),
      resultado(alternarFavorito(b, i)), resultado(alternarFavorito(c, i))];
    await resolver(); assert.equal(chamadas, 4);
    respostas[3].concluir(200); respostas[2].concluir(500); respostas[1].concluir(200); respostas[0].concluir(500);
    await Promise.all(ps);
    assert.equal(dadosDe(s, i).IsFavorite, false); assert.equal(dadosDe(s, outro).IsFavorite, true);
    assert.equal(dadosDe(b, i).IsFavorite, false); assert.equal(dadosDe(c, i).IsFavorite, true);
  } finally { globalThis.fetch = anterior; }
});
