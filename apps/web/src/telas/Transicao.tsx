// 2ª animação (PLANO §3.3): depois de "Iniciar sessão" (ou com a sessão já salva), a logo cresce até o centro da tela e a
// animação segura entre 3 e 5 s enquanto a home carrega por baixo (dados + imagens do 1º destaque decodificadas). No fim, o
// selo e o fundo tomam a cor tirada do pôster do 1º destaque e a home aparece. Desenho fino: sessão A (vídeo para o Caio aprovar).
import { useEffect, useLayoutEffect, useRef } from 'preact/hooks';
import type { Sessao } from '../api/jellyfin';
import { reduzido, voar } from '../anim/voo';
import { corDaBase, paletaDe } from '../cor/paleta';
import { css } from '../cor/oklch';
import { decodificarPrimeiras, hashDoDestaque, prepararInicio } from '../dados/inicio';
import { Logo } from '../comp/Logo';
import './transicao.css';

// tempo total (do clique até a home), já com a revelação no fim (Caio 19/10: 3 a 5 s)
export const MINIMO = 3000, MAXIMO = 5000, REVELA = 900;

export function Transicao({ s, de, fim }: { s: Sessao; de?: DOMRect | null; fim: () => void }) {
  const raiz = useRef<HTMLDivElement>(null), logo = useRef<HTMLDivElement>(null);
  useLayoutEffect(() => { if (de && logo.current) voar(logo.current, de, 760); }, []);
  useEffect(() => {
    const r = raiz.current!, t0 = performance.now();
    let acabou = false;
    const pronto = prepararInicio(s).then(d => decodificarPrimeiras(s, d).then(() => d)).catch(() => null);
    const espera = (ms: number) => new Promise(ok => setTimeout(ok, ms));
    (async () => {
      await espera(reduzido() ? 0 : 760);
      r.classList.add('respira');
      const revelar = reduzido() ? 0 : REVELA;
      const d = await Promise.race([pronto, espera(Math.max(0, MAXIMO - revelar - (performance.now() - t0))).then(() => null)]);
      const falta = MINIMO - revelar - (performance.now() - t0);
      if (falta > 0) await espera(falta);
      if (acabou) return;
      const p = paletaDe(corDaBase(hashDoDestaque(d?.destaque[0])));
      r.style.setProperty('--hs-transicao-cor', css(p.pagina));
      r.classList.add('revela');
      await espera(revelar);
      if (!acabou) fim();
    })();
    return () => { acabou = true; };
  }, []);
  return (
    <div class="transicao" ref={raiz} aria-label="Carregando" role="status">
      <div class="transicao-logo" ref={logo}><Logo modo="marca" /></div>
    </div>
  );
}
