// A casca do app: abertura → (entrada) → transição → telas (PLANO §3.1). A logo voa entre as três primeiras.
import { useEffect, useState } from 'preact/hooks';
import { quandoExpirar, type EmBreve, type Sessao } from './api/jellyfin';
import { esquecerSessao, sessaoAtual, type Servidor } from './api/servidor';
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
import { Entrada } from './telas/Entrada';
import { Inicio } from './telas/Inicio';
import { EmConstrucao } from './telas/Pagina';
import { Player } from './telas/Player';
import { Transicao } from './telas/Transicao';
import './estilo/listas.css';

type Fase = { nome: 'abertura' } | { nome: 'entrada'; de?: DOMRect | null; srv?: Servidor | null; volta?: boolean } | { nome: 'transicao'; de?: DOMRect | null } | { nome: 'casca' };
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
    pronto={(nova, de) => { setS(nova); setFase({ nome: 'transicao', de }); }}
    voltar={fase.nome === 'entrada' && fase.volta && s ? () => setFase({ nome: 'casca' }) : undefined} />;
  return (
    <>
      <Casca key={`${s.servidor}|${s.usuarioId}`} s={s}
        trocar={nova => { setS(nova); setFase({ nome: 'transicao', de: null }); }}
        entrar={srv => setFase({ nome: 'entrada', srv, volta: true })}
        sair={() => { sairDoSeerr(s).finally(() => { esquecerSessao(); setS(null); setFase({ nome: 'entrada' }); }); }} />
      {fase.nome === 'transicao' && <Transicao s={s} de={fase.de} fim={() => setFase({ nome: 'casca' })} />}
    </>
  );
}

function Casca({ s, trocar, entrar, sair }: { s: Sessao; trocar: (s: Sessao) => void; entrar: (srv: Servidor | null) => void; sair: () => void }) {
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
    : r.tela === 'fav' ? <EmConstrucao titulo="Favoritos" />
    : r.tela === 'busca' ? <EmConstrucao titulo="Buscar" />
    : r.tela === 'conta' ? <EmConstrucao titulo="Minha conta" />
    : r.tela === 'ajuda' ? <EmConstrucao titulo="Como usar" />
    : r.tela === 'apps' ? <EmConstrucao titulo="Baixar os apps" />
    : r.tela === 'sobre' ? <EmConstrucao titulo="Sobre" />
    : r.tela === 'pedidos' ? <EmConstrucao titulo="Meus pedidos" />
    : r.tela === 'apoiar' ? <EmConstrucao titulo="Apoiar o Heisuca" />
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
