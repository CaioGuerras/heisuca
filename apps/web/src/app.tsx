import { useState } from 'preact/hooks';
import { sessaoSalva, type Sessao } from './api/jellyfin';
import { Abertura } from './comp/Abertura';
import { Entrar } from './telas/Entrar';
import { Inicio } from './telas/Inicio';

export function App() {
  const [abertura, setAbertura] = useState(() => !sessionStorage.getItem('heisuca.abriu'));
  const [s, setS] = useState<Sessao | null>(sessaoSalva);
  if (abertura) return <Abertura fim={() => { sessionStorage.setItem('heisuca.abriu', '1'); setAbertura(false); }} />;
  return s ? <Inicio s={s} /> : <Entrar pronto={setS} />;
}
