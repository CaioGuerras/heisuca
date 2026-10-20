// 2ª animação (PLANO §3.3; Caio 19/10: "inversa da primeira ou algo assim", fluida, 2 a 4 s). Depois de "Iniciar sessão"
// (ou com a sessão já salva), enquanto a home carrega por baixo:
//   1. a logo cresce do lugar dela até o centro da tela (voo FLIP);
//   2. a abertura ao contrário: o ヘイスカ some, o traço de luz atravessa o HEISUCA e o apaga, e o selo fica sozinho no centro;
//   3. o selo respira enquanto a home não fica pronta (dados críticos + imagens do 1º destaque decodificadas);
//   4. o selo se abre até cobrir a tela, passando da cor do tema para a cor tirada do pôster do 1º destaque, e se desfaz
//      sobre a home, que já está nessa cor.
// Rodada 2 (Caio 19/10 noite): no fim, retângulo no celular e um círculo nascendo do selo no computador; e, quando vem
// logo depois da abertura (sessão salva), a parte "a luz apaga a palavra" é pulada (a palavra só esmaece enquanto o selo vai
// ao centro), para o total ficar em ~5 s.
// "Reduzir movimento": a logo aparece parada, e no fim só um esmaecimento para a cor do pôster.
// Sessão G/H (Caio 20/10): transição com sobreposição suave entre as fases, curvas de entrada/saída contínuas e calibração
// refinada para entrada rápida mantendo a nobreza e respiração do selo.
import { useEffect, useLayoutEffect, useRef } from 'preact/hooks';
import type { Sessao } from '../api/jellyfin';
import { animar, CURVA, reduzido, voar } from '../anim/voo';
import { corDaBase, paletaDe } from '../cor/paleta';
import { css, deLch, misturar, paraLch, type RGB } from '../cor/oklch';
import { decodificarPrimeiras, hashDoDestaque, prepararInicio } from '../dados/inicio';
import { Logo } from '../comp/Logo';
import { avisarErro } from '../aviso';
import './transicao.css';

// tempo total (do clique até a home), já com a revelação no fim
export const MINIMO = 2000, MAXIMO = 4500;
// logo depois da abertura: a transição curta com sessão salva
const MINIMO_CURTA = 1800;
const VOO = 600, REVELA = 950;
// curva da abertura do selo: começa contida e se solta (o "expirar" do carimbo), pousando devagar
const ABRE = 'cubic-bezier(0.45, 0, 0.15, 1)';
// entrada e saída suaves (sem arranque seco no começo de cada fase)
const SUAVE = 'cubic-bezier(0.42, 0, 0.2, 1)';
// a fase seguinte começa quando a anterior já fez esta fração (sobreposição leve entre as fases)
const EMENDA = 0.7;
// o selo respira ao menos isto no centro antes de se abrir (se ainda couber no tempo)
const POUSO = 200;

