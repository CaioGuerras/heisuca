import { test } from 'node:test';
import assert from 'node:assert/strict';
import { bancada, nos, resolver, texto } from './visual7-harness.ts';
import * as controles from '../src/player/controles.ts';
import * as recentes from '../src/dados/buscas-recentes.ts';
import * as ordem from '../src/dados/ordem-biblioteca.ts';
import * as compartilhar from '../src/dados/compartilhar.ts';
import { previaJellyfin } from '../src/api/trickplay.ts';
const s = { tipo: 'jellyfin', servidor: 'https://teste.invalid', usuarioId: 'u', token: 'ficticio', nome: 'Teste' };
const filme = { Id: '1', Name: 'Filme', Type: 'Movie' };
const vazio = () => {};
const guardar = () => {
  const dados = new Map<string, string>();
  Object.defineProperty(globalThis, 'localStorage', { configurable: true, value: {
    getItem: (k: string) => dados.get(k) || null, setItem: (k: string, v: string) => dados.set(k, v), removeItem: (k: string) => dados.delete(k),
  } });
};

function player() {
  const teclas = new Map<string, Function>(), eventos = new Map<string, Set<Function>>();
  const cargas: any[] = [];
  let entrouPip = 0, saiuPip = 0;
  const disparar = (nome: string) => { for (const f of eventos.get(nome) || []) f(); };
  const v = { currentTime: 30, duration: 120, volume: 0.5, muted: false, paused: true, playbackRate: 1, textTracks: [], src: '',
    removeAttribute: vazio, requestPictureInPicture: async () => { entrouPip++; doc.pictureInPictureElement = v; disparar('enterpictureinpicture'); },
    addEventListener: (nome: string, f: Function) => { if (!eventos.has(nome)) eventos.set(nome, new Set()); eventos.get(nome)!.add(f); },
    removeEventListener: (nome: string, f: Function) => eventos.get(nome)?.delete(f),
    play: async () => { v.paused = false; disparar('playing'); }, pause: () => { v.paused = true; disparar('pause'); },
  };
  const doc = { pictureInPictureEnabled: true, pictureInPictureElement: null as any, fullscreenElement: null as any,
    exitPictureInPicture: async () => { saiuPip++; doc.pictureInPictureElement = null; },
    exitFullscreen: async () => { doc.fullscreenElement = null; }, documentElement: { requestFullscreen: async () => { doc.fullscreenElement = {}; } },
    addEventListener: vazio, removeEventListener: vazio,
  };
  const fluxos = [2, 3].map(Index => ({ Index, Type: 'Subtitle', entrega: 'externa', url: `https://teste.invalid/${Index}.vtt` }));
  const b = bancada('../src/telas/Player.tsx', 'Player', {
    '../api/servidor.ts': { item: async () => filme, pode: () => false, parar: async () => {}, relatar: async () => {},
      preparar: async (_s: any, _i: any, o: any) => { cargas.push(o); return { itemId: '1', tipo: 'direto', url: 'https://teste.invalid/video', fluxos, legendaPadrao: -1 }; } },
    '../player/PainelFaixas': { PainelFaixas: () => null }, '../comp/MaisComoEste': { MaisComoEste: () => null },
    '../api/perfil': { perfilDoAparelho: () => ({}) }, '../player/controles.ts': controles,
    '../player/capitulos': { puloEm: () => null }, '../comp/Aviso': { avisar: vazio }, '../rota': { voltar: vazio },
  }, { document: doc, navigator: {}, window: { setTimeout: () => 1 }, setTimeout: () => 1, clearTimeout: vazio, setInterval: () => 1, clearInterval: vazio,
    addEventListener: (nome: string, f: Function) => teclas.set(nome, f), removeEventListener: (nome: string) => teclas.delete(nome) });
  const render = (id = '1') => {
    const a = b.render('Player', { s, id });
    for (const n of nos(a)) if (n.ref) n.ref.current = n.type === 'video' ? v : { focus: vazio };
    return a;
  };
  const tecla = (codigo: number, alvo: any = { tagName: 'BUTTON' }) => {
    let capturada = false;
    teclas.get('keydown')!({ keyCode: codigo, target: alvo, preventDefault: () => { capturada = true; }, stopImmediatePropagation: vazio });
    return capturada;
  };
  const atualizar = async () => { render(); b.efeitos(); await resolver(); render(); b.efeitos(); await resolver(); return render(); };
  const painel = () => {
    nos(render(), 'button').find(n => n.props['aria-label'] === 'Áudio e legendas')!.props.onClick();
    return nos(render()).find(n => n.props.escolherLegenda).props;
  };
  return { b, render, atualizar, tecla, painel, v, doc, disparar, cargas, pip: () => [entrouPip, saiuPip] };
}

