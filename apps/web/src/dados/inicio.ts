// Tudo o que a home mostra, carregado com prioridade: a 2ª animação (transição) espera a fase crítica
// (Destaque, Continuar e Em alta com imagens decodificadas), e a home já nasce montada por baixo dela (PLANO §3.1 e §3.3).
// As fileiras inferiores (novidades por biblioteca e em breve) carregam em paralelo e enriquecem a página suavemente.
import { bibliotecasDeVideo, continuar, emAlta, emBreve, fundo, hashDe, logo, novidades, destaque as paraDestaque, pode, proximos, temArte,
  type EmBreve, type Item, type Sessao } from '../api/servidor.ts';
import { montarFileiras } from '../comp/fileiras-inicio.ts';

export type DadosCriticos = {
  destaque: Item[];
  retomar: Item[];
  proximos: Item[];
  continuar: Item[];
  emAlta: { titulo: string; itens: Item[] };
};

export type DadosSecundarios = {
  bibliotecas: Item[];
  porBiblioteca: { biblioteca: Item; itens: Item[] }[];
  emBreve: { tv: EmBreve[]; movie: EmBreve[] };
};

export type DadosInicio = DadosCriticos & DadosSecundarios;

const cacheCritico = new Map<string, Promise<DadosCriticos>>();
const cacheSecundario = new Map<string, Promise<DadosSecundarios>>();
const secundarioVazio = (): DadosSecundarios => ({ bibliotecas: [], porBiblioteca: [], emBreve: { tv: [], movie: [] } });

export function prepararInicio(s: Sessao, renovar = false): Promise<DadosInicio> {
  const chave = `${s.servidor}|${s.usuarioId}`;
  if (!renovar && cacheCritico.has(chave)) {
    // A Home reutiliza o crítico da transição sem esperar as fileiras secundárias.
    return cacheCritico.get(chave)!.then(c => ({ ...c, ...secundarioVazio() }));
  }

  // 1. Fase Crítica: Destaque, Continuar e Em Alta (resolve rápido)
  const pCritico = (async (): Promise<DadosCriticos> => {
    const [recentes, cont, prox, alta] = await Promise.all([
      paraDestaque(s).catch(() => []),
      continuar(s).catch(() => []),
      proximos(s).catch(() => []),
      // seções que o servidor não tem (Plex: em alta e em breve) nem são pedidas; vazias, o Início não as mostra
      (pode(s, 'emAlta') ? emAlta(s) : Promise.reject()).catch(() => ({ titulo: '', itens: [] as Item[] })),
    ]);

    const destaque = [...alta.itens.filter(i => temArte(s, i)), ...recentes]
      .filter((i, k, l) => l.findIndex(x => x.Id === i.Id) === k)
      .slice(0, 9);

    return { destaque, ...montarFileiras(cont, prox), emAlta: alta };
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
      pode(s, 'emBreve') ? emBreve(s, 'tv').catch(() => []) : [],
      pode(s, 'emBreve') ? emBreve(s, 'movie').catch(() => []) : [],
    ]);
    return { bibliotecas: libs, porBiblioteca, emBreve: { tv, movie } };
  })();

  cacheSecundario.set(chave, pSecundario);
  pSecundario.catch(() => cacheSecundario.delete(chave));

  // A transição espera apenas a fase crítica
  return pCritico.then(c => ({
    ...c,
    ...secundarioVazio(),
  }));
}

export function carregarSecundario(s: Sessao): Promise<DadosSecundarios> {
  const chave = `${s.servidor}|${s.usuarioId}`;
  return cacheSecundario.get(chave) ?? Promise.resolve(secundarioVazio());
}

// imagens que precisam estar decodificadas antes da home aparecer: o 1º destaque (fundo + logo) e o começo do Continuar
export async function decodificarPrimeiras(s: Sessao, d: DadosCriticos, largura = innerWidth): Promise<void> {
  const um = d.destaque[0];
  const urls = [um && fundo(s, um, Math.min(1920, Math.round(largura * devicePixelRatio))), um && logo(s, um, 600)].filter(Boolean) as string[];
  await Promise.all(urls.map(u => { const i = new Image(); i.src = u; return i.decode().catch(() => undefined); }));
}

export const hashDoDestaque = (s: Sessao, i?: Item | null) => hashDe(s, i, 'Backdrop') || hashDe(s, i, 'Primary');
