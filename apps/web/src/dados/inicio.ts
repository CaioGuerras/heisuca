// Tudo o que a home mostra, carregado de uma vez e guardado: a 2ª animação (transição) espera isto ficar pronto, e a
// home já nasce montada por baixo dela (PLANO §3.1 e §3.3). Ordem das fileiras: PLANO §4, com a rodada 2 do Caio (19/10
// noite): Continuar e Próximo viram uma fileira só, e a fileira "Mídia" sai (as bibliotecas estão na ilha e no "Ver tudo").
import { bibliotecasDeVideo, continuar, emAlta, emBreve, fundo, hashDe, logo, novidades, paraDestaque, proximos,
  type EmBreve, type Item, type Sessao } from '../api/jellyfin';

export type DadosInicio = {
  destaque: Item[]; continuar: Item[]; emAlta: { titulo: string; itens: Item[] };
  porBiblioteca: { biblioteca: Item; itens: Item[] }[]; emBreve: { tv: EmBreve[]; movie: EmBreve[] };
};

const cache = new Map<string, Promise<DadosInicio>>();

export function prepararInicio(s: Sessao, renovar = false): Promise<DadosInicio> {
  const chave = `${s.servidor}|${s.usuarioId}`;
  if (!renovar && cache.has(chave)) return cache.get(chave)!;
  const p = (async (): Promise<DadosInicio> => {
    const [recentes, cont, prox, alta, libs] = await Promise.all([
      paraDestaque(s).catch(() => []), continuar(s).catch(() => []), proximos(s).catch(() => []),
      emAlta(s).catch(() => ({ titulo: '', itens: [] as Item[] })), bibliotecasDeVideo(s).catch(() => []),
    ]);
    // destaque (PLANO §4, v1.2 [C]): primeiro os do Em alta que têm fundo e logo, completando com os últimos adicionados até 9
    const temArte = (i: Item) => !!(i.BackdropImageTags?.length && i.ImageTags?.Logo);
    const destaque = [...alta.itens.filter(temArte), ...recentes].filter((i, k, l) => l.findIndex(x => x.Id === i.Id) === k).slice(0, 9);
    // Continuar (Caio 19/10 noite): primeiro os em andamento (com tempo e barra), depois o próximo episódio das séries em
    // andamento, sem repetir série (nem filme)
    const vistas = new Set<string>();
    const continuarTudo = [...cont, ...prox].filter(i => { const k = i.SeriesId || i.Id; if (vistas.has(k)) return false; vistas.add(k); return true; });
    const porBiblioteca = (await Promise.all(libs.filter(b => b.CollectionType !== 'boxsets').map(b =>
      novidades(s, b.Id).then(itens => ({ biblioteca: b, itens })).catch(() => ({ biblioteca: b, itens: [] as Item[] })))))
      .filter(x => x.itens.length);
    const [tv, movie] = await Promise.all([emBreve(s, 'tv').catch(() => []), emBreve(s, 'movie').catch(() => [])]);
    return { destaque, continuar: continuarTudo, emAlta: alta, porBiblioteca, emBreve: { tv, movie } };
  })();
  cache.set(chave, p);
  p.catch(() => cache.delete(chave));
  return p;
}

// imagens que precisam estar decodificadas antes da home aparecer: o 1º destaque (fundo + logo) e o começo do Continuar
export async function decodificarPrimeiras(s: Sessao, d: DadosInicio, largura = innerWidth): Promise<void> {
  const um = d.destaque[0];
  const urls = [um && fundo(s, um, Math.min(1920, Math.round(largura * devicePixelRatio))), um && logo(s, um, 600)].filter(Boolean) as string[];
  await Promise.all(urls.map(u => { const i = new Image(); i.src = u; return i.decode().catch(() => undefined); }));
}

export const hashDoDestaque = (i?: Item | null) => hashDe(i, 'Backdrop') || hashDe(i, 'Primary');
