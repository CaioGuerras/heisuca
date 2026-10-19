// A casca do app: abertura → (entrada) → transição → telas (PLANO §3.1). A logo voa entre as três primeiras.
import type { JSX } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import { quandoExpirar, type EmBreve, type Sessao } from './api/jellyfin';
import { esquecerSessao, guardarSessao, sessaoAtual, type Servidor } from './api/servidor';
import { sairDoSeerr } from './api/seerr';
import { Aviso } from './comp/Aviso';
import { MenuContexto } from './comp/MenuContexto';
import { MenuUsuario } from './comp/MenuUsuario';
import { Ilha } from './comp/Navegacao';
import { FolhaPedido, type Alvo } from './comp/Pedido';
import { TrocarServidor } from './comp/TrocarServidor';
import { registrarServidores } from './estado/casca';
import { useRota } from './rota';
import { Abertura } from './telas/Abertura';
import { Busca } from './telas/Busca';
import { Entrada } from './telas/Entrada';
import { Favoritos } from './telas/Favoritos';
import { Inicio } from './telas/Inicio';
import { EmConstrucao } from './telas/Pagina';
import './comp/instalar';
import { Player } from './telas/Player';
import { Transicao } from './telas/Transicao';
import './estilo/listas.css';

type Fase = { nome: 'abertura' } | { nome: 'entrada'; de?: DOMRect | null; srv?: Servidor | null; volta?: boolean } | { nome: 'transicao'; de?: DOMRect | null; clique?: number } | { nome: 'casca' };
const ABRIU = 'heisuca.abriu';
const abriu = () => { try { return sessionStorage.getItem(ABRIU) === '1'; } catch { return true; } };

export function App() {
  const [s, setS] = useState<Sessao | null>(sessaoAtual);
  // sessão salva + abertura já vista nesta aba: direto às telas; senão abertura (e a transição, se há sessão)
  const [fase, setFase] = useState<Fase>(() => !abriu() ? { nome: 'abertura' } : s ? { nome: 'casca' } : { nome: 'entrada' });
  useEffect(() => { quandoExpirar(() => { esquecerSessao(); setS(null); setFase({ nome: 'entrada' }); }); return () => quandoExpirar(null); }, []);

  if (fase.nome === 'abertura') return <Abertura fim={de => {
    try { sessionStorage.setItem(ABRIU, '1'); } catch { /* nada */ }
    setFase(s ? { nome: 'transicao', de } : { nome: 'entrada', de });
  }} />;
  if (fase.nome === 'entrada' || !s) return <Entrada de={fase.nome === 'entrada' ? fase.de : null} servidorInicial={fase.nome === 'entrada' ? fase.srv : undefined}
    pronto={(nova, de, clique) => { setS(nova); setFase({ nome: 'transicao', de, clique }); }}
    voltar={fase.nome === 'entrada' && fase.volta && s ? () => setFase({ nome: 'casca' }) : undefined} />;
  return (
    <>
      <Casca key={`${s.servidor}|${s.usuarioId}`} s={s}
        trocar={nova => { setS(nova); setFase({ nome: 'transicao', de: null }); }}
        atualizar={nova => { guardarSessao(nova); setS(nova); }}
        entrar={srv => setFase({ nome: 'entrada', srv, volta: true })}
        sair={() => { sairDoSeerr(s).finally(() => { esquecerSessao(); setS(null); setFase({ nome: 'entrada' }); }); }} />
      {fase.nome === 'transicao' && <Transicao s={s} de={fase.de} clique={fase.clique} fim={() => setFase({ nome: 'casca' })} />}
    </>
  );
}

function Casca({ s, trocar, atualizar, entrar, sair }: { s: Sessao; trocar: (s: Sessao) => void; atualizar: (s: Sessao) => void;
  entrar: (srv: Servidor | null) => void; sair: () => void }) {
  const r = useRota();
  const [menu, setMenu] = useState<HTMLElement | null>(null);
  const [servidores, setServidores] = useState(false);
  const [pedido, setPedido] = useState<Alvo | null>(null);
  useEffect(() => { registrarServidores(() => setServidores(true)); return () => registrarServidores(null); }, []);
  useEffect(() => { setMenu(null); }, [r]);
  const pedirEmBreve = (e: EmBreve) => { if (e.tmdb) setPedido({ tipo: e.tipo, id: e.tmdb, nome: e.nome }); };

  const comIlha = r.tela === 'inicio' || r.tela === 'biblioteca' || r.tela === 'fav';
  const tela = r.tela === 'ver' ? <Player key={r.id} s={s} id={r.id} inicio={r.inicio} />
    : r.tela === 'titulo' ? <EmConstrucao titulo="Título" />
    : r.tela === 'biblioteca' ? <EmConstrucao titulo="Biblioteca" />
    : r.tela === 'fav' ? <Favoritos s={s} />
    : r.tela === 'busca' ? <Busca s={s} />
    : r.tela === 'conta' ? <Paginas abrir={P => <P.Conta s={s} aoMudar={atualizar} />} />
    : r.tela === 'ajuda' ? <Paginas abrir={P => <P.ComoUsar s={s} />} />
    : r.tela === 'apps' ? <Paginas abrir={P => <P.Apps />} />
    : r.tela === 'sobre' ? <Paginas abrir={P => <P.Sobre />} />
    : r.tela === 'pedidos' ? <Paginas abrir={P => <P.MeusPedidos s={s} />} />
    : r.tela === 'apoiar' ? <Paginas abrir={P => <P.Apoiar />} />
    : <Inicio s={s} pedir={pedirEmBreve} />;
  return (
    <div class={`casca tela-${r.tela}${comIlha ? ' com-ilha' : ''}`}>
      {tela}
      {comIlha && <Ilha s={s} r={r} aoUsuario={setMenu} />}
      <MenuUsuario s={s} ancora={menu} fechar={() => setMenu(null)} sair={sair} />
      <TrocarServidor s={s} aberta={servidores} fechar={() => setServidores(false)} aoTrocar={trocar} aoEntrar={entrar} />
      <FolhaPedido s={s} alvo={pedido} fechar={() => setPedido(null)} />
      <MenuContexto />
      <Aviso />
    </div>
  );
}

// páginas do menu do usuário (Minha conta, Como usar, Apps, Sobre, Pedidos, Apoiar): abertas raramente, carregam sob demanda
type ModPaginas = typeof import('./telas/Paginas');
let paginas: ModPaginas | null = null;
function Paginas({ abrir }: { abrir: (P: ModPaginas) => JSX.Element }) {
  const [m, setM] = useState(paginas);
  useEffect(() => { if (!m) import('./telas/Paginas').then(x => { paginas = x; setM(x); }); }, []);
  return m ? abrir(m) : null;
}
