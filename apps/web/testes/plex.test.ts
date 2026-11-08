import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFile, readdir } from 'node:fs/promises';
import ts from 'typescript';
import { adaptador, apiDe, entradaPlex, quandoExpirar } from '../src/api/servidor.ts';
import { sessaoAtual, servidoresSalvos } from '../src/api/contas.ts';
import type { Sessao } from '../src/api/tipos.ts';

const carregar = async (nome: string) => JSON.parse(await readFile(new URL(`./plex-respostas/${nome}.json`, import.meta.url), 'utf8'));
const catalogo = await carregar('catalogo'), secoes = await carregar('secoes'), hubs = await carregar('hubs'), recursos = await carregar('recursos');
const [filme, serie, temporada, episodio, colecao] = catalogo.MediaContainer.Metadata;
const s: Sessao = { tipo: 'plex', servidor: 'https://pms.example.invalid', token: 'token-pms-ficticio',
  usuarioId: 'conta-ficticia', nome: 'Pessoa Fictícia', servidorId: 'servidor-ficticio', fotoTag: 'https://foto.example.invalid/perfil.jpg' };
const api = apiDe(s);
const json = (d: unknown, status = 200) => new Response(JSON.stringify(d), { status });
function guardar() {
  const dados = new Map([['heisuca.aparelho', 'aparelho-ficticio']]);
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: {
    getItem: (k: string) => dados.get(k) ?? null, setItem: (k: string, v: string) => dados.set(k, v), removeItem: (k: string) => dados.delete(k),
  } });
  return dados;
}
type Chamada = { url: URL; init?: RequestInit };
async function comFetch(responder: (c: Chamada) => Response | Promise<Response>, executar: (chamadas: Chamada[]) => unknown) {
  guardar(); const anterior = globalThis.fetch; const chamadas: Chamada[] = [];
  globalThis.fetch = async (u, init) => { const c = { url: new URL(String(u)), init }; chamadas.push(c); return responder(c); };
  try { await executar(chamadas); } finally { globalThis.fetch = anterior; }
}

test('Plex mapeia filme/série/temporada/episódio/coleção, ticks, percentual e campos de mídia', async () => {
  await comFetch(() => json(catalogo), async () => {
    const [f, se, te, ep, co] = await api.porIds(s, ['101','201','202','203','301']);
    assert.deepEqual([f.Type,se.Type,te.Type,ep.Type,co.Type], ['Movie','Series','Season','Episode','BoxSet']);
    assert.equal(f.RunTimeTicks, 1_000_000_000); assert.equal(f.UserData?.PlaybackPositionTicks, 250_000_000);
    assert.equal(f.UserData?.PlayedPercentage, 25); assert.equal(f.UserData?.Played, true); assert.equal(f.UserData?.IsFavorite, false);
    assert.equal(co.UserData?.PlayedPercentage, undefined); assert.equal(se.UserData?.UnplayedItemCount, 7);
    assert.equal(f.CommunityRating, 8.2); assert.equal(f.OfficialRating, 'BR-12'); assert.equal(f.PremiereDate, '2020-01-02');
    assert.deepEqual(f.Genres, ['Drama']); assert.deepEqual(f.Studios, [{ Name:'Estúdio Exemplo' }]);
    assert.equal(f.People?.[0].PrimaryImageTag, '/library/people/901/thumb'); assert.equal(f.Chapters?.[0].StartPositionTicks, 50_000_000);
    assert.deepEqual(f.MediaStreams?.slice(0,3).map(f => f.Type), ['Video','Audio','Subtitle']);
    assert.equal(f.MediaStreams?.[2].Language, 'pt-br'); assert.equal(f.MediaStreams?.[1].IsDefault, true);
    assert.equal(ep.SeriesId, '201'); assert.equal(ep.SeasonId, '202'); assert.equal(ep.SeriesName, 'Série Exemplo');
    assert.equal(ep.SeasonName, 'Temporada 1'); assert.equal(ep.ParentIndexNumber, 1); assert.equal(ep.IndexNumber, 1);
    assert.equal(f.ImageTags?.Primary, filme.thumb); assert.equal(f.ImageTags?.Logo, filme.Image[0].url);
    assert.equal(ep.SeriesPrimaryImageTag, serie.thumb); assert.equal(api.hashDe(s, f), undefined); assert.equal(api.temArte(s, f), true);
    assert.equal(api.fotoUsuario(s), s.fotoTag);
    const imagem = new URL(api.fotoPessoa(s, f.People![0])); assert.equal(imagem.pathname, '/photo/:/transcode');
    assert.equal(imagem.searchParams.get('url'), '/library/people/901/thumb'); assert.equal(imagem.searchParams.get('upscale'), '0');
  });
});

