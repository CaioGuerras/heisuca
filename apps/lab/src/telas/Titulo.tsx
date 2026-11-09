// Título: abre na hora com a prévia do cartão (imagem, cor e nome), completa quando o servidor responde.
// A página inteira é tingida pela cor do pôster (--tinta), sem mudar o tema escolhido.
import { useEffect, useMemo, useState } from 'preact/hooks';
import {
  episodios, fotoPessoa, fundo, hashDe, item, logo, paisagem, proximoDaSerie, temporadas,
  type Item, type Pessoa, type Sessao,
} from '@w/api/servidor';
import { Imagem } from '@w/comp/Imagem';
import { avisar } from '@w/comp/Aviso';
import { corDaBase } from '@w/cor/paleta';
import { previa } from '@w/dados/previa';
import { progressoAssistido } from '@w/dados/progresso';
import { selosDeMidia } from '@w/dados/selos';
import { alternarFavorito, alternarVisto, useDados } from '@w/estado/usuario';
import { irVer, voltar } from '@w/rota';
import { Poster, duracao, nota } from '../comp/Cartao';
import { Fileira, FileiraFantasma } from '../comp/Fileira';
import { Ic } from '../comp/Icone';
import { semelhantes } from '../dados/catalogo';

type ItemT = Item & { LocalTrailerCount?: number; RemoteTrailers?: { Url?: string; Name?: string }[] };

export function Titulo({ s, id }: { s: Sessao; id: string }) {
  const [i, setI] = useState<ItemT | null>(() => previa(id));
  const [completo, setCompleto] = useState(false);
  const [erro, setErro] = useState(false);
  useEffect(() => {
    let vivo = true;
    item(s, id).then(x => { if (vivo) { setI(x); setCompleto(true); } }).catch(() => vivo && setErro(true));
    return () => { vivo = false; };
  }, [id]);
  const rgb = useMemo(() => corDaBase(hashDe(s, i, 'Primary') || hashDe(s, i, 'Backdrop')), [i?.Id, completo]);
  useEffect(() => { if (i) document.title = `${i.Name} · Lume`; return () => { document.title = 'Lume'; }; }, [i?.Name]);

  if (erro && !i) return <div class="vazio"><p>Não foi possível abrir este título.</p><button class="botao" onClick={voltar}>Voltar</button></div>;
  if (!i) return <div class="titulo fantasma"><div class="titulo-arte" /><div class="titulo-corpo"><span class="osso" style="width:40%;height:48px" /></div></div>;
  const tinta = rgb ? `${rgb[0]} ${rgb[1]} ${rgb[2]}` : undefined;
  return (
    <article class="titulo" style={tinta ? `--tinta-rgb:${tinta}` : undefined}>
      <div class="titulo-arte" aria-hidden="true">
        <Imagem src={fundo(s, i, 1920)} hash={hashDe(s, i, 'Backdrop') || hashDe(s, i, 'Primary')} prioridade />
      </div>
      <div class="titulo-veu" aria-hidden="true" />
      <div class="titulo-corpo">
        <Cabeca s={s} i={i} completo={completo} />
        {i.Type === 'Series' && <Temporadas s={s} serie={i} />}
        {completo && <Elenco s={s} pessoas={i.People || []} />}
        {completo && <Semelhantes s={s} id={i.Id} />}
        {completo && <Ficha i={i} />}
      </div>
    </article>
  );
}

