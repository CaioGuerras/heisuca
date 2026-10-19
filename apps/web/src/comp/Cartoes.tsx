// Cartões das fileiras e grades (PLANO §4–§7; medidas tiradas dos prints do VidHub em ref/vidhub).
//  Poster 2:3: nota no canto inferior direito, ✓ visto no canto superior direito, título + anos.
//  Paisagem 16:9 (Continuar/Próximo): ▶ no centro, tempo "26:44 / 40:39", barra de progresso, título + "T1:E1 · nome".
//  Biblioteca 16:9 (Mídia): a capa da biblioteca e o nome embaixo.  Top 10: número em contorno alinhado à base do pôster.
import type { JSX } from 'preact';
import { capa, hashDe, imagem, paisagem, type EmBreve, type Item, type Sessao } from '../api/jellyfin';
import { useDados } from '../estado/usuario';
import { Icone } from './Icone';
import { Imagem } from './Imagem';
import { useAcoes } from './MenuContexto';
import './cartoes.css';

const TICKS = 10_000_000;
export const relogio = (seg: number) => {
  if (!Number.isFinite(seg) || seg < 0) seg = 0;
  const h = Math.floor(seg / 3600), m = Math.floor(seg / 60) % 60, s = Math.floor(seg % 60);
  return (h ? `${h}:${String(m).padStart(2, '0')}` : String(m)) + `:${String(s).padStart(2, '0')}`;
};
export const nota = (i: Item) => i.CommunityRating ? i.CommunityRating.toFixed(1).replace('.', ',') : '';
export function anos(i: Item): string {
  const ini = i.ProductionYear, fim = i.EndDate ? new Date(i.EndDate).getFullYear() : undefined;
  if (!ini) return '';
  return i.Type === 'Series' && fim && fim !== ini ? `${ini} - ${fim}` : String(ini);
}
export const episodio = (i: Item) => i.Type === 'Episode'
  ? `T${i.ParentIndexNumber ?? '?'}:E${i.IndexNumber ?? '?'}${i.Name ? ` · ${i.Name}` : ''}` : '';
export const nomeDe = (i: Item) => i.Type === 'Episode' ? (i.SeriesName || i.Name) : i.Name;

type Base = { s: Sessao; i: Item; aoAbrir: (i: Item) => void; prioridade?: boolean };

export function CartaoPoster({ s, i, aoAbrir, prioridade }: Base) {
  const d = useDados(i), acoes = useAcoes(s, i), n = nota(i);
  return (
    <button class="cartao cartao-poster" onClick={() => aoAbrir(i)} {...acoes} aria-label={`${nomeDe(i)}${anos(i) ? `, ${anos(i)}` : ''}`}>
      <span class="cartao-arte">
        <Imagem src={capa(s, i, 360)} hash={hashDe(i, 'Primary')} prioridade={prioridade} />
        {n && <span class="cartao-nota">{n}</span>}
        {d.Played && <span class="cartao-visto"><Icone nome="check" tamanho={14} /></span>}
      </span>
      <span class="cartao-nome uma-linha">{nomeDe(i)}</span>
      {anos(i) && <span class="cartao-sub uma-linha">{anos(i)}</span>}
    </button>
  );
}

export function CartaoPaisagem({ s, i, aoAbrir, prioridade, tempo = false }: Base & { tempo?: boolean }) {
  const d = useDados(i), acoes = useAcoes(s, i);
  const dur = (i.RunTimeTicks || 0) / TICKS, pos = (d.PlaybackPositionTicks || 0) / TICKS;
  const pct = d.PlayedPercentage ?? (dur ? pos / dur * 100 : 0);
  return (
    <button class="cartao cartao-paisagem" onClick={() => aoAbrir(i)} {...acoes} aria-label={`${nomeDe(i)} ${episodio(i)}`}>
      <span class="cartao-arte">
        <Imagem src={paisagem(s, i, 480)} hash={hashDe(i, i.Type === 'Episode' ? 'Primary' : 'Backdrop')} prioridade={prioridade} />
        <span class="cartao-play"><Icone nome="play_arrow" cheio tamanho={26} /></span>
        {tempo && dur > 0 && <span class="cartao-tempo">{relogio(pos)} / {relogio(dur)}</span>}
        {pct > 0 && <span class="cartao-barra"><span style={{ width: `${Math.min(100, pct)}%` }} /></span>}
      </span>
      <span class="cartao-nome uma-linha">{nomeDe(i)}</span>
      {i.Type === 'Episode' && <span class="cartao-sub uma-linha">{episodio(i)}</span>}
    </button>
  );
}

export function CartaoBiblioteca({ s, b, aoAbrir }: { s: Sessao; b: Item; aoAbrir: (b: Item) => void }) {
  const img = b.ImageTags?.Primary ? imagem(s, b.Id, 'Primary', b.ImageTags.Primary, { largura: 480 }) : '';
  return (
    <button class="cartao cartao-biblioteca" onClick={() => aoAbrir(b)} aria-label={b.Name}>
      <span class="cartao-arte">
        <Imagem src={img} hash={hashDe(b, 'Primary')} />
        {!img && <span class="cartao-biblioteca-nome">{b.Name}</span>}
      </span>
      <span class="cartao-nome uma-linha">{b.Name}</span>
    </button>
  );
}

export function CartaoTop10({ s, i, n, aoAbrir }: Base & { n: number }) {
  const acoes = useAcoes(s, i);
  return (
    <button class="cartao cartao-top10" onClick={() => aoAbrir(i)} {...acoes} aria-label={`${n}º, ${nomeDe(i)}`}>
      <span class="cartao-numero" aria-hidden="true">{n}</span>
      <span class="cartao-arte"><Imagem src={capa(s, i, 360)} hash={hashDe(i, 'Primary')} /></span>
    </button>
  );
}

export function CartaoEmBreve({ e, aoAbrir }: { e: EmBreve; aoAbrir: (e: EmBreve) => void }) {
  return (
    <button class="cartao cartao-poster" onClick={() => aoAbrir(e)} aria-label={`${e.nome}, ${e.sub}`}>
      <span class="cartao-arte"><Imagem src={e.capa} /><span class="cartao-selo">{e.jf ? 'Novo episódio' : 'Em breve'}</span></span>
      <span class="cartao-nome uma-linha">{e.nome}</span>
      {e.sub && <span class="cartao-sub uma-linha">{e.sub}</span>}
    </button>
  );
}

// esqueleto na forma do cartão (enquanto a fileira carrega)
export const EsqueletoCartoes = ({ tipo = 'poster', n = 6 }: { tipo?: 'poster' | 'paisagem'; n?: number }): JSX.Element => (
  <>{Array.from({ length: n }, (_, k) => <span key={k} class={`cartao cartao-${tipo}`} aria-hidden="true"><span class="cartao-arte esqueleto" /></span>)}</>
);
