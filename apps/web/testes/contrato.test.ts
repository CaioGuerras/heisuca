import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import ts from 'typescript';
import { apiDe, adaptador, quandoExpirar } from '../src/api/servidor.ts';
import { sessaoAtual, trocarPara, servidoresSalvos, esquecerSessao } from '../src/api/contas.ts';
import { alternarFavorito, alternarVisto, dadosDe } from '../src/estado/usuario.ts';
import type { Sessao, Item } from '../src/api/tipos.ts';

const antiga = JSON.parse(await readFile(new URL('./urls-antigas.json', import.meta.url), 'utf8'));
const s: Sessao = { ...antiga.s, tipo: 'jellyfin', servidorId: 'servidor-a' };
const i: Item = antiga.i;
function armazenamento(inicio: Record<string, string> = {}) {
  const dados = new Map(Object.entries(inicio));
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: {
    getItem: (k: string) => dados.get(k) ?? null,
    setItem: (k: string, v: string) => { dados.set(k, v); }, removeItem: (k: string) => { dados.delete(k); },
  } });
  return dados;
}

test('importar o contrato/API em processo novo não exige document nem lê armazenamento', () => {
  const arquivo = new URL('../src/api/servidor.ts', import.meta.url).href;
  const r = spawnSync(process.execPath, ['--input-type=module', '-e', `
    Object.defineProperty(globalThis, 'document', { get() { throw new Error('não tocar DOM'); } });
    Object.defineProperty(globalThis, 'localStorage', { get() { throw new Error('não ler armazenamento'); } });
    const api = await import(${JSON.stringify(arquivo)});
    if (!api.adaptador('jellyfin')) throw new Error('sem adaptador');
  `], { encoding: 'utf8' });
  assert.equal(r.status, 0, r.stderr);
  assert.equal(apiDe(s), adaptador('jellyfin'));
  assert.equal(apiDe({ ...s, servidor: 'https://outro.example.invalid' }), apiDe(s));
  assert.notEqual(adaptador('plex'), adaptador('jellyfin'));
  assert.deepEqual(apiDe(s).capacidades(), { favoritos: true, trocarSenha: true, foto: true,
    legendasRemotas: true, capitulos: true, emAlta: true, emBreve: true });
});

function importsDeJellyfin(texto: string): string[] {
  const fonte = ts.createSourceFile('arquivo.tsx', texto, ts.ScriptTarget.Latest, true, ts.ScriptKind.TSX);
  const encontrados: string[] = [];
  const visitar = (n: ts.Node) => {
    let alvo: ts.Node | undefined;
    if (ts.isImportDeclaration(n) || ts.isExportDeclaration(n)) alvo = n.moduleSpecifier;
    if (ts.isCallExpression(n) && n.expression.kind === ts.SyntaxKind.ImportKeyword) alvo = n.arguments[0];
    if (alvo && ts.isStringLiteralLike(alvo) && /(?:^|\/)api\/jellyfin(?:\.ts)?$/.test(alvo.text)) encontrados.push(alvo.text);
    ts.forEachChild(n, visitar);
  };
  visitar(fonte);
  return encontrados;
}

test('fora de src/api nenhum import estático, dinâmico ou reexport alcança Jellyfin', async () => {
  assert.equal(importsDeJellyfin(`import { x } from '../api/jellyfin'; import('../api/jellyfin.ts'); export * from '../api/jellyfin';`).length, 3);
  assert.equal(importsDeJellyfin(`// import('../api/jellyfin')\nconst x = "api/jellyfin";`).length, 0);
  const raiz = new URL('../src/', import.meta.url);
  const falhas: string[] = [];
  for (const caminho of await readdir(raiz, { recursive: true })) {
    if (caminho.startsWith('api/') || !/\.tsx?$/.test(caminho)) continue;
    for (const alvo of importsDeJellyfin(await readFile(new URL(caminho, raiz), 'utf8'))) falhas.push(caminho + ': ' + alvo);
  }
  assert.deepEqual(falhas, []);
});

test('sessões/servidores antigos recebem tipo em todos os caminhos sem perder login', () => {
  const legado = antiga.s;
  const dados = armazenamento({ 'heisuca.sessao': JSON.stringify(legado),
    'heisuca.sessoes': JSON.stringify({ antigo: legado }),
    'heisuca.servidores': JSON.stringify([{ id: 'antigo', url: s.servidor, nome: 'Antigo' }]),
  });
  assert.deepEqual(sessaoAtual(), { ...legado, tipo: 'jellyfin' });
  assert.equal(servidoresSalvos()[0].tipo, 'jellyfin');
  assert.deepEqual(trocarPara('antigo'), { ...legado, tipo: 'jellyfin' });
  assert.equal(sessaoAtual()?.token, legado.token);
  assert.equal(trocarPara('desconhecido'), null);
  assert.equal(dados.has('heisuca.sessao'), true);
  // Uma sessão atual com servidorId é removida também do mapa ao sair.
  dados.set('heisuca.sessao', JSON.stringify({ ...legado, servidorId: 'antigo' }));
  esquecerSessao();
  assert.equal(sessaoAtual(), null);
  assert.equal(trocarPara('antigo'), null);
  assert.equal(servidoresSalvos().length, 1);
});

