import type { Item } from '../api/servidor.ts';

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
