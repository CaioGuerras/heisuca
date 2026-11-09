import { useState } from 'preact/hooks';
import { previaImagem, type Item, type Sessao } from '../api/servidor.ts';
import { relogio } from '../comp/Cartoes';

export function PreviaBarra({ s, it, pos, dur, buscar }: { s: Sessao; it: Item | null; pos: number; dur: number; buscar: (seg: number) => void }) {
  const [ponto, setPonto] = useState<{ seg: number; fracao: number; largura: number } | null>(null);
  const [falhou, setFalhou] = useState('');
  const imagem = ponto && it ? previaImagem(s, it, ponto.seg) : null;
  const escala = imagem ? Math.min(1, 160 / imagem.largura) : 1;
  const medir = (ev: PointerEvent & { currentTarget: HTMLInputElement }) => {
    if (ev.pointerType === 'touch') return;
    const r = ev.currentTarget.getBoundingClientRect();
    const fracao = Math.max(0, Math.min(1, (ev.clientX - r.left) / (r.width || 1)));
    setPonto({ seg: fracao * dur, fracao, largura: r.width });
  };
  const largura = imagem ? imagem.largura * escala : 64;
  const esquerda = ponto ? Math.max(largura / 2, Math.min(ponto.largura - largura / 2, ponto.fracao * ponto.largura)) : 0;
  return <div class="player-progresso">
    <input class="player-barra" type="range" min={0} max={Number.isFinite(dur) ? dur : 0} step={1} value={pos} aria-label="Posição"
      aria-valuetext={`${relogio(pos)} de ${relogio(dur)}`}
      style={{ '--feito': `${dur ? pos / dur * 100 : 0}%` }}
      onInput={ev => buscar(Number(ev.currentTarget.value))}
      onPointerEnter={medir} onPointerMove={medir} onPointerLeave={() => setPonto(null)} onBlur={() => setPonto(null)} />
    {ponto && <div class="player-previa" role="tooltip" style={{ left: esquerda, width: largura }}>
      {imagem && falhou !== imagem.url && <>
        <div class="player-previa-imagem" style={{ width: largura, height: imagem.altura * escala,
          backgroundImage: `url("${imagem.url}")`, backgroundPosition: `-${imagem.x * escala}px -${imagem.y * escala}px`,
          backgroundSize: `${imagem.larguraFolha * escala}px ${imagem.alturaFolha * escala}px`,
        }} />
        {/* O mesmo pedido fica no cache; detecta falhas para manter apenas o tempo. */}
        <img class="visualmente-oculto" src={imagem.url} alt="" onError={() => setFalhou(imagem.url)} />
      </>}
      <span>{relogio(ponto.seg)}</span>
    </div>}
  </div>;
}
