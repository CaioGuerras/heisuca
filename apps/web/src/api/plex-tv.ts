// Plex web: identidade na query para evitar preflight; nenhum token é guardado aqui.
import { idAparelho, VERSAO } from './contas.ts';

export type QueryPlex = Record<string, string | number | boolean | undefined>;
export class ErroPlex extends Error {
  status: number;
  constructor(status: number) { super(`Plex: ${status}`); this.status = status; }
}
export function urlPlex(base: string, caminho: string, token?: string, query: QueryPlex = {}): string {
  const u = new URL(caminho, base.replace(/\/$/, '') + '/');
  // Não enviar a credencial a uma origem que apareceu num caminho de mídia/metadados.
  if (u.protocol !== 'https:' || u.origin !== new URL(base).origin) throw new Error('Endereço Plex incompatível.');
  const identidade = { 'X-Plex-Client-Identifier': idAparelho(), 'X-Plex-Product': 'Heisuca',
    'X-Plex-Version': VERSAO, 'X-Plex-Platform': 'Web', 'X-Plex-Device': 'Navegador', 'X-Plex-Token': token };
  for (const [k, v] of Object.entries({ ...query, ...identidade })) if (v !== undefined) u.searchParams.set(k, String(v));
  return u.href;
}
export async function respostaPlex(url: string, metodo = 'GET', sinal?: AbortSignal, keepalive = false): Promise<Response> {
  const r = await fetch(url, { method: metodo, headers: { Accept: 'application/json' }, signal: sinal, keepalive });
  if (!r.ok) throw new ErroPlex(r.status);
  return r;
}
const tv = async <T,>(caminho: string, token?: string, query?: QueryPlex, metodo?: string, sinal?: AbortSignal): Promise<T> =>
  (await respostaPlex(urlPlex('https://plex.tv', '/api/v2' + caminho, token, query), metodo, sinal)).json();

export class PinVencido extends Error { constructor() { super('O código Plex venceu. Peça outro.'); } }
export type PinPlex = { id: number; code: string };
export type ContaPlex = { id: string; nome: string; login?: string; foto?: string };
export type ConexaoPlex = { uri: string; local?: boolean; relay?: boolean };
export type RecursoPlex = { name: string; clientIdentifier: string; accessToken: string;
  publicAddressMatches?: boolean; connections: ConexaoPlex[] };
export const criarPin = () => tv<PinPlex>('/pins', undefined, { strong: true }, 'POST');
export function urlAutorizar(pin: PinPlex): string {
  const q = new URLSearchParams({ clientID: idAparelho(), code: pin.code, 'context[device][product]': 'Heisuca' });
  return 'https://app.plex.tv/auth#?' + q.toString();
}
function cancelado(sinal: AbortSignal) { if (sinal.aborted) throw new DOMException('Entrada cancelada.', 'AbortError'); }
function esperar(ms: number, sinal: AbortSignal): Promise<void> {
  return new Promise((ok, erro) => {
    cancelado(sinal);
    const abortar = () => { clearTimeout(t); erro(new DOMException('Entrada cancelada.', 'AbortError')); };
    const t = setTimeout(() => { sinal.removeEventListener('abort', abortar); ok(); }, ms);
    sinal.addEventListener('abort', abortar, { once: true });
  });
}
export async function esperarPin(pin: PinPlex, sinal: AbortSignal): Promise<string> {
  while (true) {
    cancelado(sinal);
    let d: { authToken?: string } = {};
    try { d = await tv(`/pins/${pin.id}`, undefined, { code: pin.code }, 'GET', sinal); }
    catch (e) {
      if (e instanceof ErroPlex && (e.status === 404 || e.status === 410)) throw new PinVencido();
      cancelado(sinal);
      // Como no Android, falha transitória não invalida um PIN ainda pendente.
      if (e instanceof ErroPlex && e.status < 500 && e.status !== 429) throw e;
    }
    cancelado(sinal);
    if (d.authToken) return d.authToken;
    await esperar(2000, sinal);
  }
}
export async function conta(tokenConta: string): Promise<ContaPlex> {
  const d = await tv<{ id: number | string; title?: string; username?: string; thumb?: string }>('/user', tokenConta);
  return { id: String(d.id), nome: d.title || d.username || '', login: d.username, foto: d.thumb };
}
const prioridade = (c: ConexaoPlex) => c.relay ? 2 : c.local ? 0 : 1;
export function conexoesPermitidas(r: RecursoPlex): ConexaoPlex[] {
  return (r.connections || []).filter(c => {
    try { return new URL(c.uri).protocol === 'https:' && (!c.local || r.publicAddressMatches === true); } catch { return false; }
  }).sort((a, b) => prioridade(a) - prioridade(b));
}
export async function servidores(tokenConta: string): Promise<RecursoPlex[]> {
  const recursos = await tv<(RecursoPlex & { provides?: string })[]>('/resources', tokenConta, { includeHttps: 1, includeRelay: 1 });
  return recursos.filter(r => r.provides?.split(',').map(x => x.trim()).includes('server') && r.accessToken && r.clientIdentifier)
    .map(r => ({ ...r, connections: conexoesPermitidas(r) }));
}
// Mesmo endpoint autenticado usado no Android (plex_client.dart:3334-3350).
export async function escolherConexao(r: RecursoPlex): Promise<ConexaoPlex> {
  const candidatas = conexoesPermitidas(r);
  const validas = await Promise.all(candidatas.map(async c => {
    const controle = new AbortController(), prazo = setTimeout(() => controle.abort(), 4000);
    try {
      const resposta = await respostaPlex(urlPlex(c.uri, '/', r.accessToken), 'GET', controle.signal);
      if (resposta.status !== 200) return false;
      const d = await resposta.json() as { MediaContainer?: { machineIdentifier?: string } };
      return d.MediaContainer?.machineIdentifier === r.clientIdentifier;
    } catch { return false; } finally { clearTimeout(prazo); }
  }));
  const escolhida = candidatas.find((_c, i) => validas[i]);
  if (!escolhida) throw new Error('Não foi possível conectar a este servidor Plex por HTTPS.');
  return escolhida;
}
