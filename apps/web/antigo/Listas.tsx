// Buscar (acervo primeiro, depois "Disponível para pedir" do Seerr), Biblioteca, Favoritos e Meus pedidos.
// Regras da busca iguais às do site atual e do app (app/ORDEM_1E_APP.md, SITE_REMODELAGEM.md).
import { useEffect, useRef, useState } from 'preact/hooks';
import { buscarAcervo, daBiblioteca, favoritos, type Item, type Sessao } from '../api/jellyfin';
import { buscar, detalhe, meusPedidos, poster, SELO, type Resultado } from '../api/seerr';
import { Grade } from '../comp/Fileira';
import { Icone } from '../comp/Icone';
import { listaBibliotecas } from '../comp/Navegacao';
import { avisar, type Alvo } from '../comp/Pedido';
import { irTitulo } from '../rota';

const ano = (r: Resultado) => (r.releaseDate || r.firstAirDate || '').slice(0, 4);
export const alvoDe = (r: Resultado): Alvo => ({ tipo: r.mediaType as 'movie' | 'tv', id: r.id, nome: r.title || r.name || '', posterPath: r.posterPath, ano: ano(r) });

export function Busca({ s, pedir }: { s: Sessao; pedir: (a: Alvo, depois?: () => void) => void }) {
  const [termo, setTermo] = useState(() => sessionStorage.getItem('heisuca.busca') || '');
  const [nossos, setNossos] = useState<Item[] | null>(null);
  const [fora, setFora] = useState<Resultado[] | null>(null);
  const [foraErro, setForaErro] = useState(false);
  const [rodada, setRodada] = useState(0);
  const campo = useRef<HTMLInputElement>(null), n = useRef(0);
  useEffect(() => { campo.current?.focus(); }, []);
  useEffect(() => {
    sessionStorage.setItem('heisuca.busca', termo);
    const q = termo.trim(), eu = ++n.current;
    if (q.length < 2) { setNossos(null); setFora(null); return; }
    const t = setTimeout(() => {
      buscarAcervo(s, q).then(r => { if (eu === n.current) setNossos(r); }).catch(() => { if (eu === n.current) setNossos([]); });
      setForaErro(false);
      buscar(s, q).then(r => { if (eu === n.current) setFora(r); }).catch(() => { if (eu === n.current) { setFora([]); setForaErro(true); } });
    }, 400);
    return () => clearTimeout(t);
  }, [termo, rodada]);
  const abrirFora = (r: Resultado) => {
    const st = r.mediaInfo?.status;
    if (st === 2 || st === 3) { avisar(`${r.title || r.name}: ${SELO[st].toLowerCase()}. Avisamos quando chegar.`); return; }
    pedir(alvoDe(r), () => setRodada(x => x + 1));  // refaz a lista: o pedido volta com o selo "Pedido"
  };
  return (
    <main class="pagina">
      <label class="busca-caixa">
        <Icone nome="search" />
        <input ref={campo} data-foco type="search" placeholder="Filmes, séries, animes…" value={termo} enterKeyHint="search"
          aria-label="Buscar" onInput={e => setTermo((e.target as HTMLInputElement).value)} />
        {termo && <button class="menu-fechar" aria-label="Limpar" onClick={() => { setTermo(''); campo.current?.focus(); }}><Icone nome="close" /></button>}
      </label>
      {termo.trim().length < 2 && <p class="pagina-nota">Procure no acervo. O que ainda não temos aparece embaixo, para pedir.</p>}
      {nossos && (nossos.length ? <><h2 class="pagina-sub">No Heisuca</h2><Grade s={s} itens={nossos} aoAbrir={i => irTitulo(i.Id)} /></>
        : <p class="pagina-nota">Nada no acervo com esse nome.</p>)}
      {fora && fora.length > 0 && (
        <>
          <h2 class="pagina-sub">Disponível para pedir</h2>
          <div class="grade">
            {fora.map(r => {
              const st = r.mediaInfo?.status || 0;
              return (
                <button data-foco class="cartao" key={`${r.mediaType}${r.id}`} onClick={() => abrirFora(r)} aria-label={`${r.title || r.name}, ${SELO[st] || 'pedir'}`}>
                  <img loading="lazy" decoding="async" src={poster(s, r.posterPath)} alt="" />
                  <span class="cartao-selo">{SELO[st] || 'Pedir'}</span>
                  <span class="cartao-nome">{r.title || r.name}</span>
                  <span class="cartao-sub">{[ano(r), r.mediaType === 'tv' ? 'Série' : 'Filme'].filter(Boolean).join(' · ')}</span>
                </button>
              );
            })}
          </div>
        </>
      )}
      {foraErro && <p class="pagina-nota">Pedidos indisponíveis agora.</p>}
    </main>
  );
}

