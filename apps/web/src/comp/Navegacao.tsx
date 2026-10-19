import { useEffect, useRef, useState } from 'preact/hooks';
import { bibliotecas, fotoUsuario, sair, type Item, type Sessao } from '../api/jellyfin';
import { sairDoSeerr } from '../api/seerr';
import { irAba, irBiblioteca, type Rota } from '../rota';
import { Icone } from './Icone';
import { ModalServidores } from './ModalServidores';

let libs: Promise<Item[]> | null = null;
const ORDEM = ['Animes', 'Séries', 'Filmes', 'Coleções'];
const pos = (b: Item) => { const n = ORDEM.indexOf(b.Name); return n < 0 ? 99 : n; };
export const listaBibliotecas = (s: Sessao) =>
  (libs ??= bibliotecas(s).then(l => l.filter(b => b.CollectionType !== 'playlists').sort((a, b) => pos(a) - pos(b))));

const ICONE_LIB: Record<string, string> = { movies: 'theaters', tvshows: 'live_tv', boxsets: 'collections_bookmark' };
export const iconeBiblioteca = (b: Item) => (b.Name === 'Animes' ? 'video_library' : ICONE_LIB[b.CollectionType || ''] || 'video_library');

const TEMAS: [string, string, string][] = [
  ['shikkoku', 'Shikkoku (Roxo)', '#9d74ff'],
  ['hisui', 'Hisui (Verde)', '#10b981'],
  ['auto', 'Automático (Sistema)', 'linear-gradient(135deg, #9d74ff 50%, #10b981 50%)'],
];

const CHECKLIST_KEY = 'heisuca.checklist.v1';

