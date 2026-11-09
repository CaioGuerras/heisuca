// Continuidade (H2, ESTUDO_MOVIMENTO_2026-11 §4): a arte do cartão tocado vira o fundo do título. View Transitions do
// mesmo documento (Chrome 111+, Safari 18+): o navegador fotografa a tela velha, a rota troca, e a arte "hs-arte" vai
// do cartão até o .titulo-arte enquanto o resto da tela velha some (transicoes.css). Sem suporte, ou com "reduzir
// movimento", quem chama usa a saída do H3 (anim/saida.ts).
// sem import do voo.ts (ele puxa a Logo): o teste em node carrega este arquivo só com o rolagem.ts
import { lembranca, lembrar, type Lembranca } from './rolagem.ts';
const reduzido = () => !!window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;

const NOME = 'hs-arte', TEXTO = 'hs-destaque-texto';
const RECENTE = 800; // ms entre o toque e a troca de rota (o hashchange chega logo depois do clique)
let toque: { el: Element; t: number } | null = null;

type ComTransicao = Document & { startViewTransition?: (f: () => Promise<void> | void) => { finished: Promise<void> } };

// guarda o último toque (fase de captura: vale para qualquer cartão sem mudar a assinatura do aoAbrir)
export function lembrarToques(doc: Document = document): () => void {
  const f = (e: Event) => { if (e.target instanceof Element) toque = { el: e.target, t: performance.now() }; };
  doc.addEventListener('click', f, true);
  return () => doc.removeEventListener('click', f, true);
}

// a arte que foi tocada: a do cartão, ou a do destaque (o toque cai no texto por cima dela)
export function origemDoToque(doc: Document = document, agora = performance.now()): HTMLElement | null {
  if (!toque || agora - toque.t > RECENTE || !toque.el.isConnected) return null;
  const cartao = toque.el.closest('.cartao');
  const moldura = cartao ? cartao.querySelector<HTMLElement>('.cartao-arte') : null;
  // só a imagem do cartão voa: a nota e os selos ficam (ampliados viravam um "8,6" gigante no meio da troca)
  const arte = moldura ? moldura.querySelector<HTMLElement>('.img') || moldura
    : !cartao && toque.el.closest('.destaque') ? doc.querySelector<HTMLElement>('.destaque-arte.atual') : null;
  if (!arte) return null;
  const r = arte.getBoundingClientRect();
  return r.width && r.bottom > 0 && r.top < innerHeight ? arte : null;
}

const semTransicao = (d: ComTransicao) => typeof d.startViewTransition !== 'function' || reduzido() || d.hidden;

// true = a troca ficou por conta da transição (aplicar é chamado lá dentro); false = quem chama faz a saída normal
export function trocarComArte(aplicar: () => void, doc: Document = document): boolean {
  const d = doc as ComTransicao;
  if (semTransicao(d)) return false;
  const origem = origemDoToque(doc);
  toque = null;
  if (!origem) return false;
  const raiz = doc.documentElement;
  // H5: a entrada que sai (ainda em vigor no mapa) guarda de onde a arte saiu, para o Voltar levar a arte de volta
  const ro = origem.getBoundingClientRect(), src = origem.querySelector('img')?.getAttribute('src');
  if (src) lembrar({ origem: { src, top: ro.top, left: ro.left } });
  origem.style.setProperty('view-transition-name', NOME);
  let t: { finished: Promise<void> };
  try {
    t = d.startViewTransition.call(doc, async () => {
      // depois da foto da tela velha: o nome passa do cartão para o fundo do título (nunca dois com o mesmo nome)
      origem.style.removeProperty('view-transition-name');
      raiz.classList.add('hs-vt');
      aplicar();
      await new Promise(r => setTimeout(r)); // o Preact pinta num microtask; o setTimeout vem depois dele
    });
  } catch { origem.style.removeProperty('view-transition-name'); return false; }
  const fim = () => raiz.classList.remove('hs-vt');
  t.finished.then(fim, fim);
  return true;
}

// H5, o caminho inverso: no Voltar, o fundo do título encolhe até o cartão (ou destaque) que o abriu. O cartão é achado
// pela imagem (o mesmo src) mais perto de onde estava, depois que a rolagem voltou; sem ele, a arte só some.
const visivel = (r: { width: number; top: number; bottom: number }) => !!r.width && r.bottom > 0 && r.top < innerHeight;
type Origem = NonNullable<Lembranca['origem']>;
const distancia = (r: { top: number; left: number }, o: Origem) => Math.abs(r.top - o.top) + Math.abs(r.left - o.left);

export function acharAlvo(o: Origem, doc: Document = document): HTMLElement | null {
  let melhor: HTMLElement | null = null, menor = Infinity;
  for (const img of Array.from(doc.querySelectorAll<HTMLElement>('.cartao-arte img, .destaque-arte.atual img'))) {
    if (img.getAttribute('src') !== o.src) continue;
    const el = img.closest<HTMLElement>('.img');
    if (!el) continue;
    const r = el.getBoundingClientRect();
    if (!visivel(r)) continue;
    const dd = distancia(r, o);
    // no destaque voa a caixa das artes inteira, com o degradê (só a foto cobria o degradê e a logo até o fim)
    if (dd < menor) { menor = dd; melhor = el.closest<HTMLElement>('.destaque-artes') || el; }
  }
  return melhor;
}

async function esperarAlvo(o: Origem, doc: Document, espera: number): Promise<HTMLElement | null> {
  const t0 = performance.now();
  for (;;) {
    await new Promise(r => setTimeout(r, 16)); // dentro da transição não há quadro (rAF parado)
    const a = acharAlvo(o, doc);
    if (a && distancia(a.getBoundingClientRect(), o) < 48) return a; // a rolagem já voltou
    if (performance.now() - t0 > espera) return a;
  }
}

export function trocarDeVolta(aplicar: () => void, doc: Document = document, espera = 400): boolean {
  const d = doc as ComTransicao;
  if (semTransicao(d)) return false;
  const arte = doc.querySelector<HTMLElement>('.titulo-arte');
  if (!arte || !visivel(arte.getBoundingClientRect())) return false;
  arte.style.setProperty('view-transition-name', NOME);
  let alvo: HTMLElement | null = null, texto: HTMLElement | null = null;
  let t: { finished: Promise<void> };
  try {
    t = d.startViewTransition.call(doc, async () => {
      arte.style.removeProperty('view-transition-name');
      aplicar(); // entra na entrada de volta: a lembrança agora é a da tela de destino
      const o = lembranca()?.origem;
      if (!o) return;
      alvo = await esperarAlvo(o, doc, espera);
      alvo?.style.setProperty('view-transition-name', NOME);
      // e o texto do destaque numa camada própria, por cima da arte que chega
      texto = alvo?.classList?.contains('destaque-artes') ? doc.querySelector<HTMLElement>('.destaque-texto') : null;
      texto?.style.setProperty('view-transition-name', TEXTO);
    });
  } catch { arte.style.removeProperty('view-transition-name'); return false; }
  const fim = () => { alvo?.style.removeProperty('view-transition-name'); texto?.style.removeProperty('view-transition-name'); };
  t.finished.then(fim, fim);
  return true;
}
