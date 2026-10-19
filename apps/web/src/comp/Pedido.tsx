// Folha de pedido (Seerr): filme pede direto; série escolhe as temporadas (padrão: todas as que ainda não foram pedidas).
// Mesma regra do site atual e do app completo; agora dentro da Folha contida.
import { useEffect, useState } from 'preact/hooks';
import type { Sessao } from '../api/jellyfin';
import { detalhe, mensagemDeErro, pedir, poster, SELO, type Temporada } from '../api/seerr';
import { avisar } from './Aviso';
import { Folha } from './Folha';
import { Icone } from './Icone';
import './pedido.css';

export type Alvo = { tipo: 'movie' | 'tv'; id: number; nome: string; posterPath?: string; ano?: string };

export function FolhaPedido({ s, alvo, fechar, pedido }: { s: Sessao; alvo: Alvo | null; fechar: () => void; pedido?: () => void }) {
  const [temps, setTemps] = useState<(Temporada & { bloq?: string })[] | null>(null);
  const [escolha, setEscolha] = useState<number[]>([]);
  const [estado, setEstado] = useState<'' | 'pedindo' | 'erro-temps'>('');
  const [sinopse, setSinopse] = useState('');
  const [post, setPost] = useState<string | undefined>();

  useEffect(() => {
    if (!alvo) return;
    setTemps(alvo.tipo === 'tv' ? null : []); setEscolha([]); setEstado(''); setSinopse(''); setPost(alvo.posterPath);
    detalhe(s, alvo.tipo, alvo.id).then(d => {
      setSinopse(d.overview || ''); setPost(p => p || d.posterPath);
      if (alvo.tipo !== 'tv') return;
      const bloq: Record<number, string> = {};
      (d.mediaInfo?.seasons || []).forEach(t => { if (t.status >= 2) bloq[t.seasonNumber] = SELO[t.status] || 'Pedido'; });
      (d.mediaInfo?.requests || []).forEach(q => { if (q.status !== 3) (q.seasons || []).forEach(t => { bloq[t.seasonNumber] ??= 'Pedido'; }); });
      const ts = (d.seasons || []).filter(t => t.seasonNumber > 0).map(t => ({ ...t, bloq: bloq[t.seasonNumber] }));
      setTemps(ts); setEscolha(ts.filter(t => !t.bloq).map(t => t.seasonNumber));
    }).catch(() => { if (alvo.tipo === 'tv') setEstado('erro-temps'); setTemps(t => t ?? []); });
  }, [alvo?.id]);

  const livres = (temps || []).filter(t => !t.bloq).length;
  const rotulo = estado === 'pedindo' ? 'Pedindo…' : alvo?.tipo === 'movie' ? 'Pedir' : !temps ? 'Carregando…' : !livres ? 'Tudo já pedido'
    : escolha.length === livres ? 'Pedir todas' : `Pedir ${escolha.length} ${escolha.length === 1 ? 'temporada' : 'temporadas'}`;
  const pode = !!alvo && estado === '' && (alvo.tipo === 'movie' || escolha.length > 0);
  const enviar = () => {
    if (!alvo) return;
    setEstado('pedindo');
    pedir(s, alvo.tipo, alvo.id, alvo.tipo === 'tv' ? escolha : undefined)
      .then(() => { fechar(); avisar('Pedido feito. Avisamos quando chegar.'); pedido?.(); })
      .catch(e => { setEstado(''); avisar(mensagemDeErro(e)); });
  };
  return (
    <Folha aberta={!!alvo} fechar={fechar} titulo={alvo ? `Pedir ${alvo.nome}` : ''}>
      {alvo && (
        <div class="pedido">
          <div class="pedido-cabeca">
            {poster(s, post) && <img src={poster(s, post)} alt="" />}
            <div><strong>{alvo.nome}</strong><small>{[alvo.ano, alvo.tipo === 'tv' ? 'Série' : 'Filme'].filter(Boolean).join(' · ')}</small></div>
          </div>
          {sinopse && <p class="pedido-sinopse">{sinopse}</p>}
          {alvo.tipo === 'tv' && (estado === 'erro-temps' ? <p class="texto-2">Pedidos indisponíveis agora.</p>
            : temps && !temps.length ? <p class="texto-2">Sem temporadas anunciadas ainda.</p>
            : temps && <fieldset class="pedido-temps"><legend>Temporadas</legend>{temps.map(t => (
              <label key={t.seasonNumber} class="pedido-temp">
                <input type="checkbox" disabled={!!t.bloq} checked={!t.bloq && escolha.includes(t.seasonNumber)}
                  onChange={e => setEscolha(x => (e.target as HTMLInputElement).checked ? [...x, t.seasonNumber] : x.filter(n => n !== t.seasonNumber))} />
                <span>{t.name && !/^Season \d+$/.test(t.name) ? t.name : `Temporada ${t.seasonNumber}`}</span>
                <small>{t.bloq || (t.episodeCount ? `${t.episodeCount} ep.` : '')}</small>
              </label>))}</fieldset>)}
          <button class="pilula pilula-tema pedido-botao" disabled={!pode} onClick={enviar}><Icone nome="add" tamanho={22} />{rotulo}</button>
        </div>
      )}
    </Folha>
  );
}
