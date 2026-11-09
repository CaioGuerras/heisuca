// Voltar sem perder o lugar (H5, ESTUDO_MOVIMENTO_2026-11 §5). Cada entrada do histórico ganha um id em history.state.hs;
// a rolagem, o destaque e a arte que abriu a tela seguinte ficam num mapa em memória com esse id. O hashchange chega com
// a entrada nova já em vigor, por isso a rota grava a rolagem velha (sair) antes de ler a nova (entrar).
// Sem imports: o teste em node carrega este arquivo sozinho.
export type Lembranca = { y?: number; destaque?: string; origem?: { src: string; top: number; left: number } };

const mapa = new Map<string, Lembranca>();
let idAtual = '';
let conta = 0;
const novoId = () => `${Date.now().toString(36)}.${++conta}`;

function idDaEntrada(h: History): string {
  const id = h.state && typeof h.state === 'object' ? (h.state as { hs?: unknown }).hs : undefined;
  if (typeof id === 'string') return id;
  const n = novoId();
  try { h.replaceState({ ...(h.state && typeof h.state === 'object' ? h.state : {}), hs: n }, ''); } catch { /* nada */ }
  return n;
}

export function iniciarRolagem(h: History = history): void {
  try { h.scrollRestoration = 'manual'; } catch { /* nada */ }
  idAtual = idDaEntrada(h);
}

export const lembranca = (): Lembranca | undefined => mapa.get(idAtual);
export function lembrar(p: Lembranca): void { if (idAtual) mapa.set(idAtual, { ...mapa.get(idAtual), ...p }); }

// a tela velha ainda está montada e rolada: guarda onde ela estava
export function sairDaEntrada(y: number): void { lembrar({ y }); }

// a entrada nova é uma que já visitamos (Voltar/Avançar), e não uma tela aberta agora
export function ehRetorno(h: History = history): boolean {
  const id = h.state && typeof h.state === 'object' ? (h.state as { hs?: unknown }).hs : undefined;
  return typeof id === 'string' && mapa.has(id);
}

export function entrarNaEntrada(h: History = history): Lembranca | undefined {
  idAtual = idDaEntrada(h);
  return mapa.get(idAtual);
}

// rola até y assim que a página tiver altura para isso (as fileiras chegam depois); desiste em 1,5 s ou no primeiro
// toque, roda ou tecla da pessoa. setTimeout e não rAF: dentro de uma View Transition o navegador não pinta.
const EVENTOS = ['wheel', 'touchstart', 'pointerdown', 'keydown'];
let parar: (() => void) | null = null;
export const pararRestauro = (): void => { parar?.(); };
export function restaurarRolagem(y: number, doc: Document = document, limite = 1500): Promise<void> {
  parar?.();
  return new Promise(resolve => {
    const t0 = performance.now();
    let vivo = true;
    const fim = () => {
      if (!vivo) return;
      vivo = false; if (parar === fim) parar = null;
      for (const e of EVENTOS) removeEventListener(e, fim, true);
      resolve();
    };
    const tentar = () => {
      if (!vivo) return;
      const max = Math.max(0, doc.documentElement.scrollHeight - innerHeight);
      scrollTo(0, Math.min(y, max));
      if (max >= y || performance.now() - t0 > limite) fim(); else setTimeout(tentar, 16);
    };
    for (const e of EVENTOS) addEventListener(e, fim, { capture: true, passive: true });
    parar = fim;
    setTimeout(tentar); // depois do render da tela nova (o Preact pinta num microtask): a velha ainda pode ser alta
  });
}
