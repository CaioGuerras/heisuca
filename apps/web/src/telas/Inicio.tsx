// Início (PLANO §4; ref/vidhub/…home_topo, …home_rolada, …foto67).
//  Topo sem barra (logo Heisuca à esquerda + busca; o servidor foi para o menu do usuário, Caio 19/10 noite). Destaque sem bordas: a arte vai até o topo e se dissolve na cor tirada do
//  pôster; no centro a logo, `★ nota | anos | gêneros | [classificação]`, a sinopse 「Título」 em 2 linhas e os pontinhos.
//  Ao rolar, a logo sobe com a página e encaixa no topo, entre a marca e a busca (…home_rolada).
//  Fileiras: Continuar · Próximo · Em alta no Brasil · Mídia · uma por biblioteca · Em breve (no fim).
import { useEffect, useLayoutEffect, useRef, useState } from 'preact/hooks';
import { fundo, hashDe, logo, type EmBreve, type Item, type Sessao } from '../api/servidor.ts';
import { usePaleta } from '../cor/paleta';
import { anos, CartaoBiblioteca, CartaoEmBreve, CartaoPaisagem, CartaoPoster, CartaoTop10, EsqueletoCartoes, nota } from '../comp/Cartoes';
import { Fileira } from '../comp/Fileira';
import { Classificacao } from '../comp/Classificacao';
import { Icone } from '../comp/Icone';
import { Imagem } from '../comp/Imagem';
import { Topo } from '../comp/Navegacao';
import { carregarSecundario, hashDoDestaque, prepararInicio, type DadosInicio } from '../dados/inicio';
import { irAba, irTitulo, irVer } from '../rota';
import './inicio.css';

const TROCA = 8000;

