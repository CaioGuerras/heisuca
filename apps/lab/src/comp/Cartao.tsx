// Cartões do Lume. As classes cartao / cartao-arte / img são as que a continuidade do Heisuca procura (a arte tocada
// voa até o fundo do título e volta para o cartão no Voltar).
import { capa, hashDe, paisagem, type Item, type Sessao } from '@w/api/servidor';
import { Imagem } from '@w/comp/Imagem';
import { progressoAssistido } from '@w/dados/progresso';
import { irTitulo, irVer } from '@w/rota';
import { Ic } from './Icone';

const ano = (i: Item) => i.ProductionYear ? String(i.ProductionYear) : '';
export const nota = (i: Item) => i.CommunityRating ? i.CommunityRating.toFixed(1).replace('.', ',') : '';
export const duracao = (ticks?: number) => {
  if (!ticks) return '';
  const m = Math.round(ticks / 6e8), h = Math.floor(m / 60);
  return h ? `${h} h ${String(m % 60).padStart(2, '0')}` : `${m} min`;
};
// episódio abre a série; o resto abre o próprio título
const destino = (i: Item) => i.Type === 'Episode' && i.SeriesId ? i.SeriesId : i.Id;

export function Poster({ s, i, ordem = 0 }: { s: Sessao; i: Item; ordem?: number }) {
  const p = progressoAssistido(i.UserData, i.RunTimeTicks);
  const visto = i.UserData?.Played;
  return (
    <a class="cartao poster" href={`#/t/${destino(i)}`} style={{ '--i': Math.min(ordem, 5) }}
      onClick={e => { e.preventDefault(); irTitulo(destino(i), i); }} aria-label={`${i.Name}${ano(i) ? `, ${ano(i)}` : ''}`}>
      <span class="cartao-arte">
        <Imagem src={capa(s, i, 420)} hash={hashDe(s, i, 'Primary')} />
        {visto && <span class="cartao-visto" title="Já visto"><Ic n="check_circle-fill" t={18} /></span>}
        {p > 0 && p < 100 && <span class="cartao-progresso"><span style={{ width: `${p}%` }} /></span>}
      </span>
      <span class="cartao-nome">{i.Name}</span>
      <span class="cartao-meta">{[ano(i), nota(i) && `★ ${nota(i)}`].filter(Boolean).join(' · ')}</span>
    </a>
  );
}

// paisagem: continuar assistindo e próximos episódios (toque = toca de onde parou)
export function Paisagem({ s, i, ordem = 0 }: { s: Sessao; i: Item; ordem?: number }) {
  const p = progressoAssistido(i.UserData, i.RunTimeTicks);
  const ep = i.Type === 'Episode';
  const sub = ep ? `T${i.ParentIndexNumber ?? '?'} · E${i.IndexNumber ?? '?'} — ${i.Name}` : ano(i);
  const resta = i.RunTimeTicks && i.UserData?.PlaybackPositionTicks ? duracao(i.RunTimeTicks - i.UserData.PlaybackPositionTicks) : '';
  return (
    <div class="cartao paisagem" style={{ '--i': Math.min(ordem, 5) }}>
      <a class="cartao-arte" href={`#/ver/${i.Id}`} aria-label={`Assistir ${ep ? i.SeriesName : i.Name}`}
        onClick={e => { e.preventDefault(); irVer(i.Id, i.UserData?.PlaybackPositionTicks); }}>
        <Imagem src={paisagem(s, i, 640)} hash={hashDe(s, i, 'Thumb') || hashDe(s, i, 'Backdrop') || hashDe(s, i, 'Primary')} />
        <span class="paisagem-play"><Ic n="play_arrow-fill" t={28} /></span>
        {p > 0 && <span class="cartao-progresso"><span style={{ width: `${p}%` }} /></span>}
      </a>
      <a class="paisagem-texto" href={`#/t/${destino(i)}`} onClick={e => { e.preventDefault(); irTitulo(destino(i), ep ? undefined : i); }}>
        <span class="cartao-nome">{ep ? i.SeriesName : i.Name}</span>
        <span class="cartao-meta">{sub}{resta && ` · faltam ${resta}`}</span>
      </a>
    </div>
  );
}
