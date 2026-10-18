import { capa, type EmBreve, type Item, type Sessao } from '../api/jellyfin';

// só ponteiro que se mexeu de verdade: na TV o cartão desliza para baixo do ponteiro parado (Magic Remote da LG) e o
// mouseenter trocaria o destaque sozinho
let px = -1, py = -1;
const mexeu = (ev: MouseEvent) => { const m = ev.clientX !== px || ev.clientY !== py; px = ev.clientX; py = ev.clientY; return m; };

export function Cartao({ s, i, aoFocar, aoAbrir, numero }: { s: Sessao; i: Item; aoFocar?: (i: Item) => void; aoAbrir: (i: Item) => void; numero?: number }) {
  const progresso = i.UserData?.PlayedPercentage;
  const sub = i.Type === 'Episode' ? `${i.SeriesName} · T${i.ParentIndexNumber}E${i.IndexNumber}` : i.ProductionYear;
  return (
    <button data-foco class={numero ? 'cartao com-numero' : 'cartao'} onFocus={() => aoFocar?.(i)} onMouseMove={ev => aoFocar && mexeu(ev) && aoFocar(i)}
      onClick={() => aoAbrir(i)} title={i.Name}>
      {numero ? <span class="cartao-numero" aria-hidden="true">{numero}</span> : null}
      <img loading="lazy" decoding="async" src={capa(s, i)} alt="" />
      {progresso ? <span class="progresso"><span style={{ width: `${progresso}%` }} /></span> : null}
      <span class="cartao-nome">{i.Type === 'Episode' ? i.SeriesName : i.Name}</span>
      <span class="cartao-sub">{sub}</span>
    </button>
  );
}

export function Fileira({ s, titulo, itens, aoFocar, aoAbrir, top10 }: { s: Sessao; titulo: string; itens: Item[]; aoFocar?: (i: Item) => void; aoAbrir: (i: Item) => void; top10?: boolean }) {
  if (!itens.length) return null;
  return (
    <section class={top10 ? 'fileira top10' : 'fileira'}>
      <h2>{titulo}</h2>
      <div class="fileira-trilho">
        {itens.map((i, n) => <Cartao key={i.Id} s={s} i={i} aoFocar={aoFocar} aoAbrir={aoAbrir} numero={top10 ? n + 1 : undefined} />)}
      </div>
    </section>
  );
}

// Em breve: temos → abre o título; não temos → folha de pedido (mesma regra do site atual)
export function FileiraEmBreve({ titulo, itens, aoAbrir }: { titulo: string; itens: EmBreve[]; aoAbrir: (e: EmBreve) => void }) {
  if (!itens.length) return null;
  return (
    <section class="fileira">
      <h2>{titulo}</h2>
      <div class="fileira-trilho">
        {itens.map(e => (
          <button data-foco class="cartao" key={`${e.tipo}${e.jf || e.tmdb}`} onClick={() => aoAbrir(e)} title={e.nome}>
            <img loading="lazy" decoding="async" src={e.capa} alt="" />
            <span class="cartao-selo">{e.jf ? 'Novo episódio' : 'Em breve'}</span>
            <span class="cartao-nome">{e.nome}</span>
            <span class="cartao-sub">{e.sub}</span>
          </button>
        ))}
      </div>
    </section>
  );
}

export function Grade({ s, itens, aoAbrir }: { s: Sessao; itens: Item[]; aoAbrir: (i: Item) => void }) {
  return <div class="grade">{itens.map(i => <Cartao key={i.Id} s={s} i={i} aoAbrir={aoAbrir} />)}</div>;
}