test('tipo explícito é preservado e armazenamento indisponível não quebra saída/troca', () => {
  armazenamento({ 'heisuca.sessao': JSON.stringify({ ...s, tipo: 'plex' }),
    'heisuca.sessoes': JSON.stringify({ plex: { ...s, tipo: 'plex' } }),
    'heisuca.servidores': JSON.stringify([{ id: 'plex', tipo: 'plex' }]) });
  assert.equal(sessaoAtual()?.tipo, 'plex'); assert.equal(trocarPara('plex')?.tipo, 'plex');
  assert.equal(servidoresSalvos()[0].tipo, 'plex');
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, get() { throw new Error('privado'); } });
  assert.equal(sessaoAtual(), null); assert.equal(trocarPara('antigo'), null);
  assert.deepEqual(servidoresSalvos(), []); assert.doesNotThrow(esquecerSessao);
});

test('catálogo/busca/imagens mantêm as URLs capturadas antes da refatoração', async () => {
  armazenamento({ 'heisuca.aparelho': 'aparelho-ficticio' });
  let url = '';
  const anterior = globalThis.fetch;
  globalThis.fetch = async u => { url = String(u); return new Response(JSON.stringify({ Items: [] })); };
  try {
    const api = apiDe(s);
    await api.item(s, i.Id); assert.equal(url, antiga.urls.item);
    await api.episodios(s, 'serie-opaca', 'temporada-opaca'); assert.equal(url, antiga.urls.episodios);
    await api.buscar(s, 'ação & lua', 'biblioteca-opaca'); assert.equal(url, antiga.urls.buscar);
    assert.equal(api.capa(s, i), antiga.urls.capa); assert.equal(api.fundo(s, i), antiga.urls.fundo);
    assert.equal(api.logo(s, i), antiga.urls.logo);
    assert.equal(api.hashDe(s, i), undefined);
  } finally { globalThis.fetch = anterior; }
});

test('requisição pendente conserva sessão e token de origem durante a troca', async () => {
  armazenamento();
  const anterior = globalThis.fetch;
  const chamadas: { url: string; auth: string }[] = [];
  const respostas: (() => void)[] = [];
  globalThis.fetch = (u, init) => new Promise(resolve => {
    chamadas.push({ url: String(u), auth: (init?.headers as Record<string, string>).Authorization });
    respostas.push(() => resolve(new Response(JSON.stringify(i))));
  });
  try {
    const a = apiDe(s).item(s, i.Id);
    const outra = { ...s, servidor: 'https://outro.example.invalid', token: 'outra-ficticia' };
    const b = apiDe(outra).item(outra, i.Id);
    respostas[1](); respostas[0](); await Promise.all([a, b]);
    assert.ok(chamadas[0].url.startsWith(s.servidor)); assert.ok(chamadas[0].auth.includes(s.token));
    assert.ok(chamadas[1].url.startsWith(outra.servidor)); assert.ok(chamadas[1].auth.includes(outra.token));
  } finally { globalThis.fetch = anterior; }
});

test('401 notifica o contrato comum e rejeita a chamada', async () => {
  armazenamento();
  const anterior = globalThis.fetch; let vezes = 0;
  globalThis.fetch = async () => new Response(null, { status: 401 });
  quandoExpirar(() => { vezes++; });
  try { await assert.rejects(apiDe(s).item(s, i.Id), /sessão vencida/); assert.equal(vezes, 1); }
  finally { quandoExpirar(null); globalThis.fetch = anterior; }
});

test('assistido/favorito não se misturam entre servidores/usuários com o mesmo Id, inclusive em rollback', async () => {
  armazenamento();
  const anterior = globalThis.fetch;
  globalThis.fetch = async () => new Response('{}');
  const a = { ...s, servidorId: 'estado-a' }, b = { ...s, servidorId: 'estado-b' }, c = { ...a, usuarioId: 'outro' };
  const it = { ...i, UserData: { Played: false, IsFavorite: false } };
  try {
    await alternarVisto(a, it); await alternarFavorito(a, it);
    assert.equal(dadosDe(a, it).Played, true); assert.equal(dadosDe(a, it).IsFavorite, true);
    assert.deepEqual(dadosDe(b, it), it.UserData); assert.deepEqual(dadosDe(c, it), it.UserData);
    globalThis.fetch = async () => { throw new Error('rede'); };
    await assert.rejects(alternarFavorito(b, it), /rede/);
    assert.deepEqual(dadosDe(b, it), it.UserData); assert.equal(dadosDe(a, it).IsFavorite, true);
  } finally { globalThis.fetch = anterior; }
});

