// Biblioteca (PLANO §6; ref/vidhub/…foto50, …foto51).
//  Topo: ← | nome da biblioteca no centro | ícone à direita que abre o menu lateral direito com as bibliotecas.
//  Sem abas (Séries/Episódios/Gêneros/Pastas) e sem ordenar/filtrar: ordem alfabética. Grade de pôsteres 2:3 (3 colunas no
//  celular, mais no computador) que carrega aos poucos ao rolar. Botão direito no cartão: visto · favoritar.
import { useEffect, useRef, useState } from 'preact/hooks';
import { bibliotecasDeVideo, daBiblioteca, hashDe, type Item, type Sessao } from '../api/jellyfin';
import { usePaleta } from '../cor/paleta';
import { CartaoPoster, EsqueletoCartoes } from '../comp/Cartoes';
import { Folha } from '../comp/Folha';
import { Icone } from '../comp/Icone';
import { irAba, irTitulo, lembrarBiblioteca, ultimaBiblioteca, voltar } from '../rota';
import './biblioteca.css';

const PAGINA = 60;
const iconeDe = (b: Item) => b.CollectionType === 'movies' ? 'movie' : b.CollectionType === 'tvshows' ? 'tv'
  : b.CollectionType === 'boxsets' ? 'collections_bookmark' : 'video_library';

export function Biblioteca({ s, id }: { s: Sessao; id?: string }) {
  const [libs, setLibs] = useState<Item[] | null>(null);
  const [bid, setBid] = useState(id || '');
  const [menu, setMenu] = useState(false);

  useEffect(() => {
    bibliotecasDeVideo(s).then(l => {
      setLibs(l);
      if (id) return;
      // #/b sem id: a última aberta (se ainda existe) ou a primeira
      const alvo = l.find(b => b.Id === ultimaBiblioteca()) || l[0];
      if (alvo) { setBid(alvo.Id); history.replaceState(history.state, '', `#/b/${alvo.Id}`); }
    }).catch(() => setLibs([]));
  }, [s.token]);
  useEffect(() => { if (id) setBid(id); }, [id]);
  useEffect(() => { if (bid) lembrarBiblioteca(bid); }, [bid]);

  const atual = libs?.find(b => b.Id === bid);
  return (
    <main class="biblioteca">
      <header class="biblioteca-topo">
        <button class="redondo" onClick={voltar} aria-label="Voltar"><Icone nome="arrow_back" tamanho={24} /></button>
        <h1 class="uma-linha">{atual?.Name || ''}</h1>
        <button class="redondo" onClick={() => setMenu(true)} aria-label="Trocar de biblioteca" aria-haspopup="dialog" disabled={!libs?.length}>
          <Icone nome="menu" tamanho={24} />
        </button>
      </header>
      {bid ? <Grade key={bid} s={s} bid={bid} /> : libs && !libs.length ? <p class="biblioteca-vazio texto-2">Nenhuma biblioteca neste servidor.</p> : <Grade s={s} bid="" />}
      <Folha aberta={menu} fechar={() => setMenu(false)} titulo="Bibliotecas" variante="lateral" classe="biblioteca-menu">
        <ul class="lista-opcoes">
          {(libs || []).map(b => (
            <li key={b.Id}>
              <button class="opcao-linha" aria-current={b.Id === bid ? 'page' : undefined}
                onClick={() => { setMenu(false); if (b.Id !== bid) { setBid(b.Id); irAba(`b/${b.Id}`); } }}>
                <Icone nome={iconeDe(b)} cheio={b.Id === bid} tamanho={24} />
                <span class="opcao-texto"><strong>{b.Name}</strong></span>
                {b.Id === bid && <span class="opcao-marca"><Icone nome="check" tamanho={22} /></span>}
              </button>
            </li>
          ))}
        </ul>
      </Folha>
    </main>
  );
}

function Grade({ s, bid }: { s: Sessao; bid: string }) {
  const [itens, setItens] = useState<Item[]>([]);
  const [total, setTotal] = useState<number | null>(null);
  const [fim, setFim] = useState(false);
  const [erro, setErro] = useState(false);
  const carregando = useRef(false), sentinela = useRef<HTMLDivElement>(null), qtd = useRef(0);
  usePaleta(hashDe(itens[0], 'Primary'));

  const mais = () => {
    if (!bid || carregando.current || fim) return;
    carregando.current = true;
    daBiblioteca(s, bid, qtd.current, PAGINA).then(d => {
      qtd.current += d.Items.length;
      setItens(l => [...l, ...d.Items]);
      setTotal(d.TotalRecordCount);
      // acabou quando chegou ao total ou o servidor mandou uma página vazia/curta
      if (!d.Items.length || d.Items.length < PAGINA || qtd.current >= d.TotalRecordCount) setFim(true);
      setErro(false);
    }).catch(() => setErro(true)).finally(() => { carregando.current = false; });
  };
  useEffect(() => { mais(); }, [bid]);
  // carrega aos poucos: a próxima página quando a sentinela chega perto da tela
  useEffect(() => {
    const el = sentinela.current; if (!el || fim || erro) return;
    const io = new IntersectionObserver(e => { if (e[0].isIntersecting) mais(); }, { rootMargin: '900px 0px' });
    io.observe(el);
    return () => io.disconnect();
  }, [fim, erro, itens.length]);

  return (
    <>
      <div class="biblioteca-grade" aria-busy={!fim}>
        {itens.map((i, k) => <CartaoPoster key={i.Id} s={s} i={i} prioridade={k < 9} aoAbrir={x => irTitulo(x.Id)} />)}
        {!fim && !erro && <EsqueletoCartoes n={total === null ? 12 : 6} />}
      </div>
      {fim && total === 0 && <p class="biblioteca-vazio texto-2">Nada nesta biblioteca ainda.</p>}
      {erro && <p class="biblioteca-vazio"><button class="pilula pilula-vidro" onClick={mais}>Não carregou. Tentar de novo</button></p>}
      <div ref={sentinela} class="biblioteca-sentinela" aria-hidden="true" />
    </>
  );
}