test('Plex usa apenas Accept e identidade/token na query; bibliotecas filtram vídeo e envelopes ausentes são vazios', async () => {
  await comFetch(c => json(c.url.pathname === '/library/sections' ? secoes : {}), async chamadas => {
    assert.deepEqual((await api.bibliotecasDeVideo(s)).map(b => b.CollectionType), ['movies','tvshows']);
    assert.equal((await api.bibliotecas(s)).length, 4);
    assert.deepEqual(await api.continuar(s), []); assert.deepEqual(await api.buscar(s,'lua','1'), []);
    for (const c of chamadas) {
      assert.deepEqual(c.init?.headers, { Accept: 'application/json' }); assert.equal(c.init?.body, undefined);
      assert.equal(c.url.searchParams.get('X-Plex-Token'), s.token);
      for (const k of ['Client-Identifier','Product','Version','Platform','Device']) assert.ok(c.url.searchParams.get('X-Plex-'+k));
    }
    for (const u of [api.capa(s, (await api.porIds(s, []))[0] || { Id:'1',Name:'',Type:'Movie',ImageTags:{Primary:'/capa'} }),
      api.fundo(s, { Id:'1',Name:'',Type:'Movie',BackdropImageTags:['/fundo'] })]) assert.equal(new URL(u).searchParams.get('X-Plex-Token'), s.token);
  });
});

test('Plex capacidades e seleção de adaptador; conta é local e ações não suportadas rejeitam', async () => {
  await comFetch(() => { throw new Error('conta não pode ir à rede'); }, async () => {
    assert.equal(adaptador('plex'), api); assert.notEqual(apiDe({ ...s, tipo:'jellyfin' }), api);
    assert.deepEqual(api.capacidades(), { favoritos:false,trocarSenha:false,foto:false,legendasRemotas:false,capitulos:true,emAlta:false,emBreve:false });
    assert.deepEqual(await api.euMesmo(s), { Id:s.usuarioId,Name:s.nome,PrimaryImageTag:s.fotoTag,Policy:{EnableSubtitleManagement:false} });
    assert.deepEqual(await api.favoritos(s,'1'), { Items:[],TotalRecordCount:0 });
    assert.deepEqual(await api.emAlta(s), { titulo:'',itens:[] }); assert.deepEqual(await api.emBreve(s,'tv'), []);
    await assert.rejects(api.favoritar(s,'1',true), /naoSuportado/); await assert.rejects(api.trocarSenha(s,'',''), /naoSuportado/);
    await assert.rejects(api.trocarFoto(s,new Blob()), /naoSuportado/); await assert.rejects(api.removerFoto(s), /naoSuportado/);
    await assert.rejects(api.buscarLegendas(s,'1','por'), /naoSuportado/); await assert.rejects(api.baixarLegenda(s,'1','x'), /naoSuportado/);
  });
});

test('Plex pagina coleção, temporadas e episódios até o fim e preserva TotalRecordCount', async () => {
  await comFetch(c => {
    if (c.url.pathname.includes('/sections/')) return json({MediaContainer:{Metadata:[filme],size:1,totalSize:8}});
    const inicio = Number(c.url.searchParams.get('X-Plex-Container-Start'));
    return json({MediaContainer:{Metadata:inicio === 0 ? [filme] : [episodio],totalSize:2,size:1}});
  }, async chamadas => {
    assert.equal((await api.daColecao(s,'301')).length,2); assert.equal((await api.temporadas(s,'201')).length,2);
    assert.equal((await api.episodios(s,'201','202')).length,2);
    assert.equal((await api.daBiblioteca(s,'1',4,1)).TotalRecordCount,8);
    assert.ok(chamadas.some(c => c.url.searchParams.get('X-Plex-Container-Start') === '1'));
  });
});

