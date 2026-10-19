import { useState } from 'preact/hooks';
import { entrar, servidorPadrao, type Sessao } from '../api/jellyfin';
import { Icone } from '../comp/Icone';

const SO = ((import.meta.env.VITE_SO_USUARIO as string | undefined) || '').split(',').filter(Boolean);

export function Entrar({ pronto }: { pronto: (s: Sessao) => void }) {
  const [servidor] = useState(servidorPadrao);
  const [usuario, setUsuario] = useState('');
  const [senha, setSenha] = useState('');
  const [erro, setErro] = useState('');
  const [indo, setIndo] = useState(false);
  const [modalServidor, setModalServidor] = useState(false);
  const [avisoOutro, setAvisoOutro] = useState('');

  async function enviar(ev: Event) {
    ev.preventDefault();
    const u = usuario.trim();
    if (!u) {
      setErro('Informe o seu usuário.');
      return;
    }
    if (SO.length && !SO.includes(u.toLowerCase())) {
      setErro('Esta versão de teste ainda não está aberta.');
      return;
    }
    setIndo(true);
    setErro('');
    try {
      pronto(await entrar(servidor, u, senha));
    } catch (e) {
      setErro(e instanceof Error ? e.message : String(e));
    } finally {
      setIndo(false);
    }
  }

  const opcoesServidor = [
    { nome: 'Jellyfin', desc: 'Conectar a outro servidor Jellyfin ou Emby', icone: 'dns' },
    { nome: 'Plex', desc: 'Acessar biblioteca do Plex Media Server', icone: 'theaters' },
    { nome: 'WebDAV', desc: 'Nuvem pessoal via protocolo WebDAV', icone: 'cloud' },
    { nome: 'SMB / Compartilhamento', desc: 'Rede local Windows ou NAS', icone: 'folder_shared' },
  ];

  return (
    <main class="entrar">
      <form class="entrar-caixa" onSubmit={enviar}>
        <div class="entrar-marca">
          <span class="selo-kanji" aria-hidden="true">炳素華</span>
          <h1 class="marca-texto">HEISUCA</h1>
          <p class="slogan">Nada entre você e o filme.</p>
        </div>

        {/* Card do Servidor Padrão */}
        <div class="servidor-cartao">
          <div class="servidor-info">
            <span class="servidor-status" title="Servidor operacional" />
            <div>
              <strong>CGSERVER</strong>
              <small>Jellyfin · {servidor.replace(/^https?:\/\//, '')}</small>
            </div>
          </div>
          <button type="button" class="servidor-trocar" onClick={() => setModalServidor(true)} title="Adicionar ou alternar servidor">
            <Icone nome="swap_horiz" />
          </button>
        </div>

        <button type="button" class="botao-link-servidor" onClick={() => setModalServidor(true)}>
          <Icone nome="add" /> Adicionar outro servidor
        </button>

        <div class="entrar-campos">
          <label>
            Usuário
            <input
              data-foco
              autoFocus
              autocomplete="username"
              value={usuario}
              onInput={e => setUsuario(e.currentTarget.value)}
              placeholder="Nome de usuário"
            />
          </label>
          <label>
            Senha
            <input
              data-foco
              type="password"
              autocomplete="current-password"
              value={senha}
              onInput={e => setSenha(e.currentTarget.value)}
              placeholder="Senha (deixe em branco se livre)"
            />
          </label>
        </div>

        {erro && <p class="erro" role="alert">{erro}</p>}

        <button data-foco class="botao entrar-botao" disabled={indo}>
          {indo ? 'Conectando…' : 'Conectar'}
        </button>
      </form>

      {/* Modal de Servidores Alternativos */}
      {modalServidor && (
        <div class="menu-fundo" onClick={e => { if (e.target === e.currentTarget) setModalServidor(false); }}>
          <div class="modal-caixa" role="dialog" aria-label="Adicionar outro servidor">
            <div class="modal-cabeca">
              <h2>Adicionar Servidor</h2>
              <button class="menu-fechar" onClick={() => setModalServidor(false)} aria-label="Fechar">
                <Icone nome="close" />
              </button>
            </div>
            <p class="modal-sub">
              O Heisuca suporta múltiplos servidores de mídia mantendo uma biblioteca unificada e limpa.
            </p>
            <div class="servidores-lista">
              {opcoesServidor.map(op => (
                <button
                  key={op.nome}
                  type="button"
                  class="servidor-opcao"
                  onClick={() => setAvisoOutro(`Conexão com ${op.nome} disponível nos apps nativos e na próxima versão web.`)}
                >
                  <Icone nome={op.icone} />
                  <div>
                    <strong>{op.nome}</strong>
                    <small>{op.desc}</small>
                  </div>
                  <Icone nome="chevron_right" />
                </button>
              ))}
            </div>
            {avisoOutro && <p class="aviso-inline">{avisoOutro}</p>}
          </div>
        </div>
      )}
    </main>
  );
}
