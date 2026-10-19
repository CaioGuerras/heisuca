// Título: série, filme e coleção (PLANO §5; ref/vidhub/…foto42, …foto43, …foto44).
//  Arte até o topo que se dissolve na cor do pôster · ← (sem ⋯) · logo · ★ nota | data | estúdio | gêneros | [idade]
//  · linha pequena "3 temps. · 1h2min · 1080p H264 SDR" · Reproduzir largo que GRUDA NO TOPO ao rolar · ♡ ⚑ · sinopse
//  「Série·Temp. 1·EP 1」 · Temporada ⌄ (folha contida) + Ver tudo › · episódios 16:9 com páginas 1-10 / 11-12
//  · Elenco em quadrado arredondado · Gêneros em pílulas · Info mídia (Vídeo e Áudio, sem caminho de arquivo).
// Só dado real: linha sem valor não aparece (PLANO §1.7).
import { useEffect, useMemo, useRef, useState } from 'preact/hooks';
import { daColecao, episodios, fotoPessoa, fundo, hashDe, item, logo, paisagem, proximoDaSerie, temporadas,
  type Fluxo, type Item, type Pessoa, type Sessao } from '../api/jellyfin';
import { usePaleta } from '../cor/paleta';
import { CartaoPoster, EsqueletoCartoes, nota, relogio } from '../comp/Cartoes';
import { Fileira } from '../comp/Fileira';
import { Folha } from '../comp/Folha';
import { Icone } from '../comp/Icone';
import { Imagem } from '../comp/Imagem';
import { useAcoes } from '../comp/MenuContexto';
import { avisar } from '../comp/Aviso';
import { alternarFavorito, alternarVisto, useDados } from '../estado/usuario';
import { irTitulo, irVer, voltar } from '../rota';
import './titulo.css';

const TICKS = 10_000_000;
const POR_PAGINA = 10;

// ---- formatação (só do que existe) ----
const dataBR = (iso?: string) => iso ? new Date(iso).toLocaleDateString('pt-BR', { timeZone: 'UTC' }) : '';
function duracao(ticks?: number): string {
  const min = Math.floor((ticks || 0) / TICKS / 60);
  if (!min) return '';
  return min >= 60 ? `${Math.floor(min / 60)}h${min % 60 ? `${min % 60}min` : ''}` : `${min}min`;
}
const numero = (n: number, casas = 0) => n.toLocaleString('pt-BR', { maximumFractionDigits: casas });
const taxa = (bps?: number) => !bps ? '' : bps >= 1e6 ? `${numero(bps / 1e6, 1)} Mbps` : `${Math.round(bps / 1000)} kbps`;
const CODECS: Record<string, string> = { h264: 'H.264', hevc: 'HEVC (H.265)', h265: 'HEVC (H.265)', av1: 'AV1', vp9: 'VP9', mpeg2video: 'MPEG-2',
  aac: 'AAC', ac3: 'Dolby Digital (AC-3)', eac3: 'Dolby Digital+ (E-AC-3)', truehd: 'Dolby TrueHD', dts: 'DTS', flac: 'FLAC', opus: 'Opus', mp3: 'MP3', vorbis: 'Vorbis' };
const codec = (c?: string) => c ? (CODECS[c.toLowerCase()] || c.toUpperCase()) : '';
const LINGUA3: Record<string, string> = { por: 'pt', eng: 'en', jpn: 'ja', spa: 'es', fre: 'fr', fra: 'fr', ger: 'de', deu: 'de', ita: 'it',
  kor: 'ko', chi: 'zh', zho: 'zh', rus: 'ru', ara: 'ar', hin: 'hi', pol: 'pl', tur: 'tr', dut: 'nl', nld: 'nl', swe: 'sv' };