test('1–3: player real integra PiP, velocidade e última legenda, preservando atalhos antigos', async () => {
  const p = player(); await p.atualizar();
  assert.ok(nos(p.render(), 'button').some(n => n.props['aria-label'] === 'Imagem no canto'));
  assert.equal(p.tecla(80), true); await resolver(); assert.deepEqual(p.pip(), [1, 0]);
  p.tecla(38); assert.equal(p.v.volume, 0.55); p.tecla(40); assert.equal(p.v.volume, 0.5);
  for (const codigo of [74, 37]) { p.tecla(codigo); assert.equal(p.v.currentTime, 20); p.tecla(codigo === 74 ? 76 : 39); assert.equal(p.v.currentTime, 30); }
  p.tecla(75); assert.equal(p.v.paused, false); p.tecla(32); assert.equal(p.v.paused, true);
  p.tecla(77); assert.equal(p.v.muted, true); p.tecla(70); assert.ok(p.doc.fullscreenElement);
  for (const alvo of [{ tagName: 'INPUT', type: 'text' }, { tagName: 'TEXTAREA' }, { isContentEditable: true }])
    for (const codigo of [38, 40, 67, 74, 76, 80, 32, 37, 39, 70, 75, 77]) assert.equal(p.tecla(codigo, alvo), false);
  p.painel().escolherLegenda(3); await p.atualizar(); p.tecla(67); await p.atualizar();
  let painel = p.painel(); assert.equal(painel.legenda, -1); painel.fechar(); await p.atualizar();
  p.tecla(67); await p.atualizar(); painel = p.painel(); assert.equal(painel.legenda, 3);
  painel.escolherVelocidade(1.5); assert.equal(p.v.playbackRate, 1.5); painel.fechar(); await p.atualizar();
  p.v.playbackRate = 1; p.disparar('ratechange'); assert.equal(p.v.playbackRate, 1.5);
  p.b.desmontar(); await resolver(); assert.deepEqual(p.pip(), [1, 1]);
});

test('2 e 5: vídeo novo reinicia velocidade; repetir filme prepara nova sessão desde zero', async () => {
  const p = player(); await p.atualizar(); p.painel().escolherVelocidade(2);
  p.render('2'); p.b.efeitos(); await resolver(); assert.equal(p.v.playbackRate, 1);
  await p.atualizar(); p.v.paused = true; p.disparar('ended');
  const a = p.render(); assert.match(texto(a), /Voltar ao títuloAssistir de novo/);
  assert.equal(nos(a).find(n => n.props.limite === 6).props.id, '1');
  const antes = p.cargas.length;
  nos(a, 'button').find(n => texto(n) === 'Assistir de novo')!.props.onClick();
  await resolver(); assert.equal(p.cargas.length, antes + 1); assert.equal(p.cargas[p.cargas.length - 1].inicioTicks, 0);
  assert.doesNotMatch(texto(p.render()), /Assistir de novo/); p.b.desmontar();
});

