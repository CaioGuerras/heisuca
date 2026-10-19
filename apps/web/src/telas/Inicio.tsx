// Início (PLANO §4; ref/vidhub/…home_topo, …home_rolada, …foto67). Base funcional da fundação; a sessão B leva ao
// acabamento com o comparador lado a lado. Ordem: destaque · Continuar · Próximo · Em alta · Mídia · bibliotecas · Em breve.
import { useEffect, useRef, useState } from 'preact/hooks';
import { fundo, hashDe, logo, type EmBreve, type Item, type Sessao } from '../api/jellyfin';
import { usePaleta } from '../cor/paleta';
import { CartaoBiblioteca, CartaoEmBreve, CartaoPaisagem, CartaoPoster, CartaoTop10, EsqueletoCartoes, nota } from '../comp/Cartoes';
import { Fileira } from '../comp/Fileira';
import { Imagem } from '../comp/Imagem';
import { Topo } from '../comp/Navegacao';
import { abrirServidores } from '../estado/casca';
import { hashDoDestaque, prepararInicio, type DadosInicio } from '../dados/inicio';
import { irAba, irTitulo, irVer } from '../rota';
import './inicio.css';

const TROCA = 8000;
const anosDe = (i: Item) => {
  const a = i.ProductionYear, b = i.EndDate ? new Date(i.EndDate).getFullYear() : undefined;
  return a ? (i.Type === 'Series' && b && b !== a ? `${a} - ${b}` : String(a)) : '';
};

