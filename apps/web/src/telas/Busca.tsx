// Busca (PLANO §8; ref/app_completo/…busca_seerr; o VidHub não tem pedidos: ref/vidhub/…busca).
//  Topo: ← Buscar; campo em pílula com 🔍 e ✕. Busca a partir de 2 letras, 300 ms depois de parar de digitar.
//  Do acervo: pôster, título, `BR-14 • 2015 • 2h 28m • 6,6★`, sinopse em 3 linhas, `<servidor> • <biblioteca>`.
//  "Disponível para pedir": só se o servidor tiver Seerr (temSeerr); "+ Pedir" abre a FolhaPedido (série escolhe temporadas).
import { useEffect, useRef, useState } from 'preact/hooks';
import { bibliotecasDeVideo, capa, hashDe, obter, type Item, type Sessao } from '../api/jellyfin';
import { buscar as buscarSeerr, poster, SELO, temSeerr, type Resultado } from '../api/seerr';
import { usePaleta } from '../cor/paleta';
import { nota } from '../comp/Cartoes';
import { Icone } from '../comp/Icone';
import { Imagem } from '../comp/Imagem';
import { FolhaPedido, type Alvo } from '../comp/Pedido';
import { irTitulo, voltar } from '../rota';
import './busca.css';

const ESPERA = 300, MINIMO = 2;
const CAMPOS = 'fields=Overview,ProductionYear,OfficialRating,CommunityRating&enableImageTypes=Primary&imageTypeLimit=1';
type Achado = Item & { biblioteca?: string };

// busca em cada biblioteca de vídeo: assim cada resultado sabe de qual biblioteca veio (o ParentId do item é a pasta, não a biblioteca)
async function buscarAcervo(s: Sessao, termo: string): Promise<Achado[]> {
  const libs = (await bibliotecasDeVideo(s)).filter(b => b.CollectionType !== 'boxsets');
  const q = encodeURIComponent(termo);
  const listas = await Promise.all(libs.map(b => obter<{ Items: Item[] }>(s, `/Items?userId=${s.usuarioId}&parentId=${b.Id}&searchTerm=${q}` +
    `&recursive=true&includeItemTypes=Movie,Series&limit=30&${CAMPOS}`).then(d => d.Items.map(i => ({ ...i, biblioteca: b.Name, tipoLib: b.CollectionType })),
      () => [] as (Achado & { tipoLib?: string })[])));
  // o mesmo item em duas bibliotecas: fica a que é do tipo dele (filme em biblioteca de filmes, série em biblioteca de séries)
  const doTipo = (i: Achado & { tipoLib?: string }) => (i.Type === 'Movie' ? 'movies' : 'tvshows') === i.tipoLib;
  const pos = new Map<string, number>(), saida: (Achado & { tipoLib?: string })[] = [];
  for (const l of listas) for (const i of l) {
    const n = pos.get(i.Id);
    if (n === undefined) { pos.set(i.Id, saida.length); saida.push(i); } else if (!doTipo(saida[n]) && doTipo(i)) saida[n] = i;
  }
  // os que começam com o termo primeiro; depois a ordem do servidor (relevância)
  const t = termo.toLowerCase();
  return saida.map((i, n) => ({ i, n, p: i.Name.toLowerCase().startsWith(t) ? 0 : 1 })).sort((a, b) => a.p - b.p || a.n - b.n).map(x => x.i);
}

const duracao = (ticks?: number) => {
  if (!ticks) return '';
  const m = Math.round(ticks / 6e8), h = Math.floor(m / 60);
  return h ? `${h}h ${String(m % 60).padStart(2, '0')}m` : `${m}m`;
};
// a duração só faz sentido no filme (na série o servidor dá a média de um episódio)
const linhaInfo = (i: Item) => [i.OfficialRating, i.ProductionYear, i.Type === 'Movie' ? duracao(i.RunTimeTicks) : '',
  nota(i) && `${nota(i)}★`].filter(Boolean).join(' • ');

type Estado<T> = { termo: string; itens: T[] | null; erro?: boolean };