export function Transicao({ s, de, clique, curta = false, fim }: { s: Sessao; de?: DOMRect | null; clique?: number; curta?: boolean; fim: () => void }) {
  const raiz = useRef<HTMLDivElement>(null), logo = useRef<HTMLDivElement>(null), campo = useRef<HTMLDivElement>(null);
  // o voo "já pousou o bastante" (EMENDA da duração): a próxima fase começa enquanto ele termina de assentar
  const voo = useRef<Promise<unknown>>(Promise.resolve());
  useLayoutEffect(() => {
    const l = logo.current!;
    if (reduzido()) return;
    const ms = de ? VOO : 460;
    const todo = de ? voar(l, de, VOO)
      : animar(l, [{ opacity: 0, transform: 'scale(.94)' }, { opacity: 1, transform: 'none' }], { duration: ms, easing: SUAVE });
    voo.current = Promise.race([todo, new Promise(ok => setTimeout(ok, ms * EMENDA))]);
  }, []);
  useEffect(() => {
    // o relógio começa no clique em Iniciar sessão (login + esmaecer já contam); sem clique (sessão salva), agora
    const r = raiz.current!, l = logo.current!, c = campo.current!, t0 = clique ?? performance.now();
    const svg = l.querySelector('svg')!, q = (sel: string) => svg.querySelector(sel) as SVGGraphicsElement;
    let acabou = false;
    const pronto = prepararInicio(s).then(d => decodificarPrimeiras(s, d).then(() => d)).catch(() => null);
    const espera = (ms: number) => new Promise(ok => setTimeout(ok, Math.max(0, ms)));
    const passou = () => performance.now() - t0;
    const menos = reduzido();
    const revela = menos ? 450 : REVELA;

    let respira: Animation | null = null;
    (async () => {
      if (!menos) {
        await voo.current;
        if (acabou) return;
        respira = await inversa(l, q, curta);
        // um instante de respiração no centro antes de abrir (sem passar do máximo)
        await espera(Math.min(POUSO, MAXIMO - revela - passou()));
      }
      // espera a home (no mínimo até completar MINIMO com a revelação; no máximo MAXIMO)
      const d = await Promise.race([pronto, espera(MAXIMO - revela - passou()).then(() => null)]);
      await espera((menos ? 1200 : curta ? MINIMO_CURTA : MINIMO) - revela - passou());
      if (acabou) return;
      const p = paletaDe(corDaBase(hashDoDestaque(d?.destaque[0])));
      const final = css(p.pagina);
      if (menos) {
        await Promise.all([animar(l, [{ opacity: 1 }, { opacity: 0 }], 200),
          animar(r, [{ backgroundColor: getComputedStyle(r).backgroundColor }, { backgroundColor: final }], 250)]);
        await animar(r, [{ opacity: 1 }, { opacity: 0 }], 200);
      } else {
        respira?.pause();   // o selo para onde está, e o campo nasce exatamente sobre ele
        await abrirSelo(r, c, q, p.pagina, corDaBase(hashDoDestaque(d?.destaque[0])), p.escuro);
      }
    })().catch(e => avisarErro(`transição: ${e instanceof Error ? e.message : String(e)}`))
      // aconteça o que acontecer na animação, a pessoa nunca fica presa aqui: a home abre
      .finally(() => { if (!acabou) fim(); });
    return () => { acabou = true; respira?.cancel(); };
  }, []);
  return (
    <div class="transicao" ref={raiz} aria-label="Carregando" role="status">
      <div class="transicao-campo" ref={campo} aria-hidden="true" />
      <div class="transicao-logo" ref={logo}><Logo modo="marca" /></div>
    </div>
  );
}

// a abertura ao contrário: o ヘイスカ some, o traço de luz nasce sob o "H", atravessa a palavra e a apaga;
// o selo vai para o centro. Devolve a respiração do selo (que segue até a home ficar pronta).
// curta (logo depois da abertura): sem o traço de luz; HEISUCA e ヘイスカ só esmaecem enquanto o selo vai ao centro.
async function inversa(l: HTMLElement, q: (sel: string) => SVGGraphicsElement, curta = false): Promise<Animation> {
  const palavra = q('.palavra'), luz = q('.luz'), kata = q('.kata'), selo = q('.selo-fundo');
  if (curta) {
    (luz as SVGElement).style.visibility = 'hidden';   // o traço fica de fora (a animação dele na abertura o deixaria aceso)
    animar(kata, [{ opacity: 0.65 }, { opacity: 0 }], { duration: 280, easing: SUAVE });
    animar(palavra, [{ opacity: 1, transform: 'none' }, { opacity: 0, transform: 'translateX(6px)' }], { duration: 340, easing: SUAVE });
    await ateOCentro(l, selo);
    return respirar(q);
  }
  // a luz anda até o fim do HEISUCA: em múltiplos da própria largura (transform-box: fill-box)
  const pb = palavra.getBBox(), lb = luz.getBBox();
  const ate = ((pb.x + pb.width - lb.x - lb.width) / Math.max(1, lb.width)) * 100;
  animar(kata, [{ opacity: 0.65, transform: 'none' }, { opacity: 0, transform: 'translateY(4px)' }], { duration: 320, easing: SUAVE });
  await animar(luz, [{ opacity: 0, transform: 'scaleX(0)' }, { opacity: 1, transform: 'none' }], { duration: 240, delay: 40, easing: SUAVE });
  // a palavra se apaga atrás da luz (recorte da esquerda para a direita, acompanhando o traço)
  const travessia = { duration: 480, easing: 'cubic-bezier(0.4, 0, 0.3, 1)' };
  animar(palavra, [{ clipPath: 'inset(-20% -2% -20% 0)', opacity: 1 }, { clipPath: 'inset(-20% -2% -20% 100%)', opacity: 0.6 }], travessia);
  animar(luz, [{ transform: 'none', opacity: 1 }, { transform: `translateX(${ate}%)`, opacity: 1, offset: 0.85 },
    { transform: `translateX(${ate}%) scaleX(0)`, opacity: 0 }], { ...travessia, duration: 520 });
  // o selo começa a ir para o centro enquanto a luz ainda se apaga no fim da palavra
  await new Promise(ok => setTimeout(ok, 520 * EMENDA));
  await ateOCentro(l, selo);
  return respirar(q);
}

