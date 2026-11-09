// Menu de tema: Sala, Matinê, Projetor. A troca revela o tema novo em círculo a partir do botão.
import { useEffect, useState } from 'preact/hooks';
import { TEMAS, temaAtual, trocarTema, type Tema } from '../tema';
import { Ic } from './Icone';

export function MenuTema() {
  const [aberto, setAberto] = useState(false);
  const [t, setT] = useState<Tema>(temaAtual);
  useEffect(() => {
    if (!aberto) return;
    const fora = (e: Event) => { if (!(e.target as HTMLElement).closest('.menu-tema')) setAberto(false); };
    const esc = (e: KeyboardEvent) => { if (e.key === 'Escape') setAberto(false); };
    addEventListener('pointerdown', fora); addEventListener('keydown', esc);
    return () => { removeEventListener('pointerdown', fora); removeEventListener('keydown', esc); };
  }, [aberto]);
  const atual = TEMAS.find(x => x.id === t) || TEMAS[0];
  return (
    <div class="menu-tema">
      <button class="redondo" aria-haspopup="menu" aria-expanded={aberto} aria-label={`Tema: ${atual.nome}`} onClick={() => setAberto(a => !a)}>
        <Ic n={atual.icone} t={20} />
      </button>
      {aberto && (
        <div class="menu" role="menu" aria-label="Tema">
          {TEMAS.map(x => (
            <button key={x.id} role="menuitemradio" aria-checked={x.id === t} class={x.id === t ? 'ativo' : ''}
              onClick={e => { const b = (e.currentTarget as HTMLElement).getBoundingClientRect();
                trocarTema(x.id, { x: b.left + b.width / 2, y: b.top + b.height / 2 }); setT(x.id); setAberto(false); }}>
              <span class={`amostra amostra-${x.id}`} aria-hidden="true" />
              <span class="menu-texto">{x.nome}<small>{x.dica}</small></span>
              {x.id === t && <Ic n="check" t={18} />}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
