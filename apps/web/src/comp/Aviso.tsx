// Aviso curto no rodapé (toast), acima da ilha. avisar('texto') de qualquer lugar.
import { useEffect, useRef, useState } from 'preact/hooks';

let mostrar: ((t: string) => void) | null = null;
export const avisar = (t: string) => mostrar?.(t);

export function Aviso() {
  const [t, setT] = useState(''); const tempo = useRef(0);
  useEffect(() => {
    mostrar = x => { setT(x); clearTimeout(tempo.current); tempo.current = window.setTimeout(() => setT(''), 3800); };
    return () => { mostrar = null; };
  }, []);
  return <div class={t ? 'aviso visivel' : 'aviso'} role="status" aria-live="polite">{t}</div>;
}