test('Plex agrupa novidades pela série, busca apenas Movie/Series sem duplicata e usa hubs de continuar', async () => {
  await comFetch(c => {
    if (c.url.pathname.endsWith('/recentlyAdded')) return json({MediaContainer:{Metadata:[episodio,temporada,serie]}});
    if (c.url.pathname.startsWith('/library/metadata/')) return json({MediaContainer:{Metadata:[serie]}});
    return json(hubs);
  }, async chamadas => {
    assert.deepEqual((await api.novidades(s,'2')).map(i => [i.Id,i.Type]), [['201','Series']]);
    assert.deepEqual((await api.buscar(s,'ação & lua','2')).map(i => i.Type), ['Movie','Series']);
    assert.equal((await api.continuar(s)).length,3);
    const busca = chamadas.find(c => c.url.pathname === '/hubs/search')!.url;
    assert.equal(busca.searchParams.get('query'),'ação & lua'); assert.equal(busca.searchParams.get('sectionId'),'2'); assert.equal(busca.searchParams.get('limit'),'30');
    assert.ok(chamadas.some(c => c.url.pathname === '/hubs' && c.url.searchParams.get('identifier') === 'home.continue,home.ondeck'));
    assert.ok(!chamadas.some(c => c.url.pathname === '/library/onDeck'));
  });
});

test('Plex recursos só incluem servidor e conexões HTTPS permitidas, na ordem de prioridade', async () => {
  await comFetch(() => json(recursos), async chamadas => {
    const r = await entradaPlex.servidores('token-conta-ficticio');
    assert.equal(r.length,1); assert.deepEqual(r[0].connections.map(c => c.uri), ['https://local.example.invalid','https://remoto.example.invalid','https://relay.example.invalid']);
    assert.equal(chamadas[0].url.searchParams.get('includeHttps'),'1');
    assert.equal(chamadas[0].url.searchParams.get('X-Plex-Token'),'token-conta-ficticio');
  });
});

test('Plex testa todas conexões em paralelo, valida identidade e prefere prioridade à velocidade', async () => {
  const resolutores: (() => void)[] = [];
  await comFetch(c => new Promise(resolve => resolutores.push(() => resolve(json({MediaContainer:{machineIdentifier:c.url.hostname.startsWith('relay') ? 'errado' : 'servidor-ficticio'}})))), async chamadas => {
    const promessa = entradaPlex.escolherConexao(recursos[0]);
    assert.equal(chamadas.length,3);
    resolutores[1](); resolutores[2](); resolutores[0]();
    assert.equal((await promessa).uri,'https://local.example.invalid');
    assert.ok(chamadas.every(c => c.url.searchParams.get('X-Plex-Token') === 'token-pms-ficticio'));
  });
});

test('Plex descarta locais fora da rede e aceita remoto após TLS, identidade/JSON/status inválidos', async () => {
  await comFetch(c => {
    if (c.url.hostname.startsWith('remoto')) throw new TypeError('TLS');
    return json({MediaContainer:{machineIdentifier:'servidor-ficticio'}});
  }, async chamadas => {
    const r = {...recursos[0],publicAddressMatches:false};
    assert.equal((await entradaPlex.escolherConexao(r)).uri,'https://relay.example.invalid');
    assert.equal(chamadas.length,2); assert.ok(chamadas.every(c => !c.url.hostname.startsWith('local')));
  });
  for (const resposta of [json({MediaContainer:{machineIdentifier:'outro'}}),new Response('não JSON'),json({},201)])
    await comFetch(() => resposta.clone(), async () => { await assert.rejects(entradaPlex.escolherConexao(recursos[0]), /não foi possível/i); });
});

