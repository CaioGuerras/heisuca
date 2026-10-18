// Navegação no modelo dos nossos apps (SITE_REMODELAGEM.md; CGFLIX TV P13/P14):
// - destinos: Início, Buscar (com "Disponível para pedir") e Favoritos. Sem aba de Pedidos: a busca já pede (Caio, P13).
// - celular (< 840 px): barra de abas embaixo; computador/tablet/TV: links no topo.
// - o resto (bibliotecas, Meus pedidos, tema, Sair) mora no menu do botão do canto (avatar) e só abre quando ele é escolhido.
import { useEffect, useRef, useState } from 'preact/hooks';
import { bibliotecas, sair, type Item, type Sessao } from '../api/jellyfin';
import { sairDoSeerr } from '../api/seerr';
import { irAba, irBiblioteca, type Rota } from '../rota';
import { Icone } from './Icone';

let libs: Promise<Item[]> | null = null;
const ORDEM = ['Animes', 'Séries', 'Filmes', 'Coleções'];
const pos = (b: Item) => { const n = ORDEM.indexOf(b.Name); return n < 0 ? 99 : n; };
export const listaBibliotecas = (s: Sessao) =>
  (libs ??= bibliotecas(s).then(l => l.filter(b => b.CollectionType !== 'playlists').sort((a, b) => pos(a) - pos(b))));

const ICONE_LIB: Record<string, string> = { movies: 'theaters', tvshows: 'live_tv', boxsets: 'collections_bookmark' };
export const iconeBiblioteca = (b: Item) => b.Name === 'Animes' ? 'video_library' : ICONE_LIB[b.CollectionType || ''] || 'video_library';

const TEMAS: [string, string][] = [['shikkoku', 'Shikkoku'], ['hisui', 'Hisui'], ['ichigo', 'Ichigo'], ['sorairo', 'Sorairo'], ['shinju', 'Shinju']];
const DESTINOS = [
  { aba: '' as const, tela: 'inicio', rot: 'Início', ic: 'home' },
  { aba: 'busca' as const, tela: 'busca', rot: 'Buscar', ic: 'search' },
  { aba: 'fav' as const, tela: 'fav', rot: 'Favoritos', ic: 'favorite' },
];

function Menu({ s, fechar }: { s: Sessao; fechar: () => void }) {
  const [lista, setLista] = useState<Item[]>([]);
  const [tema, setTema] = useState(document.documentElement.dataset.tema || 'shikkoku');
  const painel = useRef<HTMLDivElement>(null);
  useEffect(() => { listaBibliotecas(s).then(setLista).catch(() => null); }, []);
  useEffect(() => {
    painel.current?.querySelector<HTMLElement>('button')?.focus();
    const tecla = (e: KeyboardEvent) => { if (e.key === 'Escape' || e.keyCode === 10009 || e.keyCode === 461) { e.preventDefault(); e.stopPropagation(); fechar(); } };
    addEventListener('keydown', tecla, true);
    return () => removeEventListener('keydown', tecla, true);
  }, []);
  const trocarTema = (t: string) => { document.documentElement.dataset.tema = t; localStorage.setItem('heisuca.tema', t); setTema(t); };
  const ir = (f: () => void) => () => { fechar(); f(); };
  return (
    <div class="menu-fundo" onClick={e => { if (e.target === e.currentTarget) fechar(); }}>
      <div class="menu-painel" role="dialog" aria-label="Menu" ref={painel}>
        <div class="menu-cabeca">
          <span class="avatar grande" aria-hidden="true">{s.nome.slice(0, 1).toUpperCase()}</span>
          <strong>{s.nome}</strong>
          <button data-foco class="menu-fechar" aria-label="Fechar" onClick={fechar}><Icone nome="close" /></button>
        </div>
        <p class="menu-secao">Bibliotecas</p>
        {lista.map(b => (
          <button data-foco class="menu-item" key={b.Id} onClick={ir(() => irBiblioteca(b.Id))}>
            <Icone nome={iconeBiblioteca(b)} /><span>{b.Name}</span><Icone nome="chevron_right" />
          </button>
        ))}
        <p class="menu-secao">Conta</p>
        <button data-foco class="menu-item" onClick={ir(() => irAba('pedidos'))}><Icone nome="playlist_add_check" /><span>Meus pedidos</span><Icone nome="chevron_right" /></button>
        <div class="menu-temas" role="group" aria-label="Tema">
          <Icone nome="palette" />
          {TEMAS.map(([id, nome]) => (
            <button data-foco key={id} class={id === tema ? 'tema-bola ativa' : 'tema-bola'} data-tema-amostra={id} aria-pressed={id === tema}
              title={nome} aria-label={`Tema ${nome}`} onClick={() => trocarTema(id)} />
          ))}
        </div>
        <button data-foco class="menu-item" onClick={() => { sairDoSeerr(s).finally(() => { sair(); location.hash = ''; location.reload(); }); }}>
          <Icone nome="logout" /><span>Sair</span>
        </button>
      </div>
    </div>
  );
}

export function Navegacao({ s, r, rolado = true }: { s: Sessao; r: Rota; rolado?: boolean }) {
  const [aberto, setAberto] = useState(false);
  const botao = useRef<HTMLButtonElement>(null);
  const fechar = () => { setAberto(false); botao.current?.focus(); };
  return (
    <>
      <header class={rolado ? 'topo rolado' : 'topo'}>
        <button data-foco class="marca-texto pequena" onClick={() => irAba('')} aria-label="Heisuca, Início">HEISUCA</button>
        <nav class="topo-links" aria-label="Principal">
          {DESTINOS.map(d => (
            <button data-foco key={d.tela} class={r.tela === d.tela ? 'aba ativa' : 'aba'} aria-current={r.tela === d.tela ? 'page' : undefined} onClick={() => irAba(d.aba)}>
              <Icone nome={d.ic} cheio={r.tela === d.tela} /><span>{d.rot}</span>
            </button>
          ))}
        </nav>
        <button data-foco ref={botao} class="avatar-botao" aria-label="Abrir menu" aria-haspopup="dialog" aria-expanded={aberto} onClick={() => setAberto(true)}>
          <span class="avatar" aria-hidden="true">{s.nome.slice(0, 1).toUpperCase()}</span>
        </button>
      </header>
      <nav class="abas-baixo" aria-label="Principal">
        {DESTINOS.map(d => (
          <button key={d.tela} class={r.tela === d.tela ? 'aba-baixo ativa' : 'aba-baixo'} aria-current={r.tela === d.tela ? 'page' : undefined} onClick={() => irAba(d.aba)}>
            <span class="aba-pilula"><Icone nome={d.ic} cheio={r.tela === d.tela} /></span><span>{d.rot}</span>
          </button>
        ))}
      </nav>
      {aberto && <Menu s={s} fechar={fechar} />}
    </>
  );
}
