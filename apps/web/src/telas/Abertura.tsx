// Abertura da marca (carimbo 炳素華, ~2,3 s; marca/animacoes/ANIMACOES.md). Uma vez por sessão do navegador; um toque ou
// tecla pula. No fim, o traço de luz e o slogan somem e a tela diz onde a logo está, para ela voar até a próxima tela.
import { useEffect, useRef } from 'preact/hooks';
import { esmaecer } from '../anim/voo';
import { areaDaLogo, Logo } from '../comp/Logo';

export function Abertura({ fim }: { fim: (logo: DOMRect) => void }) {
  const raiz = useRef<HTMLElement>(null);
  useEffect(() => {
    const r = raiz.current!;
    let feito = false;
    const sair = async () => {
      if (feito) return; feito = true;
      r.classList.add('parada');   // congela as animações no estado final (se pulou no meio, tudo aparece)
      await Promise.all([esmaecer(r.querySelector('.slogan'), 0.72, 0, 220), esmaecer(r.querySelector('.luz'), 1, 0, 220)]);
      fim(areaDaLogo(r));
    };
    const aoAcabar = (e: AnimationEvent) => { if (e.animationName === 'hs-segura') sair(); };
    r.addEventListener('animationend', aoAcabar);
    addEventListener('keydown', sair); addEventListener('pointerdown', sair);
    return () => { r.removeEventListener('animationend', aoAcabar); removeEventListener('keydown', sair); removeEventListener('pointerdown', sair); };
  }, []);
  return <main ref={raiz} class="abertura"><Logo modo="abertura" /></main>;
}
