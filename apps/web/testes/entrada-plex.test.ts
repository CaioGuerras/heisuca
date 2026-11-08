// Fluxo da entrada Plex (api/fluxo-plex.ts) com fetch falso: nenhum acesso real ao plex.tv.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { autorizarPlex, conectarPlex, passoSeguinte, ErroEntradaPlex } from '../src/api/fluxo-plex.ts';
import { servidoresSalvos, sessaoAtual } from '../src/api/contas.ts';

const json = (d: unknown, status = 200) => new Response(JSON.stringify(d), { status });
function guardar() {
  const dados = new Map([['heisuca.aparelho', 'aparelho-ficticio']]);
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: {
    getItem: (k: string) => dados.get(k) ?? null, setItem: (k: string, v: string) => dados.set(k, v), removeItem: (k: string) => dados.delete(k),
  } });
}
type Chamada = { url: URL; init?: RequestInit };
async function comFetch(responder: (c: Chamada) => Response | Promise<Response>, executar: (chamadas: Chamada[]) => unknown) {
  guardar(); const anterior = globalThis.fetch; const chamadas: Chamada[] = [];
  globalThis.fetch = async (u, init) => { const c = { url: new URL(String(u)), init }; chamadas.push(c); return responder(c); };
  try { await executar(chamadas); } finally { globalThis.fetch = anterior; }
}
const recurso = (n: number) => ({ name: `Servidor ${n}`, clientIdentifier: `srv-${n}`, accessToken: `token-pms-${n}`, provides: 'server',
  publicAddressMatches: false, connections: [{ uri: `https://srv${n}.example.invalid`, local: false }, { uri: `http://srv${n}.lan`, local: true }] });
// plex.tv + PMS falsos: PIN 77 autoriza na 1ª consulta; cada PMS responde com o próprio machineIdentifier
function plexFalso(recursos: unknown[], pin: (c: Chamada) => Response = () => json({ authToken: 'token-conta' })) {
  return (c: Chamada) => {
    const p = c.url.pathname;
    if (c.url.hostname === 'plex.tv') {
      if (p === '/api/v2/pins') return json({ id: 77, code: 'CODIGOFICTICIO' });
      if (p === '/api/v2/pins/77') return pin(c);
      if (p === '/api/v2/user') return json({ id: 90, title: 'Pessoa Fictícia' });
      if (p === '/api/v2/resources') return json(recursos);
    }
    const n = /^srv(\d+)\./.exec(c.url.hostname)?.[1];
    return n ? json({ MediaContainer: { machineIdentifier: `srv-${n}` } }) : json({}, 404);
  };
}

test('Plex: PIN → token → 1 servidor conecta direto e a sessão fica salva como plex', async () => {
  await comFetch(plexFalso([recurso(1), { name: 'Reprodutor', provides: 'player' }]), async chamadas => {
    let mostrado: { codigo: string; url: string } | null = null;
    const a = await autorizarPlex(new AbortController().signal, (pin, url) => { mostrado = { codigo: pin.code, url }; });
    assert.deepEqual(mostrado, { codigo: 'CODIGOFICTICIO', url: mostrado!.url });
    assert.ok(mostrado!.url.startsWith('https://app.plex.tv/auth#?'));
    assert.equal(a.conta.nome, 'Pessoa Fictícia');
    const passo = passoSeguinte(a.servidores);
    assert.equal(passo.tipo, 'conectar');
    const s = await conectarPlex(passo.tipo === 'conectar' ? passo.recurso : a.servidores[0], a.conta, new AbortController().signal);
    assert.equal(s.tipo, 'plex'); assert.equal(s.servidor, 'https://srv1.example.invalid'); assert.equal(s.token, 'token-pms-1');
    assert.equal(sessaoAtual()?.tipo, 'plex');
    assert.deepEqual(servidoresSalvos().map(x => [x.tipo, x.nome]), [['plex', 'Servidor 1']]);
    // o token da conta só vai ao plex.tv; o PMS recebe o token dele
    assert.ok(chamadas.filter(c => c.url.hostname !== 'plex.tv').every(c => c.url.searchParams.get('X-Plex-Token') === 'token-pms-1'));
  });
});