test('4: barra real não pede prévia antes do ponteiro; recorta e reduz imagem; sai sem novos pedidos', () => {
  let chamadas = 0;
  const it = { ...filme, Trickplay: { fonte: { '320': { Width: 320, Height: 180, TileWidth: 4, TileHeight: 2, Interval: 1000, ThumbnailCount: 20 } } } };
  const b = bancada('../src/player/PreviaBarra.tsx', 'PreviaBarra', {
    '../api/servidor.ts': { previaImagem: (...a: any[]) => { chamadas++; return previaJellyfin(a[0], a[1], a[2]); } },
    '../comp/Cartoes': { relogio: (n: number) => String(n) },
  });
  let pos = 0;
  const render = () => b.render('PreviaBarra', { s, it, pos: 0, dur: 10, buscar: (n: number) => { pos = n; } });
  let a = render(); assert.equal(chamadas, 0); assert.equal(nos(a, 'img').length, 0);
  nos(a, 'input')[0].props.onPointerEnter({ pointerType: 'mouse', clientX: 50, currentTarget: { getBoundingClientRect: () => ({ left: 0, width: 100 }) } });
  a = render(); assert.equal(chamadas, 1);
  const imagem = nos(a, 'div').find(n => n.props.class === 'player-previa-imagem');
  assert.equal(imagem.props.style.backgroundPosition, '-160px -90px'); assert.equal(imagem.props.style.backgroundSize, '640px 180px');
  nos(a, 'input')[0].props.onInput({ currentTarget: { value: '8' } }); assert.equal(pos, 8);
  nos(a, 'input')[0].props.onPointerLeave(); a = render(); assert.equal(nos(a, 'img').length, 0); assert.equal(chamadas, 1);
});

test('6: recomendações reais excluem o próprio título, limitam seis e descartam resposta após sair', async () => {
  let concluir!: (itens: any[]) => void;
  const b = bancada('../src/comp/MaisComoEste.tsx', 'MaisComoEste', { './Cartoes': { CartaoPoster: () => null }, './Fileira': { Fileira: () => null }, '../api/servidor.ts': {
    pode: () => true, similares: () => new Promise(r => { concluir = r; }),
  } });
  const render = (id = '1') => b.render('MaisComoEste', { s, id, limite: 6 });
  render(); b.efeitos(); concluir([filme, ...Array.from({ length: 12 }, (_, n) => ({ ...filme, Id: String(n + 2) }))]);
  await resolver(); assert.equal(nos(render()).filter(n => n.props.i).length, 6);
  render('outro'); b.efeitos(); b.desmontar(); concluir([filme]); await resolver(); assert.equal(render('outro'), null);
});

test('7: botões reais abrem trailer local no player, protegem remoto e copiam o link do título', async () => {
  let abriu = '', copiou = ''; const avisos: string[] = [];
  const b = bancada('../src/telas/Titulo.tsx', 'Botoes', {
    '../api/servidor.ts': { pode: (_s: any, c: string) => c === 'trailersLocais', trailers: async () => [{ ...filme, Id: 'trailer' }] },
    '../estado/usuario': { useDados: () => ({}) }, '../dados/compartilhar.ts': compartilhar,
    '../rota': { irVer: (id: string) => { abriu = id; } }, '../comp/Aviso': { avisar: (t: string) => avisos.push(t) },
  }, { navigator: { clipboard: { writeText: async (t: string) => { copiou = t; } } }, URL, location: { href: 'https://site.invalid/app/#/t/1' } });
  let a = b.render('Botoes', { s, it: { ...filme, LocalTrailerCount: 1 } });
  await nos(a, 'button').find(n => texto(n) === 'Trailer')!.props.onClick(); assert.equal(abriu, 'trailer');
  await nos(a, 'button').find(n => texto(n) === 'Compartilhar')!.props.onClick(); assert.equal(copiou, 'https://site.invalid/app/#/t/1'); assert.deepEqual(avisos, ['Link copiado']);
  a = b.render('Botoes', { s, it: { ...filme, RemoteTrailers: [{ Url: 'https://exemplo.invalid/trailer' }] } });
  const link = nos(a, 'a')[0]; assert.equal(link.props.target, '_blank'); assert.equal(link.props.rel, 'noopener');
});