// o selo, sozinho, desliza para o centro da tela
async function ateOCentro(l: HTMLElement, selo: SVGGraphicsElement) {
  // (a escala é em torno do centro da logo: o centro do selo se afasta dele na mesma proporção)
  const sb = selo.getBoundingClientRect(), lr = l.getBoundingClientRect(), k = 1.12;
  const lx = lr.left + lr.width / 2, ly = lr.top + lr.height / 2;
  const dx = innerWidth / 2 - lx - k * (sb.left + sb.width / 2 - lx), dy = innerHeight / 2 - ly - k * (sb.top + sb.height / 2 - ly);
  await animar(l, [{ transform: 'none' }, { transform: `translate(${dx}px, ${dy}px) scale(${k})` }], { duration: 480, easing: SUAVE });
}

function respirar(q: (sel: string) => SVGGraphicsElement): Animation {
  return q('.carimbo').animate([{ transform: 'scale(1)' }, { transform: 'scale(1.035)' }, { transform: 'scale(1)' }],
    { duration: 2200, easing: 'ease-in-out', iterations: Infinity });
}

// o selo se abre até cobrir a tela: um campo do tamanho exato do selo toma o lugar do fundo dele e cresce (clip-path),
// passando pela cor do pôster até a cor da página da home; o kanji esmaece; por fim tudo se desfaz sobre a home.
async function abrirSelo(r: HTMLElement, c: HTMLElement, q: (sel: string) => SVGGraphicsElement, pagina: RGB, base: RGB | null, escuro: boolean) {
  const fundo = q('.selo-fundo'), b = fundo.getBoundingClientRect();
  const raio = 4.64 * (b.width / 70.72), W = innerWidth, H = innerHeight;
  const cor = getComputedStyle(fundo).fill;
  // no meio do caminho, o matiz do pôster com cor de verdade (a média crua do BlurHash costuma ser barrenta)
  const lch = base && paraLch(base);
  const final = css(pagina), meio = lch && lch.c > 0.02
    ? css(misturar(deLch({ l: escuro ? 0.42 : 0.74, c: Math.min(0.13, lch.c * 1.4 + 0.03), h: lch.h }), pagina, 0.25)) : final;
  const ms = 800;
  // computador: um círculo nasce do centro do selo (escondido atrás dele) e cresce até cobrir a tela; o quadrado do selo
  // esmaece por cima no começo. Celular: o próprio selo (retângulo arredondado) se abre até as bordas.
  const circulo = matchMedia('(min-width: 1024px)').matches;
  const cx = b.left + b.width / 2, cy = b.top + b.height / 2;
  const inicio = circulo ? `circle(${b.width * 0.45}px at ${cx}px ${cy}px)`
    : `inset(${b.top}px ${W - b.right}px ${H - b.bottom}px ${b.left}px round ${raio}px)`;
  const fimClip = circulo ? `circle(${Math.hypot(Math.max(cx, W - cx), Math.max(cy, H - cy)) + 2}px at ${cx}px ${cy}px)`
    : `inset(0px 0px 0px 0px round 0px)`;
  c.style.background = cor;
  c.style.clipPath = inicio;
  c.style.visibility = 'visible';
  if (circulo) animar(fundo, [{ opacity: 1 }, { opacity: 0 }], { duration: ms * 0.3, easing: 'ease-in', fill: 'forwards' });
  else (fundo as SVGElement).style.opacity = '0';
  animar(q('.selo-moldura'), [{ opacity: 1 }, { opacity: 0 }], { duration: 260, easing: SUAVE });
  animar(q('.selo-kanji'), [{ opacity: 1, transform: 'none' }, { opacity: 0, transform: 'scale(1.18)' }], { duration: ms * 0.55, easing: CURVA });
  animar(c, [
    { clipPath: c.style.clipPath, backgroundColor: cor },
    { backgroundColor: meio, offset: 0.4 },
    { clipPath: fimClip, backgroundColor: final },
  ], { duration: ms, easing: ABRE });
  // a home aparece enquanto o campo termina de se abrir (sem pausa num quadro liso): o esmaecimento começa mais cedo e
  // é mais longo, para a camada se desfazer sobre a home sem "corte"
  await new Promise(ok => setTimeout(ok, ms * 0.55));
  await animar(r, [{ opacity: 1 }, { opacity: 0 }], { duration: 500, easing: 'cubic-bezier(0.33, 0, 0.2, 1)' });
}
