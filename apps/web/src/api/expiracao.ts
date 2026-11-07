let aoExpirar: (() => void) | null = null;
export const quandoExpirar = (f: (() => void) | null) => { aoExpirar = f; };
export const notificarExpiracao = () => { aoExpirar?.(); };
