// Início: herói (troca só quando a pessoa pede), Continuar assistindo, Em alta com ranking, novidades por biblioteca
// e Em breve. Os dados vêm do mesmo preparo do Heisuca (crítico primeiro, secundário depois).
import { useEffect, useState } from 'preact/hooks';
import { fundo, hashDe, logo, type EmBreve, type Item, type Sessao } from '@w/api/servidor';
import { Imagem } from '@w/comp/Imagem';
import { carregarSecundario, prepararInicio, type DadosInicio } from '@w/dados/inicio';
import { irAba, irTitulo, irVer } from '@w/rota';
import { Paisagem, Poster, nota, duracao } from '../comp/Cartao';
import { Fileira, FileiraFantasma } from '../comp/Fileira';
import { Ic } from '../comp/Icone';

export function Inicio({ s }: { s: Sessao }) {
  const [d, setD] = useState<DadosInicio | null>(null);
  const [erro, setErro] = useState(false);
  useEffect(() => {
    let vivo = true;
    prepararInicio(s).then(c => {
      if (!vivo) return; setD(c);
      carregarSecundario(s).then(x => { if (vivo) setD(a => a && { ...a, ...x }); });
    }).catch(() => vivo && setErro(true));
    return () => { vivo = false; };
  }, []);
  if (erro) return <div class="vazio"><Ic n="info" t={32} /><p>O servidor não respondeu.</p><button class="botao" onClick={() => location.reload()}>Tentar de novo</button></div>;
  return (
    <div class="inicio">
      {d ? <Heroi s={s} itens={d.destaque} /> : <div class="heroi fantasma" aria-hidden="true" />}
      <div class="fileiras">
        {!d ? <><FileiraFantasma tipo="paisagem" /><FileiraFantasma /></> : <>
          {d.continuar.length > 0 && <Fileira titulo="Continuar assistindo" tipo="paisagem">
            {d.continuar.map((i, k) => <Paisagem key={i.Id} s={s} i={i} ordem={k} />)}</Fileira>}
          {d.emAlta.itens.length > 0 && <Fileira titulo={d.emAlta.titulo || 'Em alta'} sub="nesta semana">
            {d.emAlta.itens.slice(0, 10).map((i, k) => <div class="ranking" key={i.Id}><span class="ranking-n" aria-hidden="true">{k + 1}</span><Poster s={s} i={i} ordem={k} /></div>)}
          </Fileira>}
          {d.porBiblioteca.map(b => <Fileira key={b.biblioteca.Id} titulo={`Chegaram em ${b.biblioteca.Name}`}
            acao={{ texto: 'Ver tudo', href: `#/b/${b.biblioteca.Id}` }}>{b.itens.map((i, k) => <Poster key={i.Id} s={s} i={i} ordem={k} />)}</Fileira>)}
          {d.emBreve.movie.length > 0 && <Fileira titulo="Em breve nos cinemas">{d.emBreve.movie.map(e => <CartaoEmBreve key={e.nome} e={e} />)}</Fileira>}
          {d.emBreve.tv.length > 0 && <Fileira titulo="Novas temporadas a caminho">{d.emBreve.tv.map(e => <CartaoEmBreve key={e.nome} e={e} />)}</Fileira>}
          {!d.continuar.length && !d.emAlta.itens.length && !d.porBiblioteca.length && <div class="vazio">
            <p>Ainda não há nada por aqui.</p><button class="botao" onClick={() => irAba('b')}>Explorar o acervo</button></div>}
        </>}
      </div>
    </div>
  );
}

function CartaoEmBreve({ e }: { e: EmBreve }) {
  const dentro = <><span class="cartao-arte"><Imagem src={e.capa} /></span><span class="cartao-nome">{e.nome}</span><span class="cartao-meta">{e.sub}</span></>;
  return e.jf ? <a class="cartao poster" href={`#/t/${e.jf}`} onClick={x => { x.preventDefault(); irTitulo(e.jf!); }}>{dentro}</a>
    : <div class="cartao poster embreve">{dentro}</div>;
}

// herói: a pessoa escolhe o próximo (setas, miniaturas ou deslizando no celular); nada troca sozinho
function Heroi({ s, itens }: { s: Sessao; itens: Item[] }) {
  const [k, setK] = useState(0);
  const [toque, setToque] = useState<number | null>(null);
  if (!itens.length) return null;
  const i = itens[k % itens.length];
  const ir = (n: number) => setK((n + itens.length) % itens.length);
  const tipo = i.Type === 'Series' ? 'Série' : 'Filme';
  const meta = [tipo, i.ProductionYear, i.OfficialRating, i.Type === 'Movie' ? duracao(i.RunTimeTicks) : '', i.CommunityRating ? `★ ${nota(i)}` : ''].filter(Boolean);
  return (
    <section class="heroi" aria-roledescription="destaques" aria-label="Destaques"
      onPointerDown={e => e.pointerType === 'touch' && setToque(e.clientX)}
      onPointerUp={e => { if (toque !== null && Math.abs(e.clientX - toque) > 50) ir(k + (e.clientX < toque ? 1 : -1)); setToque(null); }}>
      <div class="heroi-fundo" key={i.Id}>
        <Imagem src={fundo(s, i, 1920)} hash={hashDe(s, i, 'Backdrop') || hashDe(s, i, 'Primary')} prioridade />
      </div>
      <div class="heroi-veu" aria-hidden="true" />
      <div class="heroi-texto" key={`t-${i.Id}`} aria-live="polite">
        {i.ImageTags?.Logo ? <h1 class="heroi-logo"><img src={logo(s, i, 640)} alt={i.Name} /></h1> : <h1 class="heroi-nome">{i.Name}</h1>}
        <p class="heroi-meta">{meta.map((m, n) => <span key={n}>{m}</span>)}</p>
        {i.Overview && <p class="heroi-sinopse">{i.Overview}</p>}
        <div class="heroi-botoes">
          <button class="botao primario" onClick={() => i.Type === 'Series' ? irTitulo(i.Id, i) : irVer(i.Id, i.UserData?.PlaybackPositionTicks)}>
            <Ic n="play_arrow-fill" t={22} />{i.Type === 'Series' ? 'Ver episódios' : i.UserData?.PlaybackPositionTicks ? 'Continuar' : 'Assistir'}</button>
          <button class="botao vidro" onClick={() => irTitulo(i.Id, i)}><Ic n="info" t={20} />Detalhes</button>
        </div>
      </div>
      {itens.length > 1 && <div class="heroi-trocar">
        <button class="redondo vidro" onClick={() => ir(k - 1)} aria-label="Destaque anterior"><Ic n="chevron_left" t={24} /></button>
        <ol class="heroi-pontos">{itens.map((x, n) => <li key={x.Id}><button aria-label={`${n + 1} de ${itens.length}: ${x.Name}`} aria-current={n === k}
          class={n === k ? 'ativo' : ''} onClick={() => setK(n)} /></li>)}</ol>
        <button class="redondo vidro" onClick={() => ir(k + 1)} aria-label="Próximo destaque"><Ic n="chevron_right" t={24} /></button>
      </div>}
    </section>
  );
}
