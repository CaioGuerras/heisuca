import { useEffect, useRef, useState } from 'preact/hooks';
import { buscarAcervo, daBiblioteca, favoritos, type Item, type Sessao } from '../api/jellyfin';
import { buscar, detalhe, meusPedidos, poster, SELO, type Resultado } from '../api/seerr';
import { Grade } from '../comp/Fileira';
import { Icone } from '../comp/Icone';
import { iconeBiblioteca, listaBibliotecas } from '../comp/Navegacao';
import { ModalServidores } from '../comp/ModalServidores';
import { avisar, type Alvo } from '../comp/Pedido';
import { irBiblioteca, irTitulo, voltar } from '../rota';

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
    <main class="pagina pagina-busca">
      <div class="busca-topo">
        <button class="botao-voltar-simples" onClick={voltar} aria-label="Voltar">
          <Icone nome="arrow_back" />
        </button>
        <label class="busca-caixa-vidhub busca-caixa">
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
      </div>

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
  const [menuLibsAberto, setMenuLibsAberto] = useState(false);
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
    <main class="pagina pagina-biblioteca">
      {/* Topo Limpo estilo VidHub (foto50): < Voltar | Nome da Biblioteca ⌵ | Menu ☰ */}
      <div class="biblioteca-topo-vidhub">
        <button class="botao-voltar-simples" onClick={voltar} aria-label="Voltar">
          <Icone nome="arrow_back" />
        </button>

        <button
          type="button"
          class="biblioteca-titulo-btn"
          onClick={() => setMenuLibsAberto(!menuLibsAberto)}
          aria-haspopup="dialog"
          aria-expanded={menuLibsAberto}
        >
          <span>{nome || 'Biblioteca'}</span>
          <Icone nome="expand_more" />
        </button>

        <button
          type="button"
          class="botao-menu-libs"
          onClick={() => setMenuLibsAberto(!menuLibsAberto)}
          aria-label="Selecionar biblioteca"
        >
          <Icone nome="menu" />
        </button>
      </div>

      {total >= 0 && <p class="biblioteca-subtotal">{total} {total === 1 ? 'título' : 'títulos'}</p>}

      {/* Grade de Conteúdo */}
      <Grade s={s} itens={itens} aoAbrir={i => irTitulo(i.Id)} />
      {total > itens.length && <button data-foco class="botao-sec pagina-mais" onClick={mais}>Carregar mais</button>}

      {/* Menu Contido das Bibliotecas (foto50 VidHub) */}
      {menuLibsAberto && (
        <div class="menu-fundo" onClick={e => { if (e.target === e.currentTarget) setMenuLibsAberto(false); }}>
          <div class="modal-caixa modal-bibliotecas-contidas" role="dialog" aria-label="Escolher Biblioteca">
            <div class="modal-cabeca">
              <h2>Bibliotecas</h2>
              <button class="menu-fechar" onClick={() => setMenuLibsAberto(false)} aria-label="Fechar">
                <Icone nome="close" />
              </button>
            </div>
            <div class="bibliotecas-menu-lista">
              {libs.map(b => (
                <button
                  key={b.Id}
                  type="button"
                  class={b.Id === ativaId ? 'lib-menu-opcao ativa atalho' : 'lib-menu-opcao atalho'}
                  onClick={() => {
                    setAtivaId(b.Id);
                    irBiblioteca(b.Id);
                    setMenuLibsAberto(false);
                  }}
                >
                  <Icone nome={iconeBiblioteca(b)} />
                  <span>{b.Name}</span>
                  {b.Id === ativaId && <Icone nome="check" />}
                </button>
              ))}

              <hr class="divisor-menu" />

              <button
                type="button"
                class="lib-menu-opcao servidor-opcao-link"
                onClick={() => {
                  setMenuLibsAberto(false);
                  setModalServidor(true);
                }}
              >
                <Icone nome="dns" />
                <span>Alternar / Adicionar Servidor</span>
                <Icone nome="chevron_right" />
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Modal Interativo de Servidores de Mídia */}
      {modalServidor && (
        <ModalServidores
          s={s}
          fechar={() => setModalServidor(false)}
          aoAlternar={() => location.reload()}
        />
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
    <main class="pagina pagina-favoritos">
      <div class="favoritos-topo">
        <button class="botao-voltar-simples" onClick={voltar} aria-label="Voltar">
          <Icone nome="arrow_back" />
        </button>
        <h1 class="pagina-titulo-vidhub">Favoritos</h1>
      </div>
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
      <div class="pedidos-topo">
        <button class="botao-voltar-simples" onClick={voltar} aria-label="Voltar">
          <Icone nome="arrow_back" />
        </button>
        <h1 class="pagina-titulo-vidhub">Meus pedidos</h1>
      </div>
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
