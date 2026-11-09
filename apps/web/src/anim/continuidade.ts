// Continuidade (H2, ESTUDO_MOVIMENTO_2026-11 §4): a arte do cartão tocado vira o fundo do título. View Transitions do
// mesmo documento (Chrome 111+, Safari 18+): o navegador fotografa a tela velha, a rota troca, e a arte "hs-arte" vai
// do cartão até o .titulo-arte enquanto o resto da tela velha some (transicoes.css). Sem suporte, ou com "reduzir
// movimento", quem chama usa a saída do H3 (anim/saida.ts).
// sem import do voo.ts (ele puxa a Logo): o teste em node carrega este arquivo sozinho
const reduzido = () => !!window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;

const NOME = 'hs-arte';
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

// true = a troca ficou por conta da transição (aplicar é chamado lá dentro); false = quem chama faz a saída normal
export function trocarComArte(aplicar: () => void, doc: Document = document): boolean {
  const d = doc as ComTransicao;
  if (typeof d.startViewTransition !== 'function' || reduzido() || doc.hidden) return false;
  const origem = origemDoToque(doc);
  toque = null;
  if (!origem) return false;
  const raiz = doc.documentElement;
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
