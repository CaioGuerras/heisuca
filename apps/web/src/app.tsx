import { useEffect, useState } from 'preact/hooks';
import { sessaoSalva, type Sessao } from './api/jellyfin';
import { Abertura } from './comp/Abertura';
import { Navegacao } from './comp/Navegacao';
import { Aviso, FolhaPedido, type Alvo } from './comp/Pedido';
import { useRota } from './rota';
import { Entrar } from './telas/Entrar';
import { Inicio } from './telas/Inicio';
import { Biblioteca, Busca, Favoritos, Pedidos } from './telas/Listas';
import { Player } from './telas/Player';
import { Titulo } from './telas/Titulo';

export function App() {
  const [abertura, setAbertura] = useState(() => !sessionStorage.getItem('heisuca.abriu'));
  const [s, setS] = useState<Sessao | null>(sessaoSalva);
  const [pedido, setPedido] = useState<{ alvo: Alvo; depois?: () => void } | null>(null);
  const [rolado, setRolado] = useState(false);
  const r = useRota();
  useEffect(() => {
    const f = () => setRolado(scrollY > 40);
    addEventListener('scroll', f, { passive: true });
    return () => removeEventListener('scroll', f);
  }, []);
  if (abertura) return <Abertura fim={() => { sessionStorage.setItem('heisuca.abriu', '1'); setAbertura(false); }} />;
  if (!s) return <Entrar pronto={setS} />;
  if (r.tela === 'titulo') return <Titulo key={r.id} s={s} id={r.id} />;
  if (r.tela === 'ver') return <Player key={r.id} s={s} id={r.id} inicio={r.inicio} />;
  const pedir = (alvo: Alvo, depois?: () => void) => setPedido({ alvo, depois });
  return (
    <div class={`casca tela-${r.tela}`}>
      <Navegacao s={s} r={r} rolado={rolado || r.tela !== 'inicio'} />
      {r.tela === 'busca' ? <Busca s={s} pedir={pedir} />
        : r.tela === 'fav' ? <Favoritos s={s} />
        : r.tela === 'pedidos' ? <Pedidos s={s} />
        : r.tela === 'biblioteca' ? <Biblioteca key={r.id} s={s} id={r.id} />
        : <Inicio s={s} pedir={pedir} />}
      {pedido && <FolhaPedido s={s} alvo={pedido.alvo} fechar={() => setPedido(null)} pedido={pedido.depois} />}
      <Aviso />
    </div>
  );
}