function Cabeca({ s, i, completo }: { s: Sessao; i: ItemT; completo: boolean }) {
  const d = useDados(s, i);
  const [prox, setProx] = useState<Item | null>(null);
  useEffect(() => { if (i.Type === 'Series') proximoDaSerie(s, i.Id).then(setProx).catch(() => {}); }, [i.Id]);
  const selos = selosDeMidia(i.MediaStreams || []);
  const meta = [i.ProductionYear && (i.EndDate && i.Type === 'Series' ? `${i.ProductionYear}–${new Date(i.EndDate).getFullYear()}` : i.ProductionYear),
    i.OfficialRating, i.Type === 'Movie' ? duracao(i.RunTimeTicks) : i.ChildCount ? `${i.ChildCount} temporada${i.ChildCount > 1 ? 's' : ''}` : ''].filter(Boolean);
  const generos = (i.Genres || []).slice(0, 3).join(', ');
  const pos = d.PlaybackPositionTicks || 0;
  const pct = progressoAssistido(d, i.RunTimeTicks);
  const assistir = () => {
    if (i.Type === 'Series') { if (prox) irVer(prox.Id, prox.UserData?.PlaybackPositionTicks); else document.querySelector('.temporadas')?.scrollIntoView({ behavior: 'smooth' }); }
    else irVer(i.Id, pos);
  };
  const rotulo = i.Type === 'Series'
    ? prox ? `${prox.UserData?.PlaybackPositionTicks ? 'Continuar' : 'Assistir'} T${prox.ParentIndexNumber ?? '?'}:E${prox.IndexNumber ?? '?'}` : 'Ver episódios'
    : pos ? 'Continuar' : 'Assistir';
  const trailer = i.RemoteTrailers?.find(t => t.Url)?.Url;
  const compartilhar = async () => {
    const url = location.href;
    try {
      if (navigator.share) { await navigator.share({ title: i.Name, url }); return; }
      await navigator.clipboard.writeText(url); avisar('Link copiado');
    } catch (e) { if ((e as Error)?.name !== 'AbortError') avisar('Não deu para compartilhar'); }
  };
  return (
    <header class="titulo-cabeca">
      {i.ImageTags?.Logo ? <h1 class="titulo-logo"><img src={logo(s, i, 800)} alt={i.Name} /></h1> : <h1 class="titulo-nome">{i.Name}</h1>}
      {i.Taglines?.[0] && <p class="titulo-frase">{i.Taglines[0]}</p>}
      <p class="titulo-meta">
        {i.CommunityRating ? <span class="nota"><Ic n="star-fill" t={16} />{nota(i)}</span> : null}
        {meta.map((m, k) => <span key={k}>{m}</span>)}
      </p>
      {(generos || selos.length > 0) && <p class="titulo-generos">
        {generos && <span>{generos}</span>}
        {selos.map(x => <span class="selo" key={x}>{x}</span>)}
      </p>}
      <div class="titulo-botoes">
        <button class="botao primario grande" onClick={assistir}>
          <Ic n="play_arrow-fill" t={24} /><span>{rotulo}</span>
          {pct > 0 && pct < 100 && i.Type !== 'Series' && <span class="botao-progresso" style={`--p:${pct}%`} />}
        </button>
        <BotaoIcone ativo={!!d.IsFavorite} ic={d.IsFavorite ? 'bookmark-fill' : 'bookmark'} rotulo={d.IsFavorite ? 'Na sua lista' : 'Minha lista'}
          onClick={() => alternarFavorito(s, i).then(v => avisar(v ? 'Adicionado à sua lista' : 'Removido da sua lista'), () => avisar('Não deu para salvar'))} />
        <BotaoIcone ativo={!!d.Played} ic={d.Played ? 'check_circle-fill' : 'check_circle'} rotulo={d.Played ? 'Visto' : 'Marcar visto'}
          onClick={() => alternarVisto(s, i).catch(() => avisar('Não deu para salvar'))} />
        {trailer && <a class="botao-icone" href={trailer} target="_blank" rel="noopener noreferrer"><span class="redondo"><Ic n="movie" t={22} /></span><span>Trailer</span></a>}
        {!trailer && (i.LocalTrailerCount || 0) > 0 && <BotaoIcone ic="movie" rotulo="Trailer" onClick={() => avisar('Trailer local: abrir no Heisuca')} />}
        <BotaoIcone ic="ios_share" rotulo="Compartilhar" onClick={compartilhar} />
      </div>
      {i.Overview ? <Sinopse texto={i.Overview} /> : !completo ? <p class="titulo-sinopse"><span class="osso" style="width:90%" /><span class="osso" style="width:70%" /></p> : null}
    </header>
  );
}

function BotaoIcone({ ic, rotulo, onClick, ativo }: { ic: string; rotulo: string; onClick: () => void; ativo?: boolean }) {
  return <button class={`botao-icone${ativo ? ' ativo' : ''}`} aria-pressed={ativo} onClick={onClick}>
    <span class="redondo"><Ic n={ic} t={22} /></span><span>{rotulo}</span></button>;
}

function Sinopse({ texto }: { texto: string }) {
  const [aberta, setAberta] = useState(false);
  const longa = texto.length > 280;
  return <div class="titulo-sinopse">
    <p class={longa && !aberta ? 'cortada' : ''}>{texto}</p>
    {longa && <button class="link" onClick={() => setAberta(!aberta)}>{aberta ? 'Mostrar menos' : 'Ler mais'}</button>}
  </div>;
}

function Temporadas({ s, serie }: { s: Sessao; serie: Item }) {
  const [lista, setLista] = useState<Item[] | null>(null);
  const [atual, setAtual] = useState<string>('');
  const [eps, setEps] = useState<Item[] | null>(null);
  useEffect(() => {
    temporadas(s, serie.Id).then(t => {
      setLista(t);
      // abre na primeira temporada com episódio não visto (onde a pessoa parou)
      const ini = t.find(x => (x.UserData?.UnplayedItemCount || 0) > 0 && x.IndexNumber !== 0) || t.find(x => x.IndexNumber !== 0) || t[0];
      if (ini) setAtual(ini.Id);
    }).catch(() => setLista([]));
  }, [serie.Id]);
  useEffect(() => {
    if (!atual) return; let vivo = true; setEps(null);
    episodios(s, serie.Id, atual).then(e => vivo && setEps(e)).catch(() => vivo && setEps([]));
    return () => { vivo = false; };
  }, [atual]);
  if (lista && !lista.length) return null;
  return (
    <section class="temporadas" aria-labelledby="temporadas-t">
      <div class="temporadas-topo">
        <h2 id="temporadas-t">Episódios</h2>
        {lista && lista.length > 1 && <div class="chips" role="tablist" aria-label="Temporadas">
          {lista.map(t => <button key={t.Id} role="tab" aria-selected={t.Id === atual} class={`chip${t.Id === atual ? ' ativo' : ''}`}
            onClick={() => setAtual(t.Id)}>{t.IndexNumber === 0 ? 'Especiais' : t.Name}</button>)}
        </div>}
      </div>
      <ol class="episodios" aria-busy={!eps}>
        {!eps ? [0, 1, 2].map(k => <li key={k} class="episodio fantasma"><span class="episodio-arte osso" /><span class="episodio-texto"><span class="osso" style="width:50%" /><span class="osso" style="width:90%" /></span></li>)
          : eps.map((e, k) => <Episodio key={e.Id} s={s} e={e} ordem={k} />)}
      </ol>
    </section>
  );
}

