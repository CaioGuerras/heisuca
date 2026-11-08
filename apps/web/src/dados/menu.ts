// Menu do usuário (PLANO §9): a ordem dos itens e a navegação por teclado, sem DOM (testável no node).
// Ordem: cabeçalho Minha conta · Como usar (só enquanto houver passo sem marcar) · Tema · Baixar os apps · Sobre ·
// Apoiar o Heisuca · servidor (discreto, rodada 2 do Caio) · Sair. Grupos vazios somem (sem linha sobrando).
export type ItemMenu = 'ajuda' | 'tema' | 'apps' | 'sobre' | 'apoiar' | 'servidor' | 'sair';

export const gruposMenu = (ajudaCompleta: boolean): ItemMenu[][] =>
  ([ajudaCompleta ? [] : ['ajuda'], ['tema', 'apps', 'sobre'], ['apoiar'], ['servidor', 'sair']] as ItemMenu[][]).filter(g => g.length);

// setas, Home e End entre os itens focáveis do menu (circular nas setas); -1 = tecla que o menu não trata
export function proximoFoco(atual: number, total: number, tecla: string): number {
  if (total <= 0) return -1;
  if (tecla === 'Home') return 0;
  if (tecla === 'End') return total - 1;
  if (tecla === 'ArrowDown') return atual < 0 ? 0 : (atual + 1) % total;
  if (tecla === 'ArrowUp') return atual < 0 ? total - 1 : (atual - 1 + total) % total;
  return -1;
}
