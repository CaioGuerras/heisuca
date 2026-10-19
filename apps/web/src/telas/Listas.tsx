import { useEffect, useRef, useState } from 'preact/hooks';
import { buscarAcervo, daBiblioteca, favoritos, type Item, type Sessao } from '../api/jellyfin';
import { buscar, detalhe, meusPedidos, poster, SELO, type Resultado } from '../api/seerr';
import { Grade } from '../comp/Fileira';
import { Icone } from '../comp/Icone';
import { iconeBiblioteca, listaBibliotecas } from '../comp/Navegacao';
import { avisar, type Alvo } from '../comp/Pedido';
import { irBiblioteca, irTitulo } from '../rota';

const ano = (r: Resultado) => (r.releaseDate || r.firstAirDate || '').slice(0, 4);
export const alvoDe = (r: Resultado): Alvo => ({
  tipo: r.mediaType as 'movie' | 'tv',
  id: r.id,
  nome: r.title || r.name || '',
  posterPath: r.posterPath,
  ano: ano(r),
});

export function Busca({ s, pedir }: { s: Sessao; pedir: (a: Alvo, depois?: () => void) => void }) {
  const [termo, setTermo] = useState(() => sessionStorage.getItem('heisuca.busca') || '');
  const [nossos, setNossos] = useState<Item[] | null>(null);
  const [fora, setFora] = useState<Resultado[] | null>(null);
  const [foraErro, setForaErro] = useState(false);
  const [rodada, setRodada] = useState(0);
  const campo = useRef<HTMLInputElement>(null), n = useRef(0);

  useEffect(() => { campo.current?.focus(); }, []);

  useEffect(() => {
    sessionStorage.setItem('heisuca.busca', termo);
    const q = termo.trim(), eu = ++n.current;
    if (q.length < 2) { setNossos(null); setFora(null); return; }
    const t = setTimeout(() => {
      buscarAcervo(s, q).then(r => { if (eu === n.current) setNossos(r); }).catch(() => { if (eu === n.current) setNossos([]); });
      setForaErro(false);
      buscar(s, q).then(r => { if (eu === n.current) setFora(r); }).catch(() => { if (eu === n.current) { setFora([]); setForaErro(true); } });
    }, 400);
    return () => clearTimeout(t);
  }, [termo, rodada]);

  const abrirFora = (r: Resultado) => {
    const st = r.mediaInfo?.status;
    if (st === 2 || st === 3) {
      avisar(`${r.title || r.name}: ${SELO[st].toLowerCase()}. Avisamos quando chegar.`);
      return;
    }
    pedir(alvoDe(r), () => setRodada(x => x + 1));
  };

  return (
    <main class="pagina">
      <label class="busca-caixa">
        <Icone nome="search" />
        <input
          ref={campo}
          data-foco
          type="search"
          placeholder="Filmes, séries, animes…"
          value={termo}
          enterKeyHint="search"
          aria-label="Buscar"
          onInput={e => setTermo((e.target as HTMLInputElement).value)}
        />
        {termo && (
          <button class="menu-fechar" aria-label="Limpar" onClick={() => { setTermo(''); campo.current?.focus(); }}>
            <Icone nome="close" />
          </button>
        )}
      </label>

      {termo.trim().length < 2 && (
        <p class="pagina-nota">Procure no acervo. O que ainda não temos aparece embaixo, para pedir.</p>
      )}

      {nossos && (
        nossos.length ? (
          <>
            <h2 class="pagina-sub">No Heisuca</h2>
            <Grade s={s} itens={nossos} aoAbrir={i => irTitulo(i.Id)} />
          </>
        ) : (
          <p class="pagina-nota">Nada no acervo com esse nome.</p>
        )
      )}

      {fora && fora.length > 0 && (
        <>
          <h2 class="pagina-sub">Disponível para pedir</h2>
          <div class="grade">
            {fora.map(r => {
              const st = r.mediaInfo?.status || 0;
              return (
                <button
                  data-foco
                  class="cartao"
                  key={`${r.mediaType}${r.id}`}
                  onClick={() => abrirFora(r)}
                  aria-label={`${r.title || r.name}, ${SELO[st] || 'pedir'}`}
                >
                  <div class="cartao-poster">
                    <img loading="lazy" decoding="async" src={poster(s, r.posterPath)} alt="" />
                    <span class="cartao-selo">{SELO[st] || 'Pedir'}</span>
                  </div>
                  <span class="cartao-nome">{r.title || r.name}</span>
                  <span class="cartao-sub">{[ano(r), r.mediaType === 'tv' ? 'Série' : 'Filme'].filter(Boolean).join(' · ')}</span>
                </button>
              );
            })}
          </div>
        </>
      )}
      {foraErro && <p class="pagina-nota">Pedidos indisponíveis agora.</p>}
    </main>
  );
}