export function Busca({ s }: { s: Sessao }) {
  usePaleta(null);
  const [texto, setTexto] = useState('');
  const [termo, setTermo] = useState('');
  const [acervo, setAcervo] = useState<Estado<Achado>>({ termo: '', itens: null });
  const [pedir, setPedir] = useState<Estado<Resultado>>({ termo: '', itens: null });
  const [seerr, setSeerr] = useState(false);
  const [alvo, setAlvo] = useState<Alvo | null>(null);
  const [pedidos, setPedidos] = useState<Set<number>>(new Set());
  const campo = useRef<HTMLInputElement>(null);

  useEffect(() => { temSeerr(s).then(setSeerr); campo.current?.focus({ preventScroll: true }); }, [s.servidor]);
  // 300 ms depois de parar de digitar
  useEffect(() => {
    const t = texto.trim();
    if (t.length < MINIMO) { setTermo(''); return; }
    const id = setTimeout(() => setTermo(t), ESPERA);
    return () => clearTimeout(id);
  }, [texto]);
  useEffect(() => {
    if (!termo) return;
    let vivo = true;
    buscarAcervo(s, termo).then(itens => vivo && setAcervo({ termo, itens }), () => vivo && setAcervo({ termo, itens: [], erro: true }));
    return () => { vivo = false; };
  }, [termo]);
  useEffect(() => {
    if (!termo || !seerr) return;
    let vivo = true;
    buscarSeerr(s, termo).then(itens => vivo && setPedir({ termo, itens }), () => vivo && setPedir({ termo, itens: [], erro: true }));
    return () => { vivo = false; };
  }, [termo, seerr]);

  const limpar = () => { setTexto(''); setTermo(''); campo.current?.focus(); };
  const ativo = termo.length >= MINIMO;
  const doAcervo = ativo && acervo.termo === termo ? acervo.itens : null;
  const paraPedir = ativo && seerr && pedir.termo === termo ? pedir.itens : null;
  const carregando = ativo && (!doAcervo || (seerr && !paraPedir));
  const nada = ativo && doAcervo && !doAcervo.length && (!seerr || (paraPedir && !paraPedir.length));
  const servidor = s.nomeServidor || 'Servidor';

  return (
    <main class="busca">
      <header class="busca-topo">
        <div class="busca-titulo">
          <button class="redondo" onClick={voltar} aria-label="Voltar"><Icone nome="arrow_back" tamanho={24} /></button>
          <h1>Buscar</h1>
        </div>
        <label class="busca-campo">
          <Icone nome="search" tamanho={24} />
          <input ref={campo} type="search" enterkeyhint="search" autocomplete="off" spellcheck={false} placeholder="Filmes e séries"
            aria-label="Buscar filmes e séries" value={texto} onInput={e => setTexto((e.target as HTMLInputElement).value)}
            onKeyDown={e => { if (e.key === 'Escape' && texto) { e.preventDefault(); limpar(); } }} />
          {texto && <button class="busca-limpar" onClick={limpar} aria-label="Limpar"><Icone nome="close" tamanho={24} /></button>}
        </label>
      </header>

      <div class="busca-corpo" aria-live="polite" aria-busy={carregando ? 'true' : 'false'}>
        {!ativo && texto.trim().length === 1 && <p class="busca-dica texto-2">Digite mais uma letra.</p>}
        {nada && <div class="busca-vazio"><Icone nome="search_off" tamanho={40} /><p>Nada encontrado para “{termo}”.</p></div>}
        {ativo && doAcervo && acervo.erro && <p class="busca-dica texto-2">Não deu para buscar no servidor agora. Tente de novo.</p>}

        {ativo && !doAcervo && <ul class="busca-lista">{[0, 1, 2].map(n => <li key={n} class="busca-item"><span class="busca-capa esqueleto" /><span class="busca-esq"><span class="esqueleto" /><span class="esqueleto" /><span class="esqueleto" /></span></li>)}</ul>}
        {doAcervo && doAcervo.length > 0 && (
          <ul class="busca-lista">
            {doAcervo.map(i => (
              <li key={i.Id}>
                <button class="busca-item" onClick={() => irTitulo(i.Id)}>
                  <Imagem classe="busca-capa" src={capa(s, i, 330)} hash={hashDe(i, 'Primary')} alt="" />
                  <span class="busca-texto">
                    <strong class="busca-nome">{i.Name}</strong>
                    {linhaInfo(i) && <small class="busca-info">{linhaInfo(i)}</small>}
                    {i.Overview && <span class="busca-sinopse">{i.Overview}</span>}
                    <small class="busca-origem"><Icone nome="dns" tamanho={16} />{[servidor, i.biblioteca].filter(Boolean).join(' • ')}</small>
                  </span>
                </button>
              </li>
            ))}
          </ul>
        )}

        {seerr && ativo && (paraPedir === null ? doAcervo !== null : paraPedir.length > 0) && (
          <section class="busca-pedir" aria-label="Disponível para pedir">
            <h2 class="titulo-secao">Disponível para pedir</h2>
            <p class="texto-2">Ainda não temos. Peça e avisamos quando chegar.</p>
            {pedir.erro && <p class="texto-2">Pedidos indisponíveis agora.</p>}
            <ul class="busca-lista">
              {(paraPedir || [0, 1].map(n => ({ id: -1 - n } as Resultado))).map(r => {
                if (r.id < 0) return <li key={r.id} class="pedir-item"><span class="pedir-capa esqueleto" /><span class="busca-esq"><span class="esqueleto" /><span class="esqueleto" /></span></li>;
                const nome = r.title || r.name || '', data = r.releaseDate || r.firstAirDate || '', ano = data.slice(0, 4);
                const selo = pedidos.has(r.id) ? 'Pedido' : SELO[r.mediaInfo?.status || 0];
                const img = poster(s, r.posterPath);
                return (
                  <li key={`${r.mediaType}-${r.id}`} class="pedir-item">
                    {img ? <img class="pedir-capa" src={img} alt="" loading="lazy" /> : <span class="pedir-capa pedir-sem" aria-hidden="true"><Icone nome={r.mediaType === 'tv' ? 'tv' : 'movie'} tamanho={26} /></span>}
                    <span class="busca-texto">
                      <strong class="busca-nome uma-linha">{nome}</strong>
                      <small class="pedir-info">{[ano, r.mediaType === 'tv' ? 'Série' : 'Filme'].filter(Boolean).join(' · ')}</small>
                    </span>
                    {selo ? <span class="pedir-selo">{selo}</span>
                      : <button class="pilula pilula-tema pedir-botao" aria-label={`Pedir ${nome}`}
                          onClick={() => setAlvo({ tipo: r.mediaType as 'movie' | 'tv', id: r.id, nome, posterPath: r.posterPath, ano })}>
                          <Icone nome="add" tamanho={22} />Pedir</button>}
                  </li>
                );
              })}
            </ul>
          </section>
        )}
      </div>
      <FolhaPedido s={s} alvo={alvo} fechar={() => setAlvo(null)} pedido={() => alvo && setPedidos(p => new Set(p).add(alvo.id))} />
    </main>
  );
}
