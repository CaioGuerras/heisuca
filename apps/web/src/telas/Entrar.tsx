import { useState } from 'preact/hooks';
import { entrar, servidorPadrao, type Sessao } from '../api/jellyfin';

// build de teste: só os logins listados entram (o Caio e a conta da bancada)
const SO = ((import.meta.env.VITE_SO_USUARIO as string | undefined) || '').split(',').filter(Boolean);

export function Entrar({ pronto }: { pronto: (s: Sessao) => void }) {
  const [usuario, setUsuario] = useState('');
  const [senha, setSenha] = useState('');
  const [erro, setErro] = useState('');
  const [indo, setIndo] = useState(false);

  async function enviar(ev: Event) {
    ev.preventDefault();
    if (SO.length && !SO.includes(usuario.trim().toLowerCase())) { setErro('Esta versão de teste ainda não está aberta.'); return; }
    setIndo(true); setErro('');
    try { pronto(await entrar(servidorPadrao(), usuario.trim(), senha)); }
    catch (e) { setErro(e instanceof Error ? e.message : String(e)); }
    finally { setIndo(false); }
  }

  return (
    <main class="entrar">
      <form class="entrar-caixa" onSubmit={enviar}>
        <h1 class="marca-texto">HEISUCA</h1>
        <p class="slogan">Nada entre você e o filme.</p>
        <label>Usuário<input data-foco autoFocus autocomplete="username" value={usuario} onInput={e => setUsuario(e.currentTarget.value)} /></label>
        <label>Senha<input data-foco type="password" autocomplete="current-password" value={senha} onInput={e => setSenha(e.currentTarget.value)} /></label>
        {erro && <p class="erro" role="alert">{erro}</p>}
        <button data-foco class="botao" disabled={indo}>{indo ? 'Entrando…' : 'Entrar'}</button>
      </form>
    </main>
  );
}
