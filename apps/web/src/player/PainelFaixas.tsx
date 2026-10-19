// Painel "Áudio e legendas" (PLANO §13; modelo: app_completo/…foto25, que o Caio elogiou): duas colunas com ✕ no
// computador e no celular deitado, uma coluna rolável no celular em pé. Fecha no ✕, tocando fora, no Esc ou ao escolher:
// nunca fica preso sobre o vídeo (erro de heisuca_reprovado/…foto20).
// "Buscar legendas…" só para quem tem a permissão de gerenciar legendas: busca PT-BR (pob) e mostra Portugal (por) à parte.
import { useEffect, useRef, useState } from 'preact/hooks';
import type { Fluxo, LegendaRemota } from '../api/jellyfin';
import { Icone } from '../comp/Icone';
import { rotuloFaixa } from './faixas';

type Props = {
  audios: Fluxo[]; legendas: Fluxo[]; audio?: number; legenda: number;
  escolherAudio: (i: number) => void; escolherLegenda: (i: number) => void; fechar: () => void;
  podeBuscar: boolean; buscar: (lingua: 'pob' | 'por') => Promise<LegendaRemota[]>; baixar: (r: LegendaRemota) => Promise<void>;
};
type Lista = { itens: LegendaRemota[]; erro?: string } | null;

function Opcao({ ativa, nome, detalhe, onClick }: { ativa: boolean; nome: string; detalhe?: string; onClick: () => void }) {
  return (
    <button class={ativa ? 'painel-opcao ativa' : 'painel-opcao'} onClick={onClick} aria-pressed={ativa}>
      <span><strong>{nome}</strong>{detalhe && <small>{detalhe}</small>}</span>
      {ativa && <Icone nome="check" tamanho={22} />}
    </button>
  );
}

