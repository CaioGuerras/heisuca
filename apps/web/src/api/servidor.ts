// Servidores Jellyfin: achar o endereço certo, guardar os servidores e as sessões de cada um, entrar por senha ou por
// Quick Connect. Só Jellyfin (PLANO §2 e §3.2). Nada de servidor pré-preenchido: o produto é a suíte, não o CGSERVER.
import { cabecalho, type Sessao } from './jellyfin';

export type Servidor = { url: string; id: string; nome: string; versao?: string };

const SERVIDORES = 'heisuca.servidores';   // [Servidor] na ordem do último uso
const SESSOES = 'heisuca.sessoes';         // { [idDoServidor]: Sessao }
const ATUAL = 'heisuca.sessao';            // a sessão em uso (mesma chave do M1, para não deslogar ninguém)

const ler = <T,>(chave: string, padrao: T): T => { try { return JSON.parse(localStorage.getItem(chave) || '') ?? padrao; } catch { return padrao; } };
const gravar = (chave: string, v: unknown) => { try { localStorage.setItem(chave, JSON.stringify(v)); } catch { /* modo privado */ } };

export const servidoresSalvos = (): Servidor[] => ler<Servidor[]>(SERVIDORES, []);
export const ultimoServidor = (): Servidor | null => servidoresSalvos()[0] ?? null;

function lembrarServidor(s: Servidor) {
  gravar(SERVIDORES, [s, ...servidoresSalvos().filter(x => x.id !== s.id)].slice(0, 8));
}

export function sessaoAtual(): Sessao | null { return ler<Sessao | null>(ATUAL, null); }

export function guardarSessao(s: Sessao) {
  gravar(ATUAL, s);
  if (s.servidorId) gravar(SESSOES, { ...ler<Record<string, Sessao>>(SESSOES, {}), [s.servidorId]: s });
}

// Sair: esquece a sessão deste servidor; o servidor continua lembrado (a tela de entrada já vem com o endereço).
export function esquecerSessao() {
  const s = sessaoAtual();
  try { localStorage.removeItem(ATUAL); } catch { /* nada */ }
  if (s?.servidorId) { const t = ler<Record<string, Sessao>>(SESSOES, {}); delete t[s.servidorId]; gravar(SESSOES, t); }
}

// Trocar de servidor: se já há sessão guardada nele, entra direto; senão devolve null (vai para a tela de entrada).
export function trocarPara(id: string): Sessao | null {
  const s = ler<Record<string, Sessao>>(SESSOES, {})[id] || null;
  const srv = servidoresSalvos().find(x => x.id === id);
  if (srv) lembrarServidor(srv);
  if (s) gravar(ATUAL, s);
  return s;
}

// ---- endereço ----
export class ErroEntrada extends Error {
  campo: 'servidor' | 'usuario' | 'senha' | 'geral';
  constructor(campo: ErroEntrada['campo'], msg: string) { super(msg); this.campo = campo; }
}