let nomesLingua: Intl.DisplayNames | null = null;
function idioma(f: Fluxo): string {
  const l = (f.Language || '').toLowerCase();
  if (!l || l === 'und') return '';
  // o servidor marca o português do Brasil como "pt-br" ou como "por" + título "(Brazil)"
  const br = l === 'pt-br' || (l === 'por' && /bra[sz]il/i.test(`${f.Title || ''} ${f.DisplayTitle || ''}`));
  const codigo = br ? 'pt-BR' : (LINGUA3[l] || l);
  try { nomesLingua ??= new Intl.DisplayNames(['pt-BR'], { type: 'language' }); const n = nomesLingua.of(codigo) || ''; return n.charAt(0).toUpperCase() + n.slice(1); }
  catch { return l; }
}
function canais(f: Fluxo): string {
  const c = (f.ChannelLayout || '').toLowerCase();
  if (c === 'stereo' || (!c && f.Channels === 2)) return 'Estéreo (2.0)';
  if (c === 'mono' || (!c && f.Channels === 1)) return 'Mono';
  if (c) return c.replace(/\(.*\)/, '').trim();
  return f.Channels ? `${f.Channels} canais` : '';
}
const faixa = (f: Fluxo) => [f.VideoRangeType, f.VideoRange].find(x => x && x !== 'Unknown') || '';
// "1080p H264 SDR" montado do próprio fluxo (o DisplayTitle às vezes traz o nome do grupo que lançou o arquivo)
function resumoVideo(f?: Fluxo): string {
  if (!f) return '';
  const w = f.Width || 0, h = f.Height || 0;
  const res = w >= 3800 ? '4K' : w >= 2500 ? '1440p' : w >= 1900 ? '1080p' : w >= 1260 ? '720p' : h ? `${h}p` : '';
  return [res, (f.Codec || '').toUpperCase(), faixa(f)].filter(Boolean).join(' ');
}
const fps = (f: Fluxo) => { const q = f.RealFrameRate || f.AverageFrameRate; return q ? numero(q, 3) : ''; };

const ehSerie = (i: Item) => i.Type === 'Series';
const ehColecao = (i: Item) => i.Type === 'BoxSet';
const rotuloEp = (e: Item) => `T${e.ParentIndexNumber ?? '?'}:E${e.IndexNumber ?? '?'}`;

export function Titulo({ s, id }: { s: Sessao; id: string }) {
  const [it, setIt] = useState<Item | null>(null);
  const [erro, setErro] = useState(false);
  useEffect(() => {
    let vivo = true;
    setIt(null); setErro(false);
    item(s, id).then(i => {
      if (!vivo) return;
      // episódio ou temporada abrem a página da série (o link continua valendo)
      if ((i.Type === 'Episode' || i.Type === 'Season') && i.SeriesId) { location.replace(`#/t/${i.SeriesId}`); return; }
      setIt(i);
    }).catch(() => vivo && setErro(true));
    return () => { vivo = false; };
  }, [id, s.token]);
  usePaleta(hashDe(it, 'Backdrop') || hashDe(it, 'Primary'));

  if (erro) return (
    <main class="titulo titulo-erro">
      <BotaoVoltar />
      <p>Não deu para abrir este título.</p>
      <button class="pilula pilula-vidro" onClick={() => location.reload()}>Tentar de novo</button>
    </main>
  );
  if (!it) return <main class="titulo"><BotaoVoltar /><div class="titulo-arte esqueleto" aria-hidden="true" /></main>;
  return <Pagina key={it.Id} s={s} it={it} />;
}

const BotaoVoltar = () => (
  <button class="redondo titulo-voltar" onClick={voltar} aria-label="Voltar"><Icone nome="arrow_back" tamanho={24} /></button>
);

