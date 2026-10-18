// Início no modelo dos nossos apps (PADROES_CGFLIX_TV.md §1–2): hero com logo, atalhos das bibliotecas (Animes, Séries,
// Filmes, Coleções) e as fileiras Continuar · Em alta no Brasil (Top 10) · Animes · Séries · Filmes · Em breve (por último,
// Caio no 2º teste da TV). A navegação (abas, menu do avatar) fica em comp/Navegacao.
import { useEffect, useRef, useState } from 'preact/hooks';
import { continuar, emAlta, emBreve, fundo, logo, novidades, type EmBreve, type Item, type Sessao } from '../api/jellyfin';
import { Fileira, FileiraEmBreve } from '../comp/Fileira';
import { Icone } from '../comp/Icone';
import { iconeBiblioteca, listaBibliotecas } from '../comp/Navegacao';
import type { Alvo } from '../comp/Pedido';
import { aoVoltarNaRaiz, irBiblioteca, irTitulo, irVer } from '../rota';
import { ehTV } from '../tv';

type Linha = { titulo: string; itens: Item[]; tocar?: boolean; top10?: boolean };
const ORDEM_LIB = ['Animes', 'Séries', 'Filmes'];

// onde o foco estava (fileira, cartão), para voltar do título no mesmo lugar
let ultimo: [number, number] = [0, 0];

// TV: a fileira focada sobe para o topo da área das fileiras e o cartão focado fica na margem esquerda. Só transform
// (regra de desempenho da TV); offsetTop/offsetLeft não mudam com transform. scrollTop/Left = 0 porque o Chromium 56 do
// Tizen 3 ignora focus({ preventScroll }).
function posicionar(caixa: HTMLElement, pista: HTMLElement, alvo: HTMLElement) {
  const cartao = alvo.closest('.cartao') as HTMLElement | null;
  if (!cartao) { pista.style.transform = ''; caixa.scrollTop = 0; return; }  // atalhos das bibliotecas: volta ao topo
  const fileira = cartao.closest('.fileira') as HTMLElement | null;
  const trilho = cartao.parentElement as HTMLElement | null;
  if (!fileira || !trilho) return;
  const primeiro = trilho.firstElementChild as HTMLElement;
  ultimo = [Array.prototype.indexOf.call(pista.children, fileira), Array.prototype.indexOf.call(trilho.children, cartao)];
  pista.style.transform = `translateY(${-fileira.offsetTop}px)`;
  trilho.style.transform = `translateX(${primeiro.offsetLeft - cartao.offsetLeft}px)`;
  caixa.scrollTop = 0; caixa.scrollLeft = 0; trilho.scrollLeft = 0;
}

