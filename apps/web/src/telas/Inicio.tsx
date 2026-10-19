import { useEffect, useRef, useState } from 'preact/hooks';
import { continuar, emAlta, emBreve, fundo, logo, novidades, type EmBreve, type Item, type Sessao } from '../api/jellyfin';
import { Fileira, FileiraEmBreve } from '../comp/Fileira';
import { listaBibliotecas } from '../comp/Navegacao';
import type { Alvo } from '../comp/Pedido';
import { aoVoltarNaRaiz, irTitulo, irVer } from '../rota';
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

      const heroItens = alta?.itens.slice(0, 7) || (lista[0]?.itens.slice(0, 7) ?? []);
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
  const nota = destaque?.CommunityRating ? destaque.CommunityRating.toFixed(1) : null;
  const ano = destaque?.ProductionYear;
  const retomar = destaque?.UserData?.PlaybackPositionTicks;

  return (
    <div class="inicio vidhub-home">
      {/* Hero Cinematográfico VidHub: Centralizado, sem botões grosseiros, sem chips de biblioteca */}
      <div
        class="destaque vidhub-hero"
        aria-live="polite"
        onMouseEnter={() => { pausaRotacao.current = true; }}
        onMouseLeave={() => { pausaRotacao.current = false; }}
        onClick={() => destaque && (retomar ? irVer(destaque.Id, retomar) : irTitulo(destaque.Id))}
        role="banner"
        title={nome ? `Ver detalhes de ${nome}` : ''}
      >
        {img && <img key={img} class="destaque-img" src={img} alt="" />}
        <div class="destaque-gradiente" />

        <div class="destaque-conteudo-central destaque-texto" key={destaque?.Id}>
          {lg ? (
            <>
              <img class="destaque-logo" src={lg} alt={nome} />
              <h1 class="sr-only">{nome}</h1>
            </>
          ) : (
            <h1 class="destaque-titulo-vidhub">{nome}</h1>
          )}

          <div class="destaque-meta-vidhub">
            {nota && <span class="destaque-nota">★ {nota}</span>}
            {nota && ano && <span class="destaque-divisor">|</span>}
            {ano && <span>{ano}</span>}
          </div>

          {destaque?.Overview && (
            <p class="destaque-sinopse-vidhub">{destaque.Overview}</p>
          )}

          {/* Dots Indicadores Centralizados */}
          {destaques.length > 1 && (
            <div class="destaque-dots-vidhub" role="tablist" aria-label="Slides em destaque">
              {destaques.map((d, idx) => (
                <button
                  key={d.Id}
                  type="button"
                  role="tab"
                  class={idx === slideAtual ? 'dot-vidhub ativo' : 'dot-vidhub'}
                  aria-selected={idx === slideAtual}
                  aria-label={`Slide ${idx + 1}: ${d.Name}`}
                  onClick={ev => {
                    ev.stopPropagation();
                    setSlideAtual(idx);
                  }}
                />
              ))}
            </div>
          )}
        </div>
      </div>

      {erro && <p class="erro">{erro}</p>}

      {/* Fileiras de Conteúdo: começa diretamente no Continuar Assistindo */}
      <div class="fileiras" ref={caixa} data-rola-sozinho={ehTV ? '' : undefined}>
        <div class="fileiras-pista" ref={pista}>
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
