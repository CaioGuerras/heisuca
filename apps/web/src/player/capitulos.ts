// Pular abertura / Pular créditos pelos CAPÍTULOS do item (PLANO §13): nunca um salto fixo. Onde não há capítulo com
// nome reconhecido, não há botão. Função pura (sem DOM nem API) para o teste em testes/capitulos.test.ts.
export type Trecho = 'abertura' | 'creditos';
export type CapituloBruto = { Name?: string | null; StartPositionTicks: number };
// para onde o botão leva: um ponto do vídeo (início do capítulo seguinte), o próximo episódio ou o fim (filme: encerra e
// volta ao título; Caio 19/10 noite, dúvida 20)
export type Pulo = { tipo: Trecho; ate: number } | { tipo: Trecho; ate: 'proximo' | 'fim' };

const TICKS = 10_000_000;

// nomes contados no acervo (PLANO §13), comparados sem maiúsculas, sem acento e sem número no fim ("OP 1", "ED2", "Opening 01")
const ABERTURA = new Set(['intro', 'opening', 'op', 'opening credits', 'title sequence', 'abertura']);
const CREDITOS = new Set(['credits', 'end credits', 'ed', 'ending', 'encerramento', 'creditos', 'creditos finais', 'credito']);

export function tipoDoCapitulo(nome?: string | null): Trecho | null {
  if (!nome) return null;
  const n = nome.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
    .replace(/[\s._-]+/g, ' ').trim()
    .replace(/\s*#?\d+$/, '').trim();
  if (ABERTURA.has(n)) return 'abertura';
  if (CREDITOS.has(n)) return 'creditos';
  return null;
}

/**
 * O que pular agora, ou null.
 * @param capitulos  `item.Chapters` (em ticks), em qualquer ordem
 * @param seg        posição atual em segundos
 * @param temProximo série com episódio seguinte: créditos no último capítulo levam a ele
 * @param filme      filme: créditos no último capítulo encerram (o player volta ao título)
 */
export function puloEm(capitulos: CapituloBruto[] | undefined, seg: number, temProximo: boolean, filme = false): Pulo | null {
  if (!capitulos?.length || !Number.isFinite(seg)) return null;
  const c = [...capitulos].sort((a, b) => a.StartPositionTicks - b.StartPositionTicks);
  // capítulo em que estamos: o último que já começou
  let i = -1;
  for (let n = 0; n < c.length; n++) if (c[n].StartPositionTicks / TICKS <= seg) i = n;
  if (i < 0) return null;
  const tipo = tipoDoCapitulo(c[i].Name);
  if (!tipo) return null;
  const seguinte = c[i + 1];
  if (seguinte) return { tipo, ate: seguinte.StartPositionTicks / TICKS };
  // último capítulo: os créditos de um episódio com sucessor levam a ele; os de um filme encerram
  if (tipo !== 'creditos') return null;
  return temProximo ? { tipo, ate: 'proximo' } : filme ? { tipo, ate: 'fim' } : null;
}

export const textoDoPulo = (t: Trecho) => (t === 'abertura' ? 'Pular abertura' : 'Pular créditos');
