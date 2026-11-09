// Biblioteca (PLANO §6; ref/vidhub/…foto50, …foto51).
//  Topo: ← | nome da biblioteca no centro | ícone à direita que abre o menu lateral direito com as bibliotecas.
//  Ordenação e filtro por biblioteca. Grade de pôsteres 2:3 (3 colunas no
//  celular, mais no computador) que carrega aos poucos ao rolar. Botão direito no cartão: visto · favoritar.
import { useEffect, useRef, useState } from 'preact/hooks';
import { bibliotecasDeVideo, daBiblioteca, hashDe, type Item, type Sessao } from '../api/servidor.ts';
import { fundoDesfocado, usePaleta } from '../cor/paleta';
import { CartaoPoster, EsqueletoCartoes } from '../comp/Cartoes';
import { Folha } from '../comp/Folha';
import { Icone } from '../comp/Icone';
import { abrirServidores } from '../estado/casca';
import { irAba, irTitulo, lembrarBiblioteca, ultimaBiblioteca, voltar } from '../rota';
import { ORDENS, lerOrdem, guardarOrdem, type OrdemBiblioteca } from '../dados/ordem-biblioteca.ts';
import './biblioteca.css';

const PAGINA = 60;
// "1 título" / "1.284 títulos": a contagem real do servidor, no formato do Brasil
export const contagem = (n: number) => `${n.toLocaleString('pt-BR')} ${n === 1 ? 'título' : 'títulos'}`;
const iconeDe = (b: Item) => b.CollectionType === 'movies' ? 'movie' : b.CollectionType === 'tvshows' ? 'tv'
  : b.CollectionType === 'boxsets' ? 'collections_bookmark' : 'video_library';

export function Biblioteca({ s, id }: { s: Sessao; id?: string }) {
  const [libs, setLibs] = useState<Item[] | null>(null);
  const [bid, setBid] = useState(id || '');
  const [menu, setMenu] = useState(false);
  const [total, setTotal] = useState<number | null>(null);

  useEffect(() => {
    // J9-08: resposta que chega depois de sair da tela (ou de trocar de sessão) é descartada antes de qualquer setter
    // e antes do history.replaceState (senão a URL da tela nova vira a biblioteca antiga)
    let vivo = true;
    bibliotecasDeVideo(s).then(l => {
      if (!vivo) return;
      setLibs(l);
      if (id) return;
      // #/b sem id: a última aberta (se ainda existe) ou a primeira
      const alvo = l.find(b => b.Id === ultimaBiblioteca()) || l[0];
      if (alvo) { setBid(alvo.Id); history.replaceState(history.state, '', `#/b/${alvo.Id}`); }
    }).catch(() => { if (vivo) setLibs([]); });
    return () => { vivo = false; };
  }, [s.token]);
  useEffect(() => { if (id) setBid(id); }, [id]);
  useEffect(() => { if (bid) lembrarBiblioteca(bid); setTotal(null); }, [bid]);

  const atual = libs?.find(b => b.Id === bid);
  return (
    <main class="biblioteca">
      <header class="biblioteca-topo">
        <button class="redondo" onClick={voltar} aria-label="Voltar"><Icone nome="arrow_back" tamanho={24} /></button>
        <div class="biblioteca-cabeca">
          <h1 class="uma-linha" title={atual?.Name}>{atual?.Name || 'Biblioteca'}</h1>
          {/* quantos títulos tem a biblioteca (TotalRecordCount); some enquanto a 1ª página não chega */}
          <p class="biblioteca-total" aria-hidden={!total}>{total ? contagem(total) : '\u00a0'}</p>
        </div>
        <button class="redondo" onClick={() => setMenu(true)} aria-label="Trocar de biblioteca" aria-haspopup="dialog" aria-expanded={menu} disabled={!libs?.length}>
          <Icone nome="menu" tamanho={24} />
        </button>
      </header>
      {bid ? <Acervo key={`${s.servidor}:${s.usuarioId}:${bid}`} s={s} bid={bid} aoTotal={setTotal} /> : libs && !libs.length ? <p class="biblioteca-vazio texto-2">Nenhuma biblioteca neste servidor.</p> : <Grade s={s} bid="" />}
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
          {/* por último, discreto: o servidor atual e "Trocar" (Caio 18/10: a Biblioteca abriga as libs e a troca de servidor) */}
          <li><hr class="separador" /></li>
          <li>
            <button class="opcao-linha biblioteca-servidor" onClick={() => { setMenu(false); setTimeout(abrirServidores, 220); }}
              aria-label={`Servidor ${s.nomeServidor || ''}. Trocar de servidor`}>
              <Icone nome="dns" tamanho={22} />
              <span class="opcao-texto"><small class="uma-linha">{s.nomeServidor || 'Servidor'}</small></span>
              <span class="biblioteca-trocar">Trocar</span>
            </button>
          </li>
        </ul>
      </Folha>
    </main>
  );
}