function Pagina({ s, it }: { s: Sessao; it: Item }) {
  const serie = ehSerie(it), colecao = ehColecao(it);
  const [temps, setTemps] = useState<Item[]>([]);
  const [atual, setAtual] = useState<Item | null>(null);        // o episódio da vez (próximo a ver ou o que está em andamento)
  const [tempSel, setTempSel] = useState<string>('');
  const [eps, setEps] = useState<Item[] | null>(null);
  const [filhos, setFilhos] = useState<Item[] | null>(null);    // títulos da coleção
  const [escolhendo, setEscolhendo] = useState(false);
  const [lista, setLista] = useState(false);
  const cacheEps = useRef(new Map<string, Item[]>());

  // série: temporadas + episódio da vez
  useEffect(() => {
    if (!serie) return;
    Promise.all([temporadas(s, it.Id).catch(() => [] as Item[]), proximoDaSerie(s, it.Id).catch(() => null)]).then(([t, p]) => {
      setTemps(t);
      if (p) setAtual(p);
      const alvo = (p && t.find(x => x.Id === p.SeasonId)) || t.find(x => (x.IndexNumber ?? 0) > 0) || t[0];
      if (alvo) setTempSel(alvo.Id);
    });
  }, [it.Id]);
  useEffect(() => {
    if (!serie || !tempSel) return;
    const c = cacheEps.current.get(tempSel);
    if (c) { setEps(c); return; }
    setEps(null);
    let vivo = true;
    episodios(s, it.Id, tempSel).then(l => {
      cacheEps.current.set(tempSel, l);
      if (!vivo) return;
      setEps(l);
      setAtual(a => a || l[0] || null);      // sem "próximo" no servidor: o 1º episódio dá a sinopse e a mídia
    }).catch(() => vivo && setEps([]));
    return () => { vivo = false; };
  }, [tempSel]);
  useEffect(() => { if (colecao) daColecao(s, it.Id).then(setFilhos).catch(() => setFilhos([])); }, [it.Id]);

  const fonteMidia = serie ? atual : colecao ? null : it;      // série: os fluxos vêm do episódio da vez
  const fluxos = fonteMidia?.MediaStreams || [];
  const video = fluxos.find(f => f.Type === 'Video');
  const audios = fluxos.filter(f => f.Type === 'Audio');

  // linha pequena: 3 temps. · 1h2min · 1080p H264 SDR
  const nTemps = temps.filter(t => (t.IndexNumber ?? 0) > 0).length;
  const pequena = [
    serie && nTemps ? `${nTemps} ${nTemps === 1 ? 'temp.' : 'temps.'}` : '',
    colecao && filhos?.length ? `${filhos.length} ${filhos.length === 1 ? 'título' : 'títulos'}` : '',
    duracao(serie ? atual?.RunTimeTicks : it.RunTimeTicks),
    resumoVideo(video),
  ].filter(Boolean);

  // botão principal
  const dEp = atual ? (atual.UserData || {}) : {};
  const dIt = it.UserData || {};
  let rotulo = 'Reproduzir', alvo: Item | null = colecao ? null : serie ? atual : it, inicio: number | undefined;
  if (serie && atual) {
    const pos = dEp.PlaybackPositionTicks || 0;
    // "Continuar" só quando o episódio tem posição salva; senão "Reproduzir T1:E3" (Caio 19/10 noite, dúvida 17)
    rotulo = `${pos > 0 ? 'Continuar' : 'Reproduzir'} ${rotuloEp(atual)}`;
    if (pos > 0) inicio = pos;
  } else if (!serie && !colecao && (dIt.PlaybackPositionTicks || 0) > 0) {
    inicio = dIt.PlaybackPositionTicks; rotulo = `Continuar de ${relogio(inicio! / TICKS)}`;
  }

  const temp = temps.find(t => t.Id === tempSel);
  const sinopse = serie && atual?.Overview
    ? { marca: `${it.Name}·${atual.ParentIndexNumber === 0 ? 'Especial' : `Temp. ${atual.ParentIndexNumber ?? '?'}`}·EP ${atual.IndexNumber ?? '?'}`, texto: atual.Overview }
    : it.Overview ? { marca: it.Name, texto: it.Overview } : null;

  return (
    <main class="titulo">
      <BotaoVoltar />
      <Cabeca s={s} it={it} />
      <Acao pequena={pequena} rotulo={rotulo} alvo={alvo} inicio={inicio} />
      <Botoes s={s} it={it} />
      {sinopse && <Sinopse marca={sinopse.marca} texto={sinopse.texto} />}

      {serie && (
        <section class="titulo-eps">
          <header class="titulo-eps-cabeca">
            <button class="titulo-temp" onClick={() => setEscolhendo(true)} disabled={temps.length < 2} aria-haspopup="dialog">
              <span>{temp?.Name || 'Temporada'}</span>{temps.length > 1 && <Icone nome="keyboard_arrow_down" tamanho={22} />}
            </button>
            {!!eps?.length && <button class="fileira-tudo" onClick={() => setLista(true)}>Ver tudo<Icone nome="chevron_right" tamanho={20} /></button>}
          </header>
          <Episodios key={tempSel} s={s} eps={eps} atual={atual} />
        </section>
      )}

      {colecao && (
        <section class="titulo-bloco">
          <h2 class="titulo-secao">Títulos</h2>
          <div class="titulo-grade">
            {!filhos && <EsqueletoCartoes n={6} />}
            {filhos?.map(f => <CartaoPoster key={f.Id} s={s} i={f} aoAbrir={x => irTitulo(x.Id)} />)}
          </div>
          {filhos && !filhos.length && <p class="texto-2 titulo-vazio">Nenhum título desta coleção no servidor.</p>}
        </section>
      )}

      <Elenco s={s} pessoas={it.People || []} />
      {!!it.Genres?.length && (
        <section class="titulo-bloco">
          <h2 class="titulo-secao">Gêneros</h2>
          <ul class="titulo-generos">{it.Genres.map(g => <li key={g}>{g}</li>)}</ul>
        </section>
      )}
      <InfoMidia video={video} audios={audios} />

      {serie && (
        <Folha aberta={escolhendo} fechar={() => setEscolhendo(false)} titulo="Temporadas" classe="titulo-folha">
          <ul class="lista-opcoes">
            {temps.map(t => (
              <li key={t.Id}>
                <button class="opcao-linha" aria-current={t.Id === tempSel ? 'true' : undefined} onClick={() => { setTempSel(t.Id); setEscolhendo(false); }}>
                  <span class="opcao-texto"><strong>{t.Name}</strong>{t.ChildCount ? <small>{t.ChildCount} {t.ChildCount === 1 ? 'episódio' : 'episódios'}</small> : null}</span>
                  {t.Id === tempSel && <span class="opcao-marca"><Icone nome="check" tamanho={22} /></span>}
                </button>
              </li>
            ))}
          </ul>
        </Folha>
      )}
      {serie && (
        <Folha aberta={lista} fechar={() => setLista(false)} titulo={temp?.Name || 'Episódios'} classe="titulo-folha titulo-folha-eps">
          <ul class="titulo-lista">
            {(eps || []).map(e => <LinhaEp key={e.Id} s={s} e={e} atual={e.Id === atual?.Id} />)}
          </ul>
        </Folha>
      )}
    </main>
  );
}

