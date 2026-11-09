// A marca: uma chama (a luz da sala de cinema) e "Lume" em Fraunces itálico.
export function Chama({ t = 26 }: { t?: number }) {
  return (
    <svg class="chama" viewBox="0 0 64 64" width={t} height={t} aria-hidden="true">
      <path d="M32 6c8 11 14 19 14 28a14 14 0 0 1-28 0c0-9 6-17 14-28z" fill="var(--acento)" />
      <path d="M32 27c3.5 4.6 6 8 6 11.5a6 6 0 0 1-12 0c0-3.5 2.5-6.9 6-11.5z" fill="var(--fundo)" opacity=".5" />
    </svg>
  );
}
export function Marca({ t = 26 }: { t?: number }) {
  return <span class="marca"><Chama t={t} /><span class="marca-nome">Lume</span></span>;
}
