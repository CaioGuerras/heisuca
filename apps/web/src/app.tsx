import { useState } from 'preact/hooks';
import { sessaoSalva, type Sessao } from './api/jellyfin';
import { Abertura } from './comp/Abertura';
import { useRota } from './rota';
import { Entrar } from './telas/Entrar';
import { Inicio } from './telas/Inicio';
import { Player } from './telas/Player';
import { Titulo } from './telas/Titulo';

export function App() {
  const [abertura, setAbertura] = useState(() => !sessionStorage.getItem('heisuca.abriu'));
  const [s, setS] = useState<Sessao | null>(sessaoSalva);
  const r = useRota();
  if (abertura) return <Abertura fim={() => { sessionStorage.setItem('heisuca.abriu', '1'); setAbertura(false); }} />;
  if (!s) return <Entrar pronto={setS} />;
  if (r.tela === 'titulo') return <Titulo key={r.id} s={s} id={r.id} />;
  if (r.tela === 'ver') return <Player key={r.id} s={s} id={r.id} inicio={r.inicio} />;
  return <Inicio s={s} />;
}