test('Plex: 2 servidores pedem escolha; o escolhido conecta pela conexão dele', async () => {
  await comFetch(plexFalso([recurso(1), recurso(2)]), async () => {
    const a = await autorizarPlex(new AbortController().signal, () => undefined);
    const passo = passoSeguinte(a.servidores);
    assert.equal(passo.tipo, 'escolher');
    assert.deepEqual(passo.tipo === 'escolher' && passo.lista.map(r => r.name), ['Servidor 1', 'Servidor 2']);
    const s = await conectarPlex(a.servidores[1], a.conta, new AbortController().signal);
    assert.equal(s.servidor, 'https://srv2.example.invalid'); assert.equal(s.nomeServidor, 'Servidor 2');
  });
});

test('Plex: PIN 404 dá a mensagem de código vencido (motivo "vencido")', async () => {
  await comFetch(plexFalso([], () => json({}, 404)), async () => {
    await assert.rejects(autorizarPlex(new AbortController().signal, () => undefined),
      (e: unknown) => e instanceof ErroEntradaPlex && e.motivo === 'vencido' && /venceu/.test(e.message));
  });
});

test('Plex: cancelar aborta sem fetch extra (antes da 1ª consulta e no meio da espera)', async () => {
  await comFetch(plexFalso([recurso(1)]), async chamadas => {
    const c = new AbortController();
    await assert.rejects(autorizarPlex(c.signal, () => c.abort()), { name: 'AbortError' });
    assert.equal(chamadas.length, 1);   // só o POST do PIN
  });
  await comFetch(plexFalso([recurso(1)], () => json({})), async chamadas => {
    const c = new AbortController();
    const p = autorizarPlex(c.signal, () => undefined);
    while (chamadas.length < 2) await new Promise(ok => setTimeout(ok, 1));
    c.abort();
    await assert.rejects(p, { name: 'AbortError' });
    await new Promise(ok => setTimeout(ok, 30));
    assert.equal(chamadas.length, 2);   // POST + 1 consulta; nada depois do cancelar
  });
  await comFetch(plexFalso([recurso(1)]), async chamadas => {
    const c = new AbortController(); c.abort();
    await assert.rejects(conectarPlex(recurso(1), { id: '90', nome: 'X' }, c.signal), { name: 'AbortError' });
    assert.equal(chamadas.length, 0);
  });
});

test('Plex: sem servidor, sem HTTPS e sem rede viram mensagens claras', async () => {
  assert.throws(() => passoSeguinte([]), (e: unknown) => e instanceof ErroEntradaPlex && e.motivo === 'sem-servidor');
  await comFetch(plexFalso([]), async () => {
    const soHttp = { ...recurso(3), connections: [{ uri: 'http://srv3.example.invalid', local: false }] };
    await assert.rejects(conectarPlex(soHttp, { id: '90', nome: 'X' }, new AbortController().signal),
      (e: unknown) => e instanceof ErroEntradaPlex && e.motivo === 'sem-https' && /HTTPS/.test(e.message));
    const mudo = { ...recurso(4), clientIdentifier: 'outro' };   // responde, mas é outra máquina
    await assert.rejects(conectarPlex(mudo, { id: '90', nome: 'X' }, new AbortController().signal),
      (e: unknown) => e instanceof ErroEntradaPlex && e.motivo === 'sem-https');
    assert.equal(sessaoAtual(), null);
  });
  await comFetch(() => { throw new TypeError('Failed to fetch'); }, async () => {
    await assert.rejects(autorizarPlex(new AbortController().signal, () => undefined),
      (e: unknown) => e instanceof ErroEntradaPlex && e.motivo === 'rede');
  });
});