export function Inicio({ s, pedir }: { s: Sessao; pedir: (e: EmBreve) => void }) {
  const [d, setD] = useState<DadosInicio | null>(null);
  const [n, setN] = useState(0);
  const [anterior, setAnterior] = useState<number | null>(null);
  const [encaixou, setEncaixou] = useState(false);
  const [pausado, setPausado] = useState(false);
  const troca = useRef(0);
  // troca em andamento (esperando a arte decodificar): o automático não atropela um clique, e mudar pausa/encaixe só
  // cancela troca automática
  const pendente = useRef<{ pedido: number; auto: boolean } | null>(null);
  const parado = useRef({ ponteiro: false, foco: false }), toque = useRef<number | null>(null);
  const casa = useRef<HTMLSpanElement>(null), marca = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    let vivo = true;
    setD(null); setN(0); setAnterior(null);
    prepararInicio(s).then(critico => {
      if (!vivo) return;
      setD(critico);
      carregarSecundario(s).then(sec => {
        if (vivo) setD(prev => prev ? { ...prev, ...sec } : null);
      });
    }).catch(() => { if (vivo) setD(null); });
    return () => { vivo = false; troca.current++; };
  }, [s.token, s.servidor, s.usuarioId]);
  const lista = d?.destaque || [];
  const atual = lista[n];
  usePaleta(hashDoDestaque(s, atual));

  const ir = async (k: number, automatica = false) => {
    if (!lista.length) return;
    const x = (k + lista.length) % lista.length, i = lista[x];
    if (x === n) { troca.current++; pendente.current = null; return; }
    const pedido = ++troca.current;
    pendente.current = { pedido, auto: automatica };
    // A arte anterior permanece inteira até a próxima arte e logo estarem prontas.
    await Promise.all([fundo(s, i, Math.min(1920, Math.round(innerWidth * devicePixelRatio))), logo(s, i, 600)]
      .filter(Boolean).map(async src => { const img = new Image(); img.src = src; await img.decode().catch(() => undefined); }));
    if (pendente.current?.pedido === pedido) pendente.current = null;
    if (pedido !== troca.current || (automatica && (parado.current.ponteiro || parado.current.foco || pausado || document.hidden || matchMedia('(prefers-reduced-motion: reduce)').matches))) return;
    setAnterior(n); setN(x);
  };
  // troca automática; para com o dedo/mouse em cima e enquanto a logo está encaixada no topo (a cor da página não muda
  // enquanto a pessoa lê as fileiras)
  useEffect(() => {
    if (lista.length < 2) return;
    const t = setInterval(() => { if (!parado.current.ponteiro && !parado.current.foco && !pausado && !encaixou && !document.hidden && !matchMedia('(prefers-reduced-motion: reduce)').matches && !pendente.current) void ir(n + 1, true); }, TROCA);
    return () => { clearInterval(t); if (pendente.current?.auto) troca.current++; };
  }, [lista.length, n, encaixou, pausado]);

  // a logo sobe com a página até o meio do topo e fica ali, encolhendo para caber entre a marca e a busca
  useLayoutEffect(() => {
    let quadro = 0, preso = false;
    const medir = () => {
      quadro = 0;
      const c = casa.current, m = marca.current;
      if (!c || !m) return;
      const esq = document.querySelector('.topo-marca')?.getBoundingClientRect();
      const busca = document.querySelector('.topo-busca')?.getBoundingClientRect();
      if (!esq || !busca) return;
      const r = c.getBoundingClientRect(), alvo = busca.top + busca.height / 2, centro = r.top + r.height / 2;
      const w = m.offsetWidth || 1, h = m.offsetHeight || 1;
      const cabe = Math.max(0.3, Math.min(1, (Math.min(busca.left - innerWidth / 2, innerWidth / 2 - esq.right) * 2 - 40) / w, (busca.height * 1.5) / h));
      const ida = Math.min(1, Math.max(0, (alvo + 140 - centro) / 140));    // nos últimos 140 px antes de encaixar
      const sobe = Math.max(0, alvo - centro);
      m.style.transform = sobe || ida ? `translateY(${sobe}px) scale(${1 - (1 - cabe) * ida})` : '';
      const agora = sobe > 0;
      if (agora !== preso) { preso = agora; setEncaixou(agora); }
    };
    const pedirQuadro = () => { if (!quadro) quadro = requestAnimationFrame(medir); };
    medir();
    addEventListener('scroll', pedirQuadro, { passive: true }); addEventListener('resize', pedirQuadro);
    const ro = new ResizeObserver(pedirQuadro); if (marca.current) ro.observe(marca.current);
    return () => { cancelAnimationFrame(quadro); removeEventListener('scroll', pedirQuadro); removeEventListener('resize', pedirQuadro); ro.disconnect(); };
  }, [atual?.Id]);

  const generos = atual?.Genres?.slice(0, 5).join(', ');
  const emBreve = d ? [...d.emBreve.tv, ...d.emBreve.movie] : [];
  return (
    <main class="inicio">
      <Topo fundo={encaixou} />
      <section class="destaque" aria-roledescription="carrossel" aria-label="Destaques"
        onFocusCapture={() => { parado.current.foco = true; }}
        onBlurCapture={e => { if (!e.currentTarget.contains(e.relatedTarget as Node | null)) parado.current.foco = false; }}
        onPointerEnter={e => { if (e.pointerType === 'mouse') parado.current.ponteiro = true; }}
        onPointerLeave={e => { if (e.pointerType === 'mouse') parado.current.ponteiro = false; }}
        onPointerDown={e => { toque.current = e.clientX; if (e.pointerType !== 'mouse') parado.current.ponteiro = true; }}
        onPointerCancel={() => { toque.current = null; parado.current.ponteiro = false; }}
        onPointerUp={e => {
          if (e.pointerType !== 'mouse') parado.current.ponteiro = false;
          if (toque.current === null) return;
          const dx = e.clientX - toque.current; toque.current = null;
          if (Math.abs(dx) > 50) ir(n + (dx < 0 ? 1 : -1));
        }}>
        <div class="destaque-artes">
          {[anterior, n].map(k => {
            const i = k === null ? null : lista[k];
            return i && <Imagem key={i.Id} classe={`destaque-arte${k === n ? ' atual' : ''}`} src={fundo(s, i, Math.min(1920, Math.round(innerWidth * devicePixelRatio)))}
              hash={hashDe(s, i, 'Backdrop')} prioridade />;
          })}
          {!lista.length && <span class="destaque-arte atual esqueleto" />}
        </div>
        {atual && (
          <button class="destaque-texto" key={atual.Id} onClick={() => irTitulo(atual.Id, atual)} aria-label={`Abrir ${atual.Name}`}>
            <span class="destaque-casa" ref={casa}>
              <span class="destaque-marca" ref={marca}>
                <MarcaDestaque key={atual.Id} s={s} i={atual} />
              </span>
            </span>
            <span class="destaque-meta">
              {nota(atual) && <span class="destaque-nota"><span class="destaque-estrela" aria-hidden="true">★</span>{nota(atual)}</span>}
              {anos(atual) && <span>{anos(atual)}</span>}
              {generos && <span class="destaque-generos">{generos}</span>}
              {atual.OfficialRating && <span><Classificacao valor={atual.OfficialRating} /></span>}
            </span>
            {atual.Overview && <span class="destaque-sinopse duas-linhas"><b>「{atual.Name}」</b> {atual.Overview}</span>}
          </button>
        )}
        {lista.length > 1 && (
          <div class="destaque-controles">
          <div class="destaque-pontos" role="group" aria-label="Escolher destaque">
            {lista.map((i, k) => <button key={i.Id} aria-pressed={k === n} aria-label={`${k + 1}: ${i.Name}`} class={k === n ? 'atual' : ''} onClick={() => ir(k)} />)}
          </div>
          <button class="destaque-pausa" onClick={() => setPausado(p => !p)} aria-pressed={pausado}
            aria-label={pausado ? 'Retomar destaques automáticos' : 'Pausar destaques automáticos'}>
            <Icone nome={pausado ? 'play_arrow' : 'pause'} tamanho={16} />
          </button>
          </div>
        )}
      </section>

      {!d && <Fileira titulo="Continuar"><EsqueletoCartoes tipo="paisagem" n={3} /></Fileira>}
      {d && d.retomar.length > 0 && (
        <Fileira titulo="Continuar">
          {d.retomar.map((i, k) => {
            const pos = i.UserData?.PlaybackPositionTicks;
            return <CartaoPaisagem key={i.Id} s={s} i={i} tempo={!!pos} prioridade={k < 2} aoAbrir={x => irVer(x.Id, pos || undefined)} />;
          })}
        </Fileira>
      )}
      {d && d.proximos.length > 0 && (
        <Fileira titulo="Próximo">
          {d.proximos.map(i => <CartaoPaisagem key={i.Id} s={s} i={i} aoAbrir={x => irVer(x.Id, x.UserData?.PlaybackPositionTicks || undefined)} />)}
        </Fileira>
      )}
      {d && d.emAlta.itens.length > 0 && (
        <Fileira titulo={d.emAlta.titulo || 'Em alta'} classe="fileira-top10">
          {d.emAlta.itens.slice(0, 10).map((i, k) => <CartaoTop10 key={i.Id} s={s} i={i} n={k + 1} aoAbrir={x => irTitulo(x.Id, x)} />)}
        </Fileira>
      )}
      {d && d.bibliotecas.length > 0 && (
        <Fileira titulo="Mídia">
          {d.bibliotecas.map(b => <CartaoBiblioteca key={b.Id} s={s} b={b} sobreposto aoAbrir={x => irAba(`b/${x.Id}`)} />)}
        </Fileira>
      )}
      {d && d.porBiblioteca.map(({ biblioteca: b, itens }) => (
        <Fileira key={b.Id} titulo={b.Name} verTudo={() => irAba(`b/${b.Id}`)}>
          {itens.map(i => <CartaoPoster key={i.Id} s={s} i={i} aoAbrir={(x: Item) => irTitulo(x.Type === 'Episode' && x.SeriesId ? x.SeriesId : x.Id, x)} />)}
        </Fileira>
      ))}
      {emBreve.length > 0 && (
        <Fileira titulo="Em breve">{emBreve.map((e, k) => <CartaoEmBreve key={k} e={e} aoAbrir={x => x.jf ? irTitulo(x.jf) : pedir(x)} />)}</Fileira>
      )}
    </main>
  );
}

// Uma logo anunciada pelo servidor pode falhar; o título continua legível em Sora (§2.3).
function MarcaDestaque({ s, i }: { s: Sessao; i: Item }) {
  const [falhou, setFalhou] = useState(false);
  const lg = logo(s, i, 600);
  return lg && !falhou ? <img class="destaque-logo" src={lg} alt={i.Name} onError={() => setFalhou(true)} />
    : <span class="destaque-nome">{i.Name}</span>;
}