test('Plex conexão expira em 4 s e continua pela próxima', async t => {
  t.mock.timers.enable({ apis:['setTimeout'] });
  try {
    await comFetch(c => c.url.hostname.startsWith('local') ? new Promise((_ok, erro) => c.init?.signal?.addEventListener('abort', () => erro(new DOMException('prazo','AbortError')))) : json({MediaContainer:{machineIdentifier:'servidor-ficticio'}}), async () => {
      const p = entradaPlex.escolherConexao(recursos[0]); t.mock.timers.tick(4000);
      assert.equal((await p).uri,'https://remoto.example.invalid');
    });
  } finally { t.mock.timers.reset(); }
});

test('Plex PIN cria via POST, URL de autorização e polling usam code; cancelamento e expiração', async () => {
  await comFetch(c => json(c.url.pathname.endsWith('/pins') ? { id:77,code:'CODIGO-FICTICIO' } : {authToken:'token-conta-ficticio'}), async chamadas => {
    const pin = await entradaPlex.criarPin(); assert.equal(chamadas[0].init?.method,'POST'); assert.equal(chamadas[0].url.searchParams.get('strong'),'true');
    const url = entradaPlex.urlAutorizar(pin); assert.ok(url.startsWith('https://app.plex.tv/auth#?')); assert.ok(url.includes('context%5Bdevice%5D%5Bproduct%5D=Heisuca'));
    assert.equal(await entradaPlex.esperarPin(pin,new AbortController().signal),'token-conta-ficticio');
    assert.equal(chamadas[1].url.searchParams.get('code'),pin.code);
    const cancelado = new AbortController(); cancelado.abort();
    await assert.rejects(entradaPlex.esperarPin(pin,cancelado.signal), {name:'AbortError'});
  });
  for (const status of [404,410]) await comFetch(() => json({},status), async () => {
    await assert.rejects(entradaPlex.esperarPin({id:77,code:'FICTICIO'},new AbortController().signal), /venceu/);
  });
  await comFetch(() => json({}), async chamadas => {
    const controle = new AbortController(); const p = entradaPlex.esperarPin({id:77,code:'FICTICIO'},controle.signal);
    await new Promise(ok => setTimeout(ok,5)); controle.abort();
    await assert.rejects(p, {name:'AbortError'}); assert.equal(chamadas.length,1);
  });
});

test('Plex entrada guarda só token PMS e foto da conta; 401 plex.tv não desloga, 401 PMS desloga', async () => {
  await comFetch(() => json({id:90,title:'Pessoa Fictícia',thumb:s.fotoTag}), async () => {
    const conta = await entradaPlex.conta('token-conta-ficticio');
    const sessao = entradaPlex.entrar(recursos[0], recursos[0].connections[1], conta);
    assert.equal(sessao.token,'token-pms-ficticio'); assert.equal(sessao.servidorId,'servidor-ficticio');
    assert.equal(sessao.usuarioId,'90'); assert.equal(sessao.fotoTag,s.fotoTag); assert.equal(sessaoAtual()?.tipo,'plex');
    assert.equal(servidoresSalvos()[0].tipo,'plex');
    assert.ok(!JSON.stringify(sessaoAtual()).includes('token-conta-ficticio'));
    assert.throws(() => entradaPlex.entrar(recursos[0], {uri:'http://inseguro.example.invalid'}, conta), /não permitida/);
  });
  let expirou = 0; quandoExpirar(() => { expirou++; });
  try {
    await comFetch(() => json({},401), async () => {
      await assert.rejects(entradaPlex.conta('token-conta-ficticio')); assert.equal(expirou,0);
      await assert.rejects(api.item(s,'101')); assert.equal(expirou,1);
    });
  } finally { quandoExpirar(null); }
});

test('Plex não é importado fora de src/api, nem por import dinâmico/reexport', async () => {
  const raiz = new URL('../src/',import.meta.url), falhas: string[] = [];
  for (const caminho of await readdir(raiz,{recursive:true})) {
    if (caminho.startsWith('api/') || !/\.tsx?$/.test(caminho)) continue;
    const fonte = ts.createSourceFile(caminho,await readFile(new URL(caminho,raiz),'utf8'),ts.ScriptTarget.Latest,true);
    const visitar = (n: ts.Node) => {
      const alvo = ts.isImportDeclaration(n) || ts.isExportDeclaration(n) ? n.moduleSpecifier
        : ts.isCallExpression(n) && n.expression.kind === ts.SyntaxKind.ImportKeyword ? n.arguments[0] : undefined;
      if (alvo && ts.isStringLiteralLike(alvo) && /(?:^|\/)(?:plex[^/]*|entrada-plex)(?:\.ts)?$/.test(alvo.text)) falhas.push(caminho);
      ts.forEachChild(n,visitar);
    };
    visitar(fonte);
  }
  assert.deepEqual(falhas,[]);
});

