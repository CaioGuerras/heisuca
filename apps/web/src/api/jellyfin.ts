// Cliente Jellyfin mínimo, escrito do zero (só fetch). Cada função é um endpoint da API REST oficial.
const VERSAO = '0.1.0';
const CHAVE = 'heisuca.sessao';

export type Sessao = { servidor: string; token: string; usuarioId: string; nome: string };
export type Item = {
  Id: string; Name: string; Type: string; SeriesName?: string; SeriesId?: string; ProductionYear?: number;
  Overview?: string; ImageTags?: Record<string, string>; BackdropImageTags?: string[];
  ParentBackdropItemId?: string; ParentBackdropImageTags?: string[]; SeriesPrimaryImageTag?: string;
  IndexNumber?: number; ParentIndexNumber?: number; CollectionType?: string;
  UserData?: { PlayedPercentage?: number; Played?: boolean };
};

function idAparelho(): string {
  let id = localStorage.getItem('heisuca.aparelho');
  if (!id) { id = Math.random().toString(36).slice(2) + Date.now().toString(36); localStorage.setItem('heisuca.aparelho', id); }
  return id;
}

function cabecalho(token?: string): string {
  const p = [`Client="Heisuca"`, `Device="Navegador"`, `DeviceId="${idAparelho()}"`, `Version="${VERSAO}"`];
  if (token) p.push(`Token="${token}"`);
  return 'MediaBrowser ' + p.join(', ');
}

export function servidorPadrao(): string {
  return (import.meta.env.VITE_SERVIDOR as string | undefined) || location.origin;
}

export function sessaoSalva(): Sessao | null {
  try { return JSON.parse(localStorage.getItem(CHAVE) || 'null'); } catch { return null; }
}

export function sair(): void { localStorage.removeItem(CHAVE); }

export async function entrar(servidor: string, usuario: string, senha: string): Promise<Sessao> {
  const r = await fetch(servidor + '/Users/AuthenticateByName', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: cabecalho() },
    body: JSON.stringify({ Username: usuario, Pw: senha }),
  });
  if (r.status === 401) throw new Error('Usuário ou senha incorretos.');
  if (!r.ok) throw new Error(`O servidor respondeu ${r.status}.`);
  const d = await r.json();
  const s: Sessao = { servidor, token: d.AccessToken, usuarioId: d.User.Id, nome: d.User.Name };
  localStorage.setItem(CHAVE, JSON.stringify(s));
  return s;
}

async function obter<T>(s: Sessao, caminho: string): Promise<T> {
  const r = await fetch(s.servidor + caminho, { headers: { Authorization: cabecalho(s.token) } });
  if (r.status === 401) { sair(); location.reload(); }
  if (!r.ok) throw new Error(`${caminho}: ${r.status}`);
  return r.json();
}

const CAMPOS = 'fields=Overview,PrimaryImageAspectRatio&enableImageTypes=Primary,Backdrop,Thumb';

export const bibliotecas = (s: Sessao) =>
  obter<{ Items: Item[] }>(s, `/UserViews?userId=${s.usuarioId}`).then(d => d.Items);

export const continuar = (s: Sessao) =>
  obter<{ Items: Item[] }>(s, `/UserItems/Resume?userId=${s.usuarioId}&limit=16&mediaTypes=Video&${CAMPOS}`)
    .then(d => d.Items);

export const novidades = (s: Sessao, bibliotecaId: string) =>
  obter<Item[]>(s, `/Items/Latest?userId=${s.usuarioId}&parentId=${bibliotecaId}&limit=20&${CAMPOS}`);

export function capa(s: Sessao, i: Item, altura = 360): string {
  if (i.ImageTags?.Primary) return `${s.servidor}/Items/${i.Id}/Images/Primary?fillHeight=${altura}&quality=90&tag=${i.ImageTags.Primary}`;
  if (i.SeriesId && i.SeriesPrimaryImageTag) return `${s.servidor}/Items/${i.SeriesId}/Images/Primary?fillHeight=${altura}&quality=90&tag=${i.SeriesPrimaryImageTag}`;
  return '';
}

export function fundo(s: Sessao, i: Item, largura = 1920): string {
  if (i.BackdropImageTags?.length) return `${s.servidor}/Items/${i.Id}/Images/Backdrop/0?fillWidth=${largura}&quality=80&tag=${i.BackdropImageTags[0]}`;
  if (i.ParentBackdropItemId && i.ParentBackdropImageTags?.length)
    return `${s.servidor}/Items/${i.ParentBackdropItemId}/Images/Backdrop/0?fillWidth=${largura}&quality=80&tag=${i.ParentBackdropImageTags[0]}`;
  return '';
}
