// Favoritos (PLANO §7; ref/vidhub/…favoritos; Caio 19/10 13:00: "separam por biblioteca").
//  O mesmo topo da home; fundo desfocado tirado do 1º favorito; uma seção por biblioteca (nome + "Ver tudo ›") com
//  pôster 2:3, nota, ✓ e título + anos. Sincronizado com o servidor (o favorito do Jellyfin); o que for desfavoritado
//  aqui mesmo (botão direito / segurar) some na hora.
import { useEffect, useState } from 'preact/hooks';
import { bibliotecasDeVideo, favoritosDe, hashDe, type Item, type Sessao } from '../api/jellyfin';
import { fundoDesfocado, usePaleta } from '../cor/paleta';
import { CartaoPoster, EsqueletoCartoes } from '../comp/Cartoes';
import { Fileira } from '../comp/Fileira';
import { Topo } from '../comp/Navegacao';
import { abrirServidores } from '../estado/casca';
import { dadosDe, useMudancas } from '../estado/usuario';
import { irTitulo } from '../rota';
import './favoritos.css';

type Secao = { biblioteca: Item; itens: Item[] };

export function Favoritos({ s }: { s: Sessao }) {
  const [secoes, setSecoes] = useState<Secao[] | null>(null);
  const [abertas, setAbertas] = useState<Set<string>>(new Set());
  const [rolou, setRolou] = useState(false);
  useMudancas();

  useEffect(() => {
    let vivo = true;
    bibliotecasDeVideo(s)
      .then(libs => Promise.all(libs.map(b => favoritosDe(s, b.Id, 60).then(r => ({ biblioteca: b, itens: r.Items })).catch(() => ({ biblioteca: b, itens: [] as Item[] })))))
      .then(l => { if (vivo) setSecoes(l.filter(x => x.itens.length)); })
      .catch(() => { if (vivo) setSecoes([]); });
    return () => { vivo = false; };
  }, [s.token]);
  useEffect(() => {
    const f = () => setRolou(scrollY > 8);
    f(); addEventListener('scroll', f, { passive: true });
    return () => removeEventListener('scroll', f);
  }, []);

  const visiveis = (secoes || []).map(x => ({ ...x, itens: x.itens.filter(i => dadosDe(i).IsFavorite !== false) })).filter(x => x.itens.length);
  const primeiro = visiveis[0]?.itens[0];
  const hashCor = hashDe(primeiro, 'Backdrop') || hashDe(primeiro, 'Primary');
  usePaleta(hashCor ?? null);
  const desfocado = fundoDesfocado(hashDe(primeiro, 'Primary') || hashCor);
  const abrir = (i: Item) => irTitulo(i.Type === 'Episode' && i.SeriesId ? i.SeriesId : i.Id);
  const alternar = (id: string) => setAbertas(a => { const n = new Set(a); if (n.has(id)) n.delete(id); else n.add(id); return n; });

  return (
    <main class="favoritos">
      {desfocado && <div class="favoritos-fundo" aria-hidden="true" style={{ backgroundImage: `url(${desfocado})` }} />}
      <Topo s={s} aoServidor={abrirServidores} fundo={rolou} />
      <h1 class="visualmente-oculto">Favoritos</h1>
      {!secoes && <Fileira titulo="Favoritos"><EsqueletoCartoes n={4} /></Fileira>}
      {secoes && !visiveis.length && <p class="favoritos-vazio">Toque em ♡ num título para guardá-lo aqui.</p>}
      {visiveis.map(({ biblioteca: b, itens }) => abertas.has(b.Id) ? (
        <section key={b.Id} class="fileira favoritos-grade">
          <header class="fileira-cabeca">
            <h2 class="titulo-secao">{b.Name}</h2>
            <button class="fileira-tudo" onClick={() => alternar(b.Id)} aria-expanded="true">Mostrar menos</button>
          </header>
          <div class="favoritos-grade-corpo">{itens.map(i => <CartaoPoster key={i.Id} s={s} i={i} aoAbrir={abrir} />)}</div>
        </section>
      ) : (
        <Fileira key={b.Id} titulo={b.Name} verTudo={() => alternar(b.Id)}>
          {itens.map((i, k) => <CartaoPoster key={i.Id} s={s} i={i} prioridade={k < 4} aoAbrir={abrir} />)}
        </Fileira>
      ))}
    </main>
  );
}
