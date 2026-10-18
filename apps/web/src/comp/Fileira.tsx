import { capa, type Item, type Sessao } from '../api/jellyfin';

export function Fileira({ s, titulo, itens, aoFocar }: { s: Sessao; titulo: string; itens: Item[]; aoFocar: (i: Item) => void }) {
  if (!itens.length) return null;
  return (
    <section class="fileira">
      <h2>{titulo}</h2>
      <div class="fileira-trilho">
        {itens.map(i => {
          const progresso = i.UserData?.PlayedPercentage;
          const sub = i.Type === 'Episode' ? `${i.SeriesName} · T${i.ParentIndexNumber}E${i.IndexNumber}` : i.ProductionYear;
          return (
            <button data-foco class="cartao" key={i.Id} onFocus={() => aoFocar(i)} onMouseEnter={() => aoFocar(i)} title={i.Name}>
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
