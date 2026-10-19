// Tela carregada sob demanda (o pacote inicial fica só com o que a home precisa; PLANO §15: orçamento de desempenho).
// `pre()` baixa antes de a pessoa tocar (a casca chama quando o navegador fica ocioso), então a tela abre na hora.
import type { ComponentType } from 'preact';
import { useEffect, useState } from 'preact/hooks';

export function sobDemanda<M extends Record<string, unknown>, K extends keyof M>(carregar: () => Promise<M>, nome: K) {
  type Props = M[K] extends ComponentType<infer P> ? P : never;
  let mod: M | null = null;
  let pedido: Promise<M> | null = null;
  const pre = () => (pedido ??= carregar().then(m => (mod = m)));
  function Tela(props: Props) {
    const [m, setM] = useState(mod);
    useEffect(() => { if (!m) pre().then(setM); }, []);
    if (!m) return null;
    const C = m[nome] as unknown as ComponentType<Props>;
    return <C {...(props as Props & object)} />;
  }
  return Object.assign(Tela, { pre });
}
