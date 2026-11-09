// Fileira com rolagem lateral nativa (encaixe por cartão) e setas no computador. Sem rolagem automática.
import type { ComponentChildren } from 'preact';
import { useRef, useState, useEffect } from 'preact/hooks';
import { Ic } from './Icone';

export function Fileira({ titulo, sub, children, tipo = 'poster', acao }: { titulo: string; sub?: string; children: ComponentChildren;
  tipo?: 'poster' | 'paisagem' | 'pessoa'; acao?: { texto: string; href: string } }) {
  const trilho = useRef<HTMLDivElement>(null);
  const [pontas, setPontas] = useState({ ini: true, fim: false });
  const medir = () => {
    const t = trilho.current; if (!t) return;
    setPontas({ ini: t.scrollLeft < 8, fim: t.scrollLeft + t.clientWidth > t.scrollWidth - 8 });
  };
  useEffect(() => { medir(); }, [children]);
  const passo = (d: number) => { const t = trilho.current; if (t) t.scrollBy({ left: d * t.clientWidth * 0.85, behavior: 'smooth' }); };
  return (
    <section class={`fileira fileira-${tipo}`} aria-label={titulo}>
      <header class="fileira-topo">
        <h2>{titulo}{sub && <small>{sub}</small>}</h2>
        {acao && <a class="fileira-acao" href={acao.href}>{acao.texto}<Ic n="chevron_right" t={18} /></a>}
      </header>
      <div class="fileira-corpo">
        <button class="fileira-seta esq" aria-label="Voltar a fileira" hidden={pontas.ini} onClick={() => passo(-1)}><Ic n="chevron_left" t={28} /></button>
        <div class="fileira-trilho" ref={trilho} onScroll={medir}>{children}</div>
        <button class="fileira-seta dir" aria-label="Avançar a fileira" hidden={pontas.fim} onClick={() => passo(1)}><Ic n="chevron_right" t={28} /></button>
      </div>
    </section>
  );
}

export function FileiraFantasma({ tipo = 'poster' }: { tipo?: 'poster' | 'paisagem' }) {
  return (
    <section class={`fileira fileira-${tipo} fantasma`} aria-hidden="true">
      <header class="fileira-topo"><h2><span class="osso" style={{ width: '9em' }} /></h2></header>
      <div class="fileira-corpo"><div class="fileira-trilho">
        {Array.from({ length: 8 }, (_, k) => <div class="cartao" key={k}><span class="cartao-arte osso" /></div>)}
      </div></div>
    </section>
  );
}