test('8: controles reais persistem por biblioteca e remontam a grade para reiniciar paginação', () => {
  guardar(); const b = bancada('../src/telas/Biblioteca.tsx', 'Acervo', { '../dados/ordem-biblioteca.ts': ordem });
  const render = () => b.render('Acervo', { s, bid: 'b', aoTotal: vazio });
  let a = render(); const gradeInicial = nos(a).find(n => n.props.escolha); assert.equal(gradeInicial.props.escolha.ordem, 'nome');
  nos(a, 'button').find(n => texto(n) === 'Só não vistos')!.props.onClick(); a = render();
  let grade = nos(a).find(n => n.props.escolha); assert.equal(grade.props.escolha.naoVistos, true); assert.notEqual(grade.key, gradeInicial.key);
  nos(a, 'button').find(n => texto(n) === 'Nota')!.props.onClick(); a = render(); grade = nos(a).find(n => n.props.escolha);
  assert.equal(grade.props.escolha.ordem, 'nota'); assert.equal(ordem.lerOrdem('jellyfin:https://teste.invalid:u:b').ordem, 'nota');
});

test('9: recentes reais repetem a busca, removem texto e não registram apenas ao digitar', () => {
  guardar(); recentes.registrarBusca('Lua'); recentes.registrarBusca('Sol');
  const b = bancada('../src/telas/Busca.tsx', 'Busca', {
    '../dados/buscas-recentes.ts': recentes, '../cor/paleta': { usePaleta: vazio }, './busca-progressiva.ts': { buscaInicial: { itens: null } },
  });
  const render = () => b.render('Busca', { s });
  let a = render(); assert.match(texto(a), /Buscas recentes/); assert.match(texto(a), /SolLua/);
  nos(a, 'button').find(n => n.props['aria-label'] === 'Remover busca Sol')!.props.onClick(); a = render(); assert.deepEqual(recentes.lerBuscas(), ['Lua']);
  nos(a, 'button').find(n => texto(n) === 'Lua')!.props.onClick(); a = render(); assert.equal(nos(a, 'input')[0].props.value, 'Lua'); assert.deepEqual(recentes.lerBuscas(), ['Lua']);
});

test('8: grade real mantém escolha nas páginas seguintes e ignora resposta depois de desmontar', async () => {
  let concluir!: (d: any) => void;
  const chamadas: any[] = [], totais: number[] = [];
  let observador: any;
  class Observador {
    f: Function;
    constructor(f: Function) { this.f = f; observador = this; }
    observe() {} disconnect() {}
  }
  const b = bancada('../src/telas/Biblioteca.tsx', 'Grade', {
    '../api/servidor.ts': { hashDe: () => '', daBiblioteca: (...args: any[]) => { chamadas.push(args); return new Promise(r => { concluir = r; }); } },
    '../cor/paleta': { usePaleta: vazio, fundoDesfocado: () => '' },
    '../comp/Cartoes': { CartaoPoster: () => null, EsqueletoCartoes: () => null },
  }, { IntersectionObserver: Observador });
  const escolha = { ordem: 'nota', naoVistos: true };
  const render = () => {
    const a = b.render('Grade', { s, bid: 'b', escolha, aoTotal: (n: number) => totais.push(n) });
    for (const n of nos(a)) if (n.ref) n.ref.current = {};
    return a;
  };
  render(); b.efeitos();
  assert.equal(chamadas.length, 1);
  assert.equal(nos(render(), 'div').find(n => n.props.class === 'biblioteca-grade')!.props['aria-busy'], true);
  concluir({ Items: Array.from({ length: 60 }, (_, n) => ({ ...filme, Id: String(n) })), TotalRecordCount: 120 });
  await resolver(); render(); b.efeitos(); observador.f([{ isIntersecting: true }]);
  assert.equal(chamadas.length, 2); assert.equal(chamadas[1][2], 60); assert.equal(chamadas[1][4], escolha);
  const antes = totais.length; b.desmontar(); concluir({ Items: [filme], TotalRecordCount: 121 });
  await resolver(); assert.equal(totais.length, antes);
});