const opcoes = { inicioTicks: 150_000_000, perfil: { Name: 'Navegador fictício' } };
const fonte = () => ({ ...antiga.f, RunTimeTicks: 900_000_000, DefaultAudioStreamIndex: 1, DefaultSubtitleStreamIndex: 2,
  MediaStreams: [ { Index: 0, Type: 'Video', Codec: 'h264' }, { Index: 1, Type: 'Audio', IsDefault: true },
    { Index: 2, Type: 'Subtitle', Codec: 'vtt', DeliveryMethod: 'External', DeliveryUrl: '/Videos/item-opaco/Subtitles/2/Stream.vtt' },
    { Index: 3, Type: 'Subtitle', Codec: 'ass', DeliveryMethod: 'External', DeliveryUrl: '/Videos/item-opaco/Subtitles/3/Stream.ass?api_key=ja-ficticia' },
    { Index: 4, Type: 'Subtitle', Codec: 'pgssub', DeliveryMethod: 'Encode' },
    { Index: 5, Type: 'Subtitle', Codec: 'vtt', DeliveryMethod: 'Embed' } ],
  MediaAttachments: [{ MimeType: 'font/ttf', DeliveryUrl: '/Videos/item-opaco/Attachments/0?nome=fonte.ttf' },
    { MimeType: 'image/jpeg', DeliveryUrl: '/Videos/item-opaco/Attachments/1' }] });

test('preparar direto mantém URL antiga, perfil, faixas/URLs absolutas e anexos ASS', async () => {
  armazenamento({ 'heisuca.aparelho': 'aparelho-ficticio' });
  const anterior = globalThis.fetch;
  let corpo: Record<string, unknown> = {};
  globalThis.fetch = async (_u, init) => {
    corpo = JSON.parse(String(init?.body));
    return new Response(JSON.stringify({ PlaySessionId: 'sessao-opaca', MediaSources: [fonte()] }));
  };
  try {
    const p = await apiDe(s).preparar(s, i, opcoes);
    assert.equal(p.url, antiga.urls.urlDireta); assert.equal(p.tipo, 'direto'); assert.equal(p.metodo, 'direto');
    assert.equal(p.fonteId, antiga.f.Id); assert.equal(p.container, 'mp4'); assert.equal(p.duracaoTicks, 900_000_000);
    assert.equal(p.inicioAplicado, 0); assert.equal(p.audioPadrao, 1); assert.equal(p.legendaPadrao, 2);
    assert.equal(p.fluxos[2].url, antiga.urls.legenda); assert.deepEqual(p.fontesAss, [antiga.urls.anexo]);
    assert.equal(p.fluxos[2].entrega, 'externa'); assert.equal(p.fluxos[4].entrega, 'gravada');
    assert.equal(p.fluxos[5].entrega, 'embutida');
    assert.ok(p.fluxos[3].url?.endsWith('?api_key=ja-ficticia'));
    assert.equal('DeliveryMethod' in p.fluxos[2], false); assert.equal('DeliveryUrl' in p.fluxos[2], false);
    for (const url of [...p.fluxos.filter(f => f.url).map(f => f.url!), ...p.fontesAss]) assert.equal(new URL(url).origin, s.servidor);
    assert.deepEqual(corpo.DeviceProfile, opcoes.perfil);
    assert.equal(corpo.EnableDirectPlay, true); assert.equal(corpo.EnableDirectStream, true);
    // O Player mantém a política de início: o pedido antigo não enviava StartTimeTicks.
    assert.equal('StartTimeTicks' in corpo, false);
  } finally { globalThis.fetch = anterior; }
});

