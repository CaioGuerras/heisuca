import { capa, type Item, type Sessao } from '../api/jellyfin';

// só ponteiro que se mexeu de verdade: na TV o cartão desliza para baixo do ponteiro parado (Magic Remote da LG) e o
// mouseenter trocaria o destaque sozinho
let px = -1, py = -1;
const mexeu = (ev: MouseEvent) => { const m = ev.clientX !== px || ev.clientY !== py; px = ev.clientX; py = ev.clientY; return m; };

export function Fileira({ s, titulo, itens, aoFocar, aoAbrir }: { s: Sessao; titulo: string; itens: Item[]; aoFocar: (i: Item) => void; aoAbrir: (i: Item) => void }) {
  if (!itens.length) return null;
  return (
    <section class="fileira">
      <h2>{titulo}</h2>
      <div class="fileira-trilho">
        {itens.map(i => {
          const progresso = i.UserData?.PlayedPercentage;
          const sub = i.Type === 'Episode' ? `${i.SeriesName} · T${i.ParentIndexNumber}E${i.IndexNumber}` : i.ProductionYear;
          return (
            <button data-foco class="cartao" key={i.Id} onFocus={() => aoFocar(i)} onMouseMove={ev => mexeu(ev) && aoFocar(i)} onClick={() => aoAbrir(i)} title={i.Name}>
              <img loading="lazy" decoding="async" src={capa(s, i)} alt="" />
              {progresso ? <span class="progresso"><span style={{ width: `${progresso}%` }} /></span> : null}
              <span class="cartao-nome">{i.Type === 'Episode' ? i.SeriesName : i.Name}</span>
              <span class="cartao-sub">{sub}</span>
            </button>
          );
        })}
      </div>
    </section>
  );
}
