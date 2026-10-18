// Rotas por # (o nginx só serve index.html; nada a configurar). #/t/<id> = título, #/ver/<id>?t=<ticks> = player.
import { useEffect, useState } from 'preact/hooks';

export type Rota = { tela: 'inicio' } | { tela: 'titulo'; id: string } | { tela: 'ver'; id: string; inicio?: number };

function ler(): Rota {
  const [caminho, busca = ''] = location.hash.slice(1).split('?');
  const p = caminho.split('/').filter(Boolean);
  if (p[0] === 't' && p[1]) return { tela: 'titulo', id: p[1] };
  if (p[0] === 'ver' && p[1]) {
    const t = Number(new URLSearchParams(busca).get('t'));
    return { tela: 'ver', id: p[1], inicio: Number.isFinite(t) && t > 0 ? t : undefined };
  }
  return { tela: 'inicio' };
}

export function useRota(): Rota {
  const [r, setR] = useState(ler);
  useEffect(() => {
    const f = () => { setR(ler()); scrollTo(0, 0); };
    addEventListener('hashchange', f);
    return () => removeEventListener('hashchange', f);
  }, []);
  return r;
}

// quantas telas o próprio app empilhou: Voltar só usa history.back() dentro do app (link direto volta ao início)
let pilha = 0;
const ir = (h: string) => { pilha++; location.hash = h; };
export const irTitulo = (id: string) => ir(`#/t/${id}`);
export const irVer = (id: string, ticks?: number) => ir(`#/ver/${id}${ticks ? `?t=${ticks}` : ''}`);
export function voltar() { if (pilha > 0) { pilha--; history.back(); } else location.hash = ''; }

// Voltar do teclado e dos controles (Esc, Backspace fora de campo, Tizen 10009, webOS 461). O player trata o dele antes.
export function ligarVoltar(): void {
  addEventListener('keydown', ev => {
    const k = ev.keyCode, alvo = ev.target as HTMLElement;
    if (k === 8 && (alvo.tagName === 'INPUT' || alvo.tagName === 'TEXTAREA')) return;
    if (k !== 8 && k !== 27 && k !== 461 && k !== 10009) return;
    if (!location.hash || location.hash === '#') return;
    ev.preventDefault(); voltar();
  });
}
