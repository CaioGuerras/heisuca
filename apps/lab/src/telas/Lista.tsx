// Minha lista: o que a pessoa guardou para ver (favoritos do servidor), os mais recentes primeiro.
import { useEffect, useState } from 'preact/hooks';
import type { Item, Sessao } from '@w/api/servidor';
import { irAba } from '@w/rota';
import { Poster } from '../comp/Cartao';
import { Ic } from '../comp/Icone';
import { minhaLista } from '../dados/catalogo';

export function Lista({ s }: { s: Sessao }) {
  const [itens, setItens] = useState<Item[] | null>(null);
  useEffect(() => { minhaLista(s).then(setItens).catch(() => setItens([])); }, []);
  return (
    <div class="explorar lista">
      <header class="explorar-topo"><h1>Minha lista</h1>
        <p class="explorar-conta">{itens ? `${itens.length} título${itens.length === 1 ? '' : 's'}` : ' '}</p></header>
      {itens && !itens.length ? <div class="vazio">
        <Ic n="bookmark" t={36} /><p>Sua lista está vazia.</p><p class="vazio-dica">Toque em “Minha lista” num título para guardar e ver depois.</p>
        <button class="botao primario" onClick={() => irAba('b')}>Explorar o acervo</button></div>
      : <div class="grade" aria-busy={!itens}>
        {itens ? itens.map((i, k) => <Poster key={i.Id} s={s} i={i} ordem={k} />)
          : Array.from({ length: 18 }, (_, k) => <div key={k} class="cartao poster fantasma" aria-hidden="true"><span class="cartao-arte osso" /><span class="osso" style="width:70%" /></div>)}
      </div>}
    </div>
  );
}
