// Carregamento do player com a nossa animação (PLANO §13): o selo 炳素華 desce como carimbo (o mesmo da abertura) e
// depois "respira" enquanto o vídeo não chega. Só o selo, sem o HEISUCA: no meio do filme a marca fica discreta.
import { useLayoutEffect, useRef } from 'preact/hooks';
import svg from '../marca/abertura.svg?raw';
import '../marca/abertura.css';

export function Carregando() {
  const raiz = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => {
    // recorta o viewBox no selo (getBBox não conta o translate do grupo: somamos, como em comp/Logo.tsx)
    // a caixa vem do retângulo do selo (o .carimbo está no meio da animação, escalado e girado; a caixa dele mentiria)
    const s = raiz.current?.querySelector('svg'), g = s?.querySelector('.selo') as SVGGElement | null;
    const r = s?.querySelector('.selo-fundo') as SVGGraphicsElement | null;
    if (!s || !g || !r) return;
    const b = r.getBBox(), m = g.transform.baseVal.consolidate()?.matrix, f = 3;
    s.setAttribute('viewBox', `${b.x + (m?.e ?? 0) - f} ${b.y + (m?.f ?? 0) - f} ${b.width + 2 * f} ${b.height + 2 * f}`);
    s.removeAttribute('aria-label');
  }, []);
  return <div class="player-carregando" role="status" aria-label="Carregando"><div ref={raiz} dangerouslySetInnerHTML={{ __html: svg }} /></div>;
}