function Acervo({ s, bid, aoTotal }: { s: Sessao; bid: string; aoTotal: (n: number) => void }) {
  const chave = `${s.tipo}:${s.servidor}:${s.usuarioId}:${bid}`;
  const [escolha, setEscolha] = useState(() => lerOrdem(chave));
  const [menuOrdem, setMenuOrdem] = useState(false);
  const escolher = (nova: OrdemBiblioteca) => { guardarOrdem(chave, nova); setEscolha(nova); };
  return <>
    <div class="biblioteca-filtros">
      <button class="pilula pilula-vidro" onClick={() => setMenuOrdem(true)} aria-haspopup="dialog" aria-expanded={menuOrdem}>
        {ORDENS.find(o => o.valor === escolha.ordem)?.nome}<Icone nome="keyboard_arrow_down" tamanho={20} />
      </button>
      <button class="pilula pilula-vidro" aria-pressed={escolha.naoVistos} onClick={() => escolher({ ...escolha, naoVistos: !escolha.naoVistos })}>
        {escolha.naoVistos && <Icone nome="check" tamanho={20} />}Só não vistos
      </button>
    </div>
    <Folha aberta={menuOrdem} fechar={() => setMenuOrdem(false)} titulo="Ordenar por">
      <ul class="lista-opcoes">{ORDENS.map(o => <li key={o.valor}><button class="opcao-linha" aria-pressed={escolha.ordem === o.valor}
        onClick={() => { escolher({ ...escolha, ordem: o.valor }); setMenuOrdem(false); }}>
        <span class="opcao-texto">{o.nome}</span>{escolha.ordem === o.valor && <Icone nome="check" tamanho={22} />}
      </button></li>)}</ul>
    </Folha>
    <Grade key={`${escolha.ordem}:${escolha.naoVistos}`} s={s} bid={bid} escolha={escolha} aoTotal={aoTotal} />
  </>;
}

function Grade({ s, bid, aoTotal, escolha }: { s: Sessao; bid: string; aoTotal?: (n: number) => void; escolha?: OrdemBiblioteca }) {
  const [itens, setItens] = useState<Item[]>([]);
  const [total, setTotal] = useState<number | null>(null);
  const [fim, setFim] = useState(false);
  const [erro, setErro] = useState(false);
  const [ocupado, setOcupado] = useState(false);
  const carregando = useRef(false), sentinela = useRef<HTMLDivElement>(null), qtd = useRef(0);
  const hash = hashDe(s, itens[0], 'Primary');
  usePaleta(hash);
  const desfocado = fundoDesfocado(hash);

  const vivo = useRef(true);
  useEffect(() => { vivo.current = true; return () => { vivo.current = false; }; }, []);
  useEffect(() => { aoTotal?.(0); }, []);
  const mais = () => {
    if (!bid || carregando.current || fim) return;
    carregando.current = true; setOcupado(true);
    daBiblioteca(s, bid, qtd.current, PAGINA, escolha).then(d => {
      if (!vivo.current) return;
      qtd.current += d.Items.length;
      setItens(l => [...l, ...d.Items]);
      setTotal(d.TotalRecordCount); aoTotal?.(d.TotalRecordCount);
      // acabou quando chegou ao total ou o servidor mandou uma página vazia/curta
      if (!d.Items.length || d.Items.length < PAGINA || qtd.current >= d.TotalRecordCount) setFim(true);
      setErro(false);
    }).catch(() => { if (vivo.current) setErro(true); }).finally(() => { if (vivo.current) { carregando.current = false; setOcupado(false); } });
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
      {desfocado && <div class="biblioteca-fundo" aria-hidden="true" style={{ backgroundImage: `url(${desfocado})` }} />}
      <div class="biblioteca-grade" role="region" aria-label="Títulos da biblioteca" aria-busy={ocupado}>
        {itens.map((i, k) => <CartaoPoster key={i.Id} s={s} i={i} prioridade={k < 9} aoAbrir={x => irTitulo(x.Id, x)} />)}
        {!fim && !erro && <EsqueletoCartoes n={total === null ? 12 : 6} />}
      </div>
      <p class="visualmente-oculto" role="status">{ocupado ? 'Carregando títulos…' : total !== null && !erro ? `${itens.length} de ${total} títulos` : ''}</p>
      {fim && total === 0 && <p class="biblioteca-vazio texto-2">Nada nesta biblioteca ainda.</p>}
      {erro && <p class="biblioteca-vazio"><button class="pilula pilula-vidro" onClick={mais}>Não carregou. Tentar de novo</button></p>}
      <div ref={sentinela} class="biblioteca-sentinela" aria-hidden="true" />
    </>
  );
}
