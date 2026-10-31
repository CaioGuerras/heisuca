// Temas do site (PLANO §2.1): Roxo = Shikkoku (cinza-lilás escuro, padrão; o nome interno "roxo" fica por compatibilidade), Verde = Hisui (claro), Automático = segue o aparelho
// (escuro → Roxo, claro → Verde), igual ao app CGFLIX. Kids e Shinju (iOS) não existem no site.
export type Escolha = 'roxo' | 'verde' | 'auto';
export type Tema = 'shikkoku' | 'hisui';

const CHAVE = 'heisuca.tema';
const escuroNoAparelho = () => !window.matchMedia || matchMedia('(prefers-color-scheme: dark)').matches;

export function escolhaAtual(): Escolha {
  let e = '';
  try { e = localStorage.getItem(CHAVE) || ''; } catch { /* modo privado */ }
  return e === 'verde' || e === 'auto' ? e : 'roxo';
}
const efetivo = (e: Escolha): Tema => e === 'verde' ? 'hisui' : e === 'roxo' ? 'shikkoku' : escuroNoAparelho() ? 'shikkoku' : 'hisui';
export const temaEfetivo = (): Tema => (document.documentElement.dataset.tema as Tema) || efetivo(escolhaAtual());

const ouvintes = new Set<() => void>();
export function aoMudarTema(f: () => void) { ouvintes.add(f); return () => { ouvintes.delete(f); }; }

function aplicar(e: Escolha) {
  const t = efetivo(e), d = document.documentElement;
  if (d.dataset.tema === t) return;
  d.dataset.tema = t;
  d.style.colorScheme = t === 'hisui' ? 'light' : 'dark';
  ouvintes.forEach(f => f());
}

export function escolherTema(e: Escolha) {
  try { localStorage.setItem(CHAVE, e); } catch { /* nada */ }
  aplicar(e);
}

// o index.html já pôs o data-tema antes do primeiro quadro; aqui só acompanhamos o aparelho no modo Automático
export function ligarTema() {
  aplicar(escolhaAtual());
  window.matchMedia?.('(prefers-color-scheme: dark)').addEventListener?.('change', () => { if (escolhaAtual() === 'auto') aplicar('auto'); });
}
