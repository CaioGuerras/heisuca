// Tudo o que a home mostra, carregado com prioridade: a 2ª animação (transição) espera a fase crítica
// (Destaque, Continuar e Em alta com imagens decodificadas), e a home já nasce montada por baixo dela (PLANO §3.1 e §3.3).
// As fileiras inferiores (novidades por biblioteca e em breve) carregam em paralelo e enriquecem a página suavemente.
import { bibliotecasDeVideo, continuar, emAlta, emBreve, fundo, hashDe, logo, novidades, paraDestaque, proximos,
  type EmBreve, type Item, type Sessao } from '../api/jellyfin';

export type DadosCriticos = {
  destaque: Item[];
  continuar: Item[];
  emAlta: { titulo: string; itens: Item[] };
};

export type DadosSecundarios = {
  porBiblioteca: { biblioteca: Item; itens: Item[] }[];
  emBreve: { tv: EmBreve[]; movie: EmBreve[] };
};

export type DadosInicio = DadosCriticos & DadosSecundarios;

const cacheCritico = new Map<string, Promise<DadosCriticos>>();
const cacheSecundario = new Map<string, Promise<DadosSecundarios>>();

export function prepararInicio(s: Sessao, renovar = false): Promise<DadosInicio> {
  const chave = `${s.servidor}|${s.usuarioId}`;
  if (!renovar && cacheCritico.has(chave)) {
    const pCritico = cacheCritico.get(chave)!;
    const pSec = cacheSecundario.get(chave);
    if (pSec) {
      return Promise.all([pCritico, pSec.catch(() => ({ porBiblioteca: [], emBreve: { tv: [], movie: [] } }))])
        .then(([c, sec]) => ({ ...c, ...sec }));
    }
    return pCritico.then(c => ({ ...c, porBiblioteca: [], emBreve: { tv: [], movie: [] } }));
  }

  // 1. Fase Crítica: Destaque, Continuar e Em Alta (resolve rápido)
  const pCritico = (async (): Promise<DadosCriticos> => {
    const [recentes, cont, prox, alta] = await Promise.all([
      paraDestaque(s).catch(() => []),
      continuar(s).catch(() => []),
      proximos(s).catch(() => []),
      emAlta(s).catch(() => ({ titulo: '', itens: [] as Item[] })),
    ]);

    const temArte = (i: Item) => !!(i.BackdropImageTags?.length && i.ImageTags?.Logo);
    const destaque = [...alta.itens.filter(temArte), ...recentes]
      .filter((i, k, l) => l.findIndex(x => x.Id === i.Id) === k)
      .slice(0, 9);

    const vistas = new Set<string>();
    const continuarTudo = [...cont, ...prox].filter(i => {
      const k = i.SeriesId || i.Id;
      if (vistas.has(k)) return false;
      vistas.add(k);
      return true;
    });

    return { destaque, continuar: continuarTudo, emAlta: alta };
  })();

  cacheCritico.set(chave, pCritico);
  pCritico.catch(() => cacheCritico.delete(chave));

  // 2. Fase Secundária: Novidades por biblioteca e Em Breve em paralelo no fundo
  const pSecundario = (async (): Promise<DadosSecundarios> => {
    const libs = await bibliotecasDeVideo(s).catch(() => []);
    const [porBiblioteca, tv, movie] = await Promise.all([
      Promise.all(libs.filter(b => b.CollectionType !== 'boxsets').map(b =>
        novidades(s, b.Id).then(itens => ({ biblioteca: b, itens })).catch(() => ({ biblioteca: b, itens: [] as Item[] }))
      )).then(res => res.filter(x => x.itens.length)),
      emBreve(s, 'tv').catch(() => []),
      emBreve(s, 'movie').catch(() => []),
    ]);
    return { porBiblioteca, emBreve: { tv, movie } };
  })();

  cacheSecundario.set(chave, pSecundario);
  pSecundario.catch(() => cacheSecundario.delete(chave));

  // A transição espera apenas a fase crítica
  return pCritico.then(c => ({
    ...c,
    porBiblioteca: [],
    emBreve: { tv: [], movie: [] },
  }));
}

export function carregarSecundario(s: Sessao): Promise<DadosSecundarios> {
  const chave = `${s.servidor}|${s.usuarioId}`;
  return cacheSecundario.get(chave) ?? Promise.resolve({ porBiblioteca: [], emBreve: { tv: [], movie: [] } });
}

// imagens que precisam estar decodificadas antes da home aparecer: o 1º destaque (fundo + logo) e o começo do Continuar
export async function decodificarPrimeiras(s: Sessao, d: DadosCriticos, largura = innerWidth): Promise<void> {
  const um = d.destaque[0];
  const urls = [um && fundo(s, um, Math.min(1920, Math.round(largura * devicePixelRatio))), um && logo(s, um, 600)].filter(Boolean) as string[];
  await Promise.all(urls.map(u => { const i = new Image(); i.src = u; return i.decode().catch(() => undefined); }));
}

export const hashDoDestaque = (i?: Item | null) => hashDe(i, 'Backdrop') || hashDe(i, 'Primary');
