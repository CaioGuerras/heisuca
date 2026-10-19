// Moldura das páginas simples (Minha conta, Como usar, Baixar os apps, Sobre, Meus pedidos, Apoiar): ← + título.
import type { ComponentChildren } from 'preact';
import { usePaleta } from '../cor/paleta';
import { Icone } from '../comp/Icone';
import { voltar } from '../rota';
import './pagina.css';

export function Pagina({ titulo, children, classe = '' }: { titulo: string; children?: ComponentChildren; classe?: string }) {
  usePaleta(null);
  return (
    <main class={`pagina ${classe}`}>
      <header class="pagina-topo">
        <button class="redondo" onClick={voltar} aria-label="Voltar"><Icone nome="arrow_back" tamanho={24} /></button>
        <h1>{titulo}</h1>
      </header>
      <div class="pagina-corpo">{children}</div>
    </main>
  );
}

// tela que ainda vai ser feita (cada sessão troca a sua)
export const EmConstrucao = ({ titulo }: { titulo: string }) => (
  <Pagina titulo={titulo}><p class="texto-2">Em construção.</p></Pagina>
);
