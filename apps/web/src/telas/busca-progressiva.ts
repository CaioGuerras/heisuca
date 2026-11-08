import type { Item, PaginaBusca } from '../api/servidor.ts';

export type Achado = Item & { biblioteca?: string; tipoLib?: string };
export type EstadoBusca = { itens: Achado[] | null; carregando: boolean; mais: boolean; erro: boolean };
export const buscaInicial: EstadoBusca = { itens: null, carregando: false, mais: true, erro: false };

// Uma instância por termo/sessão. Cursores contam os itens brutos de cada biblioteca, antes da deduplicação.
export function criarBusca(termo: string, bibliotecas: () => Promise<Item[]>,
  pagina: (b: Item, inicio: number, sinal: AbortSignal) => Promise<PaginaBusca>, publicar: (e: EstadoBusca) => void) {
  const controle = new AbortController(), saida: Achado[] = [], pos = new Map<string, number>();
  let cursores: { b: Item; inicio: number; mais: boolean }[] | undefined;
  let estado = { ...buscaInicial };
  const emitir = () => publicar({ ...estado, itens: estado.itens === null ? null : saida.slice() });
  const doTipo = (i: Achado) => (i.Type === 'Movie' ? 'movies' : 'tvshows') === i.tipoLib;
  async function carregar() {
    if (controle.signal.aborted || estado.carregando || !estado.mais) return;
    estado = { ...estado, carregando: true, erro: false }; emitir();
    try {
      if (!cursores) cursores = (await bibliotecas()).filter(b => b.CollectionType !== 'boxsets')
        .map(b => ({ b, inicio: 0, mais: true }));
      if (controle.signal.aborted) return;
      const pendentes = cursores.filter(c => c.mais);
      const paginas = await Promise.all(pendentes.map(c => pagina(c.b, c.inicio, controle.signal).catch(() => null)));
      if (controle.signal.aborted) return;
      const novos: Achado[] = [];
      paginas.forEach((d, n) => {
        if (!d) { estado.erro = true; return; }
        const c = pendentes[n];
        c.inicio += d.Items.length;
        c.mais = d.Items.length > 0 && c.inicio < d.TotalRecordCount;
        novos.push(...d.Items.map(i => ({ ...i, biblioteca: c.b.Name, tipoLib: c.b.CollectionType })));
      });
      // Ordena só o novo bloco: páginas posteriores não deslocam os títulos que já estão na tela.
      const t = termo.toLowerCase();
      novos.sort((a, b) => Number(!a.Name.toLowerCase().startsWith(t)) - Number(!b.Name.toLowerCase().startsWith(t)));
      for (const i of novos) {
        const n = pos.get(i.Id);
        if (n === undefined) { pos.set(i.Id, saida.length); saida.push(i); }
        else if (!doTipo(saida[n]) && doTipo(i)) saida[n] = i;
      }
    } catch { estado.erro = true; }
    finally {
      if (!controle.signal.aborted) {
        estado = { ...estado, itens: saida, carregando: false, mais: cursores ? cursores.some(c => c.mais) : true };
        emitir();
      }
    }
  }
  return { carregar, cancelar: () => controle.abort() };
}