export function Inicio({ s, pedir }: { s: Sessao; pedir: (e: EmBreve) => void }) {
  const [d, setD] = useState<DadosInicio | null>(null);
  const [n, setN] = useState(0);
  const [vistos, setVistos] = useState<Set<number>>(new Set([0]));
  const [rolou, setRolou] = useState(false);
  const parado = useRef(false), destaque = useRef<HTMLElement>(null), toque = useRef<number | null>(null);

  useEffect(() => { prepararInicio(s).then(setD).catch(() => setD(null)); }, [s.token]);
  const lista = d?.destaque || [];
  const atual = lista[n];
  usePaleta(hashDoDestaque(atual));

  const ir = (k: number) => { if (!lista.length) return; const x = (k + lista.length) % lista.length; setN(x); setVistos(v => new Set(v).add(x)); };
  useEffect(() => {
    if (lista.length < 2) return;
    const t = setInterval(() => { if (!parado.current && !document.hidden) ir(n + 1); }, TROCA);
    return () => clearInterval(t);
  }, [lista.length, n]);
  useEffect(() => {
    const f = () => { const h = destaque.current?.offsetHeight || 400; setRolou(scrollY > h * 0.55); };
    f(); addEventListener('scroll', f, { passive: true });
    return () => removeEventListener('scroll', f);
  }, []);

  const lg = atual ? logo(s, atual, 600) : '';
  const meta = atual ? [nota(atual) && <><span class="destaque-estrela">★</span> {nota(atual)}</>, anosDe(atual), atual.Genres?.slice(0, 3).join(', ')].filter(Boolean) : [];
  return (
    <div class="inicio">
      <Topo s={s} aoServidor={abrirServidores} fundo={rolou}
        centro={rolou && atual ? (lg ? <img class="topo-logo" src={lg} alt={atual.Name} /> : <span class="topo-nome uma-linha">{atual.Name}</span>) : null} />
      <section class="destaque" ref={destaque} aria-roledescription="carrossel" aria-label="Destaques"
        onPointerEnter={e => { if (e.pointerType === 'mouse') parado.current = true; }} onPointerLeave={() => { parado.current = false; }}
        onPointerDown={e => { toque.current = e.clientX; }}
        onPointerUp={e => { if (toque.current === null) return; const dx = e.clientX - toque.current; toque.current = null; if (Math.abs(dx) > 50) ir(n + (dx < 0 ? 1 : -1)); }}>
        <div class="destaque-artes">
          {lista.map((i, k) => vistos.has(k) && (
            <Imagem key={i.Id} classe={`destaque-arte${k === n ? ' atual' : ''}`} src={fundo(s, i, Math.min(1920, Math.round(innerWidth * devicePixelRatio)))}
              hash={hashDe(i, 'Backdrop')} prioridade={k === 0} />
          ))}
          {!lista.length && <span class="destaque-arte atual esqueleto" />}
        </div>
        {atual && (
          <button class="destaque-texto" key={atual.Id} onClick={() => irTitulo(atual.Id)} aria-label={`Abrir ${atual.Name}`}>
            {lg ? <img class="destaque-logo" src={lg} alt={atual.Name} /> : <span class="destaque-nome">{atual.Name}</span>}
            {meta.length > 0 && <span class="destaque-meta">{meta.map((m, k) => <span key={k}>{m}</span>)}{atual.OfficialRating && <span class="selo-idade">{atual.OfficialRating}</span>}</span>}
            {atual.Overview && <span class="destaque-sinopse duas-linhas">「{atual.Name}」 {atual.Overview}</span>}
          </button>
        )}
        {lista.length > 1 && (
          <div class="destaque-pontos" role="tablist">
            {lista.map((i, k) => <button key={i.Id} role="tab" aria-selected={k === n} aria-label={`Destaque ${k + 1}`} class={k === n ? 'atual' : ''} onClick={() => ir(k)} />)}
          </div>
        )}
      </section>

      {!d && <Fileira titulo="Continuar"><EsqueletoCartoes tipo="paisagem" n={3} /></Fileira>}
      {d && d.continuar.length > 0 && (
        <Fileira titulo="Continuar">
          {d.continuar.map((i, k) => <CartaoPaisagem key={i.Id} s={s} i={i} tempo prioridade={k < 2} aoAbrir={x => irVer(x.Id, x.UserData?.PlaybackPositionTicks)} />)}
        </Fileira>
      )}
      {d && d.proximo.length > 0 && (
        <Fileira titulo="Próximo">{d.proximo.map(i => <CartaoPaisagem key={i.Id} s={s} i={i} aoAbrir={x => irVer(x.Id)} />)}</Fileira>
      )}
      {d && d.emAlta.itens.length > 0 && (
        <Fileira titulo={d.emAlta.titulo} classe="fileira-top10">
          {d.emAlta.itens.map((i, k) => <CartaoTop10 key={i.Id} s={s} i={i} n={k + 1} aoAbrir={x => irTitulo(x.Id)} />)}
        </Fileira>
      )}
      {d && d.midia.length > 0 && (
        <Fileira titulo="Mídia">{d.midia.map(b => <CartaoBiblioteca key={b.Id} s={s} b={b} aoAbrir={x => irAba(`b/${x.Id}`)} />)}</Fileira>
      )}
      {d && d.porBiblioteca.map(({ biblioteca: b, itens }) => (
        <Fileira key={b.Id} titulo={b.Name} verTudo={() => irAba(`b/${b.Id}`)}>
          {itens.map(i => <CartaoPoster key={i.Id} s={s} i={i} aoAbrir={x => irTitulo(x.Type === 'Episode' && x.SeriesId ? x.SeriesId : x.Id)} />)}
        </Fileira>
      ))}
      {d && d.emBreve.tv.length > 0 && <Fileira titulo="Séries em breve">{d.emBreve.tv.map((e, k) => <CartaoEmBreve key={k} e={e} aoAbrir={x => x.jf ? irTitulo(x.jf) : pedir(x)} />)}</Fileira>}
      {d && d.emBreve.movie.length > 0 && <Fileira titulo="Filmes em breve">{d.emBreve.movie.map((e, k) => <CartaoEmBreve key={k} e={e} aoAbrir={x => x.jf ? irTitulo(x.jf) : pedir(x)} />)}</Fileira>}
    </div>
  );
}
