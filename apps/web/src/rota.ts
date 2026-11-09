// Rotas por # (o servidor web só entrega o index.html; nada a configurar no nginx).
import { useEffect, useRef, useState } from 'preact/hooks';
import type { Item } from './api/tipos';
import { guardarPrevia } from './dados/previa';
import { entrarNaEntrada, iniciarRolagem, pararRestauro, restaurarRolagem, sairDaEntrada } from './anim/rolagem.ts';

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

// identidade da tela: a mesma chave = mesma tela montada (app.tsx usa como key da troca-tela)
export const chaveDe = (r: Rota) => `${r.tela}:${'id' in r ? r.id || '' : ''}`;

// antes(r) roda com a tela antiga ainda no DOM e a rolagem antiga (a saída da troca de tela copia dali). Se devolver
// true, ele mesmo chama aplicar (a View Transition troca a rota dentro dela); senão a rota troca na hora.
export function useRota(antes?: (nova: Rota, velha: Rota, aplicar: () => void) => boolean | void): Rota {
  const [r, setR] = useState(ler);
  const atual = useRef(r);
  const gancho = useRef(antes);
  gancho.current = antes;
  useEffect(() => {
    iniciarRolagem();
    const f = () => {
      const nova = ler();
      sairDaEntrada(scrollY); // H5: a tela velha ainda está rolada onde a pessoa deixou
      let feito = false;
      const aplicar = () => {
        if (feito) return;
        feito = true; atual.current = nova;
        const volta = entrarNaEntrada();
        setR(nova);
        if (history.state?.semRolar) return;
        if (volta?.y) void restaurarRolagem(volta.y); else { pararRestauro(); scrollTo(0, 0); }
      };
      let adiado = false;
      try { adiado = gancho.current?.(nova, atual.current, aplicar) === true; } catch { /* animação nunca impede a navegação */ }
      if (!adiado) aplicar();
    };
    addEventListener('hashchange', f);
    return () => removeEventListener('hashchange', f);
  }, []);
  return r;
}

// quantas telas o próprio app empilhou: Voltar só usa history.back() dentro do app (link direto volta ao Início)
let pilha = 0;
const ir = (h: string) => { pilha++; location.hash = h; };
// de = o item do cartão clicado (vira a prévia do título quando é o próprio título)
export const irTitulo = (id: string, de?: Item) => { if (de && de.Id === id) guardarPrevia(de); ir(`#/t/${id}`); };
export const irVer = (id: string, ticks?: number) => ir(`#/ver/${id}${ticks ? `?t=${ticks}` : ''}`);
export const irPagina = (p: typeof SIMPLES[number]) => ir(`#/${p}`);
// destinos da ilha trocam a tela sem empilhar (Voltar do navegador volta ao Início)
export const irAba = (aba: '' | 'busca' | 'fav' | `b/${string}` | 'b') => { location.hash = aba ? `#/${aba}` : ''; };
export function voltar() { if (pilha > 0) { pilha--; history.back(); } else location.hash = ''; }

// biblioteca aberta por último (a aba Biblioteca volta nela)
export const ultimaBiblioteca = () => { try { return localStorage.getItem('heisuca.biblioteca') || ''; } catch { return ''; } };
export const lembrarBiblioteca = (id: string) => { try { localStorage.setItem('heisuca.biblioteca', id); } catch { /* nada */ } };
