// Folha de pedido (embaixo no celular, diálogo no computador) e aviso curto, no modelo do site atual (cgflix-nav.js):
// filme pede direto; série escolhe as temporadas (padrão: todas as que ainda não foram pedidas).
import { useEffect, useRef, useState } from 'preact/hooks';
import type { Sessao } from '../api/jellyfin';
import { detalhe, mensagemDeErro, pedir, poster, SELO, type Temporada } from '../api/seerr';
import { Icone } from './Icone';

let mostrar: ((t: string) => void) | null = null;
export const avisar = (t: string) => mostrar?.(t);
export function Aviso() {
  const [t, setT] = useState(''); const tempo = useRef(0);
  useEffect(() => { mostrar = x => { setT(x); clearTimeout(tempo.current); tempo.current = setTimeout(() => setT(''), 4200) as unknown as number; }; return () => { mostrar = null; }; }, []);
  return <div class={t ? 'aviso visivel' : 'aviso'} role="status">{t}</div>;
}

export type Alvo = { tipo: 'movie' | 'tv'; id: number; nome: string; posterPath?: string; ano?: string };

export function FolhaPedido({ s, alvo, fechar, pedido }: { s: Sessao; alvo: Alvo; fechar: () => void; pedido?: () => void }) {
  const [temps, setTemps] = useState<(Temporada & { bloq?: string })[] | null>(alvo.tipo === 'tv' ? null : []);
  const [escolha, setEscolha] = useState<number[]>([]);
  const [estado, setEstado] = useState<'' | 'pedindo' | 'erro-temps'>('');
  const [sinopse, setSinopse] = useState('');
  const [post, setPost] = useState(alvo.posterPath);
  const caixa = useRef<HTMLDivElement>(null);

  useEffect(() => {
    detalhe(s, alvo.tipo, alvo.id).then(d => {
      setSinopse(d.overview || ''); setPost(p => p || d.posterPath);
      if (alvo.tipo !== 'tv') return;
      const bloq: Record<number, string> = {};
      (d.mediaInfo?.seasons || []).forEach(t => { if (t.status >= 2) bloq[t.seasonNumber] = SELO[t.status] || 'Pedido'; });
      (d.mediaInfo?.requests || []).forEach(q => { if (q.status !== 3) (q.seasons || []).forEach(t => { bloq[t.seasonNumber] ??= 'Pedido'; }); });
      const ts = (d.seasons || []).filter(t => t.seasonNumber > 0).map(t => ({ ...t, bloq: bloq[t.seasonNumber] }));
      setTemps(ts); setEscolha(ts.filter(t => !t.bloq).map(t => t.seasonNumber));
    }).catch(() => { if (alvo.tipo === 'tv') setEstado('erro-temps'); setTemps(t => t ?? []); });
  }, []);
  useEffect(() => {
    caixa.current?.querySelector<HTMLElement>('button')?.focus();
    const tecla = (e: KeyboardEvent) => { if (e.key === 'Escape' || e.keyCode === 10009 || e.keyCode === 461) { e.preventDefault(); e.stopPropagation(); fechar(); } };
    addEventListener('keydown', tecla, true);
    return () => removeEventListener('keydown', tecla, true);
  }, []);

  const livres = (temps || []).filter(t => !t.bloq).length;
  const rotulo = estado === 'pedindo' ? 'Pedindo…' : alvo.tipo === 'movie' ? 'Pedir' : !temps ? 'Carregando…' : !livres ? 'Tudo já pedido'
    : escolha.length === livres ? 'Pedir todas' : `Pedir ${escolha.length} ${escolha.length === 1 ? 'temporada' : 'temporadas'}`;
  const pode = estado === '' && (alvo.tipo === 'movie' || escolha.length > 0);
  const enviar = () => {
    setEstado('pedindo');
    pedir(s, alvo.tipo, alvo.id, alvo.tipo === 'tv' ? escolha : undefined)
      .then(() => { fechar(); avisar('Pedido feito. Avisamos quando chegar.'); pedido?.(); })
      .catch(e => { setEstado(''); avisar(mensagemDeErro(e)); });
  };
  return (
    <div class="folha-fundo" onClick={e => { if (e.target === e.currentTarget) fechar(); }}>
      <div class="folha" role="dialog" aria-modal="true" aria-label={`Pedir ${alvo.nome}`} ref={caixa}>
        <div class="folha-cabeca">
          {poster(s, post) && <img src={poster(s, post)} alt="" />}
          <div><h2>{alvo.nome}</h2><p>{[alvo.ano, alvo.tipo === 'tv' ? 'Série' : 'Filme'].filter(Boolean).join(' · ')}</p></div>
          <button data-foco class="menu-fechar" aria-label="Fechar" onClick={fechar}><Icone nome="close" /></button>
        </div>
        {sinopse && <p class="folha-sinopse">{sinopse}</p>}
        {alvo.tipo === 'tv' && (estado === 'erro-temps' ? <p class="folha-nota">Pedidos indisponíveis agora.</p>
          : temps && !temps.length ? <p class="folha-nota">Sem temporadas anunciadas ainda.</p>
          : temps && <fieldset class="folha-temps"><legend>Temporadas</legend>{temps.map(t => (
            <label key={t.seasonNumber} class="folha-temp">
              <input type="checkbox" data-foco disabled={!!t.bloq} checked={!t.bloq && escolha.includes(t.seasonNumber)}
                onChange={e => setEscolha(x => (e.target as HTMLInputElement).checked ? [...x, t.seasonNumber] : x.filter(n => n !== t.seasonNumber))} />
              <span>{t.name && !/^Season \d+$/.test(t.name) ? t.name : `Temporada ${t.seasonNumber}`}</span>
              <small>{t.bloq || (t.episodeCount ? `${t.episodeCount} ep.` : '')}</small>
            </label>))}</fieldset>)}
        <button data-foco class="botao folha-pedir" disabled={!pode} onClick={enviar}><Icone nome="add" />{rotulo}</button>
      </div>
    </div>
  );
}
