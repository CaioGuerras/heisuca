import type { Item } from '../api/servidor.ts';

// Conserva a origem para as duas fileiras e a lista unificada usada pelo pré-carregamento.
export function montarFileiras(retomar: Item[], proximos: Item[]) {
  const vistas = new Set<string>();
  const continuar = [...retomar, ...proximos].filter(i => {
    const chave = i.SeriesId || i.Id;
    if (vistas.has(chave)) return false;
    vistas.add(chave);
    return true;
  });
  return { retomar, proximos: filtrarProximos(retomar, proximos), continuar };
}

// A origem vem das listas da API: não inferir Próximo pela ausência de posição salva.
export function filtrarProximos(continuar: Item[], proximos: Item[]): Item[] {
  const ids = new Set(continuar.map(i => i.Id));
  const series = new Set(continuar.map(i => i.SeriesId || (i.Type === 'Series' ? i.Id : '')).filter(Boolean));
  return proximos.filter(i => {
    const serie = i.SeriesId || (i.Type === 'Series' ? i.Id : '');
    if (ids.has(i.Id) || (serie && series.has(serie))) return false;
    ids.add(i.Id);
    if (serie) series.add(serie);
    return true;
  });
}
