export type OrdemBiblioteca = { ordem: string; naoVistos: boolean };
export const ORDENS = [
  { valor: 'nome', nome: 'A–Z', jellyfin: 'SortName', plex: 'titleSort' },
  { valor: 'adicionados', nome: 'Adicionados recentemente', jellyfin: 'DateCreated', plex: 'addedAt:desc' },
  { valor: 'lancamento', nome: 'Lançamento', jellyfin: 'PremiereDate', plex: 'originallyAvailableAt:desc' },
  { valor: 'nota', nome: 'Nota', jellyfin: 'CommunityRating', plex: 'rating:desc' },
] as const;
export const ordemValida = (valor?: string) => ORDENS.find(o => o.valor === valor) || ORDENS[0];
export function lerOrdem(chave: string): OrdemBiblioteca {
  try {
    const d = JSON.parse(localStorage.getItem(`heisuca.ordem.${chave}`) || '{}');
    return { ordem: ordemValida(d?.ordem).valor, naoVistos: d?.naoVistos === true };
  } catch { return { ordem: 'nome', naoVistos: false }; }
}
export function guardarOrdem(chave: string, valor: OrdemBiblioteca) {
  try { localStorage.setItem(`heisuca.ordem.${chave}`, JSON.stringify(valor)); } catch { /* armazenamento opcional */ }
}
