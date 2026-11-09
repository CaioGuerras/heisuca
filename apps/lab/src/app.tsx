// Casca do Lume: barra de vidro em cima (computador) e abas embaixo (celular), paleta de comandos (⌘K ou /),
// atalhos (?), troca de tema e a mesma continuidade do Heisuca (a arte do cartão vira o fundo do título e volta).
import { useEffect, useState } from 'preact/hooks';
import { quandoExpirar, type Sessao } from '@w/api/servidor';
import { esquecerSessao, sessaoAtual } from '@w/api/contas';
import { Aviso } from '@w/comp/Aviso';
import { chaveDe, irAba, useRota, type Rota } from '@w/rota';
import { lembrarToques, trocarComArte, trocarDeVolta } from '@w/anim/continuidade';
import { ehRetorno } from '@w/anim/rolagem';
import { sobDemanda } from '@w/sobDemanda';
import { Marca } from './comp/Marca';
import { Ic } from './comp/Icone';
import { Paleta } from './comp/Paleta';
import { Atalhos } from './comp/Atalhos';
import { MenuTema } from './comp/MenuTema';
import { Entrada } from './telas/Entrada';
import { Inicio } from './telas/Inicio';
import { Explorar } from './telas/Explorar';
import { Lista } from './telas/Lista';

const Titulo = sobDemanda(() => import('./telas/Titulo'), 'Titulo');
const Player = sobDemanda(() => import('@w/telas/Player'), 'Player');

export function App() {
  const [s, setS] = useState<Sessao | null>(sessaoAtual);
  useEffect(() => {
    quandoExpirar(() => { esquecerSessao(); setS(null); });
    return () => quandoExpirar(null);
  }, []);
  if (!s) return <Entrada pronto={setS} />;
  return <Casca key={`${s.servidor}|${s.usuarioId}`} s={s} sair={() => { esquecerSessao(); setS(null); location.hash = ''; }} />;
}

const ABAS: { id: string; nome: string; ic: string; ic2?: string; ativa: (r: Rota) => boolean; ir: () => void }[] = [
  { id: 'inicio', nome: 'Início', ic: 'home', ativa: r => r.tela === 'inicio', ir: () => irAba('') },
  { id: 'explorar', nome: 'Explorar', ic: 'explore', ativa: r => r.tela === 'biblioteca', ir: () => irAba('b') },
  { id: 'lista', nome: 'Minha lista', ic: 'bookmark', ic2: 'bookmark-fill', ativa: r => r.tela === 'fav', ir: () => irAba('fav') },
];

