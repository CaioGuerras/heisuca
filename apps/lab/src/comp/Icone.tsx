// Material Symbols Rounded 300 (Apache-2.0). Só os listados entram na build; nome novo = acrescentar no glob.
const svgs = import.meta.glob('/node_modules/@material-symbols/svg-300/rounded/{home,explore,bookmark,bookmark-fill,search,light_mode,dark_mode,theaters,play_arrow-fill,info,add,check,close,chevron_left,chevron_right,share,keyboard_arrow_down,sort,keyboard,logout,arrow_back,star-fill,history,north_west,check_circle,check_circle-fill,visibility_off,movie,progress_activity,person,shuffle,replay,ios_share,search_off}.svg',
  { query: '?raw', import: 'default', eager: true }) as Record<string, string>;

export function Ic({ n, t = 22, classe = '' }: { n: string; t?: number; classe?: string }) {
  const svg = svgs[`/node_modules/@material-symbols/svg-300/rounded/${n}.svg`] || '';
  return <span class={`icone ${classe}`} aria-hidden="true" style={{ width: t, height: t }} dangerouslySetInnerHTML={{ __html: svg }} />;
}