// "netflix.exemplo.com" → ["https://netflix.exemplo.com", "https://netflix.exemplo.com/jellyfin"]
// (os clientes oficiais tentam o mesmo: muita gente publica o Jellyfin em /jellyfin atrás do proxy)
export function candidatos(entrada: string): string[] {
  let u = entrada.trim().replace(/\s+/g, '');
  if (!u) return [];
  if (!/^https?:\/\//i.test(u)) u = 'https://' + u;
  u = u.replace(/\/+(web\/?(index\.html)?(#.*)?)?$/i, '').replace(/\/+$/, '');
  const c = [u];
  if (!/\/jellyfin$/i.test(u)) c.push(u + '/jellyfin');
  return c;
}

// só localhost é "confiável" para o navegador; http://192.168… (rede de casa) é bloqueado num site em https (conteúdo misto)
const local = (u: string) => /^http:\/\/(localhost|127\.\d+\.\d+\.\d+|\[::1\])(:\d+)?(\/|$)/i.test(u);

async function comPrazo(url: string, ms = 7000, init?: RequestInit): Promise<Response> {
  const c = new AbortController(); const t = setTimeout(() => c.abort(), ms);
  try { return await fetch(url, { ...init, signal: c.signal }); } finally { clearTimeout(t); }
}

// Acha o servidor: GET /System/Info/Public (público, com CORS "*" no Jellyfin padrão).
export async function descobrir(entrada: string): Promise<Servidor> {
  const c = candidatos(entrada);
  if (!c.length) throw new ErroEntrada('servidor', 'Digite o endereço do servidor.');
  // site em https não fala com servidor http (o navegador bloqueia: "conteúdo misto")
  if (location.protocol === 'https:' && c[0].startsWith('http://') && !local(c[0]))
    throw new ErroEntrada('servidor', 'Pelo navegador, só dá para entrar em servidores com https://. Use o endereço https do servidor ou um app Heisuca.');
  for (const url of c) {
    try {
      const r = await comPrazo(`${url}/System/Info/Public`);
      if (!r.ok) continue;
      const d = await r.json() as { Id?: string; ServerName?: string; Version?: string; ProductName?: string };
      if (!d?.Id) continue;
      return { url, id: d.Id, nome: d.ServerName || new URL(url).hostname, versao: d.Version };
    } catch { /* tenta o próximo */ }
  }
  throw new ErroEntrada('servidor', 'Não achei um servidor Jellyfin nesse endereço.');
}

type Autenticacao = { AccessToken: string; User: { Id: string; Name: string; PrimaryImageTag?: string } };
function sessaoDe(srv: Servidor, d: Autenticacao): Sessao {
  return { servidor: srv.url, servidorId: srv.id, nomeServidor: srv.nome, token: d.AccessToken, usuarioId: d.User.Id,
    nome: d.User.Name, fotoTag: d.User.PrimaryImageTag };
}

export async function entrarComSenha(srv: Servidor, usuario: string, senha: string): Promise<Sessao> {
  if (!usuario.trim()) throw new ErroEntrada('usuario', 'Digite o usuário.');
  let r: Response;
  try {
    r = await comPrazo(`${srv.url}/Users/AuthenticateByName`, 15000, {
      method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: cabecalho() },
      body: JSON.stringify({ Username: usuario.trim(), Pw: senha }),
    });
  } catch { throw new ErroEntrada('geral', 'O servidor não respondeu. Tente de novo.'); }
  if (r.status === 401) throw new ErroEntrada('senha', 'Usuário ou senha incorretos.');
  if (!r.ok) throw new ErroEntrada('geral', `O servidor recusou a entrada (${r.status}).`);
  const s = sessaoDe(srv, await r.json());
  lembrarServidor(srv); guardarSessao(s);
  return s;
}

// ---- Quick Connect (entrar com um código autorizado em outro aparelho já conectado) ----
export async function quickConnectLigado(srv: Servidor): Promise<boolean> {
  try { const r = await comPrazo(`${srv.url}/QuickConnect/Enabled`); return r.ok && (await r.json()) === true; } catch { return false; }
}

export type PedidoQC = { codigo: string; segredo: string };
export async function iniciarQuickConnect(srv: Servidor): Promise<PedidoQC> {
  const r = await comPrazo(`${srv.url}/QuickConnect/Initiate`, 10000, { method: 'POST', headers: { Authorization: cabecalho() } });
  if (!r.ok) throw new ErroEntrada('geral', 'O Quick Connect está desligado neste servidor.');
  const d = await r.json() as { Code: string; Secret: string };
  return { codigo: d.Code, segredo: d.Secret };
}

// Espera a autorização (o código vale ~10 min no servidor); devolve a sessão ou null se cancelado.
export async function esperarQuickConnect(srv: Servidor, p: PedidoQC, cancelado: () => boolean): Promise<Sessao | null> {
  while (!cancelado()) {
    await new Promise(ok => setTimeout(ok, 2500));
    if (cancelado()) return null;
    try {
      const r = await comPrazo(`${srv.url}/QuickConnect/Connect?Secret=${encodeURIComponent(p.segredo)}`, 8000, { headers: { Authorization: cabecalho() } });
      if (r.status === 404 || r.status === 400) throw new ErroEntrada('geral', 'O código venceu. Peça outro.');
      if (!r.ok) continue;
      const d = await r.json() as { Authenticated?: boolean; authenticated?: boolean };
      if (!(d.Authenticated ?? d.authenticated)) continue;
      const a = await comPrazo(`${srv.url}/Users/AuthenticateWithQuickConnect`, 10000, {
        method: 'POST', headers: { 'Content-Type': 'application/json', Authorization: cabecalho() }, body: JSON.stringify({ Secret: p.segredo }),
      });
      if (!a.ok) throw new ErroEntrada('geral', 'A autorização falhou. Peça outro código.');
      const s = sessaoDe(srv, await a.json());
      lembrarServidor(srv); guardarSessao(s);
      return s;
    } catch (e) { if (e instanceof ErroEntrada) throw e; /* rede: tenta de novo */ }
  }
  return null;
}
