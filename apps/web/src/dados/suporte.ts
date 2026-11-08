// PLANO §3.4, navegador de TV: o teste é POR RECURSO (o que o navegador realmente faz), nunca pelo nome do aparelho.
// TV moderna com tudo isto: o site normal, com ponteiro. Faltando algo: a tela limpa "O Heisuca na TV é pelo app".
// Sem DOM: recebe o ambiente (window no site, objeto falso nos testes).
// O index.html já barra quem nem roda o pacote (sem módulos ES ou sem aspect-ratio = antes do Chrome 88); este teste é a
// 2ª barreira, dentro do app, para o que o pacote usa e um navegador capado pode não ter.
type Supports = (propriedade: string, valor: string) => boolean;
export type Ambiente = {
  fetch?: unknown; Promise?: unknown; IntersectionObserver?: unknown; ResizeObserver?: unknown; AbortController?: unknown;
  URLSearchParams?: unknown; requestAnimationFrame?: unknown; matchMedia?: unknown; CSS?: { supports?: unknown };
};

const FUNCOES = ['fetch', 'Promise', 'IntersectionObserver', 'ResizeObserver', 'AbortController', 'URLSearchParams',
  'requestAnimationFrame', 'matchMedia'] as const;
// [nome, propriedade, valor]: variáveis de CSS (os temas inteiros dependem delas), grade, proporção e transformações
const CSS_NECESSARIO: [string, string, string][] = [
  ['CSS custom properties', '--hs-teste', '0'], ['CSS grid', 'display', 'grid'], ['aspect-ratio', 'aspect-ratio', '1 / 1'],
  ['transform', 'transform', 'scale(1)'],
];

export function recursosFaltando(w: Ambiente): string[] {
  const falta: string[] = FUNCOES.filter(f => typeof w[f] !== 'function');
  const css = w.CSS, sup = css && typeof css.supports === 'function' ? css.supports as Supports : null;
  for (const [nome, prop, valor] of CSS_NECESSARIO) {
    let ok = false;
    try { ok = !!sup && sup.call(css, prop, valor) === true; } catch { ok = false; }
    if (!ok) falta.push(nome);
  }
  return falta;
}
