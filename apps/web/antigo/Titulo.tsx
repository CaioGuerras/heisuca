import { useEffect, useRef, useState } from 'preact/hooks';
import { episodios, fundo, item, logo, marcarAssistido, miniatura, proximoDaSerie, temporadas, type Item, type Sessao } from '../api/jellyfin';
import { Icone } from '../comp/Icone';
import { irVer, voltar } from '../rota';

export function duracao(ticks?: number): string {
  if (!ticks) return '';
  const min = Math.round(ticks / 600_000_000);
  return min >= 60 ? `${Math.floor(min / 60)} h ${String(min % 60).padStart(2, '0')} min` : `${min} min`;
}
const resta = (i: Item) => i.RunTimeTicks && i.UserData?.PlaybackPositionTicks ? duracao(i.RunTimeTicks - i.UserData.PlaybackPositionTicks) : '';
const codigo = (e: Item) => `T${e.ParentIndexNumber ?? '?'}E${e.IndexNumber ?? '?'}`;

export function Titulo({ s, id }: { s: Sessao; id: string }) {
  const [t, setT] = useState<Item | null>(null);
  const [temps, setTemps] = useState<Item[]>([]);
  const [temp, setTemp] = useState<string>('');
  const [eps, setEps] = useState<Item[]>([]);
  const [prox, setProx] = useState<Item | null>(null);
  const [erro, setErro] = useState('');
  const play = useRef<HTMLButtonElement>(null);

  // abre o título; se vier um episódio, abre a série na temporada dele
  useEffect(() => {
    (async () => {
      try {
        let i = await item(s, id);
        const temporadaPedida = i.Type === 'Episode' ? i.SeasonId : i.Type === 'Season' ? i.Id : undefined;
        if ((i.Type === 'Episode' || i.Type === 'Season') && i.SeriesId) i = await item(s, i.SeriesId);
        setT(i);
        if (i.Type === 'Series') {
          const [ts, p] = await Promise.all([temporadas(s, i.Id), proximoDaSerie(s, i.Id)]);
          setTemps(ts); setProx(p);
          setTemp(temporadaPedida || p?.SeasonId || ts[0]?.Id || '');
        }
      } catch (e) { setErro(e instanceof Error ? e.message : String(e)); }
    })();
  }, [id]);

  useEffect(() => { if (t) play.current?.focus({ preventScroll: true }); }, [t?.Id]);

  useEffect(() => {
    if (!t || !temp) return;
    episodios(s, t.Id, temp).then(setEps).catch(e => setErro(String(e)));
  }, [t?.Id, temp]);

  async function alternarAssistido() {
    if (!t) return;
    const alvo = t.Type === 'Series' && prox ? prox : t;
    const d = await marcarAssistido(s, alvo.Id, !alvo.UserData?.Played);
    if (alvo === t) setT({ ...t, UserData: { ...t.UserData, ...d } });
    else { setProx(await proximoDaSerie(s, t.Id)); if (temp) setEps(await episodios(s, t.Id, temp)); }
  }

  if (erro) return <main class="titulo"><p class="erro">{erro}</p><button data-foco class="botao" onClick={voltar}>Voltar</button></main>;
  if (!t) return <main class="titulo carregando" aria-busy="true" />;

  const serie = t.Type === 'Series';
  const alvo = serie ? prox : t;
  const pos = alvo?.UserData?.PlaybackPositionTicks || 0;
  const rotuloPlay = serie
    ? (prox ? `${pos ? 'Continuar' : 'Assistir'} ${codigo(prox)}` : 'Assistir')
    : (pos ? 'Continuar' : 'Assistir');
  const img = fundo(s, t), lg = logo(s, t);
  const meta = [t.ProductionYear, t.OfficialRating, serie ? (temps.length ? `${temps.length} temporada${temps.length > 1 ? 's' : ''}` : '') : duracao(t.RunTimeTicks),
    t.CommunityRating ? `★ ${t.CommunityRating.toFixed(1)}` : '', (t.Genres || []).slice(0, 3).join(', ')].filter(Boolean);

  function assistir() {
    if (serie) { const e = prox || eps[0]; if (e) irVer(e.Id, e.UserData?.PlaybackPositionTicks); }
    else irVer(t!.Id, pos || undefined);
  }

  return (
    <main class="titulo">
      <div class="titulo-fundo">{img && <img src={img} alt="" />}</div>
      <header class="titulo-topo">
        <button data-foco class="aba" onClick={voltar} aria-label="Voltar"><Icone nome="arrow_back" /><span>Voltar</span></button>
      </header>
      <section class="titulo-info">
        {lg ? <img class="titulo-logo" src={lg} alt={t.Name} /> : <h1>{t.Name}</h1>}
        <p class="titulo-meta">{meta.join(' · ')}</p>
        {t.Taglines?.[0] && <p class="titulo-frase">{t.Taglines[0]}</p>}
        <p class="titulo-sinopse">{serie && prox ? prox.Overview || t.Overview : t.Overview}</p>
        <div class="titulo-acoes">
          <button data-foco ref={play} class="botao botao-play" onClick={assistir}>
            <Icone nome="play_arrow" cheio />{rotuloPlay}
          </button>
          {alvo && <button data-foco class={alvo.UserData?.Played ? 'botao-sec ativo' : 'botao-sec'} onClick={alternarAssistido}
            aria-pressed={!!alvo.UserData?.Played} title={serie ? `Marcar ${codigo(alvo)} como assistido` : 'Marcar como assistido'}>
            <Icone nome={alvo.UserData?.Played ? 'check_circle' : 'check'} cheio={!!alvo.UserData?.Played} />
            <span>{alvo.UserData?.Played ? 'Assistido' : 'Marcar assistido'}</span>
          </button>}
        </div>
        {pos > 0 && alvo?.RunTimeTicks ? (
          <div class="titulo-progresso"><span class="progresso-barra"><span style={{ width: `${Math.min(100, pos / alvo.RunTimeTicks * 100)}%` }} /></span>
            <small>Faltam {resta(alvo)}</small></div>
        ) : null}
      </section>

      {serie && (
        <section class="temporadas">
          <div class="temporadas-abas" role="tablist">
            {temps.map(x => (
              <button data-foco role="tab" aria-selected={x.Id === temp} class={x.Id === temp ? 'aba ativa' : 'aba'} key={x.Id} onClick={() => setTemp(x.Id)}>
                {x.Name}
              </button>
            ))}
          </div>
          <ol class="episodios">
            {eps.map(e => {
              const p = e.UserData?.PlayedPercentage;
              return (
                <li key={e.Id}>
                  <button data-foco class="episodio" onClick={() => irVer(e.Id, e.UserData?.PlaybackPositionTicks)}>
                    <span class="episodio-img">
                      <img loading="lazy" decoding="async" src={miniatura(s, e)} alt="" />
                      {p ? <span class="progresso"><span style={{ width: `${p}%` }} /></span> : null}
                      {e.UserData?.Played && <span class="episodio-visto"><Icone nome="check_circle" cheio tamanho={20} /></span>}
                    </span>
                    <span class="episodio-texto">
                      <strong>{e.IndexNumber}. {e.Name}</strong>
                      <small>{duracao(e.RunTimeTicks)}</small>
                      <span class="episodio-sinopse">{e.Overview}</span>
                    </span>
                  </button>
                </li>
              );
            })}
          </ol>
        </section>
      )}
    </main>
  );
}