export function Inicio({ s, pedir }: { s: Sessao; pedir: (a: Alvo) => void }) {
  const [libs, setLibs] = useState<Item[]>([]);
  const [linhas, setLinhas] = useState<Linha[]>([]);
  const [breve, setBreve] = useState<{ tv: EmBreve[]; movie: EmBreve[] }>({ tv: [], movie: [] });
  const [destaque, setDestaque] = useState<Item | null>(null);
  const [erro, setErro] = useState('');
  const caixa = useRef<HTMLDivElement>(null), pista = useRef<HTMLDivElement>(null);
  // troca do fundo espera a navegação parar: decodificar um fundo 1080p a cada seta pesa na TV
  const espera = useRef(0);
  const focar = (i: Item) => { clearTimeout(espera.current); espera.current = setTimeout(() => setDestaque(i), ehTV ? 300 : 150) as unknown as number; };

  useEffect(() => {
    (async () => {
      try {
        const [cont, todas, alta] = await Promise.all([continuar(s), listaBibliotecas(s), emAlta(s).catch(() => null)]);
        setLibs(todas);
        const vids = todas.filter(l => l.CollectionType === 'movies' || l.CollectionType === 'tvshows')
          .sort((a, b) => (ORDEM_LIB.indexOf(a.Name) + 99) % 99 - (ORDEM_LIB.indexOf(b.Name) + 99) % 99);
        const nov = await Promise.all(vids.map(l => novidades(s, l.Id).then(itens => ({ titulo: `Novidades em ${l.Name}`, itens })).catch(() => ({ titulo: l.Name, itens: [] }))));
        const lista: Linha[] = [{ titulo: 'Continuar assistindo', itens: cont, tocar: true },
          ...(alta ? [{ titulo: alta.titulo, itens: alta.itens, top10: true }] : []), ...nov].filter(l => l.itens.length);
        setLinhas(lista);
        setDestaque(alta?.itens[0] ?? lista[0]?.itens[0] ?? null);
      } catch (e) { setErro(e instanceof Error ? e.message : String(e)); }
      const [tv, movie] = await Promise.all([emBreve(s, 'tv').catch(() => []), emBreve(s, 'movie').catch(() => [])]);
      setBreve({ tv, movie });
    })();
  }, [s.token]);

  useEffect(() => {
    if (!ehTV || !linhas.length || !caixa.current || !pista.current) return;
    const c = caixa.current, p = pista.current;
    const primeiro = () => c.querySelector<HTMLElement>('.cartao');
    const f = (ev: FocusEvent) => posicionar(c, p, ev.target as HTMLElement);
    c.addEventListener('focusin', f);
    const a = document.activeElement;
    if (!a || a === document.body) {
      const fl = p.children[ultimo[0]]?.querySelector('.fileira-trilho')?.children[ultimo[1]] as HTMLElement | undefined;
      (fl || primeiro())?.focus();
    }
    aoVoltarNaRaiz(() => {
      const um = primeiro();
      if (!um || document.activeElement === um) return false;
      um.focus();
      c.querySelectorAll<HTMLElement>('.fileira-trilho').forEach(t => { t.style.transform = ''; });
      p.style.transform = '';
      return true;
    });
    return () => { c.removeEventListener('focusin', f); aoVoltarNaRaiz(null); };
  }, [linhas]);

  const abrirBreve = (e: EmBreve) => { if (e.jf) irTitulo(e.jf); else if (e.tmdb) pedir({ tipo: e.tipo, id: e.tmdb, nome: e.nome }); };
  const img = destaque ? fundo(s, destaque) : '';
  const lg = destaque ? logo(s, destaque) : '';
  const nome = destaque ? (destaque.Type === 'Episode' ? destaque.SeriesName : destaque.Name) : '';
  const retomar = destaque?.UserData?.PlaybackPositionTicks;
  return (
    <div class="inicio">
      <div class="destaque" aria-live="polite">
        {img && <img key={img} class="destaque-img" src={img} alt="" />}
        <div class="destaque-texto" key={destaque?.Id}>
          {lg ? <img class="destaque-logo" src={lg} alt={nome} /> : <h1>{nome}</h1>}
          <p>{destaque?.Overview}</p>
          {destaque && !ehTV && (
            <div class="destaque-acoes">
              <button class="botao" onClick={() => retomar ? irVer(destaque.Id, retomar) : irTitulo(destaque.Id)}>
                <Icone nome="play_arrow" cheio />{retomar ? 'Continuar' : 'Assistir'}
              </button>
              <button class="botao-sec" onClick={() => irTitulo(destaque.Id)}><Icone nome="info" />Detalhes</button>
            </div>
          )}
        </div>
      </div>
      {erro && <p class="erro">{erro}</p>}
      <div class="fileiras" ref={caixa} data-rola-sozinho={ehTV ? '' : undefined}>
        <div class="fileiras-pista" ref={pista}>
          {libs.length > 0 && (
            <nav class="atalhos" aria-label="Bibliotecas">
              {libs.map(b => <button data-foco class="atalho" key={b.Id} onClick={() => irBiblioteca(b.Id)}><Icone nome={iconeBiblioteca(b)} />{b.Name}</button>)}
            </nav>
          )}
          {linhas.map(l => <Fileira key={l.titulo} s={s} titulo={l.titulo} itens={l.itens} aoFocar={focar} top10={l.top10}
            aoAbrir={i => l.tocar ? irVer(i.Id, i.UserData?.PlaybackPositionTicks) : irTitulo(i.Id)} />)}
          <FileiraEmBreve titulo="Séries em breve" itens={breve.tv} aoAbrir={abrirBreve} />
          <FileiraEmBreve titulo="Filmes em breve" itens={breve.movie} aoAbrir={abrirBreve} />
        </div>
      </div>
    </div>
  );
}
