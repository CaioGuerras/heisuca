// Abertura da marca (carimbo 炳素華, ~2,3 s; marca/animacoes/ANIMACOES.md). Uma vez por sessão do navegador; um toque ou
// tecla pula. No fim, o traço de luz e o slogan somem e a tela diz onde a logo está, para ela voar até a próxima tela.
// §3.4: antes de tudo, o teste POR RECURSO (dados/suporte.ts). Faltando algo, a abertura vira a tela limpa "O Heisuca na TV é
// pelo app" e o app não segue (nem grava que a abertura foi vista: na próxima vez, o teste roda de novo).
import { useEffect, useRef, useState } from 'preact/hooks';
import { esmaecer } from '../anim/voo';
import { areaDaLogo, Logo } from '../comp/Logo';
import { recursosFaltando, type Ambiente } from '../dados/suporte.ts';

export function Abertura({ fim }: { fim: (logo: DOMRect) => void }) {
  const raiz = useRef<HTMLElement>(null);
  const [falta] = useState(() => recursosFaltando(window as unknown as Ambiente));
  useEffect(() => {
    if (falta.length) return;
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
  if (falta.length) return <SemSuporte falta={falta} />;
  return <main ref={raiz} class="abertura"><Logo modo="abertura" /></main>;
}

// Tela limpa (usa a .sem-suporte do index.html, com cores fixas: aqui as variáveis de CSS podem não existir).
// "Baixar os apps" abre ali mesmo a lista (a página do app precisa de conta e do resto do site).
const APPS_TV = [['Android TV', 'TVs e TV boxes com Google TV'], ['TVs Samsung e LG', 'Tizen e webOS'], ['Android', 'Celulares e tablets'], ['iPhone e iPad', 'iOS e iPadOS']];
function SemSuporte({ falta }: { falta: string[] }) {
  const [apps, setApps] = useState(() => location.hash === '#/apps');
  const link = { color: '#c4b5fd', fontWeight: 600, fontSize: 18, padding: '12px 4px', display: 'inline-block' };
  return (
    <main class="sem-suporte" data-faltando={falta.join(', ')}>
      <h1>HEISUCA</h1>
      <p style={{ fontSize: 22, color: '#f4f1fa', marginBottom: 10 }}>O Heisuca na TV é pelo app.</p>
      <p>Este navegador não tem o que o site precisa. No celular ou no computador, use um navegador atualizado.</p>
      {apps ? (
        <ul style={{ listStyle: 'none', padding: 0, margin: '24px 0 0', width: '100%', maxWidth: 420, textAlign: 'left' }}>
          {APPS_TV.map(([nome, sub]) => (
            <li key={nome} style={{ display: 'flex', justifyContent: 'space-between', gap: 12, padding: '12px 0', borderTop: '1px solid #2d243b' }}>
              <span><strong style={{ color: '#f4f1fa' }}>{nome}</strong><br /><small>{sub}</small></span><span>Em breve</span>
            </li>
          ))}
        </ul>
      ) : <a href="#/apps" style={{ ...link, marginTop: 16 }} onClick={e => { e.preventDefault(); setApps(true); }}>Baixar os apps</a>}
    </main>
  );
}
