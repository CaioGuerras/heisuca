// Explorar: bibliotecas, gêneros, ordem e "só não vistos" ficam na tela, a grade carrega aos poucos.
// A escolha é lembrada por biblioteca (só neste aparelho).
import { useEffect, useRef, useState } from 'preact/hooks';
import { bibliotecasDeVideo, type Item, type Sessao } from '@w/api/servidor';
import { irAba } from '@w/rota';
import { Poster } from '../comp/Cartao';
import { Ic } from '../comp/Icone';
import { ORDENS, explorar, generos, type Filtro, type Genero, type Ordem } from '../dados/catalogo';

const PAGINA = 48;
const LETRAS = ['#', ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'];
const chave = (b?: string) => `lume.explorar.${b || 'tudo'}`;
function lido(b?: string): Filtro {
  try { const f = JSON.parse(localStorage.getItem(chave(b)) || 'null'); if (f && f.ordem) return { ...f, biblioteca: b, letra: undefined }; } catch { /* nada */ }
  return { biblioteca: b, ordem: 'recentes', naoVistos: false };
}

export function Explorar({ s, biblioteca }: { s: Sessao; biblioteca?: string }) {
  const [bibs, setBibs] = useState<Item[]>([]);
  const [gens, setGens] = useState<Genero[]>([]);
  const [f, setF] = useState<Filtro>(() => lido(biblioteca));
  const [itens, setItens] = useState<Item[]>([]);
  const [total, setTotal] = useState<number | null>(null);
  const [carregando, setCarregando] = useState(false);
  const [ordemAberta, setOrdemAberta] = useState(false);
  const fim = useRef<HTMLDivElement>(null);
  const pedido = useRef(0);

  useEffect(() => { bibliotecasDeVideo(s).then(setBibs).catch(() => {}); }, []);
  useEffect(() => { setF(lido(biblioteca)); }, [biblioteca]);
  useEffect(() => { generos(s, f.biblioteca).then(setGens).catch(() => setGens([])); }, [f.biblioteca]);
  useEffect(() => {
    try { const { letra: _l, biblioteca: _b, ...guardar } = f; localStorage.setItem(chave(f.biblioteca), JSON.stringify(guardar)); } catch { /* nada */ }
    setItens([]); setTotal(null); mais(true);
  }, [f]);

  function mais(zerar = false) {
    const n = ++pedido.current, de = zerar ? 0 : itens.length;
    setCarregando(true);
    explorar(s, f, de, PAGINA).then(r => {
      if (n !== pedido.current) return;
      setItens(a => zerar ? r.Items : [...a, ...r.Items]); setTotal(r.TotalRecordCount);
    }).catch(() => {}).finally(() => n === pedido.current && setCarregando(false));
  }
  useEffect(() => {
    const el = fim.current; if (!el) return;
    const o = new IntersectionObserver(e => { if (e[0].isIntersecting && !carregando && total !== null && itens.length < total) mais(); }, { rootMargin: '900px' });
    o.observe(el); return () => o.disconnect();
  }, [carregando, total, itens.length]);

  const mudar = (p: Partial<Filtro>) => setF(a => ({ ...a, ...p }));
  const atual = bibs.find(b => b.Id === f.biblioteca);
  const nomeOrdem = ORDENS.find(o => o.id === f.ordem)?.nome;
  return (
    <div class="explorar">
      <header class="explorar-topo">
        <h1>{atual?.Name || 'Explorar'}</h1>
        <p class="explorar-conta" aria-live="polite">{total === null ? ' ' : `${total.toLocaleString('pt-BR')} título${total === 1 ? '' : 's'}`}</p>
      </header>
      <div class="explorar-filtros">
        <div class="chips" role="tablist" aria-label="Bibliotecas">
          <button role="tab" aria-selected={!f.biblioteca} class={`chip${!f.biblioteca ? ' ativo' : ''}`} onClick={() => irAba('b')}>Tudo</button>
          {bibs.map(b => <button key={b.Id} role="tab" aria-selected={b.Id === f.biblioteca} class={`chip${b.Id === f.biblioteca ? ' ativo' : ''}`}
            onClick={() => irAba(`b/${b.Id}`)}>{b.Name}</button>)}
        </div>
        <div class="explorar-linha">
          <div class="menu-ordem">
            <button class="chip contorno" aria-haspopup="menu" aria-expanded={ordemAberta} onClick={() => setOrdemAberta(!ordemAberta)}>
              <Ic n="sort" t={18} />{nomeOrdem}<Ic n="keyboard_arrow_down" t={18} /></button>
            {ordemAberta && <div class="menu" role="menu" onKeyDown={e => e.key === 'Escape' && setOrdemAberta(false)}>
              {ORDENS.map(o => <button key={o.id} role="menuitemradio" aria-checked={o.id === f.ordem} class={o.id === f.ordem ? 'ativo' : ''}
                onClick={() => { mudar({ ordem: o.id as Ordem }); setOrdemAberta(false); }}>
                <span class="menu-texto">{o.nome}</span>{o.id === f.ordem && <Ic n="check" t={18} />}</button>)}
            </div>}
          </div>
          <label class="alternar">
            <input type="checkbox" checked={f.naoVistos} onChange={e => mudar({ naoVistos: (e.target as HTMLInputElement).checked })} />
            <span class="alternar-trilho" aria-hidden="true" /><span>Só não vistos</span>
          </label>
          <select class="chip contorno" aria-label="Gênero" value={f.genero || ''} onChange={e => mudar({ genero: (e.target as HTMLSelectElement).value || undefined })}>
            <option value="">Todos os gêneros</option>
            {gens.map(g => <option key={g.Id} value={g.Id}>{g.Name}</option>)}
          </select>
        </div>
        {f.ordem === 'nome' && <nav class="letras" aria-label="Pular para a letra">
          {LETRAS.map(l => <button key={l} class={f.letra === l ? 'ativo' : ''} aria-pressed={f.letra === l} onClick={() => mudar({ letra: f.letra === l ? undefined : l })}>{l}</button>)}
        </nav>}
      </div>
      <div class="grade" aria-busy={carregando}>
        {itens.map((i, k) => <Poster key={i.Id} s={s} i={i} ordem={k % PAGINA} />)}
        {carregando && Array.from({ length: itens.length ? 12 : 24 }, (_, k) => <div key={`f${k}`} class="cartao poster fantasma" aria-hidden="true"><span class="cartao-arte osso" /><span class="osso" style="width:70%" /></div>)}
      </div>
      {!carregando && total === 0 && <div class="vazio"><Ic n="search_off" t={32} /><p>Nada com esses filtros.</p>
        <button class="botao" onClick={() => setF({ biblioteca: f.biblioteca, ordem: f.ordem, naoVistos: false })}>Limpar filtros</button></div>}
      <div ref={fim} class="explorar-fim" />
    </div>
  );
}