function Episodio({ s, e, ordem }: { s: Sessao; e: Item; ordem: number }) {
  const d = useDados(s, e);
  const pct = d.Played ? 100 : progressoAssistido(d, e.RunTimeTicks);
  return (
    <li class={`episodio${d.Played ? ' visto' : ''}`} style={`--i:${Math.min(ordem, 5)}`}>
      <button class="episodio-arte" onClick={() => irVer(e.Id, d.Played ? 0 : d.PlaybackPositionTicks)} aria-label={`Assistir ${e.Name}`}>
        <Imagem src={paisagem(s, e, 480)} hash={hashDe(s, e, 'Primary')} />
        <span class="episodio-play" aria-hidden="true"><Ic n="play_arrow-fill" t={28} /></span>
        {pct > 0 && pct < 100 && <span class="cartao-progresso"><span style={`width:${pct}%`} /></span>}
      </button>
      <div class="episodio-texto">
        <h3><span class="episodio-n">{e.IndexNumber ?? ''}</span>{e.Name}</h3>
        <p class="episodio-meta">{duracao(e.RunTimeTicks)}{d.Played && <span class="visto-selo"><Ic n="check" t={14} />Visto</span>}</p>
        {e.Overview && <p class="episodio-sinopse">{e.Overview}</p>}
      </div>
      <button class="episodio-visto redondo" aria-pressed={!!d.Played} aria-label={d.Played ? 'Desmarcar visto' : 'Marcar visto'}
        onClick={() => alternarVisto(s, e).catch(() => avisar('Não deu para salvar'))}><Ic n={d.Played ? 'check_circle-fill' : 'check_circle'} t={20} /></button>
    </li>
  );
}

function Elenco({ s, pessoas }: { s: Sessao; pessoas: Pessoa[] }) {
  const atores = pessoas.filter(p => p.Type === 'Actor').slice(0, 18);
  if (!atores.length) return null;
  return <Fileira titulo="Elenco" tipo="pessoa">
    {atores.map((p, k) => <div class="pessoa" key={p.Id + k} style={`--i:${Math.min(k, 5)}`}>
      <span class="pessoa-foto">{p.PrimaryImageTag ? <Imagem src={fotoPessoa(s, p, 200)} alt="" /> : <span class="pessoa-inicial">{p.Name[0]}</span>}</span>
      <span class="pessoa-nome">{p.Name}</span>{p.Role && <span class="pessoa-papel">{p.Role}</span>}
    </div>)}
  </Fileira>;
}

function Semelhantes({ s, id }: { s: Sessao; id: string }) {
  const [itens, setItens] = useState<Item[] | null>(null);
  useEffect(() => { semelhantes(s, id).then(setItens).catch(() => setItens([])); }, [id]);
  if (!itens) return <FileiraFantasma />;
  if (!itens.length) return null;
  return <Fileira titulo="Mais como este">{itens.map((x, k) => <Poster key={x.Id} s={s} i={x} ordem={k} />)}</Fileira>;
}

function Ficha({ i }: { i: Item }) {
  const por = (t: string) => (i.People || []).filter(p => p.Type === t).map(p => p.Name).slice(0, 4).join(', ');
  const linhas: [string, string][] = ([
    ['Direção', por('Director')], ['Roteiro', por('Writer')], ['Estúdio', (i.Studios || []).map(x => x.Name).slice(0, 3).join(', ')],
    ['Gêneros', (i.Genres || []).join(', ')], ['Estreia', i.PremiereDate ? new Date(i.PremiereDate).toLocaleDateString('pt-BR', { day: 'numeric', month: 'long', year: 'numeric' }) : ''],
  ] as [string, string][]).filter(([, v]) => v);
  if (!linhas.length) return null;
  return <section class="ficha" aria-label="Ficha técnica"><dl>{linhas.map(([k, v]) => <div key={k}><dt>{k}</dt><dd>{v}</dd></div>)}</dl></section>;
}

export default Titulo;
