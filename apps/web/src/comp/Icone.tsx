// Material Symbols Rounded, peso 300 (adulto); "cheio" para o item selecionado (BASE_MARCA §5).
const svgs = import.meta.glob('/node_modules/@material-symbols/svg-300/rounded/{home,search,logout,play_arrow,movie,tv,settings,arrow_back}{,-fill}.svg',
  { query: '?raw', import: 'default', eager: true }) as Record<string, string>;

export function Icone({ nome, cheio = false, tamanho = 24 }: { nome: string; cheio?: boolean; tamanho?: number }) {
  const svg = svgs[`/node_modules/@material-symbols/svg-300/rounded/${nome}${cheio ? '-fill' : ''}.svg`] || '';
  return <span class="icone" aria-hidden="true" style={{ width: tamanho, height: tamanho }} dangerouslySetInnerHTML={{ __html: svg }} />;
}
