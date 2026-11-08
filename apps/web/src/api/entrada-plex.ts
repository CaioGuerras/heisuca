import type { Sessao } from './tipos.ts';
import { guardarSessao, lembrarServidor } from './contas.ts';
import { criarPin, urlAutorizar, esperarPin, conta, servidores, escolherConexao, conexoesPermitidas,
  type RecursoPlex, type ConexaoPlex, type ContaPlex } from './plex-tv.ts';

function entrar(recurso: RecursoPlex, conexao: ConexaoPlex, conta: ContaPlex): Sessao {
  if (!conexoesPermitidas(recurso).some(c => c.uri === conexao.uri)) throw new Error('Conexão Plex não permitida.');
  const s: Sessao = { tipo: 'plex', servidor: conexao.uri.replace(/\/$/, ''), token: recurso.accessToken,
    usuarioId: conta.id, nome: conta.nome, fotoTag: conta.foto, servidorId: recurso.clientIdentifier, nomeServidor: recurso.name };
  guardarSessao(s);
  lembrarServidor({ url: s.servidor, id: recurso.clientIdentifier, nome: recurso.name, tipo: 'plex' });
  return s;
}
export const entradaPlex = { criarPin, urlAutorizar, esperarPin, conta, servidores, escolherConexao, entrar };
