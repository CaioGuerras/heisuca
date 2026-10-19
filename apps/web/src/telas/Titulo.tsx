import { useEffect, useRef, useState } from 'preact/hooks';
import {
  episodios, fotoPessoa, fundo, item, logo, marcarAssistido, marcarFavorito,
  miniatura, proximoDaSerie, temporadas, type Fluxo, type Item, type Sessao,
} from '../api/jellyfin';
import { Icone } from '../comp/Icone';
import { irVer, voltar } from '../rota';

export function duracao(ticks?: number): string {
  if (!ticks) return '';
  const min = Math.round(ticks / 600_000_000);
  return min >= 60 ? `${Math.floor(min / 60)} h ${String(min % 60).padStart(2, '0')} min` : `${min} min`;
}

const codigo = (e: Item) => `T${e.ParentIndexNumber ?? 1}:E${e.IndexNumber ?? 1}`;

export function Titulo({ s, id }: { s: Sessao; id: string }) {
  const [t, setT] = useState<Item | null>(null);
  const [temps, setTemps] = useState<Item[]>([]);
  const [tempId, setTempId] = useState<string>('');
  const [modalTemp, setModalTemp] = useState(false);
  const [eps, setEps] = useState<Item[]>([]);
  const [prox, setProx] = useState<Item | null>(null);
  const [erro, setErro] = useState('');
  const [favorito, setFavorito] = useState(false);
  const [assistido, setAssistido] = useState(false);
  const play = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    (async () => {
      try {
        let i = await item(s, id);
        const temporadaPedida = i.Type === 'Episode' ? i.SeasonId : i.Type === 'Season' ? i.Id : undefined;
        if ((i.Type === 'Episode' || i.Type === 'Season') && i.SeriesId) {
          i = await item(s, i.SeriesId);
        }
        setT(i);
        setFavorito(!!i.UserData?.IsFavorite);
        setAssistido(!!i.UserData?.Played);

        if (i.Type === 'Series') {
          const [ts, p] = await Promise.all([temporadas(s, i.Id), proximoDaSerie(s, i.Id)]);
          setTemps(ts);
          setProx(p);
          setTempId(temporadaPedida || p?.SeasonId || ts[0]?.Id || '');
        }
      } catch (e) {
        setErro(e instanceof Error ? e.message : String(e));
      }
    })();
  }, [id]);

  useEffect(() => {
    if (t) play.current?.focus({ preventScroll: true });
  }, [t?.Id]);

  useEffect(() => {
    if (!t || !tempId) return;
    episodios(s, t.Id, tempId).then(setEps).catch(e => setErro(String(e)));
  }, [t?.Id, tempId]);

  const alternarFavorito = async () => {
    if (!t) return;
    const novo = !favorito;
    setFavorito(novo);
    if (t.UserData) t.UserData.IsFavorite = novo;
    await marcarFavorito(s, t.Id, novo);
  };

  const alternarAssistido = async () => {
    if (!t) return;
    const alvo = t.Type === 'Series' && prox ? prox : t;
    const novo = !assistido;
    setAssistido(novo);
    if (alvo.UserData) alvo.UserData.Played = novo;
    await marcarAssistido(s, alvo.Id, novo);
    if (t.Type === 'Series') {
      const p = await proximoDaSerie(s, t.Id);
      setProx(p);
      if (tempId) setEps(await episodios(s, t.Id, tempId));
    }
  };

  if (erro) {
    return (
      <main class="titulo">
        <p class="erro">{erro}</p>
        <button data-foco class="botao" onClick={voltar}>Voltar</button>
      </main>
    );
  }

  if (!t) return <main class="titulo carregando" aria-busy="true" />;

  const serie = t.Type === 'Series';
  const alvo = serie ? (prox || eps[0]) : t;
  const pos = alvo?.UserData?.PlaybackPositionTicks || 0;
  const rotuloPlay = serie
    ? (prox ? `${pos ? 'Continuar' : 'Assistir'} ${codigo(prox)}` : 'Assistir')
    : (pos ? 'Continuar' : 'Assistir');

  const img = fundo(s, t, 1920);
  const lg = logo(s, t, 600);
  const temporadaAtual = temps.find(x => x.Id === tempId) || temps[0];

  // Metadados principais
  const meta = [
    t.CommunityRating ? `★ ${t.CommunityRating.toFixed(1)}` : '',
    t.ProductionYear,
    t.OfficialRating,
    (t.Genres || []).slice(0, 3).join(', '),
  ].filter(Boolean);

  // Informações de Mídia Técnicas (Estilo VidHub)
  const videoStream: Fluxo | undefined = t.MediaStreams?.find(x => x.Type === 'Video') || alvo?.MediaStreams?.find(x => x.Type === 'Video');
  const audioStream: Fluxo | undefined = t.MediaStreams?.find(x => x.Type === 'Audio') || alvo?.MediaStreams?.find(x => x.Type === 'Audio');

  const formatoVideo = [
    videoStream?.DisplayTitle?.split(' ')[0] || (t.Width ? `${t.Width}p` : 'HD'),
    videoStream?.Codec?.toUpperCase() || 'H.264',
  ].filter(Boolean).join(' · ');

  const formatoAudio = [
    audioStream?.Language || 'Português',
    audioStream?.Codec?.toUpperCase() || 'AAC',
    audioStream?.Channels ? (audioStream.Channels > 2 ? `${audioStream.Channels}.1` : 'Stereo') : 'Stereo',
  ].filter(Boolean).join(' · ');

  function assistir() {
    if (serie) {
      const e = prox || eps[0];
      if (e) irVer(e.Id, e.UserData?.PlaybackPositionTicks);
    } else {
      irVer(t!.Id, pos || undefined);
    }
  }

  return (
    <main class="titulo">
      <div class="titulo-fundo">
        {img && <img src={img} alt="" />}
        <div class="titulo-fundo-degrade" />
      </div>

      <header class="titulo-topo">
        <button data-foco class="botao-voltar" onClick={voltar} aria-label="Voltar">
          <Icone nome="arrow_back" />
          <span>Voltar</span>
        </button>
      </header>

      <section class="titulo-info">
        {lg ? (
          <img class="titulo-logo" src={lg} alt={t.Name} />
        ) : (
          <h1 class="titulo-nome">{t.Name}</h1>
        )}

        <p class="titulo-meta">{meta.join(' · ')}</p>

        <p class="titulo-submeta">
          {serie
            ? `${temps.length} temporada${temps.length > 1 ? 's' : ''} · ${formatoVideo} · ${formatoAudio}`
            : `${duracao(t.RunTimeTicks)} · ${formatoVideo} · ${formatoAudio}`}
        </p>

        {t.Taglines?.[0] && <p class="titulo-frase">"{t.Taglines[0]}"</p>}
        <p class="titulo-sinopse">{serie && prox ? (prox.Overview || t.Overview) : t.Overview}</p>

        {/* Botão de Play e Ações Diretas (sem menu de 3 pontinhos) */}
        <div class="titulo-acoes">
          <button data-foco ref={play} class="botao botao-play" onClick={assistir}>
            <Icone nome="play_arrow" cheio />
            {rotuloPlay}
          </button>

          <button
            data-foco
            type="button"
            class={favorito ? 'botao-sec ativo' : 'botao-sec'}
            onClick={alternarFavorito}
            aria-pressed={favorito}
            title={favorito ? 'Remover dos favoritos' : 'Adicionar aos favoritos'}
          >
            <Icone nome={favorito ? 'favorite' : 'favorite_border'} cheio={favorito} />
            <span>{favorito ? 'Favorito' : 'Favoritar'}</span>
          </button>

          <button
            data-foco
            type="button"
            class={assistido ? 'botao-sec ativo' : 'botao-sec'}
            onClick={alternarAssistido}
            aria-pressed={assistido}
            title={assistido ? 'Desmarcar assistido' : 'Marcar como assistido'}
          >
            <Icone nome={assistido ? 'check_circle' : 'check'} cheio={assistido} />
            <span>{assistido ? 'Assistido' : 'Marcar visto'}</span>
          </button>
        </div>

        {pos > 0 && alvo?.RunTimeTicks ? (
          <div class="titulo-progresso">
            <span class="progresso-barra">
              <span style={{ width: `${Math.min(100, (pos / alvo.RunTimeTicks) * 100)}%` }} />
            </span>
            <small>Faltam {duracao(alvo.RunTimeTicks - pos)}</small>
          </div>
        ) : null}
      </section>

      {/* Seção de Temporadas e Episódios (Dropdown Único e Carrossel 16:9) */}
      {serie && (
        <section class="temporadas">
          <div class="temporada-seletor-linha">
            <button
              data-foco
              type="button"
              class="seletor-temporada-btn"
              onClick={() => setModalTemp(true)}
              aria-haspopup="dialog"
              aria-expanded={modalTemp}
            >
              <span>{temporadaAtual?.Name || 'Temporada 1'}</span>
              <Icone nome="expand_more" />
            </button>
            <span class="temporada-contagem">{eps.length} episódios</span>
          </div>

          {/* Modal de Escolha de Temporada */}
          {modalTemp && (
            <div class="menu-fundo" onClick={e => { if (e.target === e.currentTarget) setModalTemp(false); }}>
              <div class="modal-caixa temporada-modal" role="dialog" aria-label="Escolher temporada">
                <div class="modal-cabeca">
                  <h2>Escolha a Temporada</h2>
                  <button class="menu-fechar" onClick={() => setModalTemp(false)} aria-label="Fechar">
                    <Icone nome="close" />
                  </button>
                </div>
                <div class="temporadas-opcoes">
                  {temps.map(x => (
                    <button
                      key={x.Id}
                      type="button"
                      class={x.Id === tempId ? 'temp-opcao ativa' : 'temp-opcao'}
                      onClick={() => { setTempId(x.Id); setModalTemp(false); }}
                    >
                      <span>{x.Name}</span>
                      {x.Id === tempId && <Icone nome="check" />}
                    </button>
                  ))}
                </div>
              </div>
            </div>
          )}

          {/* Lista Horizontal de Episódios com Thumbnails 16:9 */}
          <div class="episodios-trilho">
            {eps.map(e => {
              const p = e.UserData?.PlayedPercentage;
              const estaAtivo = prox?.Id === e.Id;
              return (
                <button
                  data-foco
                  key={e.Id}
                  class={estaAtivo ? 'episodio-card ativo' : 'episodio-card'}
                  onClick={() => irVer(e.Id, e.UserData?.PlaybackPositionTicks)}
                  title={`${e.IndexNumber}. ${e.Name}`}
                >
                  <div class="episodio-thumb">
                    <img loading="lazy" decoding="async" src={miniatura(s, e, 480)} alt="" />
                    <div class="episodio-play-hover" aria-hidden="true">
                      <Icone nome="play_arrow" cheio tamanho={28} />
                    </div>
                    {p ? (
                      <span class="progresso">
                        <span style={{ width: `${p}%` }} />
                      </span>
                    ) : null}
                    {e.UserData?.Played && (
                      <span class="episodio-visto">
                        <Icone nome="check_circle" cheio tamanho={18} />
                      </span>
                    )}
                  </div>
                  <div class="episodio-dados">
                    <strong>{e.IndexNumber}. {e.Name}</strong>
                    <small>{duracao(e.RunTimeTicks)}</small>
                    <p class="episodio-desc">{e.Overview}</p>
                  </div>
                </button>
              );
            })}
          </div>
        </section>
      )}

      {/* Elenco (Fotos Circulares no estilo VidHub / Apple TV) */}
      {t.People && t.People.length > 0 && (
        <section class="elenco-secao">
          <h2>Elenco</h2>
          <div class="elenco-trilho">
            {t.People.slice(0, 15).map(p => (
              <div key={p.Id || p.Name} class="elenco-card">
                <div class="elenco-foto">
                  <img
                    loading="lazy"
                    decoding="async"
                    src={fotoPessoa(s, p, 160)}
                    alt={p.Name}
                    onError={e => {
                      (e.currentTarget as HTMLElement).style.display = 'none';
                    }}
                  />
                  <div class="elenco-foto-placeholder">
                    <span>{p.Name.slice(0, 1).toUpperCase()}</span>
                  </div>
                </div>
                <strong>{p.Name}</strong>
                {p.Role && <small>{p.Role}</small>}
              </div>
            ))}
          </div>
        </section>
      )}

      {/* Cards de Mídia Técnicos (VidHub) */}
      <section class="midia-info-secao">
        <h2>Informações Técnicas</h2>
        <div class="midia-cards-grade">
          <div class="midia-card">
            <div class="midia-card-cabeca">
              <Icone nome="videocam" />
              <strong>Vídeo</strong>
            </div>
            <div class="midia-card-conteudo">
              <div class="midia-dado">
                <span>Formato / Codec</span>
                <strong>{videoStream?.Codec?.toUpperCase() || 'HEVC / H.264'}</strong>
              </div>
              <div class="midia-dado">
                <span>Resolução</span>
                <strong>{t.Width && t.Height ? `${t.Width} × ${t.Height}` : '1920 × 1080 (Full HD)'}</strong>
              </div>
              <div class="midia-dado">
                <span>Taxa de Quadros</span>
                <strong>23.976 fps</strong>
              </div>
            </div>
          </div>

          <div class="midia-card">
            <div class="midia-card-cabeca">
              <Icone nome="audiotrack" />
              <strong>Áudio</strong>
            </div>
            <div class="midia-card-conteudo">
              <div class="midia-dado">
                <span>Idioma Principal</span>
                <strong>{audioStream?.Language || 'Português (Brasil)'}</strong>
              </div>
              <div class="midia-dado">
                <span>Codec de Som</span>
                <strong>{audioStream?.Codec?.toUpperCase() || 'AAC / EAC3'}</strong>
              </div>
              <div class="midia-dado">
                <span>Canais</span>
                <strong>{audioStream?.Channels ? (audioStream.Channels > 2 ? `${audioStream.Channels}.1 Surround` : 'Estéreo (2.0)') : 'Estéreo (2.0)'}</strong>
              </div>
            </div>
          </div>
        </div>
      </section>
    </main>
  );
}
