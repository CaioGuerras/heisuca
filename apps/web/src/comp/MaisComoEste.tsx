import { useEffect, useState } from 'preact/hooks';
import { pode, similares, type Item, type Sessao } from '../api/servidor.ts';
import { irTitulo } from '../rota';
import { CartaoPoster } from './Cartoes';
import { Fileira } from './Fileira';

export function MaisComoEste({ s, id, limite = 12 }: { s: Sessao; id: string; limite?: number }) {
  const [itens, setItens] = useState<Item[]>([]);
  useEffect(() => {
    let vivo = true; setItens([]);
    if (pode(s, 'similares')) similares(s, id).then(l => {
      if (vivo) setItens(l.filter(i => i.Id !== id).slice(0, limite));
    }).catch(() => undefined);
    return () => { vivo = false; };
  }, [s, id, limite]);
  if (!pode(s, 'similares') || !itens.length) return null;
  return <Fileira titulo="Mais como este" classe="mais-como-este">
    {itens.map(i => <CartaoPoster key={i.Id} s={s} i={i} aoAbrir={x => irTitulo(x.Id, x)} />)}
  </Fileira>;
}
