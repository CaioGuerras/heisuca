import type { Servidor, Sessao } from './tipos.ts';
export type { Servidor } from './tipos.ts';
export const VERSAO = '0.2.0';
export function idAparelho(): string {
  let id = '';
  try { id = localStorage.getItem('heisuca.aparelho') || ''; } catch { /* modo privado */ }
  if (!id) { id = Math.random().toString(36).slice(2) + Date.now().toString(36); try { localStorage.setItem('heisuca.aparelho', id); } catch { /* nada */ } }
  return id;
}

const normalizar = (s: Sessao): Sessao => ({ ...s, tipo: s.tipo ?? 'jellyfin' });
const SERVIDORES = 'heisuca.servidores';   // [Servidor] na ordem do último uso
const SESSOES = 'heisuca.sessoes';         // { [idDoServidor]: Sessao }
const ATUAL = 'heisuca.sessao';            // a sessão em uso (mesma chave do M1, para não deslogar ninguém)

const ler = <T,>(chave: string, padrao: T): T => { try { return JSON.parse(localStorage.getItem(chave) || '') ?? padrao; } catch { return padrao; } };
const gravar = (chave: string, v: unknown) => { try { localStorage.setItem(chave, JSON.stringify(v)); } catch { /* modo privado */ } };

export const servidoresSalvos = (): Servidor[] => ler<Servidor[]>(SERVIDORES, []).map(s => ({ ...s, tipo: s.tipo ?? 'jellyfin' }));
export const ultimoServidor = (): Servidor | null => servidoresSalvos()[0] ?? null;

export function lembrarServidor(s: Servidor) {
  gravar(SERVIDORES, [s, ...servidoresSalvos().filter(x => x.id !== s.id)].slice(0, 8));
}

export function sessaoAtual(): Sessao | null { const s = ler<Sessao | null>(ATUAL, null); return s ? normalizar(s) : null; }

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
  const antiga = ler<Record<string, Sessao>>(SESSOES, {})[id];
  const s = antiga ? normalizar(antiga) : null;
  const srv = servidoresSalvos().find(x => x.id === id);
  if (srv) lembrarServidor(srv);
  if (s) gravar(ATUAL, s);
  return s;
}

