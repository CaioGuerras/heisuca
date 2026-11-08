// Favoritos (PLANO §7; ref/vidhub/…favoritos; Caio 19/10 13:00: "separam por biblioteca").
//  O mesmo topo da home; fundo desfocado tirado do 1º favorito; uma seção por biblioteca (nome + "Ver tudo ›") com
//  pôster 2:3, nota, ✓ e título + anos. Sincronizado com o servidor (o favorito do Jellyfin); o que for desfavoritado
//  aqui mesmo (botão direito / segurar) some na hora.
import { Fragment } from 'preact';
import { useEffect, useRef, useState } from 'preact/hooks';
import { bibliotecasDeVideo, favoritos, hashDe, type Item, type Sessao } from '../api/servidor.ts';
import { fundoDesfocado, usePaleta } from '../cor/paleta';
import { CartaoPoster, EsqueletoCartoes } from '../comp/Cartoes';
import { Fileira } from '../comp/Fileira';
import { Topo } from '../comp/Navegacao';
import { Icone } from '../comp/Icone';
import { dadosDe, useMudancas } from '../estado/usuario';
import { irAba, irTitulo } from '../rota';
import './favoritos.css';

type Secao = { biblioteca: Item; itens: Item[]; total: number; erro: boolean };
const LIMITE = 60;
// Linha abaixo do título: "12 títulos em 3 bibliotecas", com o total real de cada biblioteca menos o que foi
// desfavoritado aqui (os que não vieram na 1ª página entram pelo total do servidor). Vazio = nada a dizer.
export function resumo(l: { total: number; carregados: number; visiveis: number }[]) {
  const t = l.reduce((n, x) => n + Math.max(x.visiveis, x.total - (x.carregados - x.visiveis)), 0);
  const b = l.filter(x => x.visiveis).length;
  if (!t || !b) return '';
  return `${t.toLocaleString('pt-BR')} ${t === 1 ? 'título' : 'títulos'}${b > 1 ? ` em ${b} bibliotecas` : ''}`;
}

