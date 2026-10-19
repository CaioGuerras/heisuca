import { useEffect, useRef, useState } from 'preact/hooks';
import type Hls from 'hls.js/light';
import {
  infoReproducao, item, pararConversao, relatar, seguinte, urlDireta, urlServidor,
  type Fluxo, type Fonte, type Item, type Relato, type Sessao,
} from '../api/jellyfin';
import { hlsNativo, marcarMkvFalhou, perfilDoAparelho } from '../api/perfil';
import { avisarErro } from '../aviso';
import { Icone } from '../comp/Icone';
import { irVer, voltar } from '../rota';

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
const audioDoArquivo = (fonte: Fonte) => {
  const a = fonte.MediaStreams.filter(x => x.Type === 'Audio');
  return (a.find(x => x.IsDefault) || a[0])?.Index;
};

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
  const esconder = useRef<number>(0);
  const playBtn = useRef<HTMLButtonElement>(null);
  const toque = useRef({ tipo: 'mouse', visivel: true });

  const relato = (): Relato | null => {
    const x = est.current, v = video.current;
    if (!x || !v) return null;
    return {
      ItemId: id,
      MediaSourceId: x.fonte.Id,
      PlaySessionId: x.sessao,
      PositionTicks: Math.round(v.currentTime * TICKS),
      IsPaused: v.paused,
      PlayMethod: x.metodo,
      AudioStreamIndex: x.audio,
      SubtitleStreamIndex: x.legenda,
      CanSeek: true,
    };
  };

  function encerrar() {
    const r = relato(), x = est.current;
    if (r && iniciou.current) relatar(s, 'fim', r);
    if (x?.hls) pararConversao(s, x.sessao);
    iniciou.current = false;

    // Desliga e descarrega o vídeo completamente do navegador para nunca continuar tocando na Home
    const v = video.current;
    if (v) {
      v.pause();
      v.removeAttribute('src');
      v.load();
    }
    if ('mediaSession' in navigator) {
      navigator.mediaSession.playbackState = 'none';
    }
    hls.current?.destroy();
    hls.current = null;
  }

  async function carregar(c: Carga) {
    setEspera(true);
    setErro('');
    try {
      const corpo = (o: Carga) => ({
        DeviceProfile: perfilDoAparelho(),
        MaxStreamingBitrate: 140_000_000,
        AutoOpenLiveStream: true,
        AudioStreamIndex: o.audio,
        SubtitleStreamIndex: o.legenda,
        EnableDirectPlay: !o.semDireto,
        EnableDirectStream: true,
        EnableTranscoding: true,
      });

      let info = await infoReproducao(s, id, corpo(c));
      let fonte = info.MediaSources[0];
      if (!fonte) {
        throw new Error(
          info.ErrorCode === 'NotAllowed'
            ? 'Sua conta já está usando todas as telas permitidas.'
            : info.ErrorCode || 'Sem fonte de vídeo disponível.'
        );
      }

      let audio = c.audio ?? fonte.DefaultAudioStreamIndex;
      const legenda = c.legenda ?? fonte.DefaultSubtitleStreamIndex ?? -1;

      // Se houver mais de uma faixa de áudio e a selecionada não for a padrão do arquivo, remonta em HLS
      const audios = fonte.MediaStreams.filter(x => x.Type === 'Audio').length;
      if (fonte.SupportsDirectPlay && !c.semDireto && audios > 1 && audio !== undefined && audio !== audioDoArquivo(fonte)) {
        info = await infoReproducao(s, id, corpo({ ...c, audio, legenda, semDireto: true }));
        fonte = info.MediaSources[0];
        c = { ...c, semDireto: true };
      }

      audio = c.audio ?? fonte.DefaultAudioStreamIndex ?? audio;
      const direto = fonte.SupportsDirectPlay && !c.semDireto;
      if (!direto && !fonte.TranscodingUrl) throw new Error('Este vídeo não pode ser reproduzido neste navegador.');

      const x: Estado = {
        fonte,
        sessao: info.PlaySessionId,
        audio,
        legenda,
        metodo: direto ? 'DirectPlay' : fonte.SupportsDirectStream ? 'DirectStream' : 'Transcode',
        url: direto ? urlDireta(s, id, fonte, info.PlaySessionId) : urlServidor(s, fonte.TranscodingUrl!),
        hls: !direto,
      };

      encerrar();
      est.current = x;
      setE(x);
      await ligar(x, (c.ticks || 0) / TICKS);
    } catch (err) {
      setEspera(false);
      setErro(err instanceof Error ? err.message : String(err));
    }
  }

  async function ligar(x: Estado, seg: number) {
    const v = video.current!;
    v.removeAttribute('src');
    const comecar = () => {
      if (seg > 0) v.currentTime = seg;
      v.play().catch(() => setTocando(false));
    };

    if (x.hls) {
      const { default: H } = await import('hls.js/light');
      if (H.isSupported()) {
        const h = new H({ startPosition: seg > 0 ? seg : -1, maxBufferLength: 30, backBufferLength: 60 });
        hls.current = h;
        h.on(H.Events.ERROR, (_ev, d) => {
          if (!d.fatal) return;
          if (d.type === H.ErrorTypes.NETWORK_ERROR) h.startLoad();
          else if (d.type === H.ErrorTypes.MEDIA_ERROR) h.recoverMediaError();
          else setErro(`Falha na reprodução (${d.details}).`);
        });
        h.loadSource(x.url);
        h.attachMedia(v);
        h.on(H.Events.MANIFEST_PARSED, () => v.play().catch(() => setTocando(false)));
        return;
      }
      if (!hlsNativo()) throw new Error('Este navegador não suporta reprodução HLS.');
    }
    v.src = x.url;
    v.addEventListener('loadedmetadata', comecar, { once: true });
  }

  useEffect(() => {
    item(s, id)
      .then(i => {
        setIt(i);
        if (i.Type === 'Episode' && i.SeriesId) seguinte(s, i).then(setProx).catch(() => undefined);
      })
      .catch(() => undefined);

    carregar({ ticks: inicio });
    const sair = () => encerrar();
    addEventListener('pagehide', sair);
    return () => {
      removeEventListener('pagehide', sair);
      encerrar();
    };
  }, [id]);

  // Relato de progresso contínuo
  useEffect(() => {
    const t = setInterval(() => {
      const r = relato();
      if (r && iniciou.current && !r.IsPaused) relatar(s, 'progresso', r);
    }, 10_000);
    return () => clearInterval(t);
  }, [id]);

  // Eventos do elemento vídeo
  useEffect(() => {
    const v = video.current!;
    const ev: Record<string, () => void> = {
      playing: () => {
        setEspera(false);
        setTocando(true);
        setFim(false);
        const r = relato();
        if (!r) return;
        if (!iniciou.current) {
          iniciou.current = true;
          relatar(s, 'inicio', r);
        } else {
          relatar(s, 'progresso', r);
        }
      },
      pause: () => {
        setTocando(false);
        const r = relato();
        if (r && iniciou.current) relatar(s, 'progresso', r);
      },
      waiting: () => setEspera(true),
      canplay: () => setEspera(false),
      timeupdate: () => setPos(v.currentTime),
      durationchange: () => setDur(v.duration),
      seeked: () => {
        const r = relato();
        if (r && iniciou.current) relatar(s, 'progresso', r);
      },
      ended: () => {
        const r = relato();
        if (r) relatar(s, 'fim', r);
        iniciou.current = false;
        setFim(true);
        setVisivel(true);
      },
      error: () => {
        const x = est.current;
        if (!v.error || (x && !x.hls && v.currentSrc !== x.url)) return;
        if (x && !x.hls) {
          carregar({ audio: x.audio, legenda: x.legenda, ticks: Math.round(v.currentTime * TICKS), semDireto: true });
        } else {
          setErro('Ocorreu uma falha ao abrir este vídeo.');
        }
      },
    };
    for (const k in ev) v.addEventListener(k, ev[k]);
    return () => {
      for (const k in ev) v.removeEventListener(k, ev[k]);
    };
  }, []);

  // Proteção contra falha de decodificação de MKV no Chrome Android
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
        if (e.fonte.Container === 'mkv') marcarMkvFalhou();
        carregar({ audio: e.audio, legenda: e.legenda, ticks: Math.round(v.currentTime * TICKS), semDireto: true });
      }, 3000);
    };
    v.addEventListener('playing', conferir);
    return () => {
      clearTimeout(t);
      v.removeEventListener('playing', conferir);
    };
  }, [e]);

  // Faixas de legendas externas
  useEffect(() => {
    const v = video.current;
    if (!v || !e) return;
    const ligarFaixa = () => {
      for (const t of Array.from(v.textTracks)) t.mode = t.id === `l${e.legenda}` ? 'showing' : 'disabled';
    };
    ligarFaixa();
    v.addEventListener('loadedmetadata', ligarFaixa);
    return () => v.removeEventListener('loadedmetadata', ligarFaixa);
  }, [e]);

  // Legenda ASS via JASSUB
  useEffect(() => {
    const v = video.current;
    const l = e?.fonte.MediaStreams.find(x => x.Index === e.legenda);
    if (!v || !e || !eAss(l) || l!.DeliveryMethod !== 'External' || !l!.DeliveryUrl) return;
    let cancelado = false, instance: { destroy(): Promise<void> } | null = null;
    const fontes = (e.fonte.MediaAttachments || [])
      .filter(a => a.DeliveryUrl && /font|ttf|otf|woff/i.test(`${a.MimeType} ${a.FileName} ${a.Codec}`))
      .map(a => urlServidor(s, a.DeliveryUrl!));

    import('jassub').then(({ default: J }) => {
      if (cancelado) return;
      instance = new J({ video: v, subUrl: urlServidor(s, l!.DeliveryUrl!), fonts: fontes, maxRenderHeight: 1080 });
    }).catch(err => avisarErro(`JASSUB: ${err}`));

    return () => {
      cancelado = true;
      instance?.destroy().catch(() => undefined);
    };
  }, [e]);

  function mexeu() {
    setVisivel(true);
    clearTimeout(esconder.current);
    esconder.current = window.setTimeout(() => {
      if (!video.current?.paused && !menu) setVisivel(false);
    }, 3500);
  }

  useEffect(() => { mexeu(); }, [tocando, menu]);
  useEffect(() => {
    if (visivel && !menu) playBtn.current?.focus({ preventScroll: true });
  }, [visivel === true && !menu]);

  const alternar = () => {
    const v = video.current!;
    v.paused ? v.play() : v.pause();
  };

  const pular = (seg: number) => {
    const v = video.current!;
    v.currentTime = Math.max(0, Math.min(v.duration || 0, v.currentTime + seg));
  };

  const pularAbertura = () => {
    pular(85);
  };

  useEffect(() => {
    const f = (ev: KeyboardEvent) => {
      const k = ev.keyCode;
      if (VOLTAR.has(k)) {
        ev.preventDefault();
        ev.stopImmediatePropagation();
        if (menu) setMenu(false);
        else {
          encerrar();
          voltar();
        }
        return;
      }
      if (PLAY.has(k)) { video.current?.play(); mexeu(); return; }
      if (PAUSA.has(k)) { video.current?.pause(); mexeu(); return; }
      if (!visivel) {
        ev.preventDefault();
        ev.stopImmediatePropagation();
        if (AVANCAR.has(k)) pular(10);
        else if (RECUAR.has(k)) pular(-10);
        else if (PLAY_PAUSA.has(k)) alternar();
        mexeu();
        return;
      }
      if (k === 417) pular(30);
      else if (k === 412) pular(-10);
      else if (k === 10252 || k === 179) alternar();
      mexeu();
    };
    addEventListener('keydown', f, true);
    return () => removeEventListener('keydown', f, true);
  }, [visivel, menu]);

  const fonte = e?.fonte;
  const audios = fonte?.MediaStreams.filter(x => x.Type === 'Audio') || [];
  const legendas = fonte?.MediaStreams.filter(x => x.Type === 'Subtitle') || [];
  const externas = legendas.filter(x => x.DeliveryMethod === 'External' && x.DeliveryUrl && !eAss(x));
  const posTicks = () => Math.round((video.current?.currentTime || 0) * TICKS);

  function escolherAudio(i: number) {
    setMenu(false);
    if (e && i !== e.audio) carregar({ audio: i, legenda: e.legenda, ticks: posTicks() });
  }

  function escolherLegenda(i: number) {
    setMenu(false);
    if (!e || i === e.legenda) return;
    const nova = legendas.find(x => x.Index === i);
    const atualGravada = legendas.find(x => x.Index === e.legenda)?.DeliveryMethod === 'Encode';
    if (!atualGravada && (i === -1 || (nova?.DeliveryMethod === 'External' && nova.DeliveryUrl))) {
      const x = { ...e, legenda: i };
      est.current = x;
      setE(x);
    } else {
      carregar({ audio: e.audio, legenda: i, ticks: posTicks() });
    }
  }

  const alternarTelaCheia = () => {
    const el = document.documentElement as HTMLElement & { webkitRequestFullscreen?: () => void };
    const v = video.current as HTMLVideoElement & { webkitEnterFullscreen?: () => void };
    if (document.fullscreenElement) {
      document.exitFullscreen?.().catch(() => undefined);
    } else if (el.requestFullscreen) {
      el.requestFullscreen().catch(() => undefined);
    } else {
      v?.webkitEnterFullscreen?.();
    }
  };

  const nome = it ? (it.Type === 'Episode' ? it.SeriesName : it.Name) : '';
  const sub = it?.Type === 'Episode' ? `T${it.ParentIndexNumber}E${it.IndexNumber} · ${it.Name}` : '';

  return (
    <main class={`player${visivel ? '' : ' oculto'}`} onMouseMove={mexeu}>
      <video
        ref={video}
        playsInline
        preload="auto"
        onPointerDown={ev => { toque.current = { tipo: ev.pointerType, visivel }; }}
        onClick={() => {
          const t = toque.current;
          if (t.tipo === 'mouse') {
            if (t.visivel) alternar();
            mexeu();
          } else if (t.visivel) {
            setVisivel(false);
          } else {
            mexeu();
          }
        }}
      >
        {e && externas.map(x => (
          <track
            key={`${e.sessao}-${x.Index}`}
            id={`l${x.Index}`}
            kind="subtitles"
            label={nomeFluxo(x)}
            srcLang={x.Language || 'und'}
            src={urlServidor(s, x.DeliveryUrl!)}
          />
        ))}
      </video>

      {/* Selo Heisuca de Carregamento com Kanji */}
      {espera && !erro && (
        <div class="player-espera" aria-label="Carregando">
          <div class="player-carimbo-kanji">
            <span class="kanji-selo-pulso">炳素華</span>
          </div>
        </div>
      )}

      {erro && (
        <div class="player-erro" role="alert">
          <p>{erro}</p>
          <button data-foco class="botao" onClick={() => carregar({ ticks: posTicks(), semDireto: true })}>
            Tentar de novo
          </button>
        </div>
      )}

      {/* Topo do Player */}
      <header class="player-topo">
        <button
          data-foco
          class="botao-voltar-player"
          onClick={() => {
            encerrar();
            voltar();
          }}
          aria-label="Voltar para a página anterior"
        >
          <Icone nome="arrow_back" />
        </button>
        <div class="player-titulos">
          <strong>{nome}</strong>
          {sub && <small>{sub}</small>}
        </div>
      </header>

      {/* Próximo Episódio ao Fim */}
      {fim && prox && (
        <div class="player-proximo">
          <small>Próximo episódio</small>
          <strong>T{prox.ParentIndexNumber}E{prox.IndexNumber} · {prox.Name}</strong>
          <button data-foco class="botao" ref={el => el?.focus()} onClick={() => irVer(prox.Id)}>
            <Icone nome="skip_next" cheio />
            Assistir
          </button>
        </div>
      )}

      {/* Base do Player */}
      <footer class="player-base">
        <input
          data-foco
          class="player-barra"
          type="range"
          min={0}
          max={dur || 0}
          step={1}
          value={pos}
          aria-label="Posição do vídeo"
          style={{ '--feito': `${dur ? (pos / dur) * 100 : 0}%` } as Record<string, string>}
          onInput={ev => {
            const v = video.current!;
            v.currentTime = Number(ev.currentTarget.value);
          }}
        />

        <div class="player-controles">
          <button data-foco class="player-icone-btn" onClick={() => pular(-10)} aria-label="Voltar 10 segundos">
            <Icone nome="replay_10" tamanho={28} />
          </button>

          <button
            data-foco
            ref={playBtn}
            class="player-icone-btn player-play"
            onClick={alternar}
            aria-label={tocando ? 'Pausar' : 'Reproduzir'}
          >
            <Icone nome={tocando ? 'pause' : 'play_arrow'} cheio tamanho={36} />
          </button>

          <button data-foco class="player-icone-btn" onClick={() => pular(10)} aria-label="Avançar 10 segundos">
            <Icone nome="forward_10" tamanho={28} />
          </button>

          <span class="player-tempo">
            {relogio(pos)} / {relogio(dur)}
          </span>

          <span class="player-espaco" />

          {/* Botão Pular Abertura */}
          <button data-foco class="player-pular-btn" onClick={pularAbertura} title="Avançar abertura (+85s)">
            <Icone nome="skip_next" />
            <span>Pular abertura</span>
          </button>

          {/* Botão Áudio e Legendas */}
          {(audios.length > 1 || legendas.length > 0) && (
            <button
              data-foco
              class={menu ? 'player-icone-btn ativo' : 'player-icone-btn'}
              onClick={() => setMenu(!menu)}
              aria-expanded={menu}
              aria-label="Áudio e legendas"
              title="Áudio e Legendas"
            >
              <Icone nome="subtitles" tamanho={26} />
            </button>
          )}

          {/* Botão Tela Cheia */}
          <button data-foco class="player-icone-btn" onClick={alternarTelaCheia} aria-label="Tela cheia" title="Tela cheia">
            <Icone nome="fullscreen" tamanho={28} />
          </button>
        </div>
      </footer>

      {/* Modal Centralizado e Dividido de Áudio e Legendas com Botão Fechar [X] */}
      {menu && e && (
        <div class="menu-fundo" onClick={e => { if (e.target === e.currentTarget) setMenu(false); }}>
          <div class="player-modal-dialogo" role="dialog" aria-label="Configurações de Áudio e Legendas">
            <div class="player-modal-cabeca">
              <h2>Áudio e Legendas</h2>
              <button class="menu-fechar" onClick={() => setMenu(false)} aria-label="Fechar configurações">
                <Icone nome="close" />
              </button>
            </div>

            <div class="player-modal-corpo">
              {/* Coluna 1: Áudio */}
              <div class="player-coluna">
                <h3>Faixas de Áudio</h3>
                <div class="player-opcoes-lista">
                  {audios.map(a => (
                    <button
                      key={a.Index}
                      type="button"
                      class={a.Index === e.audio ? 'player-faixa-opcao ativa' : 'player-faixa-opcao'}
                      onClick={() => escolherAudio(a.Index)}
                    >
                      <span class="faixa-nome">{nomeFluxo(a)}</span>
                      {a.Index === e.audio && <Icone nome="check" />}
                    </button>
                  ))}
                </div>
              </div>

              {/* Coluna 2: Legendas */}
              <div class="player-coluna">
                <h3>Legendas</h3>
                <div class="player-opcoes-lista">
                  <button
                    type="button"
                    class={e.legenda === -1 ? 'player-faixa-opcao ativa' : 'player-faixa-opcao'}
                    onClick={() => escolherLegenda(-1)}
                  >
                    <span class="faixa-nome">Desativadas</span>
                    {e.legenda === -1 && <Icone nome="check" />}
                  </button>
                  {legendas.map(l => (
                    <button
                      key={l.Index}
                      type="button"
                      class={l.Index === e.legenda ? 'player-faixa-opcao ativa' : 'player-faixa-opcao'}
                      onClick={() => escolherLegenda(l.Index)}
                    >
                      <span class="faixa-nome">
                        {nomeFluxo(l)}
                        {l.IsForced ? ' (Forçada)' : ''}
                      </span>
                      {l.Index === e.legenda && <Icone nome="check" />}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}
