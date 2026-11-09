// Paleta de comandos (⌘K ou /): busca ao vivo no acervo, buscas recentes e comandos (temas, ir a, sair).
// Setas escolhem, Enter abre, Esc fecha. Uma lista só, com aria-activedescendant (leitores de tela acompanham).
import { useEffect, useMemo, useRef, useState } from 'preact/hooks';
import { capa, hashDe, type Item, type Sessao } from '@w/api/servidor';
import { Imagem } from '@w/comp/Imagem';
import { irAba, irTitulo } from '@w/rota';
import { buscaRapida, esquecerBusca, lembrarBusca, recentes } from '../dados/catalogo';
import { TEMAS, trocarTema } from '../tema';
import { Ic } from './Icone';

type Linha = { id: string; grupo: string; nome: string; sub?: string; ic?: string; item?: Item; fazer: () => void; remover?: () => void };
const TIPO: Record<string, string> = { Movie: 'Filme', Series: 'Série', Episode: 'Episódio' };

export function Paleta({ s, aberta, fechar, atalhos }: { s: Sessao; aberta: boolean; fechar: () => void; atalhos: () => void }) {
  const d = useRef<HTMLDialogElement>(null);
  const campo = useRef<HTMLInputElement>(null);
  const [texto, setTexto] = useState('');
  const [achados, setAchados] = useState<Item[] | null>(null);
  const [buscando, setBuscando] = useState(false);
  const [sel, setSel] = useState(0);
  const [, setVersao] = useState(0);

  useEffect(() => {
    const x = d.current; if (!x) return;
    if (aberta && !x.open) { x.showModal(); setTexto(''); setAchados(null); setSel(0); requestAnimationFrame(() => campo.current?.focus()); }
    if (!aberta && x.open) x.close();
  }, [aberta]);

  useEffect(() => {
    const t = texto.trim();
    if (t.length < 2) { setAchados(null); setBuscando(false); return; }
    const c = new AbortController();
    setBuscando(true);
    const espera = setTimeout(() => {
      buscaRapida(s, t, c.signal).then(r => { setAchados(r); setSel(0); }).catch(() => undefined).finally(() => { if (!c.signal.aborted) setBuscando(false); });
    }, 160);
    return () => { clearTimeout(espera); c.abort(); };
  }, [texto]);

  const abrir = (i: Item) => {
    lembrarBusca(texto.trim() || i.Name);
    fechar();
    const id = i.Type === 'Episode' && i.SeriesId ? i.SeriesId : i.Id;
    irTitulo(id, i.Type === 'Episode' ? undefined : i);
  };

  const linhas = useMemo<Linha[]>(() => {
    const t = texto.trim().toLowerCase();
    const comandos: Linha[] = [
      { id: 'c-inicio', grupo: 'Ir para', nome: 'Início', ic: 'home', fazer: () => { fechar(); irAba(''); } },
      { id: 'c-explorar', grupo: 'Ir para', nome: 'Explorar o acervo', ic: 'explore', fazer: () => { fechar(); irAba('b'); } },
      { id: 'c-lista', grupo: 'Ir para', nome: 'Minha lista', ic: 'bookmark', fazer: () => { fechar(); irAba('fav'); } },
      ...TEMAS.map(x => ({ id: `t-${x.id}`, grupo: 'Tema', nome: `Tema ${x.nome}`, sub: x.dica, ic: x.icone, fazer: () => { fechar(); trocarTema(x.id); } })),
      { id: 'c-atalhos', grupo: 'Ajuda', nome: 'Atalhos do teclado', ic: 'keyboard', fazer: atalhos },
    ];
    if (!t) {
      const rec: Linha[] = recentes().map(r => ({ id: `r-${r}`, grupo: 'Buscas recentes', nome: r, ic: 'history',
        fazer: () => setTexto(r), remover: () => { esquecerBusca(r); setVersao(v => v + 1); } }));
      return [...rec, ...comandos];
    }
    const acervo: Linha[] = (achados || []).map(i => ({ id: `i-${i.Id}`, grupo: 'No acervo', item: i, nome: i.Type === 'Episode' ? `${i.SeriesName} — ${i.Name}` : i.Name,
      sub: [TIPO[i.Type] || '', i.ProductionYear || '', i.Type === 'Episode' ? `T${i.ParentIndexNumber} E${i.IndexNumber}` : ''].filter(Boolean).join(' · '),
      fazer: () => abrir(i) }));
    return [...acervo, ...comandos.filter(c => c.nome.toLowerCase().includes(t))];
  }, [texto, achados]);

  useEffect(() => { if (sel >= linhas.length) setSel(Math.max(0, linhas.length - 1)); }, [linhas.length]);
  useEffect(() => { document.getElementById(`pl-${sel}`)?.scrollIntoView({ block: 'nearest' }); }, [sel]);

  const tecla = (e: KeyboardEvent) => {
    if (e.key === 'ArrowDown') { e.preventDefault(); setSel(x => Math.min(linhas.length - 1, x + 1)); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setSel(x => Math.max(0, x - 1)); }
    else if (e.key === 'Enter') { e.preventDefault(); linhas[sel]?.fazer(); }
  };

  let grupo = '';
  return (
    <dialog ref={d} class="paleta" onClose={fechar} onClick={e => { if (e.target === d.current) fechar(); }} aria-label="Buscar">
      <div class="paleta-campo">
        <Ic n={buscando ? 'progress_activity' : 'search'} t={22} classe={buscando ? 'girando' : ''} />
        <input ref={campo} type="search" value={texto} placeholder="Buscar filmes, séries, episódios ou comandos"
          onInput={e => setTexto((e.currentTarget as HTMLInputElement).value)} onKeyDown={tecla}
          role="combobox" aria-expanded="true" aria-controls="paleta-lista" aria-activedescendant={linhas.length ? `pl-${sel}` : undefined}
          autocomplete="off" spellcheck={false} enterKeyHint="search" />
        <kbd class="paleta-esc">Esc</kbd>
      </div>
      <ul id="paleta-lista" class="paleta-lista" role="listbox" aria-label="Resultados">
        {linhas.map((l, k) => {
          const cab = l.grupo !== grupo ? (grupo = l.grupo) : null;
          return [
            cab && <li key={`g-${cab}`} class="paleta-grupo" role="presentation">{cab}
              {cab === 'Buscas recentes' && <button onClick={() => { esquecerBusca(); setVersao(v => v + 1); }}>Limpar</button>}</li>,
            <li key={l.id} id={`pl-${k}`} role="option" aria-selected={k === sel} class={`paleta-linha${k === sel ? ' sel' : ''}`}
              onPointerMove={() => setSel(k)} onClick={() => l.fazer()}>
              {l.item ? <Imagem classe="paleta-capa" src={capa(s, l.item, 120)} hash={hashDe(s, l.item, 'Primary')} /> : <span class="paleta-ic"><Ic n={l.ic || 'north_west'} t={20} /></span>}
              <span class="paleta-texto"><span>{l.nome}</span>{l.sub && <small>{l.sub}</small>}</span>
              {l.remover ? <button class="paleta-remover" aria-label={`Remover ${l.nome} das recentes`} onClick={e => { e.stopPropagation(); l.remover!(); }}><Ic n="close" t={16} /></button>
                : k === sel && <kbd>↵</kbd>}
            </li>,
          ];
        })}
        {texto.trim().length >= 2 && achados && !achados.length && !buscando && <li class="paleta-vazio" role="presentation">Nada com “{texto.trim()}” no acervo.</li>}
      </ul>
    </dialog>
  );
}