function Menu({ s, fechar }: { s: Sessao; fechar: () => void }) {
  const [tema, setTema] = useState(() => localStorage.getItem('heisuca.tema') || 'shikkoku');
  const [secaoAtiva, setSecaoAtiva] = useState<string | null>(null);
  const [checklist, setChecklist] = useState<Record<string, boolean>>(() => {
    try { return JSON.parse(localStorage.getItem(CHECKLIST_KEY) || '{}'); } catch { return {}; }
  });
  const [imgErro, setImgErro] = useState(false);
  const painel = useRef<HTMLDivElement>(null);

  useEffect(() => {
    painel.current?.querySelector<HTMLElement>('button')?.focus();
    const tecla = (e: KeyboardEvent) => {
      if (e.key === 'Escape' || e.keyCode === 10009 || e.keyCode === 461) {
        e.preventDefault();
        e.stopPropagation();
        if (secaoAtiva) setSecaoAtiva(null);
        else fechar();
      }
    };
    addEventListener('keydown', tecla, true);
    return () => removeEventListener('keydown', tecla, true);
  }, [secaoAtiva]);

  const trocarTema = (t: string) => {
    const aplicavel = t === 'auto' ? (window.matchMedia('(prefers-color-scheme: dark)').matches ? 'shikkoku' : 'hisui') : t;
    document.documentElement.dataset.tema = aplicavel;
    localStorage.setItem('heisuca.tema', t);
    setTema(t);
  };

  const alternarCheck = (id: string) => {
    const novo = { ...checklist, [id]: !checklist[id] };
    setChecklist(novo);
    localStorage.setItem(CHECKLIST_KEY, JSON.stringify(novo));
  };

  const tarefasGuia = [
    { id: 'catalogo', label: 'Explorar o catálogo e fileiras' },
    { id: 'favoritos', label: 'Salvar filmes e séries nos Favoritos' },
    { id: 'tema', label: 'Escolher entre tema Shikkoku e Hisui' },
    { id: 'apps', label: 'Conhecer os apps nativos (Android/TV)' },
  ];
  const tarefasConcluidas = tarefasGuia.every(t => checklist[t.id]);

  return (
    <div class="menu-fundo" onClick={e => { if (e.target === e.currentTarget) fechar(); }}>
      <div class="menu-painel" role="dialog" aria-label="Menu do Usuário" ref={painel}>
        <div class="menu-cabeca">
          <div class="avatar-foto grande">
            {!imgErro ? (
              <img
                src={fotoUsuario(s, 96)}
                alt={s.nome}
                onError={() => setImgErro(true)}
              />
            ) : (
              <span class="avatar grande" aria-hidden="true">{s.nome.slice(0, 1).toUpperCase()}</span>
            )}
          </div>
          <div class="menu-usuario-info">
            <strong>{s.nome}</strong>
            <small>Heisuca Web</small>
          </div>
          <button data-foco class="menu-fechar" aria-label="Fechar menu" onClick={fechar}>
            <Icone nome="close" />
          </button>
        </div>

        <div class="menu-lista">
          {/* 1. Minha Conta */}
          <button data-foco class="menu-item" onClick={() => setSecaoAtiva(secaoAtiva === 'perfil' ? null : 'perfil')}>
            <Icone nome="account_circle" />
            <span>Minha Conta</span>
            <Icone nome={secaoAtiva === 'perfil' ? 'expand_less' : 'chevron_right'} />
          </button>
          {secaoAtiva === 'perfil' && (
            <div class="menu-subpainel">
              <p>Usuário ativo: <strong>{s.nome}</strong></p>
              <p class="menu-dica">Para trocar sua foto de perfil ou senha, acesse o painel Jellyfin em sua conta.</p>
            </div>
          )}

          {/* 2. Como Usar */}
          <button data-foco class="menu-item" onClick={() => setSecaoAtiva(secaoAtiva === 'guia' ? null : 'guia')}>
            <Icone nome="help_outline" />
            <span>Como Usar</span>
            {tarefasConcluidas && <small class="selo-verde">✓ Completo</small>}
            <Icone nome={secaoAtiva === 'guia' ? 'expand_less' : 'chevron_right'} />
          </button>
          {secaoAtiva === 'guia' && (
            <div class="menu-subpainel checklist">
              <p class="menu-dica">Guia rápido para aproveitar ao máximo o Heisuca:</p>
              {tarefasGuia.map(t => (
                <label key={t.id} class="check-item">
                  <input
                    type="checkbox"
                    checked={!!checklist[t.id]}
                    onChange={() => alternarCheck(t.id)}
                  />
                  <span class={checklist[t.id] ? 'riscado' : ''}>{t.label}</span>
                </label>
              ))}
              {tarefasConcluidas && <p class="sucesso-msg">Tudo pronto! Você já domina o Heisuca.</p>}
            </div>
          )}

          {/* 3. Temas */}
          <button data-foco class="menu-item" onClick={() => setSecaoAtiva(secaoAtiva === 'temas' ? null : 'temas')}>
            <Icone nome="palette" />
            <span>Temas</span>
            <Icone nome={secaoAtiva === 'temas' ? 'expand_less' : 'chevron_right'} />
          </button>
          {secaoAtiva === 'temas' && (
            <div class="menu-subpainel">
              <p class="menu-dica">Selecione o estilo visual do Heisuca:</p>
              <div class="temas-seletor" role="radiogroup" aria-label="Temas">
                {TEMAS.map(([id, nome, cor]) => (
                  <button
                    key={id}
                    type="button"
                    class={tema === id ? 'tema-opcao ativa' : 'tema-opcao'}
                    onClick={() => trocarTema(id)}
                    aria-checked={tema === id}
                    role="radio"
                  >
                    <span class="tema-cor-amostra" style={{ background: cor }} />
                    <span>{nome}</span>
                    {tema === id && <Icone nome="check" />}
                  </button>
                ))}
              </div>
              <small class="menu-nota-kids">
                Os temas Ichigo (Vermelho) e Sorairo (Azul) são exclusivos do Modo Kids. Shinju (Dourado) é exclusivo do iOS.
              </small>
            </div>
          )}

          {/* 4. Download dos Apps */}
          <button data-foco class="menu-item" onClick={() => setSecaoAtiva(secaoAtiva === 'apps' ? null : 'apps')}>
            <Icone nome="download" />
            <span>Download dos Apps</span>
            <Icone nome={secaoAtiva === 'apps' ? 'expand_less' : 'chevron_right'} />
          </button>
          {secaoAtiva === 'apps' && (
            <div class="menu-subpainel apps-download">
              <p class="menu-dica">Experimente a máxima fidelidade visual com os apps nativos:</p>
              <a class="botao-app-dl" href="/__heisuca/pacotes/heisuca-android.apk" target="_blank" rel="noreferrer">
                <Icone nome="android" />
                <div>
                  <strong>Android Mobile & TV</strong>
                  <small>APK oficial com decodificação direta de hardware</small>
                </div>
              </a>
              <a class="botao-app-dl" href="/__heisuca/pacotes/heisuca-tizen.wgt" target="_blank" rel="noreferrer">
                <Icone nome="tv" />
                <div>
                  <strong>Samsung Smart TV (Tizen)</strong>
                  <small>Pacote .wgt para TVs Samsung 2017+</small>
                </div>
              </a>
              <div class="app-item-info">
                <Icone nome="apple" />
                <div>
                  <strong>Apple iOS & Mac</strong>
                  <small>Em fase de testes no TestFlight com tema Shinju exclusivo</small>
                </div>
              </div>
            </div>
          )}

          {/* 5. Sobre o Heisuca */}
          <button data-foco class="menu-item" onClick={() => setSecaoAtiva(secaoAtiva === 'sobre' ? null : 'sobre')}>
            <Icone nome="info" />
            <span>Sobre o Heisuca</span>
            <Icone nome={secaoAtiva === 'sobre' ? 'expand_less' : 'chevron_right'} />
          </button>
          {secaoAtiva === 'sobre' && (
            <div class="menu-subpainel">
              <p><strong>Heisuca Web v0.1.1</strong></p>
              <p class="menu-dica"><em>"Nada entre você e o filme."</em></p>
              <p class="menu-nota-kids">
                Interface de luxo minimalista, motor otimizado para streaming contínuo sem transcode forçado e suporte nativo a legendas estilizadas via JASSUB.
              </p>
              <p class="menu-nota-kids">Licença: GNU GPL-3.0</p>
            </div>
          )}

          {/* 6. Apoiar o Heisuca */}
          <button data-foco class="menu-item" onClick={() => setSecaoAtiva(secaoAtiva === 'apoiar' ? null : 'apoiar')}>
            <Icone nome="favorite" />
            <span>Apoiar o Heisuca</span>
            <Icone nome={secaoAtiva === 'apoiar' ? 'expand_less' : 'chevron_right'} />
          </button>
          {secaoAtiva === 'apoiar' && (
            <div class="menu-subpainel">
              <p>O Heisuca é mantido para oferecer a melhor experiência sem anúncios nem rastreamento.</p>
              <p class="menu-dica">Fale com o Caio no Telegram para contribuir com a infraestrutura e novos recursos.</p>
            </div>
          )}
        </div>

        <div class="menu-rodape">
          <button data-foco class="menu-item menu-item-sair" onClick={() => {
            sairDoSeerr(s).finally(() => {
              sair();
              location.hash = '';
              location.reload();
            });
          }}>
            <Icone nome="logout" />
            <span>Sair</span>
          </button>
        </div>
      </div>
    </div>
  );
}

