// Navegação espacial (setas do controle da TV e do teclado). Escolhe o elemento [data-foco] mais próximo na direção.
type Dir = 'ArrowUp' | 'ArrowDown' | 'ArrowLeft' | 'ArrowRight';

function candidatos(): HTMLElement[] {
  return Array.from(document.querySelectorAll<HTMLElement>('[data-foco]')).filter(e => e.offsetParent !== null);
}

function proximo(atual: HTMLElement, dir: Dir): HTMLElement | null {
  const a = atual.getBoundingClientRect();
  const ax = a.left + a.width / 2, ay = a.top + a.height / 2;
  let melhor: HTMLElement | null = null, nota = Infinity;
  for (const e of candidatos()) {
    if (e === atual) continue;
    const b = e.getBoundingClientRect();
    const bx = b.left + b.width / 2, by = b.top + b.height / 2;
    const dx = bx - ax, dy = by - ay;
    const ok = dir === 'ArrowRight' ? dx > 1 : dir === 'ArrowLeft' ? dx < -1 : dir === 'ArrowDown' ? dy > 1 : dy < -1;
    if (!ok) continue;
    // eixo principal pesa 1, eixo cruzado pesa 3: mantém o foco na mesma fileira
    const n = dir === 'ArrowLeft' || dir === 'ArrowRight' ? Math.abs(dx) + 3 * Math.abs(dy) : Math.abs(dy) + 3 * Math.abs(dx);
    if (n < nota) { nota = n; melhor = e; }
  }
  return melhor;
}

export function ligarFoco(): void {
  addEventListener('keydown', ev => {
    if (!['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight'].includes(ev.key)) return;
    const atual = document.activeElement as HTMLElement | null;
    if (atual && atual.tagName === 'INPUT' && (ev.key === 'ArrowLeft' || ev.key === 'ArrowRight')) return;
    const alvo = atual && atual.hasAttribute('data-foco') ? proximo(atual, ev.key as Dir) : candidatos()[0];
    if (alvo) {
      ev.preventDefault();
      alvo.focus({ preventScroll: true });
      // [data-rola-sozinho]: a tela posiciona por transform (TV); rolar aqui desalinharia
      if (!alvo.closest('[data-rola-sozinho]')) alvo.scrollIntoView({ block: 'nearest', inline: 'nearest', behavior: 'smooth' });
    }
  });
}
