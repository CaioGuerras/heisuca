const CHAVE = 'heisuca.buscas';
const limparTexto = (t: string) => t.trim().slice(0, 200);
export function lerBuscas(): string[] {
  try {
    const valor: unknown = JSON.parse(localStorage.getItem(CHAVE) || '[]');
    if (!Array.isArray(valor)) return [];
    const vistas = new Set<string>();
    return valor.filter((t): t is string => typeof t === 'string').map(limparTexto).filter(t => {
      const chave = t.toLocaleLowerCase('pt-BR');
      if (!t || vistas.has(chave)) return false;
      vistas.add(chave); return true;
    }).slice(0, 8);
  } catch { return []; }
}
function salvar(textos: string[]) { try { localStorage.setItem(CHAVE, JSON.stringify(textos)); } catch { /* armazenamento opcional */ } }
export function registrarBusca(texto: string) {
  const t = limparTexto(texto);
  if (t) salvar([t, ...lerBuscas().filter(x => x.toLocaleLowerCase('pt-BR') !== t.toLocaleLowerCase('pt-BR'))].slice(0, 8));
}
export function removerBusca(texto: string) { salvar(lerBuscas().filter(t => t !== texto)); }
export function limparBuscas() { try { localStorage.removeItem(CHAVE); } catch { /* armazenamento opcional */ } }
