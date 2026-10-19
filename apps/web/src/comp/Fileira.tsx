// Fileira horizontal: título + "Ver tudo ›" (opcional) e o trilho que rola de lado. No computador (ponteiro fino), setas
// aparecem ao passar o mouse, porque mouse não "arrasta" a fileira como o dedo. [P] do PLANO §4 (computador).
import type { ComponentChildren } from 'preact';
import { useEffect, useRef, useState } from 'preact/hooks';
import { Icone } from './Icone';
import './fileira.css';

export function Fileira({ titulo, verTudo, children, classe = '' }:
  { titulo: string; verTudo?: () => void; children: ComponentChildren; classe?: string }) {
  const trilho = useRef<HTMLDivElement>(null);
  const [ponta, setPonta] = useState({ ini: true, fim: false });
  useEffect(() => {
    const t = trilho.current; if (!t) return;
    const f = () => setPonta({ ini: t.scrollLeft < 8, fim: t.scrollLeft + t.clientWidth > t.scrollWidth - 8 });
    f(); t.addEventListener('scroll', f, { passive: true });
    const ro = new ResizeObserver(f); ro.observe(t);
    return () => { t.removeEventListener('scroll', f); ro.disconnect(); };
  }, []);
  const rolar = (dir: number) => { const t = trilho.current; if (t) t.scrollBy({ left: dir * t.clientWidth * 0.85, behavior: 'smooth' }); };
  return (
    <section class={`fileira ${classe}`}>
      <header class="fileira-cabeca">
        <h2 class="titulo-secao">{titulo}</h2>
        {verTudo && <button class="fileira-tudo" onClick={verTudo}>Ver tudo<Icone nome="chevron_right" tamanho={20} /></button>}
      </header>
      <div class="fileira-corpo">
        {!ponta.ini && <button class="fileira-seta esq" aria-label="Voltar" onClick={() => rolar(-1)}><Icone nome="chevron_left" tamanho={28} /></button>}
        <div class="fileira-trilho" ref={trilho}>{children}</div>
        {!ponta.fim && <button class="fileira-seta dir" aria-label="Avançar" onClick={() => rolar(1)}><Icone nome="chevron_right" tamanho={28} /></button>}
      </div>
    </section>
  );
}