export function PainelFaixas(p: Props) {
  const caixa = useRef<HTMLDivElement>(null);
  const [busca, setBusca] = useState(false);
  const [br, setBr] = useState<Lista>(null);
  const [pt, setPt] = useState<Lista>(null);
  const [baixando, setBaixando] = useState('');
  const [falhou, setFalhou] = useState('');

  // Tab não sai do painel (aria-modal): do último volta ao primeiro e vice-versa
  useEffect(() => {
    const tecla = (e: KeyboardEvent) => {
      if (e.key !== 'Tab' || !caixa.current) return;
      const f = Array.from(caixa.current.querySelectorAll<HTMLElement>('button:not([disabled]), [href], input, [tabindex]:not([tabindex="-1"])'));
      if (!f.length) return;
      const i = f.indexOf(document.activeElement as HTMLElement);
      if (i === -1 || (e.shiftKey && i === 0) || (!e.shiftKey && i === f.length - 1)) { e.preventDefault(); (e.shiftKey ? f[f.length - 1] : f[0]).focus(); }
    };
    addEventListener('keydown', tecla, true);
    return () => removeEventListener('keydown', tecla, true);
  }, []);

  // foco no item escolhido (teclado) ao abrir e ao trocar de vista
  useEffect(() => {
    const el = caixa.current?.querySelector<HTMLElement>('.painel-opcao.ativa, .painel-fechar');
    el?.focus({ preventScroll: true });
  }, [busca]);

  function abrirBusca() {
    setBusca(true);
    if (br) return;
    const ler = (l: 'pob' | 'por', pronto: (x: Lista) => void) => p.buscar(l)
      .then(itens => pronto({ itens }))
      .catch(() => pronto({ itens: [], erro: 'A busca não respondeu. Tente de novo mais tarde.' }));
    ler('pob', setBr);
    // "por" mistura resultados do Brasil: o que já veio em PT-BR não se repete embaixo
    ler('por', x => setPt(x));
  }
  const ptSemRepetir = pt && br ? { ...pt, itens: pt.itens.filter(r => !br.itens.some(b => b.Id === r.Id)) } : pt;

  async function baixar(r: LegendaRemota) {
    if (baixando) return;
    setBaixando(r.Id); setFalhou('');
    try { await p.baixar(r); } catch { setFalhou(r.Id); } finally { setBaixando(''); }
  }

  const resultado = (r: LegendaRemota) => (
    <button key={r.Id} class="painel-opcao painel-resultado" onClick={() => baixar(r)} disabled={!!baixando && baixando !== r.Id}>
      <span>
        <strong>{r.Name || r.Id}</strong>
        <small>{falhou === r.Id ? 'Não deu para baixar. Tente outra.'
          : [r.ProviderName, r.Format?.toUpperCase(), r.DownloadCount ? `${r.DownloadCount.toLocaleString('pt-BR')} downloads` : '',
            r.IsHashMatch ? 'feita para este arquivo' : ''].filter(Boolean).join(' · ')}</small>
      </span>
      <Icone nome={baixando === r.Id ? 'progress_activity' : 'download'} tamanho={22} classe={baixando === r.Id ? 'girando' : ''} />
    </button>
  );
  const secao = (titulo: string, l: Lista) => (
    <section class="painel-coluna">
      <h3>{titulo}</h3>
      {!l ? <p class="painel-nota">Buscando…</p>
        : l.erro ? <p class="painel-nota">{l.erro}</p>
        : !l.itens.length ? <p class="painel-nota">Nada encontrado.</p>
        : l.itens.map(resultado)}
    </section>
  );

  return (
    <div class="painel-fundo" onClick={p.fechar}>
      <div ref={caixa} class={busca ? 'painel painel-busca' : 'painel'} role="dialog" aria-modal="true"
        aria-label={busca ? 'Buscar legendas' : 'Áudio e legendas'} onClick={ev => ev.stopPropagation()}>
        <header class="painel-cabeca">
          {busca
            ? <button class="painel-voltar" onClick={() => setBusca(false)} aria-label="Voltar para Áudio e legendas"><Icone nome="chevron_left" tamanho={26} /></button>
            : <Icone nome="subtitles" cheio tamanho={24} />}
          <h2>{busca ? 'Buscar legendas' : 'Áudio e legendas'}</h2>
          <button class="painel-fechar" onClick={p.fechar} aria-label="Fechar"><Icone nome="close" tamanho={24} /></button>
        </header>
        {busca ? (
          <div class="painel-corpo painel-corpo-busca">
            {secao('Português (Brasil)', br)}
            {secao('Português (Portugal)', ptSemRepetir)}
          </div>
        ) : (
          <div class="painel-corpo">
            <section class="painel-coluna">
              <h3>Áudio</h3>
              {p.audios.map(a => { const r = rotuloFaixa(a); return (
                <Opcao key={a.Index} ativa={a.Index === p.audio} nome={r.nome} detalhe={r.detalhe} onClick={() => p.escolherAudio(a.Index)} />); })}
            </section>
            <section class="painel-coluna">
              <h3>Legendas</h3>
              <Opcao ativa={p.legenda === -1} nome="Desligadas" onClick={() => p.escolherLegenda(-1)} />
              {p.legendas.map(l => { const r = rotuloFaixa(l); return (
                <Opcao key={l.Index} ativa={l.Index === p.legenda} nome={r.nome}
                  detalhe={[r.detalhe, l.DeliveryMethod === 'Encode' ? 'o servidor grava no vídeo' : ''].filter(Boolean).join(' · ')}
                  onClick={() => p.escolherLegenda(l.Index)} />); })}
              {p.podeBuscar && (
                <button class="painel-opcao painel-buscar" onClick={abrirBusca}>
                  <span><strong>Buscar legendas…</strong><small>Português, pela internet</small></span>
                  <Icone nome="search" tamanho={22} />
                </button>
              )}
            </section>
          </div>
        )}
      </div>
    </div>
  );
}
