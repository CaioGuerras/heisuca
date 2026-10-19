import { useEffect, useRef, useState } from 'preact/hooks';
import './player.css';
import type Hls from 'hls.js/light';
import {
  anterior, baixarLegenda, buscarLegendas, euMesmo, infoReproducao, item, paisagem, pararConversao, relatar, seguinte,
  urlDireta, urlServidor, type Fluxo, type Fonte, type Item, type LegendaRemota, type Relato, type Sessao,
} from '../api/jellyfin';
import { hlsNativo, marcarMkvFalhou, perfilDoAparelho } from '../api/perfil';
import { avisarErro } from '../aviso';
import { avisar } from '../comp/Aviso';
import { Icone } from '../comp/Icone';
import { Carregando } from '../player/Carregando';
import { puloEm, textoDoPulo } from '../player/capitulos';
import { PainelFaixas } from '../player/PainelFaixas';
import { voltar } from '../rota';

type Metodo = Relato['PlayMethod'];
type Carga = { audio?: number; legenda?: number; ticks?: number; semDireto?: boolean };
type Estado = { fonte: Fonte; sessao: string; metodo: Metodo; audio?: number; legenda: number; url: string; hls: boolean };

const TICKS = 10_000_000;
const relogio = (seg: number) => {
  if (!Number.isFinite(seg) || seg < 0) seg = 0;
  const h = Math.floor(seg / 3600), m = Math.floor(seg / 60) % 60, s = Math.floor(seg % 60);
  return (h ? `${h}:${String(m).padStart(2, '0')}` : String(m)) + `:${String(s).padStart(2, '0')}`;
};
const eAss = (f?: Fluxo) => !!f && (f.Codec === 'ass' || f.Codec === 'ssa');
const nomeFluxo = (f: Fluxo) => f.DisplayTitle || f.Title || f.Language || `Faixa ${f.Index}`;
// faixa de áudio que o navegador toca por conta própria (a padrão do arquivo, senão a primeira)
const audioDoArquivo = (fonte: Fonte) => {
  const a = fonte.MediaStreams.filter(x => x.Type === 'Audio');
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
  const esconder = useRef<number>(0);
  const playBtn = useRef<HTMLButtonElement>(null);
  const toque = useRef({ tipo: 'mouse', visivel: true });

  const relato = (): Relato | null => {
    const x = est.current, v = video.current;
    if (!x || !v) return null;
    return { ItemId: id, MediaSourceId: x.fonte.Id, PlaySessionId: x.sessao, PositionTicks: Math.round(v.currentTime * TICKS),
      IsPaused: v.paused, PlayMethod: x.metodo, AudioStreamIndex: x.audio, SubtitleStreamIndex: x.legenda, CanSeek: true };
  };

  function encerrar() {
    const r = relato(), x = est.current;
    if (r && iniciou.current) relatar(s, 'fim', r);
    if (x?.hls) pararConversao(s, x.sessao);
    iniciou.current = false;
    hls.current?.destroy(); hls.current = null;
  }

  const corpo = (o: Carga) => ({
    DeviceProfile: perfilDoAparelho(), MaxStreamingBitrate: 140_000_000, AutoOpenLiveStream: true,
    AudioStreamIndex: o.audio, SubtitleStreamIndex: o.legenda,
    EnableDirectPlay: !o.semDireto, EnableDirectStream: true, EnableTranscoding: true,
  });

  async function carregar(c: Carga) {
    setEspera(true); setErro('');
    try {
      let info = await infoReproducao(s, id, corpo(c));
      let fonte = info.MediaSources[0];
      if (!fonte) throw new Error(info.ErrorCode === 'NotAllowed'
        ? 'Sua conta já está usando todas as telas. Feche o vídeo em outro aparelho e tente de novo.'
        : info.ErrorCode || 'Sem fonte de vídeo.');
      let audio = c.audio ?? fonte.DefaultAudioStreamIndex;
      const legenda = c.legenda ?? fonte.DefaultSubtitleStreamIndex ?? -1;
      // o navegador não troca a faixa de áudio sozinho: se a escolhida não é a do arquivo, o servidor remonta (HLS)
      const audios = fonte.MediaStreams.filter(x => x.Type === 'Audio').length;
      if (fonte.SupportsDirectPlay && !c.semDireto && audios > 1 && audio !== undefined && audio !== audioDoArquivo(fonte)) {
        info = await infoReproducao(s, id, corpo({ ...c, audio, legenda, semDireto: true }));
        fonte = info.MediaSources[0];
        c = { ...c, semDireto: true };
      }
      audio = c.audio ?? fonte.DefaultAudioStreamIndex ?? audio;
      const direto = fonte.SupportsDirectPlay && !c.semDireto;
      if (!direto && !fonte.TranscodingUrl) throw new Error('Este vídeo não pode ser tocado neste aparelho.');
      const x: Estado = {
        fonte, sessao: info.PlaySessionId, audio, legenda,
        metodo: direto ? 'DirectPlay' : fonte.SupportsDirectStream ? 'DirectStream' : 'Transcode',
        url: direto ? urlDireta(s, id, fonte, info.PlaySessionId) : urlServidor(s, fonte.TranscodingUrl!), hls: !direto,
      };
      encerrar();
      est.current = x; setE(x);
      await ligar(x, (c.ticks || 0) / TICKS);
    } catch (err) { setEspera(false); setErro(err instanceof Error ? err.message : String(err)); }
  }

  async function ligar(x: Estado, seg: number) {
    const v = video.current!;
    v.removeAttribute('src');
    const comecar = () => { if (seg > 0) v.currentTime = seg; v.play().catch(() => setTocando(false)); };
    if (x.hls) {
      const { default: H } = await import('hls.js/light');
      if (H.isSupported()) {
        const h = new H({ startPosition: seg > 0 ? seg : -1, maxBufferLength: 30, backBufferLength: 60 });
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
    item(s, id).then(i => {
      setIt(i);
      if (i.Type === 'Episode' && i.SeriesId) {
        seguinte(s, i).then(setProx).catch(() => undefined);
        anterior(s, i).then(setAnt).catch(() => undefined);
      }
    }).catch(() => undefined);
    // "Buscar legendas…" só para quem pode gerenciar legendas no servidor (PLANO §13)
    euMesmo(s).then(u => setPodeBuscar(!!u.Policy?.EnableSubtitleManagement)).catch(() => undefined);
    carregar({ ticks: inicio });
    const sair = () => encerrar();
    addEventListener('pagehide', sair);
    return () => { removeEventListener('pagehide', sair); encerrar(); };
  }, [id]);

  // progresso a cada 10 s enquanto toca
  useEffect(() => {
    const t = setInterval(() => { const r = relato(); if (r && iniciou.current && !r.IsPaused) relatar(s, 'progresso', r); }, 10_000);
    return () => clearInterval(t);
  }, [id]);

  // eventos do <video>
  useEffect(() => {
    const v = video.current!;
    const ev: Record<string, () => void> = {
      playing: () => {
        setEspera(false); setTocando(true); setFim(false);
        const r = relato(); if (!r) return;
        if (!iniciou.current) { iniciou.current = true; relatar(s, 'inicio', r); } else relatar(s, 'progresso', r);
      },
      pause: () => { setTocando(false); const r = relato(); if (r && iniciou.current) relatar(s, 'progresso', r); },
      waiting: () => setEspera(true),
      canplay: () => setEspera(false),
      timeupdate: () => setPos(v.currentTime),
      durationchange: () => setDur(v.duration),
      seeked: () => { const r = relato(); if (r && iniciou.current) relatar(s, 'progresso', r); },
      ended: () => { const r = relato(); if (r) relatar(s, 'fim', r); iniciou.current = false; setFim(true); setVisivel(true); },
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
    if (!v || !e || e.hls || !e.fonte.MediaStreams.some(x => x.Type === 'Video')) return;
    let t = 0;
    const conferir = () => {
      clearTimeout(t);
      t = window.setTimeout(() => {
        if (v.paused || est.current !== e) return;
        const quadros = v.getVideoPlaybackQuality?.().totalVideoFrames;
        if (v.videoWidth > 0 && quadros !== 0) return;
        const codec = e.fonte.MediaStreams.find(x => x.Type === 'Video')?.Codec;
        avisarErro(`sem quadro no direto: ${e.fonte.Container}/${codec} largura=${v.videoWidth} quadros=${quadros} ${navigator.userAgent}`);
        if (e.fonte.Container === 'mkv') marcarMkvFalhou();
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
    const l = e?.fonte.MediaStreams.find(x => x.Index === e.legenda);
    if (!v || !e || !eAss(l) || l!.DeliveryMethod !== 'External' || !l!.DeliveryUrl) return;
    let fim = false, r: { destroy(): Promise<void> } | null = null;
    const fontes = (e.fonte.MediaAttachments || [])
      .filter(a => a.DeliveryUrl && /font|ttf|otf|woff/i.test(`${a.MimeType} ${a.FileName} ${a.Codec}`))
      .map(a => urlServidor(s, a.DeliveryUrl!));
    import('jassub').then(({ default: J }) => {
      if (fim) return;
      r = new J({ video: v, subUrl: urlServidor(s, l!.DeliveryUrl!), fonts: fontes, maxRenderHeight: 1080 });
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
    document.addEventListener('fullscreenchange', f);
    return () => document.removeEventListener('fullscreenchange', f);
  }, []);

  const alternar = () => { const v = video.current!; v.paused ? v.play() : v.pause(); };
  const pular = (seg: number) => { const v = video.current!; v.currentTime = Math.max(0, Math.min(v.duration || 0, v.currentTime + seg)); };
  const mudo = () => { const v = video.current!; v.muted = !v.muted; avisar(v.muted ? 'Som desligado' : 'Som ligado'); };
  // outro episódio: troca a rota sem empilhar (Voltar continua levando ao título; o Player remonta e encerra o anterior)
  const trocar = (ep: Item) => location.replace(`#/ver/${ep.Id}`);
  const tela = () => {
    const el = document.documentElement as HTMLElement & { webkitRequestFullscreen?: () => void };
    const v = video.current as HTMLVideoElement & { webkitEnterFullscreen?: () => void };
    if (document.fullscreenElement) document.exitFullscreen();
    else if (el.requestFullscreen) el.requestFullscreen().catch(() => undefined);
    else v.webkitEnterFullscreen?.();
  };

  // teclado (computador) e controle remoto: espaço/K tocar e pausar, ←/→ 10 s, F tela cheia, M mudo, Esc sai da tela
  // cheia ou volta. Com o painel aberto, só o Esc/Voltar (fecha o painel); o resto é do painel.
  useEffect(() => {
    const f = (ev: KeyboardEvent) => {
      if (ev.ctrlKey || ev.metaKey || ev.altKey) return;
      const k = ev.keyCode, alvo = ev.target as HTMLInputElement;
      const pare = () => { ev.preventDefault(); ev.stopImmediatePropagation(); };
      if (VOLTAR.has(k) && !(k === 8 && alvo.tagName === 'INPUT' && alvo.type !== 'range')) {
        pare();
        if (menu) setMenu(false);
        else if (document.fullscreenElement) document.exitFullscreen();
        else voltar();
        return;
      }
      if (menu) return;
      if (PLAY.has(k)) video.current?.play();
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
  }, [visivel, menu]);

  const fonte = e?.fonte;
  const audios = fonte?.MediaStreams.filter(x => x.Type === 'Audio') || [];
  const legendas = fonte?.MediaStreams.filter(x => x.Type === 'Subtitle') || [];
  // texto simples vira <track>; ASS vai para o JASSUB (efeito acima)
  const externas = legendas.filter(x => x.DeliveryMethod === 'External' && x.DeliveryUrl && !eAss(x));
  const posTicks = () => Math.round((video.current?.currentTime || 0) * TICKS);
  function escolherAudio(i: number) { setMenu(false); if (e && i !== e.audio) carregar({ audio: i, legenda: e.legenda, ticks: posTicks() }); }
  function escolherLegenda(i: number) {
    setMenu(false);
    if (!e || i === e.legenda) return;
    const nova = legendas.find(x => x.Index === i);
    const atualGravada = legendas.find(x => x.Index === e.legenda)?.DeliveryMethod === 'Encode';
    // texto por fora troca na hora; legenda gravada no vídeo (ou sair dela) pede nova carga
    if (!atualGravada && (i === -1 || (nova?.DeliveryMethod === 'External' && nova.DeliveryUrl))) {
      const x = { ...e, legenda: i }; est.current = x; setE(x);
    } else carregar({ audio: e.audio, legenda: i, ticks: posTicks() });
  }

  // Buscar legendas: baixa no servidor, pede a lista de novo (PlaybackInfo) e liga a faixa que apareceu
  async function baixarRemota(r: LegendaRemota) {
    const x = est.current;
    if (!x) return;
    await baixarLegenda(s, id, r.Id);
    const antes = new Set(x.fonte.MediaStreams.filter(f => f.Type === 'Subtitle').map(f => f.Index));
    const info = await infoReproducao(s, id, corpo({ audio: x.audio, legenda: x.legenda, semDireto: x.hls }));
    const lista = info.MediaSources[0]?.MediaStreams;
    if (!lista) throw new Error('sem lista de faixas');
    const nova = lista.filter(f => f.Type === 'Subtitle' && !antes.has(f.Index)).pop();
    setMenu(false);
    const atual = est.current;
    if (!atual) return;
    if (!nova) {
      // a mesma legenda baixada de novo (o servidor só substitui o arquivo): nada novo para ligar
      avisar('Essa legenda já estava na lista');
      return;
    }
    avisar('Legenda baixada e ligada');
    const atualGravada = atual.fonte.MediaStreams.find(f => f.Index === atual.legenda)?.DeliveryMethod === 'Encode';
    if (!atualGravada && nova.DeliveryMethod === 'External' && nova.DeliveryUrl && !eAss(nova)) {
      // texto por fora: entra como <track> sem recarregar o vídeo
      const y = { ...atual, fonte: { ...atual.fonte, MediaStreams: lista }, legenda: nova.Index };
      est.current = y; setE(y);
    } else carregar({ audio: atual.audio, legenda: nova.Index, ticks: posTicks() });
  }

  const serie = it?.Type === 'Episode';
  const nome = it ? (serie ? it.SeriesName : it.Name) : '';
  const ep = serie && it ? [`T${it.ParentIndexNumber ?? '?'}:E${it.IndexNumber ?? '?'}`, it.Name].filter(Boolean).join(' · ') : '';
  // Pular abertura/créditos: só dentro do capítulo, pelo nome dele (player/capitulos.ts)
  const pulo = !fim && !erro ? puloEm(it?.Chapters, pos, !!prox) : null;
  const fazerPulo = () => {
    if (!pulo) return;
    if (pulo.ate === 'proximo') { if (prox) trocar(prox); }
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
          <track key={`${e.sessao}-${x.Index}`} id={`l${x.Index}`} kind="subtitles" label={nomeFluxo(x)}
            srcLang={x.Language || 'und'} src={urlServidor(s, x.DeliveryUrl!)} />
        ))}
      </video>

      {carregando && <Carregando />}
      {erro && <div class="player-erro" role="alert"><p>{erro}</p><button class="player-pilula" onClick={() => carregar({ ticks: posTicks(), semDireto: true })}>Tentar de novo</button></div>}

      <header class="player-topo">
        <button class="player-icone" onClick={voltar} aria-label="Voltar"><Icone nome="arrow_back" tamanho={26} /></button>
        <h1 class="uma-linha">{nome}{ep && <span> {ep}</span>}</h1>
      </header>

      {!carregando && !erro && (
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
            <small>Próximo episódio</small>
            <strong class="uma-linha">T{prox.ParentIndexNumber}:E{prox.IndexNumber} · {prox.Name}</strong>
            <button class="player-pilula" ref={el => el?.focus()} onClick={() => trocar(prox)}><Icone nome="play_arrow" cheio tamanho={20} />Assistir</button>
          </div>
        </div>
      )}

      <footer class="player-base">
        <span class="player-tempo">{relogio(pos)}</span>
        <input class="player-barra" type="range" min={0} max={dur || 0} step={1} value={pos} aria-label="Posição"
          aria-valuetext={`${relogio(pos)} de ${relogio(dur)}`}
          style={{ '--feito': `${dur ? pos / dur * 100 : 0}%` } as Record<string, string>}
          onInput={ev => { const v = video.current!; v.currentTime = Number(ev.currentTarget.value); }} />
        <span class="player-tempo">{relogio(dur)}</span>
        <button class={menu ? 'player-icone ativo' : 'player-icone'} disabled={!e} onClick={() => setMenu(!menu)}
          aria-expanded={menu} aria-label="Áudio e legendas" title="Áudio e legendas">
          <Icone nome="subtitles" tamanho={26} />
        </button>
        <button class="player-icone" onClick={tela} aria-label={cheia ? 'Sair da tela cheia' : 'Tela cheia'} title={cheia ? 'Sair da tela cheia (F)' : 'Tela cheia (F)'}>
          <Icone nome={cheia ? 'fullscreen_exit' : 'fullscreen'} tamanho={26} />
        </button>
      </footer>

      {menu && e && (
        <PainelFaixas audios={audios} legendas={legendas} audio={e.audio} legenda={e.legenda}
          escolherAudio={escolherAudio} escolherLegenda={escolherLegenda} fechar={() => setMenu(false)}
          podeBuscar={podeBuscar} buscar={l => buscarLegendas(s, id, l)} baixar={baixarRemota} />
      )}
    </main>
  );
}
