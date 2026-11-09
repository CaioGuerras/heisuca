// Busca (PLANO §8; ref/app_completo/…busca_seerr; o VidHub não tem pedidos: ref/vidhub/…busca).
//  Topo: ← Buscar; campo em pílula com 🔍 e ✕. Busca a partir de 2 letras, 300 ms depois de parar de digitar.
//  Do acervo: pôster, título, `BR-14 • 2015 • 2h 28m • 6,6★`, sinopse em 3 linhas, `<servidor> • <biblioteca>`.
//  "Disponível para pedir": só se o servidor tiver Seerr (temSeerr); "+ Pedir" abre a FolhaPedido (série escolhe temporadas).
//  "Meus pedidos ›" mora aqui (saiu do menu do usuário): discreto, no título da seção e sob o campo enquanto não há busca.
import { useEffect, useRef, useState } from 'preact/hooks';
import { bibliotecasDeVideo, capa, hashDe, buscar, type Item, type Sessao } from '../api/servidor.ts';
import { buscar as buscarSeerr, poster, SELO, temSeerr, type Resultado } from '../api/seerr';
import { usePaleta } from '../cor/paleta';
import { nota } from '../comp/Cartoes';
import { Classificacao } from '../comp/Classificacao';
import { Icone } from '../comp/Icone';
import { Imagem } from '../comp/Imagem';
import { FolhaPedido, type Alvo } from '../comp/Pedido';
import { irPagina, irTitulo, voltar } from '../rota';
import { criarBusca, buscaInicial, type EstadoBusca } from './busca-progressiva.ts';
import './busca.css';

const ESPERA = 300, MINIMO = 2;
const duracao = (ticks?: number) => {
  if (!ticks) return '';
  const m = Math.round(ticks / 6e8), h = Math.floor(m / 60);
  return h ? `${h}h ${String(m % 60).padStart(2, '0')}m` : `${m}m`;
};
// a duração só faz sentido no filme (na série o servidor dá a média de um episódio)
const linhaInfo = (i: Item) => [i.ProductionYear, i.Type === 'Movie' ? duracao(i.RunTimeTicks) : '',
  nota(i) && `${nota(i)}★`].filter(Boolean).join(' • ');

type Estado<T> = { termo: string; itens: T[] | null; erro?: boolean };

