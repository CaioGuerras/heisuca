// Folha de atalhos do teclado (tecla ?).
import { useEffect, useRef } from 'preact/hooks';
import { Ic } from './Icone';

const LISTA: [string[], string][] = [
  [['⌘', 'K'], 'Buscar ou abrir um comando'], [['/'], 'Buscar'], [['?'], 'Mostrar estes atalhos'],
  [['G', 'I'], 'Ir ao Início'], [['G', 'E'], 'Ir a Explorar'], [['G', 'L'], 'Ir à Minha lista'],
  [['Esc'], 'Fechar ou voltar'],
];
const PLAYER: [string[], string][] = [
  [['Espaço'], 'Tocar ou pausar'], [['←', '→'], 'Voltar ou avançar'], [['F'], 'Tela cheia'], [['M'], 'Sem som'],
];

export function Atalhos({ aberta, fechar }: { aberta: boolean; fechar: () => void }) {
  const d = useRef<HTMLDialogElement>(null);
  useEffect(() => { const x = d.current; if (!x) return; if (aberta && !x.open) x.showModal(); if (!aberta && x.open) x.close(); }, [aberta]);
  const linhas = (l: [string[], string][]) => l.map(([teclas, o]) => <li key={o}><span>{o}</span><span class="teclas">{teclas.map(k => <kbd key={k}>{k}</kbd>)}</span></li>);
  return (
    <dialog ref={d} class="folha atalhos" onClose={fechar} onClick={e => { if (e.target === d.current) fechar(); }} aria-labelledby="atalhos-t">
      <header><h2 id="atalhos-t">Atalhos do teclado</h2><button class="redondo" onClick={fechar} aria-label="Fechar"><Ic n="close" t={20} /></button></header>
      <h3>Em qualquer tela</h3><ul>{linhas(LISTA)}</ul>
      <h3>Assistindo</h3><ul>{linhas(PLAYER)}</ul>
    </dialog>
  );
}