const perfil = { DirectPlayProfiles:[{Type:'Video',Container:'mp4,m4v,webm',VideoCodec:'h264,vp9',AudioCodec:'aac,opus'}] };
const opcoes = { inicioTicks:120_000_000, perfil };
const fetchNativo = globalThis.fetch;
const srt = '\uFEFF1\r\n00:00:01,250 --> 00:00:02,750\r\nOlá, mundo.\r\n\r\n2\r\n00:00:03,000 --> 00:00:05,000\r\n<i>Teste</i>\r\n';

test('Plex prepara direto: perfil, token, índices, SRT blob VTT, ASS/VTT externas e embutida', async () => {
  await comFetch(c => c.url.pathname === '/library/streams/12' ? new Response(srt) : json({MediaContainer:{Metadata:[filme]}}), async chamadas => {
    const p = await api.preparar(s,{Id:'101'},opcoes);
    assert.equal(p.tipo,'direto'); assert.equal(p.metodo,'direto'); assert.equal(p.fonteId,'501'); assert.equal(p.container,'mp4');
    assert.equal(p.inicioAplicado,0); assert.equal(p.duracaoTicks,1_000_000_000); assert.equal(p.audioPadrao,11); assert.equal(p.legendaPadrao,12);
    assert.equal(p.erro,undefined); assert.deepEqual(p.fontesAss,[]);
    assert.equal(new URL(p.url).pathname,'/library/parts/501/arquivo.mp4'); assert.equal(new URL(p.url).searchParams.get('X-Plex-Token'),s.token);
    const l = p.fluxos.find(f => f.Index === 12)!;
    assert.equal(l.entrega,'externa'); assert.ok(l.url?.startsWith('blob:'));
    const vtt = await fetchNativo(l.url!).then(r => r.text());
    assert.equal(vtt,'WEBVTT\n\n1\n00:00:01.250 --> 00:00:02.750\nOlá, mundo.\n\n2\n00:00:03.000 --> 00:00:05.000\n<i>Teste</i>\n');
    for (const n of [13,15]) { const f = p.fluxos.find(f => f.Index === n)!;
      assert.equal(f.entrega,'externa'); assert.equal(new URL(f.url!).searchParams.get('X-Plex-Token'),s.token); }
    assert.equal(p.fluxos.find(f => f.Index === 14)?.entrega,'embutida');
    assert.ok(!p.fluxos.some(f => f.entrega === 'gravada'));
    assert.ok(chamadas.every(c => c.init?.method !== 'PUT' && c.init?.body === undefined));
    assert.ok(chamadas.every(c => Object.keys(c.init?.headers || {}).join(',') === 'Accept'));
    await api.parar(s,p);
    await assert.rejects(fetchNativo(l.url!)); // o encerramento libera a URL blob sem stopped duplicado
  });
});

test('Plex recusa MKV, codecs incompatíveis e semDireto, sem PUT ou transcode', async () => {
  const mkv = {...filme,Media:[{...filme.Media[0],container:'mkv'}]};
  await comFetch(() => json({MediaContainer:{Metadata:[mkv]}}), async chamadas => {
    await assert.rejects(api.preparar(s,{Id:'101'},opcoes), /^Error: naoSuportado$/);
    assert.equal(chamadas.length,1);
  });
  await comFetch(() => json({MediaContainer:{Metadata:[filme]}}), async chamadas => {
    await assert.rejects(api.preparar(s,{Id:'101'},{...opcoes,semDireto:true}), /naoSuportado/);
    await assert.rejects(api.preparar(s,{Id:'101'},{...opcoes,perfil:{DirectPlayProfiles:[{Type:'Video',Container:'mp4',VideoCodec:'hevc',AudioCodec:'aac'}]}}), /naoSuportado/);
    await assert.rejects(api.preparar(s,{Id:'101'},{...opcoes,perfil:{DirectPlayProfiles:[{Type:'Video',Container:'mp4',VideoCodec:'h264',AudioCodec:'flac'}]}}), /naoSuportado/);
    assert.ok(chamadas.every(c => c.url.pathname === '/library/metadata/101' && c.init?.method === 'GET'));
  });
});