export function Busca({ s }: { s: Sessao }) {
  usePaleta(null);
  const [texto, setTexto] = useState('');
  const termo = texto.trim();
  const [acervo, setAcervo] = useState<EstadoBusca & { termo: string }>({ termo: '', ...buscaInicial });
  const [pedir, setPedir] = useState<Estado<Resultado>>({ termo: '', itens: null });
  const [repetirPedidos, setRepetirPedidos] = useState(0);
  const [seerr, setSeerr] = useState(false);
  const [alvo, setAlvo] = useState<Alvo | null>(null);
  const [pedidos, setPedidos] = useState<Set<number>>(new Set());
  const campo = useRef<HTMLInputElement>(null);

  useEffect(() => { temSeerr(s).then(setSeerr); campo.current?.focus({ preventScroll: true }); }, [s.servidor]);
  const busca = useRef<ReturnType<typeof criarBusca> | null>(null);
  const fim = useRef<HTMLDivElement>(null);
  useEffect(() => {
    if (termo.length < MINIMO) return;
    setAcervo({ termo, ...buscaInicial });
    const atual = criarBusca(termo, () => bibliotecasDeVideo(s),
      (b, inicio, sinal) => buscar(s, termo, b.Id, inicio, 30, sinal), e => setAcervo({ termo, ...e }));
    busca.current = atual;
    const id = setTimeout(() => { void atual.carregar(); }, ESPERA);
    return () => { clearTimeout(id); atual.cancelar(); };
  }, [termo, s]);
  useEffect(() => {
    if (termo.length < MINIMO || !seerr) return;
    setPedir({ termo, itens: null });
    let vivo = true;
    const id = setTimeout(() => {
      buscarSeerr(s, termo).then(itens => vivo && setPedir({ termo, itens }), () => vivo && setPedir({ termo, itens: [], erro: true }));
    }, ESPERA);
    return () => { vivo = false; clearTimeout(id); };
  }, [termo, seerr, s, repetirPedidos]);

  const alterar = (valor: string) => {
    if (valor.trim() !== termo) {
      busca.current?.cancelar();
      setAcervo({ termo: '', ...buscaInicial });
      setPedir({ termo: '', itens: null });
    }
    setTexto(valor);
  };
  const limpar = () => { alterar(''); campo.current?.focus(); };
  const ativo = termo.length >= MINIMO;
  const doAcervo = ativo && acervo.termo === termo ? acervo.itens : null;
  const paraPedir = ativo && seerr && pedir.termo === termo ? pedir.itens : null;
  const carregando = ativo && (!doAcervo || acervo.carregando || (seerr && !paraPedir));
  const nada = ativo && !carregando && doAcervo && !doAcervo.length && (!seerr || (paraPedir && !paraPedir.length));
  useEffect(() => {
    if (!doAcervo || acervo.carregando || acervo.erro || !acervo.mais || !fim.current) return;
    const observador = new IntersectionObserver(entradas => {
      if (entradas.some(e => e.isIntersecting)) void busca.current?.carregar();
    }, { rootMargin: '400px 0px' });
    observador.observe(fim.current);
    return () => observador.disconnect();
  }, [doAcervo, acervo.carregando, acervo.erro, acervo.mais]);
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
            aria-label="Buscar filmes e séries" value={texto} onInput={e => alterar((e.target as HTMLInputElement).value)}
            onKeyDown={e => { if (e.key === 'Escape' && texto) { e.preventDefault(); limpar(); } }} />
          {texto && <button class="busca-limpar" onClick={limpar} aria-label="Limpar"><Icone nome="close" tamanho={24} /></button>}
        </label>
      </header>

      <div class="busca-corpo" aria-live="polite" aria-busy={carregando ? 'true' : 'false'}>
        {!ativo && !texto.trim() && <div class="busca-vazio busca-inicial"><Icone nome="search" tamanho={40} />
          <p>Qual história você quer ver?</p><small>Busque por um filme ou uma série.</small>
        </div>}
        {!ativo && texto.trim().length === 1 && <p class="busca-dica texto-2">Digite mais uma letra.</p>}
        {!ativo && seerr && <MeusPedidos classe="busca-pedidos-solto" />}
        {nada && !acervo.erro && !(seerr && pedir.erro) && <div class="busca-vazio"><Icone nome="search_off" tamanho={40} />
          <p>Nada encontrado para “{termo}”.</p><small>Tente outro título ou confira como ele está escrito.</small>
        </div>}
        {ativo && seerr && pedir.termo === termo && pedir.erro && <div class="busca-estado" role="status">
          <p>Pedidos indisponíveis agora.</p>
          <button class="pilula" onClick={() => setRepetirPedidos(n => n + 1)}>Tentar de novo</button>
        </div>}

        {ativo && !doAcervo && <><span class="visualmente-oculto">Buscando títulos…</span>
          <ul class="busca-lista" aria-hidden="true">{[0, 1, 2].map(n => <li key={n} class="busca-item"><span class="busca-capa esqueleto" /><span class="busca-esq"><span class="esqueleto" /><span class="esqueleto" /><span class="esqueleto" /></span></li>)}</ul>
        </>}
        {doAcervo && doAcervo.length > 0 && (
          <ul class="busca-lista">
            {doAcervo.map(i => (
              <li key={i.Id}>
                <button class="busca-item" onClick={() => irTitulo(i.Id, i)}>
                  <Imagem classe="busca-capa" src={capa(s, i, 330)} hash={hashDe(s, i, 'Primary')} alt="" />
                  <span class="busca-texto">
                    <strong class="busca-nome">{i.Name}</strong>
                    {(i.OfficialRating || linhaInfo(i)) && <span class="busca-info">
                      {i.OfficialRating && <Classificacao valor={i.OfficialRating} />}
                      {i.OfficialRating && linhaInfo(i) && <span aria-hidden="true">•</span>}
                      {linhaInfo(i) && <span>{linhaInfo(i)}</span>}
                    </span>}
                    {i.Overview && <span class="busca-sinopse">{i.Overview}</span>}
                    <small class="busca-origem"><Icone nome="dns" tamanho={16} />{[servidor, i.biblioteca].filter(Boolean).join(' • ')}</small>
                  </span>
                </button>
              </li>
            ))}
          </ul>
        )}

        {ativo && doAcervo && <>
          {acervo.erro && <div class="busca-estado" role="status">
            <p>{doAcervo.length ? 'Não deu para carregar todos os títulos.' : 'Não deu para buscar no servidor agora.'}</p>
            <button class="pilula" onClick={() => { void busca.current?.carregar(); }}>Tentar de novo</button>
          </div>}
          <div ref={fim} class="busca-fim">
            {acervo.carregando && <small>Buscando mais títulos…</small>}
          </div>
        </>}

        {seerr && ativo && (paraPedir === null ? doAcervo !== null : paraPedir.length > 0) && (
          <section class="busca-pedir" aria-label="Disponível para pedir">
            <div class="busca-pedir-cabeca"><h2 class="titulo-secao">Disponível para pedir</h2><MeusPedidos /></div>
            <p class="texto-2">Ainda não temos. Peça e avisamos quando chegar.</p>
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

const MeusPedidos = ({ classe = '' }: { classe?: string }) => (
  <button class={`busca-meus ${classe}`} onClick={() => irPagina('pedidos')}>Meus pedidos<Icone nome="chevron_right" tamanho={18} /></button>
);