export function Favoritos({ s }: { s: Sessao }) {
  const [secoes, setSecoes] = useState<Secao[] | null>(null);
  const [abertas, setAbertas] = useState<Set<string>>(new Set());
  const [rolou, setRolou] = useState(false);
  const [erro, setErro] = useState(false);
  const [tentativa, setTentativa] = useState(0);
  const [ocupadas, setOcupadas] = useState<Set<string>>(new Set());
  const ciclo = useRef(0), carregando = useRef(new Set<string>());
  useMudancas();

  useEffect(() => {
    const rodada = ++ciclo.current;
    setSecoes(null); setErro(false); setAbertas(new Set()); setOcupadas(new Set()); carregando.current.clear();
    bibliotecasDeVideo(s)
      .then(libs => Promise.all((rodada === ciclo.current ? libs : []).map(b => favoritos(s, b.Id, LIMITE)
        .then(r => ({ biblioteca: b, itens: r.Items, total: r.TotalRecordCount, erro: false }))
        .catch(() => ({ biblioteca: b, itens: [] as Item[], total: 0, erro: true })))))
      .then(l => { if (rodada === ciclo.current) setSecoes(l); })
      .catch(() => { if (rodada === ciclo.current) { setSecoes([]); setErro(true); } });
    return () => { ciclo.current++; };
  }, [s.token, s.servidor, s.usuarioId, tentativa]);
  useEffect(() => {
    const f = () => setRolou(scrollY > 8);
    f(); addEventListener('scroll', f, { passive: true });
    return () => removeEventListener('scroll', f);
  }, []);

  const visiveis = (secoes || []).map(secao => ({ secao, itens: secao.itens.filter(i => dadosDe(s, i).IsFavorite !== false) }))
    .filter(x => x.itens.length || x.secao.erro);
  const primeiro = visiveis.find(x => x.itens.length)?.itens[0];
  const hashCor = hashDe(s, primeiro, 'Backdrop') || hashDe(s, primeiro, 'Primary');
  usePaleta(hashCor ?? null);
  const desfocado = fundoDesfocado(hashDe(s, primeiro, 'Primary') || hashCor);
  const linha = resumo(visiveis.map(x => ({ total: x.secao.total, carregados: x.secao.itens.length, visiveis: x.itens.length })));
  const abrir = (i: Item) => irTitulo(i.Type === 'Episode' && i.SeriesId ? i.SeriesId : i.Id);
  const completar = async (secao: Secao) => {
    const id = secao.biblioteca.Id, rodada = ciclo.current;
    if (carregando.current.has(id)) return;
    carregando.current.add(id); setOcupadas(new Set(carregando.current));
    try {
      // O adaptador já aceita limite: a consulta completa só acontece ao pedir “Ver tudo”.
      const r = await favoritos(s, id, Math.max(LIMITE, secao.total));
      if (rodada === ciclo.current) setSecoes(l => l && l.map(x => x.biblioteca.Id === id
        ? { ...x, itens: r.Items, total: r.TotalRecordCount, erro: false } : x));
    } catch {
      if (rodada === ciclo.current) setSecoes(l => l && l.map(x => x.biblioteca.Id === id ? { ...x, erro: true } : x));
    } finally {
      if (rodada === ciclo.current) { carregando.current.delete(id); setOcupadas(new Set(carregando.current)); }
    }
  };
  const alternar = (secao: Secao) => {
    const id = secao.biblioteca.Id;
    setAbertas(a => { const n = new Set(a); if (n.has(id)) n.delete(id); else n.add(id); return n; });
    if (!abertas.has(id) && secao.itens.length < secao.total) void completar(secao);
  };

  return (
    <main class="favoritos">
      {desfocado && <div class="favoritos-fundo" aria-hidden="true" style={{ backgroundImage: `url(${desfocado})` }} />}
      <Topo fundo={rolou} />
      <header class="favoritos-cabeca">
        <h1 class="favoritos-titulo">Favoritos</h1>
        {linha && <p class="favoritos-resumo">{linha}</p>}
      </header>
      {/* carregando: o esqueleto de uma seção (barra no lugar do nome), sem repetir "Favoritos" logo abaixo do título */}
      {!secoes && <section class="fileira favoritos-carregando" aria-busy="true" aria-label="Carregando favoritos">
        <header class="fileira-cabeca"><span class="favoritos-barra esqueleto" /></header>
        <div class="fileira-trilho"><EsqueletoCartoes n={8} /></div>
      </section>}
      {erro && <div class="favoritos-vazio" role="status"><p>Não deu para carregar os favoritos.</p>
        <button class="pilula pilula-tema" onClick={() => setTentativa(t => t + 1)}>Tentar de novo</button></div>}
      {secoes && !erro && !visiveis.length && <div class="favoritos-vazio">
        <Icone nome="favorite" tamanho={36} /><p>Toque em ♡ num título para <span style={{ whiteSpace: 'nowrap' }}>guardá-lo</span> aqui.</p>
        <button class="pilula pilula-tema" onClick={() => irAba('b')}><Icone nome="video_library" tamanho={20} />Abrir a Biblioteca</button>
      </div>}
      {visiveis.map(({ secao, itens }) => {
        const b = secao.biblioteca, ocupada = ocupadas.has(b.Id);
        const totalVisivel = secao.total - (secao.itens.length - itens.length);
        return <Fragment key={b.Id}>
          {abertas.has(b.Id) ? (
            <section class="fileira favoritos-grade" aria-busy={ocupada}>
              <header class="fileira-cabeca">
                <h2 class="titulo-secao">{b.Name}</h2>
                <button class="fileira-tudo" onClick={() => alternar(secao)} aria-expanded="true">Mostrar menos</button>
              </header>
              <div class="favoritos-grade-corpo">{itens.map(i => <CartaoPoster key={i.Id} s={s} i={i} aoAbrir={abrir} />)}</div>
            </section>
          ) : (
            <Fileira titulo={b.Name} verTudo={itens.length ? () => alternar(secao) : undefined}>
              {itens.map((i, k) => <CartaoPoster key={i.Id} s={s} i={i} prioridade={k < 4} aoAbrir={abrir} />)}
            </Fileira>
          )}
          <div class="favoritos-estado" role="status" aria-busy={ocupada}>
            {ocupada ? <p>Carregando favoritos…</p> : secao.erro ? <>
              <p>Não deu para carregar os favoritos de {b.Name}.</p>
              <button class="pilula pilula-tema" onClick={() => void completar(secao)}>Tentar de novo</button>
            </> : abertas.has(b.Id) && secao.itens.length < secao.total ? <>
              <p>Mostrando {itens.length} de {totalVisivel} favoritos.</p>
              <button class="pilula pilula-tema" onClick={() => void completar(secao)}>Tentar carregar todos</button>
            </> : null}
          </div>
        </Fragment>;
      })}
    </main>
  );
}
