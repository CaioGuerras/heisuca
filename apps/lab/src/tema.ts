// Tema do Lume: Sala (escuro quente), Matinê (claro) e Projetor (preto OLED). A troca "acende" a partir do botão
// (View Transition com recorte circular); com "reduzir movimento" ou sem suporte, só esmaece.
export type Tema = 'sala' | 'matine' | 'projetor';
export const TEMAS: { id: Tema; nome: string; dica: string; icone: string }[] = [
  { id: 'sala', nome: 'Sala', dica: 'Escuro e quente, para a noite', icone: 'dark_mode' },
  { id: 'matine', nome: 'Matinê', dica: 'Claro, cor de papel', icone: 'light_mode' },
  { id: 'projetor', nome: 'Projetor', dica: 'Preto total, para telas OLED', icone: 'theaters' },
];
export const temaAtual = (): Tema => (document.documentElement.getAttribute('data-tema') as Tema) || 'sala';
const reduzido = () => matchMedia('(prefers-reduced-motion: reduce)').matches;

export function trocarTema(t: Tema, de?: { x: number; y: number }) {
  const html = document.documentElement;
  try { localStorage.setItem('lume.tema', t); } catch { /* nada */ }
  const aplicar = () => {
    html.setAttribute('data-tema', t);
    const meta = document.querySelector('meta[name="theme-color"]');
    meta?.setAttribute('content', getComputedStyle(html).getPropertyValue('--fundo').trim() || '#14110e');
  };
  const d = document as Document & { startViewTransition?: (f: () => void) => { ready: Promise<void> } };
  if (!d.startViewTransition || reduzido() || temaAtual() === t) { aplicar(); return; }
  html.classList.add('vt-tema');
  const vt = d.startViewTransition(aplicar);
  const x = de?.x ?? innerWidth - 40, y = de?.y ?? 32;
  const r = Math.hypot(Math.max(x, innerWidth - x), Math.max(y, innerHeight - y));
  vt.ready.then(() => {
    document.documentElement.animate({ clipPath: [`circle(0px at ${x}px ${y}px)`, `circle(${r}px at ${x}px ${y}px)`] },
      { duration: 520, easing: 'cubic-bezier(0.2, 0, 0, 1)', pseudoElement: '::view-transition-new(root)' });
  }).catch(() => undefined);
  (vt as unknown as { finished: Promise<void> }).finished?.finally(() => html.classList.remove('vt-tema'));
}