test('Plex relê faixas, cria nova sessão por preparar e usa -1 sem legenda escolhida', async () => {
  const m = {...filme,Media:[{...filme.Media[0],Part:[{...filme.Media[0].Part[0],Stream:filme.Media[0].Part[0].Stream.filter((f: {streamType:number}) => f.streamType !== 3)}]}]};
  let leitura = 0;
  await comFetch(c => {
    if (c.url.pathname === '/library/streams/12') return new Response(srt);
    leitura++;
    return json({MediaContainer:{Metadata:leitura > 2 ? [filme] : [m]}});
  }, async () => {
    const a = await api.preparar(s,{Id:'101'},opcoes), b = await api.preparar(s,{Id:'101'},opcoes);
    assert.notEqual(a.sessaoReproducao,b.sessaoReproducao); assert.equal(a.legendaPadrao,-1);
    const faixas = await api.faixas(s,a,opcoes);
    assert.equal(faixas.length,6); await api.parar(s,a); await api.parar(s,b);
  });
});

test('Plex timeline em ms usa POST medido, stopped único com parar e scrobble no concluído', async () => {
  await comFetch(c => c.url.pathname === '/library/streams/12' ? new Response(srt) : json({MediaContainer:{Metadata:[filme]}}), async chamadas => {
    const p = await api.preparar(s,{Id:'101'},opcoes); chamadas.length = 0;
    for (const [fase,pausado] of [['inicio',false],['progresso',true],['fim',false]] as const)
      await api.relatar(s,p,fase,{posicaoTicks:700_000_000,pausado,motivo:fase === 'fim' ? 'concluido' : undefined});
    await api.parar(s,p);
    const timeline = chamadas.filter(c => c.url.pathname === '/:/timeline');
    assert.deepEqual(timeline.map(c => c.url.searchParams.get('state')),['playing','paused','stopped']);
    assert.ok(timeline.every(c => c.init?.method === 'POST' && c.init?.keepalive === true && c.init?.body === undefined));
    assert.equal(timeline[2].url.searchParams.get('time'),'70000'); assert.equal(timeline[2].url.searchParams.get('duration'),'100000');
    assert.equal(timeline[2].url.searchParams.get('key'),'/library/metadata/101');
    assert.equal(timeline[2].url.searchParams.get('ratingKey'),'101'); assert.equal(timeline[2].url.searchParams.get('X-Plex-Session-Identifier'),p.sessaoReproducao);
    assert.equal(chamadas.filter(c => c.url.pathname === '/:/scrobble').length,1);
    assert.ok(chamadas.every(c => c.init?.keepalive && c.url.searchParams.get('X-Plex-Token') === s.token));
    assert.ok(chamadas.every(c => Object.keys(c.init?.headers || {}).join(',') === 'Accept'));
  });
});

test('Plex fim manda scrobble independentemente de falha na timeline; abandono não marca assistido', async () => {
  const p = {itemId:'101',url:'',tipo:'direto' as const,metodo:'direto' as const,sessaoReproducao:'sessao-ficticia',fonteId:'501',duracaoTicks:50000,inicioAplicado:0,fluxos:[],fontesAss:[]};
  await comFetch(() => { throw new TypeError('rede'); }, async chamadas => {
    await assert.doesNotReject(api.relatar(s,p,'fim',{posicaoTicks:50000,pausado:true,motivo:'concluido'}));
    assert.deepEqual(chamadas.map(c => c.url.pathname),['/:/timeline','/:/scrobble']);
    chamadas.length = 0;
    await api.relatar(s,p,'fim',{posicaoTicks:50000,pausado:true,motivo:'abandono'}); await api.parar(s,p);
    assert.deepEqual(chamadas.map(c => c.url.pathname),['/:/timeline']);
  });
});
