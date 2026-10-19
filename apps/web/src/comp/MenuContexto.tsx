// Botão direito no cartão (no celular, tocar e segurar): Marcar como visto/não visto e Favoritar/Desfavoritar
// (Caio 18/10 22:24; PLANO §4). Um menu só na página, aberto onde o ponteiro estava.
import { useEffect, useRef, useState } from 'preact/hooks';
import type { Item, Sessao } from '../api/jellyfin';
import { alternarFavorito, alternarVisto, dadosDe } from '../estado/usuario';
import { avisar } from './Aviso';
import { Icone } from './Icone';
import './menu-contexto.css';

type Opcao = { rotulo: string; icone: string; cheio?: boolean; acao: () => void };
type Aberto = { x: number; y: number; titulo: string; opcoes: Opcao[] };
let abrir: ((a: Aberto) => void) | null = null;

function opcoesDe(s: Sessao, i: Item): Opcao[] {
  const d = dadosDe(i), nome = i.Type === 'Episode' ? `${i.SeriesName} ${i.Name}` : i.Name;
  return [
    { rotulo: d.Played ? 'Marcar como não visto' : 'Marcar como visto', icone: 'flag', cheio: !d.Played,
      acao: () => alternarVisto(s, i).then(v => avisar(v ? `${nome}: visto.` : `${nome}: não visto.`)).catch(() => avisar('Não deu certo. Tente de novo.')) },
    { rotulo: d.IsFavorite ? 'Tirar dos favoritos' : 'Favoritar', icone: 'favorite', cheio: !d.IsFavorite,
      acao: () => alternarFavorito(s, i).then(v => avisar(v ? 'Guardado nos Favoritos.' : 'Tirado dos Favoritos.')).catch(() => avisar('Não deu certo. Tente de novo.')) },
  ];
}

// espalha nos cartões: onContextMenu (mouse) + segurar 500 ms (dedo)
export function useAcoes(s: Sessao, i: Item) {
  const t = useRef(0), segurou = useRef(false), ini = useRef<[number, number]>([0, 0]);
  const mostrar = (x: number, y: number) => abrir?.({ x, y, titulo: i.Type === 'Episode' ? `${i.SeriesName}` : i.Name, opcoes: opcoesDe(s, i) });
  return {
    onContextMenu: (e: MouseEvent) => { e.preventDefault(); mostrar(e.clientX, e.clientY); },
    onPointerDown: (e: PointerEvent) => {
      if (e.pointerType === 'mouse') return;
      segurou.current = false; ini.current = [e.clientX, e.clientY];
      clearTimeout(t.current);
      t.current = window.setTimeout(() => { segurou.current = true; navigator.vibrate?.(12); mostrar(ini.current[0], ini.current[1]); }, 500);
    },
    onPointerMove: (e: PointerEvent) => { if (Math.hypot(e.clientX - ini.current[0], e.clientY - ini.current[1]) > 10) clearTimeout(t.current); },
    onPointerUp: () => clearTimeout(t.current),
    onPointerCancel: () => clearTimeout(t.current),
    onClickCapture: (e: MouseEvent) => { if (segurou.current) { e.preventDefault(); e.stopPropagation(); segurou.current = false; } },
  };
}

export function MenuContexto() {
  const [a, setA] = useState<Aberto | null>(null);
  const caixa = useRef<HTMLDivElement>(null);
  useEffect(() => { abrir = setA; return () => { abrir = null; }; }, []);
  useEffect(() => {
    if (!a) return;
    const fechar = () => setA(null);
    const tecla = (e: KeyboardEvent) => { if (e.key === 'Escape') fechar(); };
    addEventListener('keydown', tecla); addEventListener('scroll', fechar, { passive: true, capture: true }); addEventListener('resize', fechar);
    caixa.current?.querySelector<HTMLElement>('button')?.focus({ preventScroll: true });
    return () => { removeEventListener('keydown', tecla); removeEventListener('scroll', fechar, { capture: true }); removeEventListener('resize', fechar); };
  }, [a]);
  if (!a) return null;
  // cabe na tela: abre para o lado que tem espaço
  const L = 236, A = 52 * a.opcoes.length + 44;
  const x = Math.min(Math.max(8, a.x), innerWidth - L - 8), y = a.y + A > innerHeight - 8 ? Math.max(8, a.y - A) : a.y;
  return (
    <div class="mc-fundo" onPointerDown={e => { if (e.target === e.currentTarget) setA(null); }} onContextMenu={e => { e.preventDefault(); setA(null); }}>
      <div class="mc" ref={caixa} role="menu" aria-label={a.titulo} style={{ left: x, top: y, transformOrigin: `${a.x - x}px ${a.y - y}px` }}>
        <p class="mc-titulo uma-linha">{a.titulo}</p>
        {a.opcoes.map(o => (
          <button key={o.rotulo} role="menuitem" class="mc-opcao" onClick={() => { setA(null); o.acao(); }}>
            <span>{o.rotulo}</span><Icone nome={o.icone} cheio={o.cheio} tamanho={22} />
          </button>
        ))}
      </div>
    </div>
  );
}