function Cabeca({ s, it }: { s: Sessao; it: Item }) {
  const lg = logo(s, it, 700);
  const [semLogo, setSemLogo] = useState(false);
  const arte = fundo(s, it, Math.min(1920, Math.round(innerWidth * devicePixelRatio)));
  const n = nota(it), estudio = it.Studios?.[0]?.Name;
  const meta = [
    n && <><span class="titulo-estrela">★</span> {n}</>,
    dataBR(it.PremiereDate) || (it.ProductionYear ? String(it.ProductionYear) : ''),
    estudio,
    it.Genres?.slice(0, 3).join(', '),
  ].filter(Boolean);
  return (
    <header class="titulo-cabeca">
      <div class="titulo-arte">
        <Imagem src={arte || undefined} hash={hashDe(it, 'Backdrop')} prioridade />
      </div>
      <div class="titulo-marca">
        {lg && !semLogo ? <img class="titulo-logo" src={lg} alt={it.Name} onError={() => setSemLogo(true)} />
          : <h1 class="titulo-nome">{it.Name}</h1>}
        {lg && !semLogo && <h1 class="visualmente-oculto">{it.Name}</h1>}
        {(meta.length > 0 || it.OfficialRating) && (
          <p class="titulo-meta">{meta.map((m, k) => <span key={k}>{m}</span>)}{it.OfficialRating && <span class="selo-idade">{it.OfficialRating}</span>}</p>
        )}
      </div>
    </header>
  );
}

// a linha pequena + o Reproduzir; grudam no topo quando a página rola (ref/vidhub/…foto43)
function Acao({ pequena, rotulo, alvo, inicio }: { pequena: string[]; rotulo: string; alvo: Item | null; inicio?: number }) {
  const caixa = useRef<HTMLDivElement>(null);
  const [grudado, setGrudado] = useState(false);
  useEffect(() => {
    const f = () => { const c = caixa.current; if (c) setGrudado(c.getBoundingClientRect().top <= parseFloat(getComputedStyle(c).top) + 0.5); };
    f(); addEventListener('scroll', f, { passive: true }); addEventListener('resize', f);
    return () => { removeEventListener('scroll', f); removeEventListener('resize', f); };
  }, []);
  return (
    <div ref={caixa} class={`titulo-acao${grudado ? ' grudado' : ''}`}>
      {pequena.length > 0 && <p class="titulo-pequena">{pequena.map((p, k) => <span key={k}>{p}</span>)}</p>}
      {alvo && (
        <button class="titulo-play" onClick={() => irVer(alvo.Id, inicio)}>
          <Icone nome="play_arrow" cheio tamanho={26} /><span class="uma-linha">{rotulo}</span>
        </button>
      )}
    </div>
  );
}

