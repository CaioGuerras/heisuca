import { useEffect, useRef } from 'preact/hooks';
import svg from '../marca/abertura.svg?raw';
import '../marca/abertura.css';

// A abertura "carimbo" (marca/animacoes/abertura.html): uma vez por sessão; qualquer tecla ou toque pula.
export function Abertura({ fim }: { fim: () => void }) {
  const raiz = useRef<HTMLElement>(null);
  useEffect(() => {
    let feito = false;
    const sair = () => {
      if (feito) return; feito = true;
      raiz.current?.classList.add('saindo');
      setTimeout(fim, 360);
    };
    const r = raiz.current!;
    const aoAcabar = (e: AnimationEvent) => { if (e.animationName === 'hs-segura') sair(); };
    r.addEventListener('animationend', aoAcabar);
    addEventListener('keydown', sair); addEventListener('pointerdown', sair);
    return () => { r.removeEventListener('animationend', aoAcabar); removeEventListener('keydown', sair); removeEventListener('pointerdown', sair); };
  }, []);
  return <main ref={raiz} class="abertura" dangerouslySetInnerHTML={{ __html: svg }} />;
}
