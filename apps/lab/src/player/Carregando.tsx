// Carregamento do player no Lume: a chama da marca respira enquanto o vídeo não chega (sem o selo do Heisuca).
export function Carregando() {
  return (
    <div class="lume-carregando" role="status" aria-label="Carregando">
      <svg viewBox="0 0 64 64" width="56" height="56" aria-hidden="true">
        <path d="M32 10c7 10 12 17 12 25a12 12 0 0 1-24 0c0-8 5-15 12-25z" fill="var(--acento)" />
        <path d="M32 28c3 4 5 7 5 10a5 5 0 0 1-10 0c0-3 2-6 5-10z" fill="var(--fundo)" opacity=".55" />
      </svg>
    </div>
  );
}
