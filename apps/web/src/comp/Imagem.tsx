// BlurHash real enquanto carrega; cada URL tem estado próprio, inclusive depois de uma falha.
import { useEffect, useMemo, useState } from 'preact/hooks';
import { corMedia, fundoDesfocado } from '../cor/paleta';

type Props = { src?: string; alt?: string; hash?: string; classe?: string; prioridade?: boolean; aoErro?: () => void };
export function Imagem(props: Props) {
  return <Conteudo key={props.src || ''} {...props} />;
}
// URLs já decodificadas nesta visita: remontar (prévia → página pronta, voltar) mostra na hora, sem refazer o fade
const prontas = new Set<string>();
function Conteudo({ src, alt = '', hash, classe = '', prioridade = false, aoErro }: Props) {
  const [ok, setOk] = useState(() => !!src && prontas.has(src));
  const [falhou, setFalhou] = useState(false);
  const [desfocado, setDesfocado] = useState('');
  const fundo = useMemo(() => corMedia(hash), [hash]);
  // A cor média entra primeiro; o desenho do hash vem após a montagem, fora do render.
  useEffect(() => { setDesfocado(fundoDesfocado(hash)); }, [hash]);
  return (
    <span class={`img ${classe}`} style={{ backgroundColor: fundo, backgroundImage: desfocado ? `url(${desfocado})` : undefined }}>
      {src && !falhou && (
        <img src={src} alt={alt} decoding="async" loading={prioridade ? 'eager' : 'lazy'}
          {...{ fetchpriority: prioridade ? 'high' : 'auto' }}
          class={ok ? 'ok' : ''} onLoad={async e => {
            const img = e.currentTarget;
            await img.decode().catch(() => undefined);
            if (prontas.size > 600) prontas.clear();
            if (src) prontas.add(src);
            setOk(true);
          }} onError={() => { setFalhou(true); aoErro?.(); }} />
      )}
    </span>
  );
}
