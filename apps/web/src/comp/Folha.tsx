// Janela contida (PLANO §5: o seletor de temporada nunca empurra nem cobre a página de qualquer jeito).
//  variante "folha": sobe de baixo no celular, caixa centralizada no computador.
//  variante "balao": cresce a partir do elemento que a abriu (o menu do usuário nasce da foto na ilha; §9).
//  variante "lateral": menu que entra pela direita (as bibliotecas, na tela Biblioteca; §6).
// Fecha no ✕, no Esc, tocando fora ou pelo próprio conteúdo. Rolagem própria; a página por trás não rola.
import type { ComponentChildren } from 'preact';
import { useEffect, useLayoutEffect, useRef, useState } from 'preact/hooks';
import { Icone } from './Icone';
import './folha.css';

type Props = { aberta: boolean; fechar: () => void; titulo?: string; ancora?: HTMLElement | null; variante?: 'folha' | 'balao' | 'lateral';
  classe?: string; semCabeca?: boolean; children: ComponentChildren };

export function Folha({ aberta, fechar, titulo, ancora, variante = 'folha', classe = '', semCabeca = false, children }: Props) {
  const caixa = useRef<HTMLDivElement>(null);
  const [saindo, setSaindo] = useState(false);
  const [visivel, setVisivel] = useState(aberta);
  const [pos, setPos] = useState<Record<string, string | number>>({});
  const voltarFoco = useRef<HTMLElement | null>(null);

  useEffect(() => {
    if (aberta) { setPos({}); setVisivel(true); setSaindo(false); voltarFoco.current = document.activeElement as HTMLElement; }
    else if (visivel) { setSaindo(true); const t = setTimeout(() => { setVisivel(false); setSaindo(false); voltarFoco.current?.focus?.({ preventScroll: true }); }, 200); return () => clearTimeout(t); }
  }, [aberta]);

  // balão: posição e origem da animação a partir da âncora (abre para onde há espaço)
  useLayoutEffect(() => {
    if (!visivel || variante !== 'balao' || !ancora || !caixa.current) return;
    // offsetWidth/Height = tamanho real; o getBoundingClientRect pegaria a caixa no meio da animação (scale .6)
    const a = ancora.getBoundingClientRect(), c = { width: caixa.current.offsetWidth, height: caixa.current.offsetHeight };
    const m = 10, emBaixo = a.top > innerHeight / 2;
    const left = Math.min(Math.max(m, a.left + a.width / 2 - c.width / 2), innerWidth - c.width - m);
    const top = emBaixo ? Math.max(m, a.top - c.height - 10) : Math.min(a.bottom + 10, innerHeight - c.height - m);
    // nascido de baixo: preso pela base, para crescer para cima se o conteúdo aumentar (a escolha do tema abre dentro do menu).
    // A origem da animação fica no ponto real da âncora (vale também quando a caixa encostou na borda da tela).
    const base = Math.max(m, innerHeight - a.top + 10), x = `${a.left + a.width / 2 - left}px`;
    setPos(emBaixo ? { left, bottom: base, top: 'auto', transformOrigin: `${x} calc(100% + ${a.top - (innerHeight - base)}px)` }
      : { left, top, transformOrigin: `${x} ${a.bottom - top}px` });
  }, [visivel, ancora, variante]);

  useEffect(() => {
    if (!visivel) return;
    // html e body: o Safari do iOS só para de rolar a página de trás com o body travado
    const d = document.documentElement, b = document.body, antes = d.style.overflow, antesB = b.style.overflow;
    d.style.overflow = 'hidden'; b.style.overflow = 'hidden';
    const tecla = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { e.stopPropagation(); fechar(); return; }
      if (e.key !== 'Tab' || !caixa.current) return;
      const f = Array.from(caixa.current.querySelectorAll<HTMLElement>('button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"])')).filter(x => !x.hasAttribute('disabled'));
      if (!f.length) return;
      const i = f.indexOf(document.activeElement as HTMLElement);
      if (i === -1) { e.preventDefault(); (e.shiftKey ? f[f.length - 1] : f[0]).focus(); return; }
      if (e.shiftKey && i <= 0) { e.preventDefault(); f[f.length - 1].focus(); } else if (!e.shiftKey && i === f.length - 1) { e.preventDefault(); f[0].focus(); }
    };
    addEventListener('keydown', tecla, true);
    requestAnimationFrame(() => caixa.current?.querySelector<HTMLElement>('[autofocus], .folha-corpo button, .folha-corpo input, button')?.focus({ preventScroll: true }));
    return () => { d.style.overflow = antes; b.style.overflow = antesB; removeEventListener('keydown', tecla, true); };
  }, [visivel]);

  if (!visivel) return null;
  return (
    <div class={`folha-fundo folha-${variante}${saindo ? ' saindo' : ''}`} onPointerDown={e => { if (e.target === e.currentTarget) fechar(); }}>
      <div ref={caixa} class={`folha ${classe}`} role="dialog" aria-modal="true" aria-label={titulo} style={variante === 'balao' ? { ...pos, visibility: pos.left === undefined ? 'hidden' : 'visible' } : undefined}>
        {variante === 'folha' && <span class="folha-alca" aria-hidden="true" />}
        {!semCabeca && (titulo || variante === 'folha') && (
          <header class="folha-cabeca">
            {titulo && <h2>{titulo}</h2>}
            <button class="folha-fechar" aria-label="Fechar" onClick={fechar}><Icone nome="close" tamanho={22} /></button>
          </header>
        )}
        <div class="folha-corpo">{children}</div>
      </div>
    </div>
  );
}
