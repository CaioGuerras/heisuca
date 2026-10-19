import { useEffect, useRef, useState } from 'preact/hooks';
import { continuar, emAlta, emBreve, fundo, logo, novidades, type EmBreve, type Item, type Sessao } from '../api/jellyfin';
import { Fileira, FileiraEmBreve } from '../comp/Fileira';
import { Icone } from '../comp/Icone';
import { iconeBiblioteca, listaBibliotecas } from '../comp/Navegacao';
import type { Alvo } from '../comp/Pedido';
import { aoVoltarNaRaiz, irBiblioteca, irTitulo, irVer } from '../rota';
import { ehTV } from '../tv';

type Linha = { titulo: string; itens: Item[]; tocar?: boolean; top10?: boolean; continuar?: boolean };
const ORDEM_LIB = ['Animes', 'Séries', 'Filmes'];

let ultimo: [number, number] = [0, 0];

function posicionar(caixa: HTMLElement, pista: HTMLElement, alvo: HTMLElement) {
  const cartao = alvo.closest('.cartao') as HTMLElement | null;
  if (!cartao) { pista.style.transform = ''; caixa.scrollTop = 0; return; }
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
  const [destaques, setDestaques] = useState<Item[]>([]);
  const [slideAtual, setSlideAtual] = useState(0);
  const [breve, setBreve] = useState<{ tv: EmBreve[]; movie: EmBreve[] }>({ tv: [], movie: [] });
  const [erro, setErro] = useState('');
  const caixa = useRef<HTMLDivElement>(null), pista = useRef<HTMLDivElement>(null);
  const timerRotacao = useRef<number>(0);
  const pausaRotacao = useRef(false);

  const carregarDados = async () => {
    try {
      const [cont, todas, alta] = await Promise.all([continuar(s), listaBibliotecas(s), emAlta(s).catch(() => null)]);
      setLibs(todas);
      const vids = todas.filter(l => l.CollectionType === 'movies' || l.CollectionType === 'tvshows')
        .sort((a, b) => (ORDEM_LIB.indexOf(a.Name) + 99) % 99 - (ORDEM_LIB.indexOf(b.Name) + 99) % 99);
      const nov = await Promise.all(
        vids.map(l => novidades(s, l.Id).then(itens => ({ titulo: `Novidades em ${l.Name}`, itens })).catch(() => ({ titulo: l.Name, itens: [] })))
      );
      const lista: Linha[] = [
        ...(cont.length ? [{ titulo: 'Continuar assistindo', itens: cont, tocar: true, continuar: true }] : []),
        ...(alta ? [{ titulo: alta.titulo, itens: alta.itens, top10: true }] : []),
        ...nov,
      ].filter(l => l.itens.length);
      setLinhas(lista);

      // Hero rotation items: mix of Em Alta items and Top novelty items
      const heroItens = alta?.itens.slice(0, 5) || (lista[0]?.itens.slice(0, 5) ?? []);
      setDestaques(heroItens);
    } catch (e) {
      setErro(e instanceof Error ? e.message : String(e));
    }
    const [tv, movie] = await Promise.all([emBreve(s, 'tv').catch(() => []), emBreve(s, 'movie').catch(() => [])]);
    setBreve({ tv, movie });
  };

  useEffect(() => {
    carregarDados();
  }, [s.token]);

  // Rotação suave do carrossel do Hero
  useEffect(() => {
    if (!destaques.length || ehTV) return;
    const proximoSlide = () => {
      if (!pausaRotacao.current) {
        setSlideAtual(at => (at + 1) % destaques.length);
      }
    };
    timerRotacao.current = window.setInterval(proximoSlide, 7500);
    return () => clearInterval(timerRotacao.current);
  }, [destaques.length]);

  // Navegação na TV
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

  const destaque = destaques[slideAtual] || null;
  const abrirBreve = (e: EmBreve) => {
    if (e.jf) irTitulo(e.jf);
    else if (e.tmdb) pedir({ tipo: e.tipo, id: e.tmdb, nome: e.nome });
  };

  const img = destaque ? fundo(s, destaque, 1920) : '';
  const lg = destaque ? logo(s, destaque, 600) : '';
  const nome = destaque ? (destaque.Type === 'Episode' ? destaque.SeriesName : destaque.Name) : '';
  const retomar = destaque?.UserData?.PlaybackPositionTicks;
  const metaHero = [
    destaque?.ProductionYear,
    destaque?.OfficialRating,
    destaque?.Genres?.slice(0, 3).join(', '),
  ].filter(Boolean);

  return (
    <div class="inicio">
      {/* Hero Rotativo */}
      <div
        class="destaque"
        aria-live="polite"
        onMouseEnter={() => { pausaRotacao.current = true; }}
        onMouseLeave={() => { pausaRotacao.current = false; }}
      >
        {img && <img key={img} class="destaque-img" src={img} alt="" />}
        <div class="destaque-gradiente" />
        <div class="destaque-texto" key={destaque?.Id}>
          {lg ? <img class="destaque-logo" src={lg} alt={nome} /> : <h1>{nome}</h1>}
          {metaHero.length > 0 && <p class="destaque-meta">{metaHero.join(' · ')}</p>}
          <p class="destaque-sinopse">{destaque?.Overview}</p>
          {destaque && !ehTV && (
            <div class="destaque-acoes">
              <button
                class="botao botao-play"
                onClick={() => retomar ? irVer(destaque.Id, retomar) : irTitulo(destaque.Id)}
              >
                <Icone nome="play_arrow" cheio />
                {retomar ? 'Continuar' : 'Assistir'}
              </button>
              <button class="botao-sec" onClick={() => irTitulo(destaque.Id)}>
                <Icone nome="info" />
                Detalhes
              </button>
            </div>
          )}
        </div>

        {/* Indicadores do carrossel (dots) */}
        {destaques.length > 1 && !ehTV && (
          <div class="destaque-dots" role="tablist" aria-label="Slides em destaque">
            {destaques.map((d, idx) => (
              <button
                key={d.Id}
                type="button"
                role="tab"
                class={idx === slideAtual ? 'dot ativo' : 'dot'}
                aria-selected={idx === slideAtual}
                aria-label={`Slide ${idx + 1}: ${d.Name}`}
                onClick={() => setSlideAtual(idx)}
              />
            ))}
          </div>
        )}
      </div>

      {erro && <p class="erro">{erro}</p>}

      <div class="fileiras" ref={caixa} data-rola-sozinho={ehTV ? '' : undefined}>
        <div class="fileiras-pista" ref={pista}>
          {/* Atalhos rápidos das bibliotecas */}
          {libs.length > 0 && (
            <nav class="atalhos" aria-label="Bibliotecas">
              {libs.map(b => (
                <button data-foco class="atalho" key={b.Id} onClick={() => irBiblioteca(b.Id)}>
                  <Icone nome={iconeBiblioteca(b)} />
                  {b.Name}
                </button>
              ))}
            </nav>
          )}

          {/* Fileiras de Conteúdo */}
          {linhas.map(l => (
            <Fileira
              key={l.titulo}
              s={s}
              titulo={l.titulo}
              itens={l.itens}
              top10={l.top10}
              continuar={l.continuar}
              aoAtualizar={carregarDados}
              aoAbrir={i => l.tocar ? irVer(i.Id, i.UserData?.PlaybackPositionTicks) : irTitulo(i.Id)}
            />
          ))}

          <FileiraEmBreve titulo="Séries em breve" itens={breve.tv} aoAbrir={abrirBreve} />
          <FileiraEmBreve titulo="Filmes em breve" itens={breve.movie} aoAbrir={abrirBreve} />
        </div>
      </div>
    </div>
  );
}
