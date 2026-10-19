// Material Symbols Rounded, peso 300 (BASE_MARCA §5; Apache-2.0); "cheio" para o item selecionado.
// Só os ícones listados entram na build (glob abaixo); nome novo = acrescentar aqui.
const svgs = import.meta.glob('/node_modules/@material-symbols/svg-300/rounded/{home,video_library,favorite,search,arrow_back,chevron_right,chevron_left,keyboard_arrow_down,close,check,check_circle,flag,play_arrow,pause,replay_10,forward_10,skip_next,skip_previous,subtitles,fullscreen,fullscreen_exit,add,info,person,logout,palette,help,download,volunteer_activism,visibility,visibility_off,photo_camera,delete,mobile_lock_portrait,dns,star,schedule,playlist_add_check,menu,movie,tv,collections_bookmark,account_circle,swap_horiz,more_horiz,progress_activity,search_off,cloud_off,videocam,music_note,android,mobile,desktop_windows,install_desktop,connected_tv,ios_share,more_vert,code,open_in_new,notifications,volume_up,volume_down,volume_off}{,-fill}.svg',
  { query: '?raw', import: 'default', eager: true }) as Record<string, string>;

export function Icone({ nome, cheio = false, tamanho = 24, classe = '' }: { nome: string; cheio?: boolean; tamanho?: number; classe?: string }) {
  const svg = svgs[`/node_modules/@material-symbols/svg-300/rounded/${nome}${cheio ? '-fill' : ''}.svg`] || '';
  return <span class={`icone ${classe}`} aria-hidden="true" style={{ width: tamanho, height: tamanho }} dangerouslySetInnerHTML={{ __html: svg }} />;
}
