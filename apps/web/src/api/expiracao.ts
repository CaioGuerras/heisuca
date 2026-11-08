import type { Sessao } from './tipos.ts';

let aoExpirar: ((origem: Sessao) => void) | null = null;
export const quandoExpirar = (f: ((origem: Sessao) => void) | null) => { aoExpirar = f; };
export const notificarExpiracao = (origem: Sessao) => { aoExpirar?.(origem); };
