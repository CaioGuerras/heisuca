// Seerr (pedidos) na mesma origem do Jellyfin (/__seerr/). Login automático por Quick Connect, como no site atual
// (cgflix-nav.js): o Seerr gera o código, esta aba o autoriza no Jellyfin com o login da própria pessoa e o Seerr conclui.
// Sem segunda senha e sem o token do Jellyfin sair daqui. Dado do Seerr só vira texto (o JSX escapa), nunca HTML.
import { autorizarQuickConnect, type Sessao } from './jellyfin';

export type Resultado = {
  id: number; mediaType: 'movie' | 'tv' | 'person'; title?: string; name?: string; posterPath?: string;
  releaseDate?: string; firstAirDate?: string; overview?: string; mediaInfo?: { status?: number; jellyfinMediaId?: string };
};
export type Temporada = { seasonNumber: number; name?: string; episodeCount?: number };
export type Pedido = {
  id: number; status: number; createdAt: string; type: 'movie' | 'tv'; seasons?: { seasonNumber: number }[];
  media: { tmdbId: number; status: number; mediaType: 'movie' | 'tv'; jellyfinMediaId?: string };
};

// mediaInfo.status: 1 desconhecido, 2 pedido, 3 baixando, 4 parcial, 5 disponível
export const SELO: Record<number, string> = { 2: 'Pedido', 3: 'Baixando', 4: 'Em parte', 5: 'Disponível' };
const POSTER = /^\/[A-Za-z0-9_-]+\.(jpg|jpeg|png|webp)$/;
export const poster = (s: Sessao, p?: string) => p && POSTER.test(p) ? `${s.servidor}/__seerr/imageproxy/tmdb/t/p/w300_and_h450_face${p}` : '';

class Erro extends Error { status: number; constructor(status: number) { super(`seerr ${status}`); this.status = status; } }
const api = (s: Sessao) => `${s.servidor}/__seerr/api/v1`;

// O servidor tem Seerr? Convenção: o Seerr publicado na mesma origem, em /__seerr/ (como no CGSERVER). Sem isso, a busca
// fica só no acervo e "Meus pedidos" some (PLANO §8). Uma consulta por servidor.
const comSeerr = new Map<string, Promise<boolean>>();
export function temSeerr(s: Sessao): Promise<boolean> {
  let p = comSeerr.get(s.servidor);
  if (!p) {
    p = fetch(`${api(s)}/status`, { credentials: 'omit' }).then(r => r.ok ? r.json() : null)
      .then((d: { version?: string } | null) => !!d?.version).catch(() => false);
    comSeerr.set(s.servidor, p);
  }
  return p;
}
async function req<T>(s: Sessao, caminho: string, metodo = 'GET', corpo?: unknown): Promise<T> {
  const r = await fetch(api(s) + caminho, {
    method: metodo, credentials: 'include',
    headers: { Accept: 'application/json', ...(corpo ? { 'Content-Type': 'application/json' } : {}) },
    body: corpo ? JSON.stringify(corpo) : undefined,
  });
  if (!r.ok) throw new Erro(r.status);
  return (r.status === 204 ? null : await r.json()) as T;
}

const semTraco = (x: string) => x.replace(/-/g, '').toLowerCase();
let sessao: Promise<{ id: number }> | null = null, dono = '';
async function entrar(s: Sessao) {
  const qc = await req<{ code: string; secret: string }>(s, '/auth/jellyfin/quickconnect/initiate', 'POST');
  if (!/^[0-9]{4,8}$/.test(String(qc.code)) || !qc.secret) throw new Error('quickconnect');
  await autorizarQuickConnect(s, String(qc.code));
  await req(s, '/auth/jellyfin/quickconnect/authenticate', 'POST', { secret: qc.secret });
  return req<{ id: number }>(s, '/auth/me');
}
function usuario(s: Sessao) {
  if (sessao && dono === s.usuarioId) return sessao;
  dono = s.usuarioId;
  sessao = req<{ id: number; jellyfinUserId?: string }>(s, '/auth/me').then(async u => {
    // mesmo navegador, outra conta do Jellyfin: sai do Seerr e entra de novo
    if (u.jellyfinUserId && semTraco(u.jellyfinUserId) !== semTraco(s.usuarioId)) { await req(s, '/auth/logout', 'POST').catch(() => null); return entrar(s); }
    return u;
  }, e => { if (e instanceof Erro && (e.status === 401 || e.status === 403)) return entrar(s); throw e; });
  sessao.catch(() => { sessao = null; });
  return sessao;
}
async function seerr<T>(s: Sessao, caminho: string, metodo = 'GET', corpo?: unknown): Promise<T> {
  await usuario(s);
  try { return await req<T>(s, caminho, metodo, corpo); }
  catch (e) {
    if (!(e instanceof Erro) || e.status !== 401) throw e;
    sessao = null; await usuario(s);  // sessão do Seerr venceu: entra de novo uma vez
    return req<T>(s, caminho, metodo, corpo);
  }
}
export const sairDoSeerr = (s: Sessao) => req(s, '/auth/logout', 'POST').catch(() => null).then(() => { sessao = null; });

const q = (x: string) => encodeURIComponent(x).replace(/[!'()*]/g, c => '%' + c.charCodeAt(0).toString(16).toUpperCase());
// regras da busca (app/ORDEM_1E_APP.md): 4/5 já aparecem como nossos; 2/3 com selo; pessoas fora
export const buscar = (s: Sessao, termo: string) =>
  seerr<{ results: Resultado[] }>(s, `/search?query=${q(termo)}&page=1&language=pt-BR`)
    .then(d => d.results.filter(r => (r.mediaType === 'movie' || r.mediaType === 'tv') && r.mediaInfo?.status !== 4 && r.mediaInfo?.status !== 5));

export const detalhe = (s: Sessao, tipo: 'movie' | 'tv', id: number) =>
  seerr<Resultado & { seasons?: Temporada[]; mediaInfo?: { status?: number; seasons?: { seasonNumber: number; status: number }[];
    requests?: { status: number; seasons?: { seasonNumber: number }[] }[] } }>(s, `/${tipo}/${id}?language=pt-BR`);

export const pedir = (s: Sessao, tipo: 'movie' | 'tv', id: number, temporadas?: number[]) =>
  seerr(s, '/request', 'POST', { mediaType: tipo, mediaId: id, is4k: false, ...(tipo === 'tv' ? { seasons: temporadas } : {}) });

export async function meusPedidos(s: Sessao): Promise<Pedido[]> {
  const u = await usuario(s);
  return seerr<{ results: Pedido[] }>(s, `/request?take=50&skip=0&sort=added&requestedBy=${u.id}`).then(d => d.results);
}

export const mensagemDeErro = (e: unknown) => e instanceof Erro && e.status === 403 ? 'Sua conta não pode fazer pedidos. Fale com quem administra o servidor.'
  : e instanceof Erro && e.status === 409 ? 'Isso já foi pedido.' : 'Não deu para pedir agora. Tente de novo.';
