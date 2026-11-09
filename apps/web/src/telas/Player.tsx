import { useEffect, useRef, useState } from 'preact/hooks';
import './player.css';
import type Hls from 'hls.js/light';
import {
  anterior, baixarLegenda, buscarLegendas, euMesmo, preparar, faixas, item, paisagem, parar, pode, relatar, seguinte,
  type FluxoPlano, type Plano, type Item, type LegendaRemota, type PosicaoRelato, type Sessao,
} from '../api/servidor.ts';
import { hlsNativo, marcarMkvFalhou, perfilDoAparelho } from '../api/perfil';
import { avisarErro } from '../aviso';
import { avisar } from '../comp/Aviso';
import { Icone } from '../comp/Icone';
import { Carregando } from '../player/Carregando';
import { puloEm, textoDoPulo } from '../player/capitulos';
import { PainelFaixas } from '../player/PainelFaixas';
import { MaisComoEste } from '../comp/MaisComoEste';
import { PreviaBarra } from '../player/PreviaBarra';
import { acaoDaTecla, ajustarVolume, alternarPip, sairDoPip, aplicarVelocidade, campoDeTexto } from '../player/controles.ts';
import { voltar } from '../rota';

// fim do episódio: passa sozinho para o próximo depois desta contagem (Caio 19/10 noite, dúvida 19)
const CONTAGEM = 10;

type Carga = { audio?: number; legenda?: number; ticks?: number; semDireto?: boolean };
type Estado = { plano: Plano; audio?: number; legenda: number; url: string; hls: boolean };

const TICKS = 10_000_000;
const relogio = (seg: number) => {
  if (!Number.isFinite(seg) || seg < 0) seg = 0;
  const h = Math.floor(seg / 3600), m = Math.floor(seg / 60) % 60, s = Math.floor(seg % 60);
  return (h ? `${h}:${String(m).padStart(2, '0')}` : String(m)) + `:${String(s).padStart(2, '0')}`;
};
const eAss = (f?: FluxoPlano) => !!f && (f.Codec === 'ass' || f.Codec === 'ssa');
const nomeFluxo = (f: FluxoPlano) => f.DisplayTitle || f.Title || f.Language || `Faixa ${f.Index}`;
// faixa de áudio que o navegador toca por conta própria (a padrão do arquivo, senão a primeira)
const audioDoArquivo = (plano: Plano) => {
  const a = plano.fluxos.filter(x => x.Type === 'Audio');
  return (a.find(x => x.IsDefault) || a[0])?.Index;
};
// teclas de controle remoto (Tizen/webOS) além do teclado
const VOLTAR = new Set([8, 27, 461, 10009]), PLAY_PAUSA = new Set([13, 32, 179, 10252]), PLAY = new Set([415]), PAUSA = new Set([19]);
const AVANCAR = new Set([39, 417]), RECUAR = new Set([37, 412]);