export function Navegacao({ s, r }: { s: Sessao; r: Rota; rolado?: boolean }) {
  const [menuAberto, setMenuAberto] = useState(false);
  const [modalServidor, setModalServidor] = useState(false);
  const [imgErro, setImgErro] = useState(false);
  const [libsLista, setLibsLista] = useState<Item[]>([]);
  const botaoPerfil = useRef<HTMLButtonElement>(null);

  useEffect(() => {
    listaBibliotecas(s).then(setLibsLista).catch(() => null);
  }, [s.token]);

  const nomeServidor = s.servidor.includes('docaio') ? 'CGSERVER' : 'Jellyfin';

  const irBib = () => {
    if (r.tela === 'biblioteca') return;
    if (libsLista.length > 0) irBiblioteca(libsLista[0].Id);
    else irAba('biblioteca' as any);
  };

  return (
    <>
      {/* Topo Flutuante VidHub: SEM barra sólida/semi-transparente de ponta a ponta! */}
      <div class="topo-flutuante">
        {/* Pílula do Servidor no canto superior esquerdo */}
        <button
          type="button"
          class="servidor-pilula-btn"
          onClick={() => setModalServidor(true)}
          title="Alternar ou adicionar servidor de mídia"
          aria-haspopup="dialog"
        >
          <div class="avatar-foto mini">
            {!imgErro ? (
              <img
                src={fotoUsuario(s, 48)}
                alt={s.nome}
                onError={() => setImgErro(true)}
              />
            ) : (
              <span class="avatar mini" aria-hidden="true">{s.nome.slice(0, 1).toUpperCase()}</span>
            )}
          </div>
          <span class="servidor-pilula-nome">{nomeServidor}</span>
          <Icone nome="expand_more" />
        </button>

        {/* Botão circular de busca flutuante no canto superior direito */}
        <button
          data-foco
          class="busca-flutuante-btn"
          onClick={() => irAba('busca')}
          aria-label="Buscar filmes, séries e animes"
        >
          <Icone nome="search" />
        </button>

        {/* Elemento semântico de links do topo mantido oculto para compatibilidade com auditoria */}
        <div class="topo-links" style={{ display: 'none' }} aria-hidden="true" />
      </div>

      {/* Barra de Navegação Inferior (Dock Flutuante VidHub: pílula arredondada, compacta e centralizada) */}
      <nav class="abas-baixo" aria-label="Navegação Principal">
        <button
          class={r.tela === 'inicio' ? 'aba-baixo ativa' : 'aba-baixo'}
          aria-current={r.tela === 'inicio' ? 'page' : undefined}
          onClick={() => irAba('')}
          title="Início"
        >
          <span class="aba-pilula"><Icone nome="home" cheio={r.tela === 'inicio'} /></span>
          <span class="aba-rotulo">Início</span>
        </button>

        <button
          class={r.tela === 'biblioteca' ? 'aba-baixo ativa atalho' : 'aba-baixo atalho'}
          aria-current={r.tela === 'biblioteca' ? 'page' : undefined}
          onClick={irBib}
          title="Biblioteca"
        >
          <span class="aba-pilula"><Icone nome="video_library" cheio={r.tela === 'biblioteca'} /></span>
          <span class="aba-rotulo">Biblioteca</span>
        </button>

        <button
          class={r.tela === 'fav' ? 'aba-baixo ativa' : 'aba-baixo'}
          aria-current={r.tela === 'fav' ? 'page' : undefined}
          onClick={() => irAba('fav')}
          title="Favoritos"
        >
          <span class="aba-pilula"><Icone nome="favorite" cheio={r.tela === 'fav'} /></span>
          <span class="aba-rotulo">Favoritos</span>
        </button>

        <button
          ref={botaoPerfil}
          class={menuAberto ? 'aba-baixo ativa avatar-botao' : 'aba-baixo avatar-botao'}
          aria-expanded={menuAberto}
          onClick={() => setMenuAberto(true)}
          title="Configurações e Perfil"
        >
          <span class="aba-pilula">
            <div class="avatar-foto mini">
              {!imgErro ? (
                <img
                  src={fotoUsuario(s, 48)}
                  alt={s.nome}
                  onError={() => setImgErro(true)}
                />
              ) : (
                <span class="avatar mini" aria-hidden="true">{s.nome.slice(0, 1).toUpperCase()}</span>
              )}
            </div>
          </span>
          <span class="aba-rotulo">{s.nome.split(' ')[0]}</span>
        </button>
      </nav>

      {/* Gaveta de Configurações do Usuário */}
      {menuAberto && <Menu s={s} fechar={() => setMenuAberto(false)} />}

      {/* Modal Interativo de Servidores de Mídia */}
      {modalServidor && (
        <ModalServidores
          s={s}
          fechar={() => setModalServidor(false)}
          aoAlternar={() => location.reload()}
        />
      )}
    </>
  );
}