function Casca({ s, sair }: { s: Sessao; sair: () => void }) {
  useEffect(() => lembrarToques(), []);
  const r = useRota((nova, velha, aplicar) => {
    if (nova.tela === 'ver' || velha.tela === 'ver' || chaveDe(nova) === chaveDe(velha)) return false;
    if (nova.tela === 'titulo' && trocarComArte(aplicar)) return true;
    if (velha.tela === 'titulo' && ehRetorno() && trocarDeVolta(aplicar)) return true;
    return false;
  });
  const [paleta, setPaleta] = useState(false);
  const [atalhos, setAtalhos] = useState(false);
  const [rolou, setRolou] = useState(false);

  useEffect(() => {
    const ocioso = (window as unknown as { requestIdleCallback?: (f: () => void) => void }).requestIdleCallback || ((f: () => void) => setTimeout(f, 1500));
    ocioso(() => { Titulo.pre(); Player.pre(); });
    const rolar = () => setRolou(scrollY > 8);
    addEventListener('scroll', rolar, { passive: true });
    return () => removeEventListener('scroll', rolar);
  }, []);

  // atalhos globais (fora de campos de texto e fora do player, que tem os dele)
  useEffect(() => {
    const tecla = (e: KeyboardEvent) => {
      if (r.tela === 'ver') return;
      const alvo = e.target as HTMLElement | null;
      const digitando = !!alvo && (alvo.isContentEditable || /^(INPUT|TEXTAREA|SELECT)$/.test(alvo.tagName));
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') { e.preventDefault(); setPaleta(p => !p); return; }
      if (digitando || e.metaKey || e.ctrlKey || e.altKey) return;
      if (e.key === '/') { e.preventDefault(); setPaleta(true); }
      else if (e.key === '?') { e.preventDefault(); setAtalhos(true); }
      else if (e.key === 'g') {
        const proxima = (k: KeyboardEvent) => {
          removeEventListener('keydown', proxima, true);
          if (k.key === 'i') irAba(''); else if (k.key === 'e') irAba('b'); else if (k.key === 'l') irAba('fav');
        };
        addEventListener('keydown', proxima, true);
        setTimeout(() => removeEventListener('keydown', proxima, true), 1200);
      }
    };
    addEventListener('keydown', tecla);
    return () => removeEventListener('keydown', tecla);
  }, [r.tela]);

  if (r.tela === 'ver') return <div class="casca tela-ver"><Player key={r.id} s={s} id={r.id} inicio={r.inicio} /><Aviso /></div>;
  const tela = r.tela === 'titulo' ? <Titulo key={r.id} s={s} id={r.id} />
    : r.tela === 'biblioteca' ? <Explorar s={s} biblioteca={r.id} />
    : r.tela === 'fav' ? <Lista s={s} />
    : <Inicio s={s} />;
  return (
    <div class={`casca tela-${r.tela}${rolou ? ' rolou' : ''}`}>
      <a class="pular" href="#conteudo">Pular para o conteúdo</a>
      <header class="barra">
        <a class="barra-marca" href="#/" onClick={e => { e.preventDefault(); irAba(''); }} aria-label="Lume, início"><Marca /></a>
        <nav class="barra-abas" aria-label="Principal">
          {ABAS.map(a => <a key={a.id} href={a.id === 'inicio' ? '#/' : a.id === 'explorar' ? '#/b' : '#/fav'}
            class={a.ativa(r) ? 'ativa' : ''} aria-current={a.ativa(r) ? 'page' : undefined}
            onClick={e => { e.preventDefault(); a.ir(); }}>{a.nome}</a>)}
        </nav>
        <div class="barra-acoes">
          <button class="barra-busca" onClick={() => setPaleta(true)} aria-label="Buscar (atalho: /)" aria-keyshortcuts="Control+K /">
            <Ic n="search" t={20} /><span>Buscar</span><kbd>⌘K</kbd>
          </button>
          <MenuTema />
          <MenuConta s={s} sair={sair} atalhos={() => setAtalhos(true)} />
        </div>
      </header>
      <main id="conteudo" class="palco" key={chaveDe(r)}>{tela}</main>
      <nav class="abas" aria-label="Principal">
        {ABAS.map(a => <a key={a.id} href="#" class={a.ativa(r) ? 'ativa' : ''} aria-current={a.ativa(r) ? 'page' : undefined}
          onClick={e => { e.preventDefault(); a.ir(); }}><Ic n={a.ativa(r) && a.ic2 ? a.ic2 : a.ic} t={24} /><span>{a.nome}</span></a>)}
        <a href="#" onClick={e => { e.preventDefault(); setPaleta(true); }}><Ic n="search" t={24} /><span>Buscar</span></a>
      </nav>
      <Paleta s={s} aberta={paleta} fechar={() => setPaleta(false)} atalhos={() => { setPaleta(false); setAtalhos(true); }} />
      <Atalhos aberta={atalhos} fechar={() => setAtalhos(false)} />
      <Aviso />
    </div>
  );
}

function MenuConta({ s, sair, atalhos }: { s: Sessao; sair: () => void; atalhos: () => void }) {
  const [aberto, setAberto] = useState(false);
  useEffect(() => {
    if (!aberto) return;
    const fora = (e: Event) => { if (!(e.target as HTMLElement).closest('.conta')) setAberto(false); };
    const esc = (e: KeyboardEvent) => { if (e.key === 'Escape') setAberto(false); };
    addEventListener('pointerdown', fora); addEventListener('keydown', esc);
    return () => { removeEventListener('pointerdown', fora); removeEventListener('keydown', esc); };
  }, [aberto]);
  return (
    <div class="conta">
      <button class="avatar" aria-haspopup="menu" aria-expanded={aberto} onClick={() => setAberto(a => !a)} aria-label={`Conta de ${s.nome}`}>
        {(s.nome || '?').slice(0, 1).toUpperCase()}
      </button>
      {aberto && (
        <div class="menu" role="menu">
          <p class="menu-quem">{s.nome}<small>{s.nomeServidor || new URL(s.servidor).host}</small></p>
          <button role="menuitem" onClick={() => { setAberto(false); atalhos(); }}><Ic n="keyboard" t={20} />Atalhos do teclado</button>
          <button role="menuitem" onClick={sair}><Ic n="logout" t={20} />Sair</button>
        </div>
      )}
    </div>
  );
}
