// A marca (esboço C: selo 炳素華 + HEISUCA + ヘイスカ, cor do selo = tema; LOGO.md). Mesmo desenho da abertura, para a logo
// poder "voar" entre as telas (anim/voo.ts): abertura → entrada → transição (PLANO §3.1).
import { useLayoutEffect, useRef } from 'preact/hooks';
import svg from '../marca/abertura.svg?raw';
import '../marca/abertura.css';
import './Logo.css';

// partes que formam a logo (o traço de luz e o slogan só existem na abertura)
export const PARTES = ['.selo', '.palavra', '.kata'];

export function Logo({ modo = 'marca', classe = '', aoMontar }: { modo?: 'abertura' | 'marca'; classe?: string; aoMontar?: (el: HTMLElement) => void }) {
  const raiz = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    const el = raiz.current!, s = el.querySelector('svg');
    if (s && modo === 'marca') {
      // recorta o viewBox na logo (selo + HEISUCA + ヘイスカ), com folga para a "tinta" não encostar na borda.
      // getBBox não conta o transform do próprio grupo (o .selo tem translate): somamos o deslocamento.
      const cx = PARTES.map(p => s.querySelector(p) as SVGGraphicsElement | null).filter(Boolean).map(g => {
        const b = g!.getBBox(), m = (g as SVGGElement).transform?.baseVal.consolidate()?.matrix;
        return { x: b.x + (m?.e ?? 0), y: b.y + (m?.f ?? 0), x2: b.x + (m?.e ?? 0) + b.width, y2: b.y + (m?.f ?? 0) + b.height };
      });
      if (cx.length) {
        const f = 2, x = Math.min(...cx.map(c => c.x)) - f, y = Math.min(...cx.map(c => c.y)) - f;
        s.setAttribute('viewBox', `${x} ${y} ${Math.max(...cx.map(c => c.x2)) + f - x} ${Math.max(...cx.map(c => c.y2)) + f - y}`);
      }
    }
    // abertura: recorta só as laterais vazias do quadro 640×360 (o desenho aprovado não muda; a logo fica centrada e,
    // no celular em pé, ocupa a largura em vez de ~60% dela). Um leve deslocamento à direita compensa o peso do selo.
    if (s && modo === 'abertura') s.setAttribute('viewBox', '90 50 450 260');
    aoMontar?.(el);
  }, [modo]);
  return <div ref={raiz} class={`logo logo-${modo} ${classe}`} dangerouslySetInnerHTML={{ __html: svg }} />;
}

// retângulo (na tela) que a logo ocupa: a união do selo, do HEISUCA e do ヘイスカ
export function areaDaLogo(el: Element): DOMRect {
  const r = PARTES.map(p => el.querySelector(p)?.getBoundingClientRect()).filter(Boolean) as DOMRect[];
  const x = Math.min(...r.map(c => c.left)), y = Math.min(...r.map(c => c.top));
  return new DOMRect(x, y, Math.max(...r.map(c => c.right)) - x, Math.max(...r.map(c => c.bottom)) - y);
}
