import { useState } from 'preact/hooks';
import { capa, miniatura, marcarAssistido, marcarFavorito, type EmBreve, type Item, type Sessao } from '../api/jellyfin';
import { Icone } from './Icone';

let px = -1, py = -1;
const mexeu = (ev: MouseEvent) => {
  const m = ev.clientX !== px || ev.clientY !== py;
  px = ev.clientX; py = ev.clientY;
  return m;
};

export type AcaoContexto = { item: Item; x: number; y: number };

export function CartaoContinuar({
  s, i, aoAbrir, aoFocar, emContexto,
}: {
  s: Sessao; i: Item; aoAbrir: (i: Item) => void; aoFocar?: (i: Item) => void; emContexto?: (ev: MouseEvent, i: Item) => void;
}) {
  const progresso = i.UserData?.PlayedPercentage;
  const titulo = i.Type === 'Episode' ? (i.SeriesName || i.Name) : i.Name;
  const sub = i.Type === 'Episode'
    ? `T${i.ParentIndexNumber ?? 1}:E${i.IndexNumber ?? 1} · ${i.Name}`
    : (i.ProductionYear ? String(i.ProductionYear) : '');

  return (
    <button
      data-foco
      class="cartao cartao-continuar"
      onFocus={() => aoFocar?.(i)}
      onMouseMove={ev => aoFocar && mexeu(ev) && aoFocar(i)}
      onClick={() => aoAbrir(i)}
      onContextMenu={ev => {
        if (emContexto) {
          ev.preventDefault();
          emContexto(ev, i);
        }
      }}
      title={`${titulo} - ${sub}`}
    >
      <div class="cartao-continuar-thumb">
        <img loading="lazy" decoding="async" src={miniatura(s, i, 480)} alt="" />
        <div class="cartao-continuar-play" aria-hidden="true">
          <Icone nome="play_arrow" cheio tamanho={32} />
        </div>
        {progresso ? (
          <span class="progresso">
            <span style={{ width: `${progresso}%` }} />
          </span>
        ) : null}
      </div>
      <span class="cartao-nome">{titulo}</span>
      <span class="cartao-sub">{sub}</span>
    </button>
  );
}

export function Cartao({
  s, i, aoFocar, aoAbrir, numero, emContexto,
}: {
  s: Sessao; i: Item; aoFocar?: (i: Item) => void; aoAbrir: (i: Item) => void; numero?: number; emContexto?: (ev: MouseEvent, i: Item) => void;
}) {
  const progresso = i.UserData?.PlayedPercentage;
  const sub = i.Type === 'Episode' ? `${i.SeriesName} · T${i.ParentIndexNumber}E${i.IndexNumber}` : (i.ProductionYear ? String(i.ProductionYear) : '');

  return (
    <button
      data-foco
      class={numero ? 'cartao com-numero' : 'cartao'}
      onFocus={() => aoFocar?.(i)}
      onMouseMove={ev => aoFocar && mexeu(ev) && aoFocar(i)}
      onClick={() => aoAbrir(i)}
      onContextMenu={ev => {
        if (emContexto) {
          ev.preventDefault();
          emContexto(ev, i);
        }
      }}
      title={i.Name}
    >
      {numero ? <span class="cartao-numero" aria-hidden="true">{numero}</span> : null}
      <div class="cartao-poster">
        <img loading="lazy" decoding="async" src={capa(s, i, 360)} alt="" />
        {progresso ? (
          <span class="progresso">
            <span style={{ width: `${progresso}%` }} />
          </span>
        ) : null}
        {i.UserData?.Played && (
          <span class="cartao-visto" title="Assistido">
            <Icone nome="check_circle" cheio tamanho={18} />
          </span>
        )}
        {i.UserData?.IsFavorite && (
          <span class="cartao-fav" title="Favorito">
            <Icone nome="favorite" cheio tamanho={18} />
          </span>
        )}
      </div>
      <span class="cartao-nome">{i.Type === 'Episode' ? i.SeriesName : i.Name}</span>
      <span class="cartao-sub">{sub}</span>
    </button>
  );
}