export function Player({ s, id, inicio }: { s: Sessao; id: string; inicio?: number }) {
  const video = useRef<HTMLVideoElement>(null);
  const hls = useRef<Hls | null>(null);
  const est = useRef<Estado | null>(null);
  const iniciou = useRef(false);
  const [e, setE] = useState<Estado | null>(null);
  const [it, setIt] = useState<Item | null>(null);
  const [tocando, setTocando] = useState(false);
  const [pos, setPos] = useState(0);
  const [dur, setDur] = useState(0);
  const [visivel, setVisivel] = useState(true);
  const [menu, setMenu] = useState(false);
  const [espera, setEspera] = useState(true);
  const [erro, setErro] = useState('');
  const [prox, setProx] = useState<Item | null>(null);
  const [fim, setFim] = useState(false);
  const [ant, setAnt] = useState<Item | null>(null);
  const [podeBuscar, setPodeBuscar] = useState(false);
  const [cheia, setCheia] = useState(false);
  const [conta, setConta] = useState<number | null>(null);
  const [volume, setVolume] = useState({ nivel: 1, mudo: false });
  const [velocidade, setVelocidade] = useState(1);
  const velocidadeAtual = useRef(1);
  const ultimaLegenda = useRef<number | null>(null);
  const [pip, setPip] = useState(false);
  const fimBotao = useRef<HTMLButtonElement>(null);
  const esconder = useRef<number>(0);
  const playBtn = useRef<HTMLButtonElement>(null);
  const toque = useRef({ tipo: 'mouse', visivel: true });

  const relato = (): PosicaoRelato | null => {
    const x = est.current, v = video.current;
    if (!x || !v) return null;
    return { posicaoTicks: Math.round(v.currentTime * TICKS), pausado: v.paused, audio: x.audio, legenda: x.legenda };
  };

  const reportar = (fase: 'inicio' | 'progresso' | 'fim', r: PosicaoRelato) => {
    const x = est.current;
    if (x) return relatar(s, x.plano, fase, r);
  };

  function encerrar() {
    const r = relato(), x = est.current;
    if (r && iniciou.current) reportar('fim', { ...r, motivo: 'abandono' });
    // Sempre: o adaptador decide (Jellyfin encerra o HLS; Plex libera os blobs de legenda, mesmo sem ter tocado — J9-09).
    if (x) parar(s, x.plano).catch(() => undefined);
    iniciou.current = false;
    hls.current?.destroy(); hls.current = null;
  }

  const opcoes = (o: Carga) => ({
    inicioTicks: o.ticks || 0, audio: o.audio, legenda: o.legenda, semDireto: o.semDireto, perfil: perfilDoAparelho(),
  });
  const conferirPlano = (p: Plano) => {
    if (p.erro === 'limiteTelas') throw new Error('Sua conta já está usando todas as telas. Feche o vídeo em outro aparelho e tente de novo.');
    return p;
  };

  async function carregar(c: Carga) {
    setEspera(true); setErro('');
    try {
      let plano = conferirPlano(await preparar(s, { Id: id }, opcoes(c)));
      let audio = c.audio ?? plano.audioPadrao;
      const legenda = c.legenda ?? plano.legendaPadrao ?? -1;
      // o navegador não troca a faixa de áudio sozinho: se a escolhida não é a do arquivo, o servidor remonta (HLS)
      const audios = plano.fluxos.filter(x => x.Type === 'Audio').length;
      if (plano.tipo === 'direto' && !c.semDireto && audios > 1 && audio !== undefined && audio !== audioDoArquivo(plano)) {
        const descartado = plano;
        plano = conferirPlano(await preparar(s, { Id: id }, opcoes({ ...c, audio, legenda, semDireto: true })));
        parar(s, descartado).catch(() => undefined);
        c = { ...c, semDireto: true };
      }
      audio = c.audio ?? plano.audioPadrao ?? audio;
      if (legenda !== -1) ultimaLegenda.current = legenda;
      const x: Estado = { plano, audio, legenda, url: plano.url, hls: plano.tipo === 'hls' };
      encerrar();
      est.current = x; setE(x);
      await ligar(x, (c.ticks || 0) / TICKS);
    } catch (err) { setEspera(false); setErro(err instanceof Error ? err.message : String(err)); }
  }

  async function ligar(x: Estado, seg: number) {
    const v = video.current!;
    v.removeAttribute('src');
    aplicarVelocidade(v, velocidadeAtual.current);
    const comecar = () => { aplicarVelocidade(v, velocidadeAtual.current); if (seg > 0) v.currentTime = seg; v.play().catch(() => setTocando(false)); };
    if (x.hls) {
      const { default: H } = await import('hls.js/light');
      if (H.isSupported()) {
        const h = new H({
          startPosition: seg > 0 ? seg : -1,
          // partida rápida: não baixa um pedaço só para medir a banda antes de começar
          testBandwidth: false,
          // estimativa inicial de banda (20 Mb/s): servidor caseiro com banda folgada; o ABR corrige após os 1os pedaços
          abrEwmaDefaultEstimate: 20_000_000,
          // nível inicial automático, escolhido pela estimativa acima (o Jellyfin costuma mandar um nível só)
          startLevel: -1,
          // já pede o 1º pedaço enquanto o <video> ainda prepara o MediaSource
          startFragPrefetch: true,
          // buffer limitado (medido: sem teto chegava a 193 MB em 20 s)
          maxBufferLength: 30, maxMaxBufferLength: 60, maxBufferSize: 60 * 1000 * 1000, backBufferLength: 30,
        });
        hls.current = h;
        h.on(H.Events.ERROR, (_ev, d) => {
          if (!d.fatal) return;
          if (d.type === H.ErrorTypes.NETWORK_ERROR) h.startLoad();
          else if (d.type === H.ErrorTypes.MEDIA_ERROR) h.recoverMediaError();
          else setErro(`Falha no vídeo (${d.details}).`);
        });
        h.loadSource(x.url); h.attachMedia(v);
        h.on(H.Events.MANIFEST_PARSED, () => v.play().catch(() => setTocando(false)));
        return;
      }
      if (!hlsNativo()) throw new Error('Este navegador não toca HLS.');
    }
    v.src = x.url;
    v.addEventListener('loadedmetadata', comecar, { once: true });
  }

  // abre: dados do item (título no topo, próximo episódio) e a primeira carga
  useEffect(() => {
    velocidadeAtual.current = 1; setVelocidade(1); aplicarVelocidade(video.current, 1);
    ultimaLegenda.current = null;
    item(s, id).then(i => {
      setIt(i);
      if (i.Type === 'Episode' && i.SeriesId) {
        seguinte(s, i).then(setProx).catch(() => undefined);
        anterior(s, i).then(setAnt).catch(() => undefined);
      }
    }).catch(() => undefined);
    // "Buscar legendas…" só para quem pode gerenciar legendas no servidor (PLANO §13)
    if (pode(s, 'legendasRemotas')) euMesmo(s).then(u => setPodeBuscar(!!u.Policy?.EnableSubtitleManagement)).catch(() => undefined);
    carregar({ ticks: inicio });
    const sair = () => { void sairDoPip(document, video.current).catch(() => undefined); encerrar(); };
    addEventListener('pagehide', sair);
    const v = video.current;
    return () => { removeEventListener('pagehide', sair); clearTimeout(esconder.current); void sairDoPip(document, v).catch(() => undefined); encerrar(); };
  }, [id]);

  // progresso a cada 10 s enquanto toca
  useEffect(() => {
    const t = setInterval(() => { const r = relato(); if (r && iniciou.current && !r.pausado) reportar('progresso', r); }, 10_000);
    return () => clearInterval(t);
  }, [id]);

  // eventos do <video>
  useEffect(() => {
    const v = video.current!;
    const ev: Record<string, () => void> = {
      ratechange: () => aplicarVelocidade(v, velocidadeAtual.current),
      enterpictureinpicture: () => setPip(true),
      leavepictureinpicture: () => setPip(false),
      playing: () => {
        setEspera(false); setTocando(true); setFim(false);
        const r = relato(); if (!r) return;
        if (!iniciou.current) { iniciou.current = true; reportar('inicio', r); } else reportar('progresso', r);
      },
      pause: () => { setTocando(false); const r = relato(); if (r && iniciou.current) reportar('progresso', r); },
      waiting: () => setEspera(true),
      canplay: () => setEspera(false),
      timeupdate: () => setPos(v.currentTime),
      durationchange: () => setDur(v.duration),
      volumechange: () => setVolume({ nivel: v.volume, mudo: v.muted }),
      seeked: () => { const r = relato(); if (r && iniciou.current) reportar('progresso', r); },
      ended: () => { const r = relato(); if (r) reportar('fim', { ...r, motivo: 'concluido' }); iniciou.current = false; setTocando(false); setEspera(false); setFim(true); setVisivel(true); },
      error: () => {
        // tocar direto falhou (codec que o navegador disse aceitar e não aceita): tenta pelo servidor
        const x = est.current;
        if (!v.error || (x && !x.hls && v.currentSrc !== x.url)) return; // erro velho da fonte anterior
        if (x && !x.hls) carregar({ audio: x.audio, legenda: x.legenda, ticks: Math.round(v.currentTime * TICKS), semDireto: true });
        else setErro('O vídeo não abriu.');
      },
    };
    for (const k in ev) v.addEventListener(k, ev[k]);
    return () => { for (const k in ev) v.removeEventListener(k, ev[k]); };
  }, []);

  // tocar direto pode abrir o arquivo e tocar só o áudio, sem erro (MKV no Chrome do Android, 18/10): 3 s tocando sem
  // nenhum quadro de vídeo = vai pelo servidor (remonta em HLS, sem converter o vídeo) a partir do mesmo ponto
  useEffect(() => {
    const v = video.current;
    if (!v || !e || e.hls || !e.plano.fluxos.some(x => x.Type === 'Video')) return;
    let t = 0;
    const conferir = () => {
      clearTimeout(t);
      t = window.setTimeout(() => {
        if (v.paused || est.current !== e) return;
        const quadros = v.getVideoPlaybackQuality?.().totalVideoFrames;
        if (v.videoWidth > 0 && quadros !== 0) return;
        const codec = e.plano.fluxos.find(x => x.Type === 'Video')?.Codec;
        avisarErro(`sem quadro no direto: ${e.plano.container}/${codec} largura=${v.videoWidth} quadros=${quadros} ${navigator.userAgent}`);
        if (e.plano.container === 'mkv') marcarMkvFalhou();
        carregar({ audio: e.audio, legenda: e.legenda, ticks: Math.round(v.currentTime * TICKS), semDireto: true });
      }, 3000);
    };
    v.addEventListener('playing', conferir);
    return () => { clearTimeout(t); v.removeEventListener('playing', conferir); };
  }, [e]);

  // legendas de texto: <track> por fora; liga só a escolhida
  useEffect(() => {
    const v = video.current;
    if (!v || !e) return;
    const ligarFaixa = () => { for (const t of Array.from(v.textTracks)) t.mode = t.id === `l${e.legenda}` ? 'showing' : 'disabled'; };
    ligarFaixa();
    v.addEventListener('loadedmetadata', ligarFaixa);
    return () => v.removeEventListener('loadedmetadata', ligarFaixa);
  }, [e]);

  // legenda ASS: desenhada pelo JASSUB (wasm de ~2 MB, carregado só aqui) com as fontes anexadas ao arquivo
  useEffect(() => {
    const v = video.current;
    const l = e?.plano.fluxos.find(x => x.Index === e.legenda);
    if (!v || !e || !eAss(l) || l!.entrega !== 'externa' || !l!.url) return;
    let fim = false, r: { destroy(): Promise<void> } | null = null;
    const fontes = e.plano.fontesAss;
    import('jassub').then(({ default: J }) => {
      if (fim) return;
      r = new J({ video: v, subUrl: l!.url!, fonts: fontes, maxRenderHeight: 1080 });
    }); // falha aqui vira unhandledrejection e cai no log do nginx (main.tsx)
    return () => { fim = true; r?.destroy().catch(() => undefined); };
  }, [e]);

  // ---- interface (PLANO §13; desenho: vidhub/…foto46–49, painel: app_completo/…foto25) ----

  // controles somem sozinhos enquanto toca (o cursor some junto: .player.oculto)
  function mexeu() {
    setVisivel(true);
    clearTimeout(esconder.current);
    esconder.current = window.setTimeout(() => { if (!video.current?.paused && !menu) setVisivel(false); }, 3500);
  }
  useEffect(() => { mexeu(); }, [tocando, menu]);
  useEffect(() => { if (visivel && !menu) playBtn.current?.focus({ preventScroll: true }); }, [visivel === true && !menu]);
  useEffect(() => {
    const f = () => setCheia(!!document.fullscreenElement);
    // iPhone: a tela cheia é a do próprio <video> (webkitEnterFullscreen), com eventos próprios
    const v = video.current, entra = () => setCheia(true), sai = () => setCheia(false);
    document.addEventListener('fullscreenchange', f);
    v?.addEventListener('webkitbeginfullscreen', entra); v?.addEventListener('webkitendfullscreen', sai);
    return () => { document.removeEventListener('fullscreenchange', f); v?.removeEventListener('webkitbeginfullscreen', entra); v?.removeEventListener('webkitendfullscreen', sai); };
  }, []);

  const alternar = () => { const v = video.current!; v.paused ? v.play() : v.pause(); };
  const pular = (seg: number) => { const v = video.current!; v.currentTime = Math.max(0, Math.min(v.duration || 0, v.currentTime + seg)); };
  const mudo = () => { const v = video.current!; v.muted = !v.muted; avisar(v.muted ? 'Som desligado' : 'Som ligado'); };
  // outro episódio: troca a rota sem empilhar (Voltar continua levando ao título; o Player remonta e encerra o anterior)
  const trocar = (ep: Item) => location.replace(`#/ver/${ep.Id}`);
  // contagem do fim do episódio: começa quando o vídeo acaba e há próximo; "Cancelar" para e deixa o cartão com Assistir
  useEffect(() => { setConta(fim && prox ? CONTAGEM : null); }, [fim, prox]);
  useEffect(() => {
    if (conta === null || !prox) return;
    if (conta <= 0) { trocar(prox); return; }
    const t = setTimeout(() => setConta(c => (c === null ? null : c - 1)), 1000);
    return () => clearTimeout(t);
  }, [conta]);
  // volume (só no computador; no celular o volume é o do aparelho e a barra some pelo CSS)
  const mudarVolume = (n: number) => { const v = video.current!; v.volume = n; v.muted = n === 0; };
  const imagemNoCanto = () => { void alternarPip(document, video.current).catch(() => avisar('Não deu para abrir a imagem no canto.')); };
  const mudarVelocidade = (n: number) => { velocidadeAtual.current = n; setVelocidade(n); aplicarVelocidade(video.current, n); };
  useEffect(() => { if (fim && it?.Type === 'Movie') fimBotao.current?.focus(); }, [fim, it]);
  const tela = () => {
    const el = document.documentElement as HTMLElement & { webkitRequestFullscreen?: () => void };
    const v = video.current as HTMLVideoElement & { webkitEnterFullscreen?: () => void };
    if (document.fullscreenElement) document.exitFullscreen();
    else if (el.requestFullscreen) el.requestFullscreen().catch(() => undefined);
    else v.webkitEnterFullscreen?.();
  };

  // Teclado: espaço/K tocar e pausar, ←/→ e J/L 10 s, ↑/↓ volume, C legenda, P imagem no canto, F tela cheia, M mudo.
  // Esc sai da tela
  // cheia ou volta. Com o painel aberto, só o Esc/Voltar (fecha o painel); o resto é do painel.
  useEffect(() => {
    const f = (ev: KeyboardEvent) => {
      if (ev.ctrlKey || ev.metaKey || ev.altKey) return;
      const k = ev.keyCode, alvo = ev.target as HTMLElement;
      if (campoDeTexto(alvo)) return;
      const pare = () => { ev.preventDefault(); ev.stopImmediatePropagation(); };
      if (VOLTAR.has(k)) {
        pare();
        if (menu) setMenu(false);
        else if (document.fullscreenElement) document.exitFullscreen();
        else voltar();
        return;
      }
      if (menu) return;
      const acao = acaoDaTecla(k, alvo);
      if (acao === 'volumeMais' || acao === 'volumeMenos') {
        const v = video.current!;
        mudarVolume(ajustarVolume(v.muted ? 0 : v.volume, acao === 'volumeMais' ? 1 : -1));
      }
      else if (acao === 'legenda') {
        const atual = est.current;
        if (atual) escolherLegenda(atual.legenda !== -1 ? -1 : (ultimaLegenda.current ?? legendas[0]?.Index ?? -1));
      }
      else if (acao === 'recuar') pular(-10);
      else if (acao === 'avancar') pular(10);
      else if (acao === 'pip') imagemNoCanto();
      else if (PLAY.has(k)) video.current?.play();
      else if (PAUSA.has(k)) video.current?.pause();
      else if (k === 13) { if (visivel) { mexeu(); return; } alternar(); }   // Enter num botão segue o normal; escondido, OK pausa
      else if (PLAY_PAUSA.has(k) || k === 75) alternar();
      else if (k === 417) pular(30);
      else if (AVANCAR.has(k)) pular(10);
      else if (RECUAR.has(k)) pular(-10);
      else if (k === 70) tela();
      else if (k === 77) mudo();
      else { mexeu(); return; }                       // Tab, Enter num botão etc.: segue o normal e mostra os controles
      pare(); mexeu();
    };
    addEventListener('keydown', f, true);
    return () => removeEventListener('keydown', f, true);
  }, [visivel, menu, e]);

  const plano = e?.plano;
  const audios = plano?.fluxos.filter(x => x.Type === 'Audio') || [];
  const legendas = plano?.fluxos.filter(x => x.Type === 'Subtitle') || [];
  // texto simples vira <track>; ASS vai para o JASSUB (efeito acima)
  const externas = legendas.filter(x => x.entrega === 'externa' && x.url && !eAss(x));
  const posTicks = () => Math.round((video.current?.currentTime || 0) * TICKS);
  function escolherAudio(i: number) { setMenu(false); if (e && i !== e.audio) carregar({ audio: i, legenda: e.legenda, ticks: posTicks() }); }
  function escolherLegenda(i: number) {
    setMenu(false);
    if (!e || i === e.legenda) return;
    if (i !== -1) ultimaLegenda.current = i;
    const nova = legendas.find(x => x.Index === i);
    const atualGravada = legendas.find(x => x.Index === e.legenda)?.entrega === 'gravada';
    // texto por fora troca na hora; legenda gravada no vídeo (ou sair dela) pede nova carga
    if (!atualGravada && (i === -1 || (nova?.entrega === 'externa' && nova.url))) {
      const x = { ...e, legenda: i }; est.current = x; setE(x);
    } else carregar({ audio: e.audio, legenda: i, ticks: posTicks() });
  }

  // Buscar legendas: baixa no servidor, pede a lista de novo (PlaybackInfo) e liga a faixa que apareceu
  async function baixarRemota(r: LegendaRemota) {
    const x = est.current;
    if (!x) return;
    await baixarLegenda(s, id, r.Id);
    const antes = new Set(x.plano.fluxos.filter(f => f.Type === 'Subtitle').map(f => f.Index));
    const lista = await faixas(s, x.plano, opcoes({ audio: x.audio, legenda: x.legenda, semDireto: x.hls }));
    const nova = lista.filter(f => f.Type === 'Subtitle' && !antes.has(f.Index)).pop();
    setMenu(false);
    const atual = est.current;
    if (!atual) return;
    if (!nova) {
      // a mesma legenda baixada de novo (o servidor só substitui o arquivo): nada novo para ligar
      avisar('Essa legenda já estava na lista');
      return;
    }
    ultimaLegenda.current = nova.Index;
    avisar('Legenda baixada e ligada');
    const atualGravada = atual.plano.fluxos.find(f => f.Index === atual.legenda)?.entrega === 'gravada';
    if (!atualGravada && nova.entrega === 'externa' && nova.url && !eAss(nova)) {
      // texto por fora: entra como <track> sem recarregar o vídeo
      const y = { ...atual, plano: { ...atual.plano, fluxos: lista }, legenda: nova.Index };
      est.current = y; setE(y);
    } else carregar({ audio: atual.audio, legenda: nova.Index, ticks: posTicks() });
  }

  const serie = it?.Type === 'Episode';
  const nome = it ? (serie ? it.SeriesName : it.Name) : '';
  const ep = serie && it ? [`T${it.ParentIndexNumber ?? '?'}:E${it.IndexNumber ?? '?'}`, it.Name].filter(Boolean).join(' · ') : '';
  // Pular abertura/créditos: só dentro do capítulo, pelo nome dele (player/capitulos.ts)
  const pulo = !fim && !erro ? puloEm(it?.Chapters, pos, !!prox, it?.Type === 'Movie') : null;
  const fazerPulo = () => {
    if (!pulo) return;
    if (pulo.ate === 'proximo') { if (prox) trocar(prox); }
    // filme: os créditos encerram e voltam ao título (o Player desmonta e encerra a reprodução)
    else if (pulo.ate === 'fim') { video.current?.pause(); location.replace(`#/t/${id}`); }
    else { video.current!.currentTime = pulo.ate; mexeu(); }
  };
  const carregando = espera && !erro;

  return (
    <main class={`player${visivel ? '' : ' oculto'}${carregando ? ' esperando' : ''}`} onMouseMove={mexeu}>
      {/* crossOrigin: legenda <track> e vídeo direto vindos de outro endereço (servidor ≠ site) só carregam com CORS;
          sem isto o navegador recusa o .vtt em silêncio (achado da sessão E, 19/10). O Jellyfin responde CORS "*". */}
      <video ref={video} crossOrigin="anonymous" playsInline preload="auto"
        onPointerDown={ev => { toque.current = { tipo: ev.pointerType, visivel }; }}
        onClick={() => {
          // mouse: clique pausa/toca; toque: mostra ou esconde os controles (como nos apps de streaming)
          const t = toque.current;
          if (t.tipo === 'mouse') { if (t.visivel) alternar(); mexeu(); }
          else if (t.visivel) setVisivel(false); else mexeu();
        }}
        onDblClick={() => { if (toque.current.tipo === 'mouse') tela(); }}>
        {e && externas.map(x => (
          <track key={`${e.plano.sessaoReproducao}-${x.Index}`} id={`l${x.Index}`} kind="subtitles" label={nomeFluxo(x)}
            srcLang={x.Language || 'und'} src={x.url!} />
        ))}
      </video>

      {carregando && <Carregando />}
      {erro && <div class="player-erro" role="alert"><p>{erro}</p><button class="player-pilula" onClick={() => carregar({ ticks: posTicks(), semDireto: true })}>Tentar de novo</button></div>}

      <header class="player-topo">
        <button class="player-icone" onClick={voltar} aria-label="Voltar"><Icone nome="arrow_back" tamanho={26} /></button>
        <h1 class="uma-linha">{nome}{ep && <span> {ep}</span>}</h1>
      </header>

      {!fim && !carregando && !erro && (
        <div class="player-centro">
          {serie && <button class="player-icone" disabled={!ant} onClick={() => ant && trocar(ant)} aria-label="Episódio anterior"><Icone nome="skip_previous" cheio tamanho={30} /></button>}
          <button class="player-icone" onClick={() => pular(-10)} aria-label="Voltar 10 segundos"><Icone nome="replay_10" tamanho={34} /></button>
          <button ref={playBtn} class="player-icone player-play" onClick={alternar} aria-label={tocando ? 'Pausar' : 'Tocar'}>
            <Icone nome={tocando ? 'pause' : 'play_arrow'} cheio tamanho={46} />
          </button>
          <button class="player-icone" onClick={() => pular(10)} aria-label="Avançar 10 segundos"><Icone nome="forward_10" tamanho={34} /></button>
          {serie && <button class="player-icone" disabled={!prox} onClick={() => prox && trocar(prox)} aria-label="Próximo episódio"><Icone nome="skip_next" cheio tamanho={30} /></button>}
        </div>
      )}

      {pulo && !menu && <button class="player-pular" onClick={fazerPulo}>{textoDoPulo(pulo.tipo)}</button>}

      {fim && prox && (
        <div class="player-proximo">
          {paisagem(s, prox, 320) && <img src={paisagem(s, prox, 320)} alt="" />}
          <div>
            <small aria-live="polite">{conta !== null ? `Próximo episódio em ${conta} s` : 'Próximo episódio'}</small>
            <strong class="uma-linha">T{prox.ParentIndexNumber}:E{prox.IndexNumber} · {prox.Name}</strong>
            <span class="player-proximo-acoes">
              <button class={`player-pilula${conta !== null ? ' contando' : ''}`} ref={el => el?.focus()} onClick={() => trocar(prox)}
                style={{ '--contagem': `${CONTAGEM}s` } as Record<string, string>}><Icone nome="play_arrow" cheio tamanho={20} />Assistir</button>
              {conta !== null && <button class="player-cancelar" onClick={() => setConta(null)}>Cancelar</button>}
            </span>
          </div>
        </div>
      )}

      {fim && it?.Type === 'Movie' && <section class="player-final" aria-label="Filme concluído">
        <h2>{it.Name}</h2>
        <div class="player-final-acoes">
          <button ref={fimBotao} class="player-pilula" onClick={() => location.replace(`#/t/${id}`)}>Voltar ao título</button>
          <button class="player-pilula" onClick={() => { setFim(false); void carregar({ ticks: 0, audio: e?.audio, legenda: e?.legenda }); }}>Assistir de novo</button>
        </div>
        <MaisComoEste s={s} id={id} limite={6} />
      </section>}

      <footer class="player-base">
        <span class="player-tempo">{relogio(pos)}</span>
        <PreviaBarra s={s} it={it} pos={pos} dur={dur} buscar={seg => { video.current!.currentTime = seg; }} />
        <span class="player-tempo">{relogio(dur)}</span>
        <button class={menu ? 'player-icone ativo' : 'player-icone'} disabled={!e} onClick={() => setMenu(!menu)}
          aria-expanded={menu} aria-label="Áudio e legendas" title="Áudio e legendas">
          <Icone nome="subtitles" tamanho={26} />
        </button>
        <div class="player-volume">
          <button class="player-icone" onClick={() => mudarVolume(volume.mudo || volume.nivel === 0 ? (volume.nivel || 1) : 0)}
            aria-label={volume.mudo ? 'Ligar o som' : 'Desligar o som'} title={volume.mudo ? 'Ligar o som (M)' : 'Desligar o som (M)'}>
            <Icone nome={volume.mudo || volume.nivel === 0 ? 'volume_off' : volume.nivel < 0.5 ? 'volume_down' : 'volume_up'} tamanho={24} />
          </button>
          <input class="player-barra player-vol" type="range" min={0} max={1} step={0.05} value={volume.mudo ? 0 : volume.nivel}
            aria-label="Volume" aria-valuetext={`${Math.round((volume.mudo ? 0 : volume.nivel) * 100)}%`}
            style={{ '--feito': `${(volume.mudo ? 0 : volume.nivel) * 100}%` } as Record<string, string>}
            onInput={ev => mudarVolume(Number(ev.currentTarget.value))} />
        </div>
        {document.pictureInPictureEnabled && <button class={pip ? 'player-icone ativo' : 'player-icone'} onClick={imagemNoCanto}
          aria-pressed={pip} aria-label="Imagem no canto" title="Imagem no canto (P)"><Icone nome="picture_in_picture_alt" tamanho={24} /></button>}
        <button class="player-icone" onClick={tela} aria-label={cheia ? 'Sair da tela cheia' : 'Tela cheia'} title={cheia ? 'Sair da tela cheia (F)' : 'Tela cheia (F)'}>
          <Icone nome={cheia ? 'fullscreen_exit' : 'fullscreen'} tamanho={26} />
        </button>
      </footer>

      {menu && e && (
        <PainelFaixas velocidade={velocidade} escolherVelocidade={mudarVelocidade} audios={audios} legendas={legendas} audio={e.audio} legenda={e.legenda}
          escolherAudio={escolherAudio} escolherLegenda={escolherLegenda} fechar={() => setMenu(false)}
          podeBuscar={podeBuscar} buscar={l => buscarLegendas(s, id, l)} baixar={baixarRemota} />
      )}
    </main>
  );
}