export function Biblioteca({ s, id }: { s: Sessao; id?: string }) {
  const [libs, setLibs] = useState<Item[]>([]);
  const [ativaId, setAtivaId] = useState(id || '');
  const [nome, setNome] = useState('');
  const [itens, setItens] = useState<Item[]>([]);
  const [total, setTotal] = useState(-1);
  const [modalServidor, setModalServidor] = useState(false);
  const carregando = useRef(false);

  useEffect(() => {
    listaBibliotecas(s).then(l => {
      setLibs(l);
      const selId = id || l[0]?.Id || '';
      setAtivaId(selId);
      setNome(l.find(b => b.Id === selId)?.Name || '');
    });
  }, [s.token, id]);

  const carregarItens = (bibId: string, reset = false) => {
    if (!bibId || carregando.current) return;
    carregando.current = true;
    const inicio = reset ? 0 : itens.length;
    daBiblioteca(s, bibId, inicio)
      .then(d => {
        setItens(x => (reset ? d.Items : [...x, ...d.Items]));
        setTotal(d.TotalRecordCount);
      })
      .finally(() => {
        carregando.current = false;
      });
  };

  useEffect(() => {
    if (ativaId) {
      setNome(libs.find(b => b.Id === ativaId)?.Name || '');
      carregarItens(ativaId, true);
    }
  }, [ativaId]);

  const mais = () => {
    if (total >= 0 && itens.length >= total) return;
    carregarItens(ativaId, false);
  };

  useEffect(() => {
    const f = () => {
      if (innerHeight + scrollY > document.body.scrollHeight - 900) mais();
    };
    addEventListener('scroll', f, { passive: true });
    return () => removeEventListener('scroll', f);
  });

  return (
    <main class="pagina">
      {/* Barra de Seleção de Bibliotecas e Servidor */}
      <div class="biblioteca-topo-nav">
        <div class="bibliotecas-chips" role="tablist">
          {libs.map(b => (
            <button
              key={b.Id}
              type="button"
              role="tab"
              class={b.Id === ativaId ? 'atalho ativo' : 'atalho'}
              aria-selected={b.Id === ativaId}
              onClick={() => {
                setAtivaId(b.Id);
                irBiblioteca(b.Id);
              }}
            >
              <Icone nome={iconeBiblioteca(b)} />
              <span>{b.Name}</span>
            </button>
          ))}
        </div>

        <button
          type="button"
          class="botao-sec biblioteca-servidor-btn"
          onClick={() => setModalServidor(true)}
          title="Alternar ou adicionar servidor de mídia"
        >
          <Icone nome="dns" />
          <span>CGSERVER</span>
          <Icone nome="swap_horiz" />
        </button>
      </div>

      <h1 class="pagina-titulo">{nome}</h1>
      {total >= 0 && <p class="pagina-nota">{total} {total === 1 ? 'título' : 'títulos'}</p>}
      <Grade s={s} itens={itens} aoAbrir={i => irTitulo(i.Id)} />
      {total > itens.length && <button data-foco class="botao-sec pagina-mais" onClick={mais}>Carregar mais</button>}

      {/* Modal de Alternar Servidor */}
      {modalServidor && (
        <div class="menu-fundo" onClick={e => { if (e.target === e.currentTarget) setModalServidor(false); }}>
          <div class="modal-caixa" role="dialog" aria-label="Servidores de mídia">
            <div class="modal-cabeca">
              <h2>Servidores de Mídia</h2>
              <button class="menu-fechar" onClick={() => setModalServidor(false)} aria-label="Fechar">
                <Icone nome="close" />
              </button>
            </div>
            <p class="modal-sub">
              No VidHub e no Heisuca, cada servidor possui sua própria biblioteca isolada:
            </p>
            <div class="servidores-lista">
              <div class="servidor-opcao ativa">
                <Icone nome="check_circle" cheio />
                <div>
                  <strong>CGSERVER (Jellyfin)</strong>
                  <small>Servidor principal conectado</small>
                </div>
              </div>
              <div class="servidor-opcao desativada">
                <Icone nome="theaters" />
                <div>
                  <strong>Plex</strong>
                  <small>Em breve nos apps nativos</small>
                </div>
              </div>
              <div class="servidor-opcao desativada">
                <Icone nome="cloud" />
                <div>
                  <strong>WebDAV</strong>
                  <small>Em breve nos apps nativos</small>
                </div>
              </div>
              <div class="servidor-opcao desativada">
                <Icone nome="folder_shared" />
                <div>
                  <strong>SMB / NAS Local</strong>
                  <small>Em breve nos apps nativos</small>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </main>
  );
}

export function Favoritos({ s }: { s: Sessao }) {
  const [itens, setItens] = useState<Item[] | null>(null);

  const carregarFav = () => {
    favoritos(s).then(setItens).catch(() => setItens([]));
  };

  useEffect(() => {
    carregarFav();
  }, [s.token]);

  return (
    <main class="pagina">
      <h1 class="pagina-titulo">Favoritos</h1>
      {itens && !itens.length && (
        <p class="pagina-nota">
          Nada aqui ainda. Na página de qualquer filme ou série, toque no botão <strong>Favoritar</strong> para guardar.
        </p>
      )}
      {itens && <Grade s={s} itens={itens} aoAbrir={i => irTitulo(i.Id)} aoAtualizar={carregarFav} />}
    </main>
  );
}

const ESTADO_PEDIDO: Record<number, string> = { 1: 'Aguardando aprovação', 2: 'Aprovado', 3: 'Recusado' };
type LinhaPedido = { id: number; nome: string; capa: string; estado: string; jf?: string; data: string };

export function Pedidos({ s }: { s: Sessao }) {
  const [linhas, setLinhas] = useState<LinhaPedido[] | null>(null);
  const [erro, setErro] = useState(false);

  useEffect(() => {
    meusPedidos(s)
      .then(ps =>
        Promise.all(
          ps.map(async p => {
            const d = await detalhe(s, p.media.mediaType, p.media.tmdbId).catch(() => null);
            const st = p.media.status;
            return {
              id: p.id,
              nome: d?.title || d?.name || `#${p.media.tmdbId}`,
              capa: poster(s, d?.posterPath),
              jf: p.media.jellyfinMediaId,
              estado: st === 5 ? 'Disponível' : st === 4 ? 'Em parte' : st === 3 ? 'Baixando' : ESTADO_PEDIDO[p.status] || 'Pedido',
              data: new Date(p.createdAt).toLocaleDateString('pt-BR'),
            };
          })
        )
      )
      .then(setLinhas)
      .catch(() => {
        setErro(true);
        setLinhas([]);
      });
  }, [s.token]);

  return (
    <main class="pagina">
      <h1 class="pagina-titulo">Meus pedidos</h1>
      {erro && <p class="pagina-nota">Pedidos indisponíveis agora.</p>}
      {linhas && !linhas.length && !erro && (
        <p class="pagina-nota">Você ainda não pediu nada. Na Busca, o que não temos aparece para pedir.</p>
      )}
      <ul class="pedidos">
        {(linhas || []).map(l => (
          <li key={l.id}>
            <button data-foco class="pedido" disabled={!l.jf} onClick={() => l.jf && irTitulo(l.jf)}>
              {l.capa ? <img src={l.capa} alt="" loading="lazy" /> : <span class="pedido-sem-capa" />}
              <span class="pedido-texto">
                <strong>{l.nome}</strong>
                <small>Pedido em {l.data}</small>
              </span>
              <span class={l.estado === 'Disponível' ? 'pedido-estado pronto' : 'pedido-estado'}>{l.estado}</span>
            </button>
          </li>
        ))}
      </ul>
    </main>
  );
}
