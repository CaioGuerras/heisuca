// Imagem com a cor média do BlurHash por baixo enquanto carrega, e entrada suave (sem "pulo" de layout: a caixa tem
// proporção fixa no CSS de quem usa).
import { useState } from 'preact/hooks';
import { corMedia } from '../cor/paleta';

export function Imagem({ src, alt = '', hash, classe = '', prioridade = false }:
  { src?: string; alt?: string; hash?: string; classe?: string; prioridade?: boolean }) {
  const [ok, setOk] = useState(false);
  const [falhou, setFalhou] = useState(false);
  const fundo = corMedia(hash);
  return (
    <span class={`img ${classe}`} style={fundo ? { backgroundColor: fundo } : undefined}>
      {src && !falhou && (
        <img src={src} alt={alt} decoding="async" loading={prioridade ? 'eager' : 'lazy'}
          {...{ fetchpriority: prioridade ? 'high' : 'auto' }}
          class={ok ? 'ok' : ''} onLoad={() => setOk(true)} onError={() => setFalhou(true)} />
      )}
    </span>
  );
}
