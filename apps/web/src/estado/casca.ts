// Atalhos que qualquer tela usa sem passar props: abrir o "Trocar servidor" (pílula do topo) e saber se o servidor tem
// Seerr. A casca (app.tsx) registra as funções.
let servidores: (() => void) | null = null;
export const registrarServidores = (f: (() => void) | null) => { servidores = f; };
export const abrirServidores = () => servidores?.();
