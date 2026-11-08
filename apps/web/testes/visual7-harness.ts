import { readFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { runInNewContext } from 'node:vm';
import ts from 'typescript';

// Executa componentes reais com portas em memória, sem DOM, rede ou threads de navegador.
export function bancada(arquivo: string, expor: string, portas: Record<string, any> = {}, globais = {},
  prepararFonte = (fonte: string) => fonte) {
  const nativo = createRequire(import.meta.url), valores: any[] = [], dependencias: any[][] = [];
  const limpezas: (() => void)[] = [], pendentes: (() => void)[] = [];
  let indice = 0;
  const hooks = {
    useState(inicial: any) {
      const k = indice++;
      if (!(k in valores)) valores[k] = typeof inicial === 'function' ? inicial() : inicial;
      return [valores[k], (v: any) => { valores[k] = typeof v === 'function' ? v(valores[k]) : v; }];
    },
    useRef(inicial: any) {
      const k = indice++;
      return valores[k] || (valores[k] = { current: inicial });
    },
    useMemo(f: () => any) { return f(); },
    useEffect(f: () => any, deps: any[]) {
      const k = indice++;
      if (!dependencias[k] || deps.some((v, n) => !Object.is(v, dependencias[k][n]))) {
        dependencias[k] = deps;
        pendentes.push(() => { limpezas[k]?.(); limpezas[k] = f(); });
      }
    },
    useLayoutEffect() {},
  };
  const m = { exports: {} as Record<string, any> };
  const js = ts.transpileModule(prepararFonte(readFileSync(new URL(arquivo, import.meta.url), 'utf8')) + `\nexport { ${expor} };`, {
    compilerOptions: { module: ts.ModuleKind.CommonJS, target: ts.ScriptTarget.ES2022,
      jsx: ts.JsxEmit.ReactJSX, jsxImportSource: 'preact' },
  }).outputText;
  runInNewContext(js, { module: m, exports: m.exports, Intl, ...globais, require: (nome: string) => {
    if (nome === 'preact/jsx-runtime') return nativo(nome);
    if (nome === 'preact/hooks') return hooks;
    return portas[nome] || {};
  } });
  return {
    render(nome: string, props: any) { indice = 0; return m.exports[nome](props); },
    efeitos() { for (const f of pendentes.splice(0)) f(); },
    desmontar() { for (const f of limpezas) f?.(); },
  };
}

export function nos(v: any, tipo?: any): any[] {
  if (!v || typeof v !== 'object') return [];
  if (Array.isArray(v)) return v.flatMap(x => nos(x, tipo));
  return [...(v.type && (!tipo || v.type === tipo) ? [v] : []), ...nos(v.props?.children, tipo)];
}
export function texto(v: any): string {
  if (v === null || v === undefined || typeof v === 'boolean') return '';
  if (typeof v !== 'object') return String(v);
  return Array.isArray(v) ? v.map(texto).join('') : texto(v.props?.children);
}
export async function resolver() { for (let n = 0; n < 20; n++) await Promise.resolve(); }
