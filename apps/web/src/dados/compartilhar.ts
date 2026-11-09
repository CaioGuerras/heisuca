type Compartilhador = { share?: (dados: { title: string; url: string }) => Promise<void>; clipboard?: { writeText: (texto: string) => Promise<void> } };
export async function compartilharTitulo(nav: Compartilhador, titulo: string, url: string) {
  if (nav.share) {
    try { await nav.share({ title: titulo, url }); return 'compartilhado'; }
    catch (erro) { if ((erro as { name?: string })?.name === 'AbortError') return 'cancelado'; }
  }
  if (!nav.clipboard) throw new Error('Cópia indisponível');
  await nav.clipboard.writeText(url); return 'copiado';
}
export function trailerRemoto(url?: string): string | null {
  try { const u = new URL(url || ''); return ['https:', 'http:'].includes(u.protocol) ? u.href : null; } catch { return null; }
}