function Botoes({ s, it }: { s: Sessao; it: Item }) {
  const d = useDados(it);
  const erro = () => avisar('Não deu certo. Tente de novo.');
  return (
    <div class="titulo-botoes">
      <button class="titulo-botao" aria-pressed={!!d.IsFavorite} aria-label={d.IsFavorite ? 'Tirar dos favoritos' : 'Favoritar'} title={d.IsFavorite ? 'Tirar dos favoritos' : 'Favoritar'}
        onClick={() => alternarFavorito(s, it).then(v => avisar(v ? 'Guardado nos Favoritos.' : 'Tirado dos Favoritos.')).catch(erro)}>
        <Icone nome="favorite" cheio={!!d.IsFavorite} tamanho={28} />
      </button>
      <button class="titulo-botao" aria-pressed={!!d.Played} aria-label={d.Played ? 'Marcar como não visto' : 'Marcar como visto'} title={d.Played ? 'Marcar como não visto' : 'Marcar como visto'}
        onClick={() => alternarVisto(s, it).then(v => avisar(v ? 'Marcado como visto.' : 'Marcado como não visto.')).catch(erro)}>
        <Icone nome="flag" cheio={!!d.Played} tamanho={28} />
      </button>
    </div>
  );
}

function Sinopse({ marca, texto }: { marca: string; texto: string }) {
  const [aberta, setAberta] = useState(false);
  return (
    <p class={`titulo-sinopse${aberta ? ' aberta' : ''}`} onClick={() => setAberta(a => !a)}>
      <strong>「{marca}」</strong> {texto}
    </p>
  );
}

function Episodios({ s, eps, atual }: { s: Sessao; eps: Item[] | null; atual: Item | null }) {
  const paginas = useMemo(() => {
    const l = eps || [], p: Item[][] = [];
    for (let k = 0; k < l.length; k += POR_PAGINA) p.push(l.slice(k, k + POR_PAGINA));
    return p;
  }, [eps]);
  const inicial = Math.max(0, paginas.findIndex(p => p.some(e => e.Id === atual?.Id)));
  const [pag, setPag] = useState(inicial);
  useEffect(() => setPag(inicial), [paginas]);
  const trilho = useRef<HTMLDivElement>(null);
  // o episódio da vez à vista
  useEffect(() => {
    const el = trilho.current?.querySelector<HTMLElement>('.titulo-ep.atual');
    if (el && trilho.current) trilho.current.scrollLeft = Math.max(0, el.offsetLeft - trilho.current.offsetLeft - 14);
  }, [pag, paginas]);

  if (!eps) return <div class="titulo-trilho"><EsqueletoCartoes tipo="paisagem" n={3} /></div>;
  if (!eps.length) return <p class="texto-2 titulo-vazio">Nenhum episódio desta temporada no servidor.</p>;
  const nome = (p: Item[]) => {
    const a = p[0].IndexNumber, b = p[p.length - 1].IndexNumber;
    return a === undefined ? '' : a === b || b === undefined ? String(a) : `${a}-${b}`;
  };
  return (
    <>
      <div class="titulo-trilho" ref={trilho}>
        {(paginas[pag] || []).map(e => <CartaoEp key={e.Id} s={s} e={e} atual={e.Id === atual?.Id} />)}
      </div>
      {paginas.length > 1 && (
        <div class="titulo-paginas" role="tablist" aria-label="Páginas de episódios">
          {paginas.map((p, k) => (
            <button key={k} role="tab" aria-selected={k === pag} class={k === pag ? 'atual' : ''} onClick={() => setPag(k)}>{nome(p) || k + 1}</button>
          ))}
        </div>
      )}
    </>
  );
}

function CartaoEp({ s, e, atual }: { s: Sessao; e: Item; atual: boolean }) {
  const d = useDados(e), acoes = useAcoes(s, e);
  const dur = (e.RunTimeTicks || 0) / TICKS, pos = (d.PlaybackPositionTicks || 0) / TICKS;
  const pct = d.PlayedPercentage ?? (dur && pos ? pos / dur * 100 : 0);
  const titulo = `${e.IndexNumber !== undefined ? `${e.IndexNumber}. ` : ''}${e.Name}`;
  return (
    <button class={`titulo-ep${atual ? ' atual' : ''}`} onClick={() => irVer(e.Id, d.PlaybackPositionTicks || undefined)} {...acoes}
      aria-current={atual ? 'true' : undefined} aria-label={`${titulo}${d.Played ? ', visto' : ''}`}>
      <span class="titulo-ep-arte">
        <Imagem src={paisagem(s, e, 480)} hash={hashDe(e, 'Primary')} />
        {d.Played && <span class="cartao-visto"><Icone nome="check" tamanho={14} /></span>}
        {pct > 0 && !d.Played && <span class="cartao-barra"><span style={{ width: `${Math.min(100, pct)}%` }} /></span>}
      </span>
      <span class="titulo-ep-nome uma-linha">{titulo}</span>
    </button>
  );
}

