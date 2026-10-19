// A cor de cada tela sai do pôster (PLANO §2.2): BlurHash do servidor → cor da faixa de baixo da imagem (onde ela se
// dissolve na página) → claridade do tema (Roxo escuro, Verde claro) → um toque da primária do tema → contraste AA medido.
import { decode } from 'blurhash';
import { useEffect } from 'preact/hooks';
import { comContraste, contraste, css, deLch, hex, misturar, paraLch, type RGB } from './oklch';
import { aoMudarTema, temaEfetivo } from '../tema';

export type Paleta = { escuro: boolean; pagina: RGB; superficie: RGB; texto: RGB; texto2: RGB };

const pix = new Map<string, Uint8ClampedArray>();
function pixels(hash: string, w: number, h: number): Uint8ClampedArray | null {
  const k = `${hash}|${w}x${h}`;
  if (!pix.has(k)) { try { pix.set(k, decode(hash, w, h)); } catch { return null; } }
  return pix.get(k)!;
}

// média da faixa de baixo (40% finais): é a parte da arte que encosta na página
export function corDaBase(hash?: string | null): RGB | null {
  if (!hash) return null;
  const w = 12, h = 10, p = pixels(hash, w, h);
  if (!p) return null;
  let r = 0, g = 0, b = 0, n = 0;
  for (let y = Math.floor(h * 0.6); y < h; y++) for (let x = 0; x < w; x++) { const i = (y * w + x) * 4; r += p[i]; g += p[i + 1]; b += p[i + 2]; n++; }
  return [Math.round(r / n), Math.round(g / n), Math.round(b / n)];
}

// cor média da imagem inteira (fundo do cartão enquanto a imagem carrega)
const medias = new Map<string, string>();
export function corMedia(hash?: string | null): string | undefined {
  if (!hash) return undefined;
  if (!medias.has(hash)) {
    const p = pixels(hash, 4, 4);
    if (!p) return undefined;
    let r = 0, g = 0, b = 0;
    for (let i = 0; i < 64; i += 4) { r += p[i]; g += p[i + 1]; b += p[i + 2]; }
    medias.set(hash, css([Math.round(r / 16), Math.round(g / 16), Math.round(b / 16)]));
  }
  return medias.get(hash);
}

// fundo desfocado (Favoritos, Biblioteca): o próprio BlurHash em 32×18, ampliado pelo CSS. Desfoque sem custo de GPU.
const fundos = new Map<string, string>();
export function fundoDesfocado(hash?: string | null): string {
  if (!hash) return '';
  if (fundos.has(hash)) return fundos.get(hash)!;
  const w = 32, h = 18, p = pixels(hash, w, h);
  if (!p) return '';
  const c = document.createElement('canvas'); c.width = w; c.height = h;
  const ctx = c.getContext('2d'); if (!ctx) return '';
  const img = ctx.createImageData(w, h); img.data.set(p); ctx.putImageData(img, 0, 0);
  const url = c.toDataURL('image/png');
  fundos.set(hash, url);
  return url;
}

const varTema = (nome: string) => getComputedStyle(document.documentElement).getPropertyValue(`--hs-tema-cor-${nome}`).trim() || '#000';

export function paletaDe(base: RGB | null): Paleta {
  const escuro = temaEfetivo() === 'shikkoku';
  const prim = hex(varTema('primaria'));
  if (!base) {
    const pagina = hex(varTema('fundo'));
    return { escuro, pagina, superficie: hex(varTema('superficie')), texto: hex(varTema('texto')), texto2: hex(varTema('texto-2')) };
  }
  const b = paraLch(base);
  const croma = (f: number, min: number, max: number) => Math.min(max, Math.max(min, b.c * f));
  let pagina: RGB, superficie: RGB, texto: RGB, texto2: RGB;
  if (escuro) {
    pagina = misturar(deLch({ l: 0.215, c: croma(0.7, 0.014, 0.06), h: b.h }), prim, 0.1);
    superficie = misturar(deLch({ l: 0.27, c: croma(0.5, 0.012, 0.045), h: b.h }), prim, 0.1);
    texto = hex(varTema('texto'));
    texto2 = comContraste({ l: 0.74, c: Math.min(b.c * 0.3, 0.03), h: b.h }, superficie, 4.6);
  } else {
    // ref/vidhub/…home_topo: o claro do VidHub é um pastel de verdade (InuYasha ≈ L 0,68), não um papel quase branco.
    // Ficamos um pouco mais claros que ele (0,80) e com mais croma que a v1, para a cor do pôster aparecer.
    pagina = misturar(deLch({ l: 0.8, c: croma(0.85, 0.014, 0.075), h: b.h }), prim, 0.04);
    superficie = misturar(deLch({ l: 0.93, c: croma(0.4, 0.008, 0.04), h: b.h }), prim, 0.05);
    texto = comContraste({ l: 0.2, c: 0.02, h: b.h }, pagina, 10);
    texto2 = comContraste({ l: 0.46, c: Math.min(b.c * 0.4, 0.035), h: b.h }, pagina, 4.6);
  }
  // garantia: o texto principal nunca abaixo de 7:1 nem o secundário abaixo de 4,5:1 sobre a página
  if (contraste(texto, pagina) < 7) texto = comContraste(paraLch(texto), pagina, 7);
  if (contraste(texto2, pagina) < 4.5) texto2 = comContraste(paraLch(texto2), pagina, 4.5);
  return { escuro, pagina, superficie, texto, texto2 };
}

// grava a paleta nas variáveis da página (as transições do CSS fazem o crossfade da cor)
export function aplicarPaleta(p: Paleta, alvo: HTMLElement = document.documentElement) {
  const v = (k: string, x: string) => alvo.style.setProperty(k, x);
  v('--hs-pagina', css(p.pagina)); v('--hs-superficie', css(p.superficie));
  v('--hs-texto', css(p.texto)); v('--hs-texto-2', css(p.texto2));
  v('--hs-linha', css(p.texto, 0.12)); v('--hs-pagina-0', css(p.pagina, 0));
  v('--hs-vidro', p.escuro ? css(misturar(p.pagina, [255, 255, 255], 0.1), 0.62) : css([255, 255, 255], 0.74));
  v('--hs-vidro-borda', p.escuro ? css([255, 255, 255], 0.08) : css([255, 255, 255], 0.7));
  if (alvo === document.documentElement) document.querySelector('meta[name="theme-color"]')?.setAttribute('content', css(p.pagina));
}

let ultima: RGB | null = null;
aoMudarTema(() => aplicarPaleta(paletaDe(ultima)));

// Hook: a tela diz qual imagem manda na cor (hash do fundo do destaque, da série, do 1º favorito…). null = cor do tema.
export function usePaleta(hash?: string | null) {
  useEffect(() => {
    ultima = corDaBase(hash);
    aplicarPaleta(paletaDe(ultima));
  }, [hash]);
}
