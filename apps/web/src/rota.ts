// Rotas por # (o servidor web só entrega o index.html; nada a configurar no nginx).
import { useEffect, useState } from 'preact/hooks';

export type Rota =
  | { tela: 'inicio' } | { tela: 'biblioteca'; id?: string } | { tela: 'fav' } | { tela: 'busca' }
  | { tela: 'titulo'; id: string } | { tela: 'ver'; id: string; inicio?: number }
  | { tela: 'conta' } | { tela: 'ajuda' } | { tela: 'apps' } | { tela: 'sobre' } | { tela: 'pedidos' } | { tela: 'apoiar' };

const SIMPLES = ['fav', 'busca', 'conta', 'ajuda', 'apps', 'sobre', 'pedidos', 'apoiar'] as const;

export function ler(): Rota {
  const [caminho, busca = ''] = location.hash.slice(1).split('?');
  const p = caminho.split('/').filter(Boolean);
  if (p[0] === 't' && p[1]) return { tela: 'titulo', id: p[1] };
  if (p[0] === 'ver' && p[1]) {
    const t = Number(new URLSearchParams(busca).get('t'));
    return { tela: 'ver', id: p[1], inicio: Number.isFinite(t) && t > 0 ? t : undefined };
  }
  if (p[0] === 'b') return { tela: 'biblioteca', id: p[1] };
  if ((SIMPLES as readonly string[]).includes(p[0])) return { tela: p[0] } as Rota;
  return { tela: 'inicio' };
}

export function useRota(): Rota {
  const [r, setR] = useState(ler);
  useEffect(() => {
    const f = () => { setR(ler()); if (!history.state?.semRolar) scrollTo(0, 0); };
    addEventListener('hashchange', f);
    return () => removeEventListener('hashchange', f);
  }, []);
  return r;
}

// quantas telas o próprio app empilhou: Voltar só usa history.back() dentro do app (link direto volta ao Início)
let pilha = 0;
const ir = (h: string) => { pilha++; location.hash = h; };
export const irTitulo = (id: string) => ir(`#/t/${id}`);
export const irVer = (id: string, ticks?: number) => ir(`#/ver/${id}${ticks ? `?t=${ticks}` : ''}`);
export const irPagina = (p: typeof SIMPLES[number]) => ir(`#/${p}`);
// destinos da ilha trocam a tela sem empilhar (Voltar do navegador volta ao Início)
export const irAba = (aba: '' | 'busca' | 'fav' | `b/${string}` | 'b') => { location.hash = aba ? `#/${aba}` : ''; };
export function voltar() { if (pilha > 0) { pilha--; history.back(); } else location.hash = ''; }

// biblioteca aberta por último (a aba Biblioteca volta nela)
export const ultimaBiblioteca = () => { try { return localStorage.getItem('heisuca.biblioteca') || ''; } catch { return ''; } };
export const lembrarBiblioteca = (id: string) => { try { localStorage.setItem('heisuca.biblioteca', id); } catch { /* nada */ } };
