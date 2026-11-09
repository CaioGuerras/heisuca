// H1 (ESTUDO_MOVIMENTO_2026-11 §3): o cartão clicado entrega ao título o que já sabe (nome, artes, hash da cor).
// O título abre pintado com isso enquanto o item completo chega. Só memória; as últimas 40 bastam.
import type { Item } from '../api/tipos';

const guardadas = new Map<string, Item>();
export function guardarPrevia(i: Item): void {
  guardadas.delete(i.Id);
  guardadas.set(i.Id, i);
  if (guardadas.size > 40) { const velha = guardadas.keys().next().value; if (velha !== undefined) guardadas.delete(velha); }
}
export const previa = (id: string): Item | null => guardadas.get(id) || null;