function LinhaEp({ s, e, atual }: { s: Sessao; e: Item; atual: boolean }) {
  const d = useDados(e);
  return (
    <li>
      <button class={`titulo-linha${atual ? ' atual' : ''}`} onClick={() => irVer(e.Id, d.PlaybackPositionTicks || undefined)}>
        <span class="titulo-linha-arte"><Imagem src={paisagem(s, e, 320)} hash={hashDe(e, 'Primary')} />
          {d.Played && <span class="cartao-visto"><Icone nome="check" tamanho={14} /></span>}</span>
        <span class="titulo-linha-texto">
          <strong class="uma-linha">{e.IndexNumber !== undefined ? `${e.IndexNumber}. ` : ''}{e.Name}</strong>
          {duracao(e.RunTimeTicks) && <small>{duracao(e.RunTimeTicks)}</small>}
          {e.Overview && <span class="duas-linhas">{e.Overview}</span>}
        </span>
      </button>
    </li>
  );
}

function Elenco({ s, pessoas }: { s: Sessao; pessoas: Pessoa[] }) {
  const atores = pessoas.filter(p => p.Type === 'Actor');
  const lista = (atores.length ? atores : pessoas.filter(p => p.Type === 'GuestStar')).slice(0, 30);
  if (!lista.length) return null;
  return (
    <Fileira titulo="Elenco" classe="titulo-elenco">
      {lista.map(p => {
        const f = fotoPessoa(s, p, 240);
        return (
          <div key={p.Id} class="titulo-pessoa">
            <span class="titulo-pessoa-foto">
              {f ? <Imagem src={f} hash={(p as Pessoa & { ImageBlurHashes?: { Primary?: Record<string, string> } }).ImageBlurHashes?.Primary?.[p.PrimaryImageTag || '']} />
                : <span class="titulo-silhueta"><Icone nome="person" cheio tamanho={34} /></span>}
            </span>
            <strong class="titulo-pessoa-nome">{p.Name}</strong>
            {p.Role && <span class="titulo-pessoa-papel">{p.Role}</span>}
          </div>
        );
      })}
    </Fileira>
  );
}

function InfoMidia({ video, audios }: { video?: Fluxo; audios: Fluxo[] }) {
  const linhasVideo: [string, string][] = video ? [
    ['Resolução', video.Width && video.Height ? `${video.Width} × ${video.Height}` : ''],
    ['Codec', [codec(video.Codec), video.Profile].filter(Boolean).join(' · ')],
    ['Faixa dinâmica', faixa(video)],
    ['Quadros por segundo', fps(video)],
    ['Taxa de bits', taxa(video.BitRate)],
  ] : [];
  const cartoes = [
    { titulo: 'Vídeo', icone: 'videocam', linhas: linhasVideo.filter(l => l[1]) },
    ...audios.map((a, k) => ({
      titulo: audios.length > 1 ? `Áudio ${k + 1}` : 'Áudio', icone: 'music_note',
      linhas: ([['Idioma', idioma(a)], ['Codec', codec(a.Codec)], ['Canais', canais(a)],
        ['Padrão', a.IsDefault === undefined ? '' : a.IsDefault ? 'Sim' : 'Não']] as [string, string][]).filter(l => l[1]),
    })),
  ].filter(c => c.linhas.length);
  if (!cartoes.length) return null;
  return (
    <section class="titulo-bloco">
      <h2 class="titulo-secao">Info mídia</h2>
      <div class="titulo-midia">
        {cartoes.map(c => (
          <div key={c.titulo} class="titulo-midia-cartao">
            <h3><Icone nome={c.icone} cheio tamanho={20} />{c.titulo}</h3>
            <dl>{c.linhas.map(([k, v]) => <div key={k}><dt>{k}</dt><dd>{v}</dd></div>)}</dl>
          </div>
        ))}
      </div>
    </section>
  );
}