test('preparar HLS distingue remux/conversão e respeita semDireto e faixas escolhidas', async () => {
  armazenamento(); const anterior = globalThis.fetch;
  const f = { ...fonte(), SupportsDirectPlay: false, TranscodingUrl: '/hls/inicio.m3u8?media=opaca' };
  const pedidos: Record<string, unknown>[] = [];
  globalThis.fetch = async (_u, init) => {
    pedidos.push(JSON.parse(String(init?.body)));
    return new Response(JSON.stringify({ PlaySessionId: 'hls-opaca', MediaSources: [f] }));
  };
  try {
    let p = await apiDe(s).preparar(s, i, opcoes);
    assert.equal(p.tipo, 'hls'); assert.equal(p.metodo, 'remux');
    assert.equal(p.url, `${s.servidor}/hls/inicio.m3u8?media=opaca&api_key=${s.token}`);
    f.SupportsDirectStream = false;
    p = await apiDe(s).preparar(s, i, opcoes); assert.equal(p.metodo, 'conversao');
    f.SupportsDirectPlay = true;
    p = await apiDe(s).preparar(s, i, { ...opcoes, semDireto: true, audio: 3, legenda: -1 });
    assert.equal(p.tipo, 'hls'); assert.equal(pedidos[2].EnableDirectPlay, false);
    assert.equal(pedidos[2].AudioStreamIndex, 3); assert.equal(pedidos[2].SubtitleStreamIndex, -1);
  } finally { globalThis.fetch = anterior; }
});

test('preparar retorna limiteTelas e preserva falhas de fonte/fluxo indisponível', async () => {
  armazenamento(); const anterior = globalThis.fetch;
  let info: unknown = { PlaySessionId: '', MediaSources: [], ErrorCode: 'NotAllowed' };
  globalThis.fetch = async () => new Response(JSON.stringify(info));
  try {
    assert.equal((await apiDe(s).preparar(s, i, opcoes)).erro, 'limiteTelas');
    info = { PlaySessionId: '', MediaSources: [] };
    await assert.rejects(apiDe(s).preparar(s, i, opcoes), /Sem fonte de vídeo/);
    info = { PlaySessionId: '', MediaSources: [{ ...fonte(), SupportsDirectPlay: false }] };
    await assert.rejects(apiDe(s).preparar(s, i, opcoes), /não pode ser tocado/);
  } finally { globalThis.fetch = anterior; }
});

test('faixas relê PlaybackInfo sem trocar o plano/sessão, com legenda nova pronta', async () => {
  armazenamento(); const anterior = globalThis.fetch; let n = 0;
  globalThis.fetch = async () => {
    const f = fonte();
    if (n++) f.MediaStreams.push({ Index: 6, Type: 'Subtitle', Codec: 'vtt', DeliveryMethod: 'External', DeliveryUrl: '/nova.vtt' });
    return new Response(JSON.stringify({ PlaySessionId: `sessao-${n}`, MediaSources: [f] }));
  };
  try {
    const p = await apiDe(s).preparar(s, i, opcoes);
    const novas = await apiDe(s).faixas(s, p, opcoes);
    assert.equal(p.sessaoReproducao, 'sessao-1'); assert.equal(p.fluxos.length, 6);
    assert.equal(novas.length, 7); assert.equal(novas[6].url, `${s.servidor}/nova.vtt?api_key=${s.token}`);
  } finally { globalThis.fetch = anterior; }
});

test('relatos neutros preservam corpo Jellyfin e keepalive no fim/parar', async () => {
  armazenamento({ 'heisuca.aparelho': 'aparelho-ficticio' });
  const anterior = globalThis.fetch;
  const chamadas: { url: string; init?: RequestInit }[] = [];
  globalThis.fetch = async (url, init) => {
    chamadas.push({ url: String(url), init });
    return new Response(JSON.stringify({ PlaySessionId: 'sessao-opaca', MediaSources: [fonte()] }));
  };
  try {
    const api = apiDe(s), p = await api.preparar(s, i, opcoes);
    chamadas.length = 0;
    for (const fase of ['inicio', 'progresso', 'fim'] as const)
      await api.relatar(s, p, fase, { posicaoTicks: 321, pausado: true, audio: 1, legenda: -1, motivo: 'concluido' });
    assert.deepEqual(chamadas.map(c => c.url), ['/Sessions/Playing', '/Sessions/Playing/Progress', '/Sessions/Playing/Stopped'].map(c => s.servidor + c));
    assert.deepEqual(chamadas.map(c => c.init?.keepalive), [false, false, true]);
    assert.deepEqual(JSON.parse(String(chamadas[2].init?.body)), { ItemId: i.Id, MediaSourceId: antiga.f.Id,
      PlaySessionId: 'sessao-opaca', PositionTicks: 321, IsPaused: true, PlayMethod: 'DirectPlay', AudioStreamIndex: 1,
      SubtitleStreamIndex: -1, CanSeek: true });
    await api.parar(s, p);
    assert.equal(chamadas[3].init?.method, 'DELETE'); assert.equal(chamadas[3].init?.keepalive, true);
    assert.equal(chamadas[3].url, `${s.servidor}/Videos/ActiveEncodings?deviceId=aparelho-ficticio&playSessionId=sessao-opaca`);
  } finally { globalThis.fetch = anterior; }
});