export function MenuContexto({
  s, ctx, fechar, aoAtualizar,
}: {
  s: Sessao; ctx: AcaoContexto; fechar: () => void; aoAtualizar?: () => void;
}) {
  const [assistido, setAssistido] = useState(!!ctx.item.UserData?.Played);
  const [favorito, setFavorito] = useState(!!ctx.item.UserData?.IsFavorite);

  const alternarAssistido = async () => {
    const novo = !assistido;
    setAssistido(novo);
    if (ctx.item.UserData) ctx.item.UserData.Played = novo;
    await marcarAssistido(s, ctx.item.Id, novo);
    aoAtualizar?.();
    fechar();
  };

  const alternarFavorito = async () => {
    const novo = !favorito;
    setFavorito(novo);
    if (ctx.item.UserData) ctx.item.UserData.IsFavorite = novo;
    await marcarFavorito(s, ctx.item.Id, novo);
    aoAtualizar?.();
    fechar();
  };

  return (
    <div class="contexto-fundo" onClick={fechar}>
      <div
        class="contexto-menu"
        style={{
          top: `${Math.min(window.innerHeight - 120, ctx.y)}px`,
          left: `${Math.min(window.innerWidth - 200, ctx.x)}px`,
        }}
        onClick={e => e.stopPropagation()}
      >
        <button type="button" class="contexto-item" onClick={alternarAssistido}>
          <Icone nome={assistido ? 'check_box' : 'check_box_outline_blank'} />
          <span>{assistido ? 'Desmarcar visto' : 'Marcar como visto'}</span>
        </button>
        <button type="button" class="contexto-item" onClick={alternarFavorito}>
          <Icone nome={favorito ? 'favorite' : 'favorite_border'} cheio={favorito} />
          <span>{favorito ? 'Remover dos favoritos' : 'Favoritar'}</span>
        </button>
      </div>
    </div>
  );
}

export function Fileira({
  s, titulo, itens, aoFocar, aoAbrir, top10, continuar, aoAtualizar,
}: {
  s: Sessao; titulo: string; itens: Item[]; aoFocar?: (i: Item) => void; aoAbrir: (i: Item) => void;
  top10?: boolean; continuar?: boolean; aoAtualizar?: () => void;
}) {
  const [ctx, setCtx] = useState<AcaoContexto | null>(null);
  if (!itens.length) return null;

  const handleContexto = (ev: MouseEvent, item: Item) => {
    setCtx({ item, x: ev.clientX, y: ev.clientY });
  };

  return (
    <section class={top10 ? 'fileira top10' : continuar ? 'fileira fileira-continuar' : 'fileira'}>
      <h2>{titulo}</h2>
      <div class="fileira-trilho">
        {itens.map((i, n) => {
          if (continuar) {
            return (
              <CartaoContinuar
                key={i.Id}
                s={s}
                i={i}
                aoAbrir={aoAbrir}
                aoFocar={aoFocar}
                emContexto={handleContexto}
              />
            );
          }
          return (
            <Cartao
              key={i.Id}
              s={s}
              i={i}
              aoFocar={aoFocar}
              aoAbrir={aoAbrir}
              numero={top10 ? n + 1 : undefined}
              emContexto={handleContexto}
            />
          );
        })}
      </div>
      {ctx && <MenuContexto s={s} ctx={ctx} fechar={() => setCtx(null)} aoAtualizar={aoAtualizar} />}
    </section>
  );
}

export function FileiraEmBreve({
  titulo, itens, aoAbrir,
}: {
  titulo: string; itens: EmBreve[]; aoAbrir: (e: EmBreve) => void;
}) {
  if (!itens.length) return null;
  return (
    <section class="fileira">
      <h2>{titulo}</h2>
      <div class="fileira-trilho">
        {itens.map(e => (
          <button data-foco class="cartao" key={`${e.tipo}${e.jf || e.tmdb}`} onClick={() => aoAbrir(e)} title={e.nome}>
            <div class="cartao-poster">
              <img loading="lazy" decoding="async" src={e.capa} alt="" />
              <span class="cartao-selo">{e.jf ? 'Novo episódio' : 'Em breve'}</span>
            </div>
            <span class="cartao-nome">{e.nome}</span>
            <span class="cartao-sub">{e.sub}</span>
          </button>
        ))}
      </div>
    </section>
  );
}

export function Grade({
  s, itens, aoAbrir, aoAtualizar,
}: {
  s: Sessao; itens: Item[]; aoAbrir: (i: Item) => void; aoAtualizar?: () => void;
}) {
  const [ctx, setCtx] = useState<AcaoContexto | null>(null);
  const handleContexto = (ev: MouseEvent, item: Item) => {
    setCtx({ item, x: ev.clientX, y: ev.clientY });
  };

  return (
    <>
      <div class="grade">
        {itens.map(i => (
          <Cartao
            key={i.Id}
            s={s}
            i={i}
            aoAbrir={aoAbrir}
            emContexto={handleContexto}
          />
        ))}
      </div>
      {ctx && <MenuContexto s={s} ctx={ctx} fechar={() => setCtx(null)} aoAtualizar={aoAtualizar} />}
    </>
  );
}
