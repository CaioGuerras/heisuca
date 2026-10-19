// Topo flutuante e ilha inferior (PLANO §4; ref/vidhub/…home_topo, …foto67, …favoritos).
//  Topo: SEM barra. À esquerda a pílula [foto + nome do servidor] (abre "Trocar servidor"); à direita a busca redonda.
//        O meio recebe a logo do título quando a tela rola (a home passa em `centro`). Sem 3 pontinhos.
//  Ilha: flutuante, centralizada, de vidro: Início · Biblioteca · Favoritos · [foto] Usuário.
import type { ComponentChildren } from 'preact';
import { useRef } from 'preact/hooks';
import { fotoUsuario, type Sessao } from '../api/jellyfin';
import { irAba, ultimaBiblioteca, type Rota } from '../rota';
import { Icone } from './Icone';
import './navegacao.css';

export function Avatar({ s, tamanho = 28 }: { s: Sessao; tamanho?: number }) {
  const f = fotoUsuario(s, tamanho * 3);
  return f ? <img class="avatar" src={f} alt="" width={tamanho} height={tamanho} />
    : <span class="avatar avatar-vazio" style={{ width: tamanho, height: tamanho }} aria-hidden="true"><Icone nome="person" cheio tamanho={tamanho * 0.7} /></span>;
}

export function Topo({ s, centro, aoServidor, fundo = false, semBusca = false }:
  { s: Sessao; centro?: ComponentChildren; aoServidor: () => void; fundo?: boolean; semBusca?: boolean }) {
  return (
    <header class={`topo${fundo ? ' com-fundo' : ''}`}>
      <button class="topo-servidor" onClick={aoServidor} aria-label={`Servidor ${s.nomeServidor || ''}. Trocar de servidor`}>
        <Avatar s={s} tamanho={28} /><span class="uma-linha">{s.nomeServidor || 'Servidor'}</span>
      </button>
      <div class="topo-centro">{centro}</div>
      {!semBusca ? <button class="redondo topo-busca" onClick={() => irAba('busca')} aria-label="Buscar"><Icone nome="search" tamanho={24} /></button>
        : <span class="topo-vazio" />}
    </header>
  );
}

export function Ilha({ s, r, aoUsuario }: { s: Sessao; r: Rota; aoUsuario: (el: HTMLElement) => void }) {
  const eu = useRef<HTMLButtonElement>(null);
  const lib = ultimaBiblioteca();
  const item = (ativo: boolean, icone: string, rotulo: string, ir: () => void) => (
    <button class={`ilha-item${ativo ? ' ativo' : ''}`} aria-current={ativo ? 'page' : undefined} onClick={ir}>
      <Icone nome={icone} cheio={ativo} tamanho={24} /><span>{rotulo}</span>
    </button>
  );
  const nome = s.nome.split(/[\s._-]/)[0] || s.nome;
  return (
    <nav class="ilha" aria-label="Navegação">
      {item(r.tela === 'inicio', 'home', 'Início', () => irAba(''))}
      {item(r.tela === 'biblioteca', 'video_library', 'Biblioteca', () => irAba(lib ? `b/${lib}` : 'b'))}
      {item(r.tela === 'fav', 'favorite', 'Favoritos', () => irAba('fav'))}
      <button ref={eu} class="ilha-item ilha-eu" onClick={() => eu.current && aoUsuario(eu.current)} aria-haspopup="dialog" aria-label={`Usuário ${s.nome}`}>
        <Avatar s={s} tamanho={22} /><span class="uma-linha">{nome}</span>
      </button>
    </nav>
  );
}