export function Biblioteca({ s, id }: { s: Sessao; id: string }) {
  const [nome, setNome] = useState('');
  const [itens, setItens] = useState<Item[]>([]);
  const [total, setTotal] = useState(-1);
  const carregando = useRef(false);
  const mais = () => {
    if (carregando.current || (total >= 0 && itens.length >= total)) return;
    carregando.current = true;
    daBiblioteca(s, id, itens.length).then(d => { setItens(x => [...x, ...d.Items]); setTotal(d.TotalRecordCount); })
      .finally(() => { carregando.current = false; });
  };
  useEffect(() => { listaBibliotecas(s).then(l => setNome(l.find(b => b.Id === id)?.Name || '')); mais(); }, []);
  // carrega mais ao chegar perto do fim (rolagem ou foco do controle)
  useEffect(() => {
    const f = () => { if (innerHeight + scrollY > document.body.scrollHeight - 900) mais(); };
    addEventListener('scroll', f, { passive: true });
    return () => removeEventListener('scroll', f);
  });
  return (
    <main class="pagina">
      <h1 class="pagina-titulo">{nome}</h1>
      {total >= 0 && <p class="pagina-nota">{total} {total === 1 ? 'título' : 'títulos'}</p>}
      <Grade s={s} itens={itens} aoAbrir={i => irTitulo(i.Id)} />
      {total > itens.length && <button data-foco class="botao-sec pagina-mais" onClick={mais}>Carregar mais</button>}
    </main>
  );
}

export function Favoritos({ s }: { s: Sessao }) {
  const [itens, setItens] = useState<Item[] | null>(null);
  useEffect(() => { favoritos(s).then(setItens).catch(() => setItens([])); }, []);
  return (
    <main class="pagina">
      <h1 class="pagina-titulo">Favoritos</h1>
      {itens && !itens.length && <p class="pagina-nota">Nada aqui ainda. Na página do título, toque no coração para guardar.</p>}
      {itens && <Grade s={s} itens={itens} aoAbrir={i => irTitulo(i.Id)} />}
    </main>
  );
}

const ESTADO_PEDIDO: Record<number, string> = { 1: 'Aguardando aprovação', 2: 'Aprovado', 3: 'Recusado' };
type Linha = { id: number; nome: string; capa: string; estado: string; jf?: string; data: string };
export function Pedidos({ s }: { s: Sessao }) {
  const [linhas, setLinhas] = useState<Linha[] | null>(null);
  const [erro, setErro] = useState(false);
  useEffect(() => {
    meusPedidos(s).then(ps => Promise.all(ps.map(async p => {
      const d = await detalhe(s, p.media.mediaType, p.media.tmdbId).catch(() => null);
      const st = p.media.status;
      return { id: p.id, nome: d?.title || d?.name || `#${p.media.tmdbId}`, capa: poster(s, d?.posterPath), jf: p.media.jellyfinMediaId,
        estado: st === 5 ? 'Disponível' : st === 4 ? 'Em parte' : st === 3 ? 'Baixando' : ESTADO_PEDIDO[p.status] || 'Pedido',
        data: new Date(p.createdAt).toLocaleDateString('pt-BR') };
    }))).then(setLinhas).catch(() => { setErro(true); setLinhas([]); });
  }, []);
  return (
    <main class="pagina">
      <h1 class="pagina-titulo">Meus pedidos</h1>
      {erro && <p class="pagina-nota">Pedidos indisponíveis agora.</p>}
      {linhas && !linhas.length && !erro && <p class="pagina-nota">Você ainda não pediu nada. Na Busca, o que não temos aparece para pedir.</p>}
      <ul class="pedidos">
        {(linhas || []).map(l => (
          <li key={l.id}>
            <button data-foco class="pedido" disabled={!l.jf} onClick={() => l.jf && irTitulo(l.jf)}>
              {l.capa ? <img src={l.capa} alt="" loading="lazy" /> : <span class="pedido-sem-capa" />}
              <span class="pedido-texto"><strong>{l.nome}</strong><small>Pedido em {l.data}</small></span>
              <span class={l.estado === 'Disponível' ? 'pedido-estado pronto' : 'pedido-estado'}>{l.estado}</span>
            </button>
          </li>
        ))}
      </ul>
    </main>
  );
}
