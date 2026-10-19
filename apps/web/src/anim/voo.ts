// "A logo vai e vem entre as telas" (Caio, 19/10; PLANO §3.1). Técnica FLIP com Web Animations: o elemento já está no
// lugar final; medimos onde a logo dele está e onde ela estava (de), e animamos da posição antiga até a nova. Só
// transform (GPU), sem layout no meio. "Reduzir movimento": troca direta, sem voo.
import { areaDaLogo } from '../comp/Logo';

export const CURVA = 'cubic-bezier(0.2, 0, 0, 1)';
export const reduzido = () => !!window.matchMedia?.('(prefers-reduced-motion: reduce)').matches;

export async function voar(el: HTMLElement, de: DOMRect, ms = 720): Promise<void> {
  if (reduzido() || !el.animate) return;
  const para = areaDaLogo(el), caixa = el.getBoundingClientRect();
  if (!para.width || !de.width) return;
  const s = de.width / para.width;
  // ponto P do elemento (origem no canto) vai para O + s·(P − O) + t; queremos para.x → de.x
  const tx = de.left - caixa.left - s * (para.left - caixa.left), ty = de.top - caixa.top - s * (para.top - caixa.top);
  el.style.transformOrigin = '0 0';
  await el.animate([{ transform: `translate(${tx}px, ${ty}px) scale(${s})` }, { transform: 'none' }], { duration: ms, easing: CURVA, fill: 'backwards' }).finished.catch(() => undefined);
  el.style.transformOrigin = '';
}

export const esmaecer = (el: Element | null, de: number, para: number, ms = 320, atraso = 0) =>
  el && !reduzido() && (el as HTMLElement).animate
    ? (el as HTMLElement).animate([{ opacity: de }, { opacity: para }], { duration: ms, delay: atraso, easing: CURVA, fill: 'forwards' }).finished.catch(() => undefined)
    : Promise.resolve();
