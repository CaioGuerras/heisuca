// Entrada Plex sem JSX (testável): PIN → token da conta → servidores → conexão HTTPS → sessão.
// A tela só mostra os passos; toda decisão (conectar direto, pedir escolha, que erro dizer) mora aqui.
import type { Sessao } from './tipos.ts';
import { entradaPlex } from './entrada-plex.ts';
import { ErroPlex, PinVencido, conexoesPermitidas, type ContaPlex, type PinPlex, type RecursoPlex } from './plex-tv.ts';

export type { RecursoPlex };
export type MotivoPlex = 'vencido' | 'sem-servidor' | 'sem-https' | 'rede' | 'recusou';
export class ErroEntradaPlex extends Error {
  motivo: MotivoPlex;
  constructor(motivo: MotivoPlex, msg: string) { super(msg); this.motivo = motivo; }
}
export const cancelada = (e: unknown) => e instanceof DOMException && e.name === 'AbortError';
function abortou(sinal: AbortSignal) { if (sinal.aborted) throw new DOMException('Entrada cancelada.', 'AbortError'); }

// Traduz falhas de rede/plex.tv para PT-BR; cancelamento e erros já traduzidos passam como estão.
function traduzir(e: unknown): unknown {
  if (cancelada(e) || e instanceof ErroEntradaPlex) return e;
  if (e instanceof PinVencido) return new ErroEntradaPlex('vencido', 'O código venceu antes da autorização. Gere outro para tentar de novo.');
  if (e instanceof ErroPlex) return new ErroEntradaPlex('recusou', `O Plex recusou o pedido (${e.status}). Tente de novo daqui a pouco.`);
  return new ErroEntradaPlex('rede', 'Sem resposta do Plex. Confira a internet e tente de novo.');
}

export type Autorizacao = { conta: ContaPlex; servidores: RecursoPlex[] };
// Pede o PIN, avisa a tela (código + link) e espera a autorização; devolve a conta e os servidores dela.
export async function autorizarPlex(sinal: AbortSignal, aoPin: (pin: PinPlex, url: string) => void, aoAutorizar?: () => void): Promise<Autorizacao> {
  try {
    abortou(sinal);
    const pin = await entradaPlex.criarPin();
    abortou(sinal);
    aoPin(pin, entradaPlex.urlAutorizar(pin));
    const token = await entradaPlex.esperarPin(pin, sinal);
    abortou(sinal);
    aoAutorizar?.();
    const [conta, servidores] = await Promise.all([entradaPlex.conta(token), entradaPlex.servidores(token)]);
    abortou(sinal);
    return { conta, servidores };
  } catch (e) { throw traduzir(e); }
}

// 0 servidores: erro; 1: conecta direto; vários: a tela lista os nomes para escolher.
export type Passo = { tipo: 'conectar'; recurso: RecursoPlex } | { tipo: 'escolher'; lista: RecursoPlex[] };
export function passoSeguinte(servidores: RecursoPlex[]): Passo {
  if (!servidores.length) throw new ErroEntradaPlex('sem-servidor', 'Nenhum servidor Plex nesta conta. Entre com a conta que tem acesso ao servidor.');
  return servidores.length === 1 ? { tipo: 'conectar', recurso: servidores[0] } : { tipo: 'escolher', lista: servidores };
}

// Testa as conexões HTTPS e cria a sessão (guardada e lembrada com tipo 'plex' por entradaPlex.entrar).
export async function conectarPlex(recurso: RecursoPlex, conta: ContaPlex, sinal: AbortSignal): Promise<Sessao> {
  abortou(sinal);
  if (!conexoesPermitidas(recurso).length)
    throw new ErroEntradaPlex('sem-https', `“${recurso.name}” não tem endereço HTTPS que o navegador alcance. Ligue o acesso remoto no Plex ou use um app Heisuca.`);
  let conexao;
  try { conexao = await entradaPlex.escolherConexao(recurso); }
  catch {   // escolherConexao já engole a rede de cada candidata: falhar aqui é não alcançar nenhuma por HTTPS
    abortou(sinal);
    throw new ErroEntradaPlex('sem-https', `Não deu para alcançar “${recurso.name}” por HTTPS. Confira se o servidor está ligado e com acesso remoto.`);
  }
  abortou(sinal);
  return entradaPlex.entrar(recurso, conexao, conta);
}
