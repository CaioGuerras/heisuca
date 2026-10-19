import { useState } from 'preact/hooks';
import {
  alternarParaServidor, entrar, removerServidorSalvo, servidoresSalvos,
  type ServidorSalvo, type Sessao,
} from '../api/jellyfin';
import { Icone } from './Icone';

export function ModalServidores({
  s, fechar, aoAlternar,
}: {
  s: Sessao; fechar: () => void; aoAlternar: (nova: Sessao) => void;
}) {
  const [salvos, setSalvos] = useState<ServidorSalvo[]>(servidoresSalvos);
  const [adicionandoJellyfin, setAdicionandoJellyfin] = useState(false);
  const [url, setUrl] = useState('');
  const [nome, setNome] = useState('');
  const [usuario, setUsuario] = useState('');
  const [senha, setSenha] = useState('');
  const [erro, setErro] = useState('');
  const [conectando, setConectando] = useState(false);
  const [avisoNativo, setAvisoNativo] = useState('');

  const trocar = (srv: ServidorSalvo) => {
    const nova = alternarParaServidor(srv);
    aoAlternar(nova);
    fechar();
    location.reload();
  };

  const excluir = (ev: MouseEvent, urlSrv: string) => {
    ev.stopPropagation();
    removerServidorSalvo(urlSrv);
    setSalvos(servidoresSalvos());
  };

  const handleConectarNovo = async (ev: Event) => {
    ev.preventDefault();
    const u = url.trim();
    const usr = usuario.trim();
    if (!u) { setErro('Informe a URL do servidor.'); return; }
    if (!usr) { setErro('Informe o nome de usuário.'); return; }

    setConectando(true);
    setErro('');
    try {
      const urlFinal = u.startsWith('http://') || u.startsWith('https://') ? u : `https://${u}`;
      const nova = await entrar(urlFinal, usr, senha, nome.trim() || undefined);
      aoAlternar(nova);
      fechar();
      location.reload();
    } catch (e) {
      setErro(e instanceof Error ? e.message : String(e));
    } finally {
      setConectando(false);
    }
  };

  return (
    <div class="menu-fundo" onClick={e => { if (e.target === e.currentTarget) fechar(); }}>
      <div class="modal-caixa modal-servidores" role="dialog" aria-label="Servidores de Mídia">
        <div class="modal-cabeca">
          <h2>Servidores de Mídia</h2>
          <button class="menu-fechar" onClick={fechar} aria-label="Fechar">
            <Icone nome="close" />
          </button>
        </div>

        <p class="modal-sub">
          O Heisuca permite conectar múltiplos servidores, mantendo cada ambiente organizado e isolado.
        </p>

        {/* Lista de Servidores Conectados / Salvos */}
        <div class="servidores-secao">
          <h3>Servidores Salvos</h3>
          <div class="servidores-lista">
            {/* Servidor Ativo */}
            <div class="servidor-card ativo">
              <div class="servidor-card-icone">
                <Icone nome="dns" />
              </div>
              <div class="servidor-card-info">
                <strong>{s.servidor.includes('docaio') ? 'CGSERVER' : 'Jellyfin'}</strong>
                <small>{s.servidor.replace(/^https?:\/\//, '')} · {s.nome}</small>
              </div>
              <span class="servidor-selo-ativo">Conectado</span>
            </div>

            {/* Outros servidores salvos */}
            {salvos.filter(srv => srv.url !== s.servidor).map(srv => (
              <div key={srv.url} class="servidor-card" onClick={() => trocar(srv)}>
                <div class="servidor-card-icone">
                  <Icone nome="dns" />
                </div>
                <div class="servidor-card-info">
                  <strong>{srv.nome}</strong>
                  <small>{srv.url.replace(/^https?:\/\//, '')} · {srv.usuario}</small>
                </div>
                <button type="button" class="servidor-btn-conectar" onClick={() => trocar(srv)}>
                  Alternar
                </button>
                <button type="button" class="servidor-btn-remover" onClick={e => excluir(e, srv.url)} title="Remover">
                  <Icone nome="close" />
                </button>
              </div>
            ))}
          </div>
        </div>

        {/* Adicionar Servidor */}
        {!adicionandoJellyfin ? (
          <div class="servidores-secao">
            <h3>Adicionar Outro Servidor</h3>
            <div class="servidores-adicionar-grid">
              <button
                type="button"
                class="adicionar-tipo-btn"
                onClick={() => { setAdicionandoJellyfin(true); setAvisoNativo(''); }}
              >
                <Icone nome="dns" />
                <div>
                  <strong>Jellyfin / Emby</strong>
                  <small>Conectar a qualquer servidor Jellyfin</small>
                </div>
                <Icone nome="add" />
              </button>

              <button
                type="button"
                class="adicionar-tipo-btn desativado"
                onClick={() => setAvisoNativo('Suporte a Plex em desenvolvimento para os apps nativos.')}
              >
                <Icone nome="theaters" />
                <div>
                  <strong>Plex</strong>
                  <small>Em breve nos apps nativos</small>
                </div>
                <span class="badge-breve">Breve</span>
              </button>

              <button
                type="button"
                class="adicionar-tipo-btn desativado"
                onClick={() => setAvisoNativo('Suporte a WebDAV em desenvolvimento para os apps nativos.')}
              >
                <Icone nome="cloud" />
                <div>
                  <strong>WebDAV</strong>
                  <small>Em breve nos apps nativos</small>
                </div>
                <span class="badge-breve">Breve</span>
              </button>

              <button
                type="button"
                class="adicionar-tipo-btn desativado"
                onClick={() => setAvisoNativo('Suporte a SMB / NAS em desenvolvimento para os apps nativos.')}
              >
                <Icone nome="folder_shared" />
                <div>
                  <strong>SMB / NAS</strong>
                  <small>Em breve nos apps nativos</small>
                </div>
                <span class="badge-breve">Breve</span>
              </button>
            </div>
            {avisoNativo && <p class="aviso-inline">{avisoNativo}</p>}
          </div>
        ) : (
          <form class="servidor-form-adicionar" onSubmit={handleConectarNovo}>
            <h3>Conectar Servidor Jellyfin</h3>
            <label>
              Endereço do Servidor (URL)
              <input
                type="url"
                required
                placeholder="https://seu-jellyfin.com"
                value={url}
                onInput={e => setUrl(e.currentTarget.value)}
              />
            </label>
            <label>
              Nome do Servidor (Opcional)
              <input
                type="text"
                placeholder="Ex: Meu Servidor Casa"
                value={nome}
                onInput={e => setNome(e.currentTarget.value)}
              />
            </label>
            <label>
              Usuário
              <input
                type="text"
                required
                placeholder="Seu usuário"
                value={usuario}
                onInput={e => setUsuario(e.currentTarget.value)}
              />
            </label>
            <label>
              Senha
              <input
                type="password"
                placeholder="Sua senha (deixe em branco se livre)"
                value={senha}
                onInput={e => setSenha(e.currentTarget.value)}
              />
            </label>

            {erro && <p class="erro">{erro}</p>}

            <div class="servidor-form-botoes">
              <button
                type="button"
                class="botao-sec"
                onClick={() => { setAdicionandoJellyfin(false); setErro(''); }}
              >
                Voltar
              </button>
              <button type="submit" class="botao" disabled={conectando}>
                {conectando ? 'Conectando…' : 'Conectar Servidor'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}
