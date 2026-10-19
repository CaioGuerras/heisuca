// Cor: sRGB ↔ OKLab/OKLCH (Björn Ottosson, domínio público) e contraste da WCAG 2.x. Sem dependência.
export type RGB = [number, number, number];          // 0–255
export type LCH = { l: number; c: number; h: number }; // l 0–1, c ~0–0.37, h em graus

const lin = (v: number) => { v /= 255; return v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4; };
const gama = (v: number) => 255 * (v <= 0.0031308 ? 12.92 * v : 1.055 * v ** (1 / 2.4) - 0.055);

export function paraOklab([r8, g8, b8]: RGB): [number, number, number] {
  const r = lin(r8), g = lin(g8), b = lin(b8);
  const l = Math.cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  const m = Math.cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  const s = Math.cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  return [0.2104542553 * l + 0.793617785 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.428592205 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.808675766 * s];
}

function deOklab(L: number, a: number, b: number): [number, number, number] {
  const l = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3;
  const m = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3;
  const s = (L - 0.0894841775 * a - 1.291485548 * b) ** 3;
  return [4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.707614701 * s];
}

export function paraLch(rgb: RGB): LCH {
  const [l, a, b] = paraOklab(rgb);
  return { l, c: Math.hypot(a, b), h: ((Math.atan2(b, a) * 180) / Math.PI + 360) % 360 };
}

// OKLCH → sRGB, reduzindo o croma até caber no sRGB (mantém claridade e matiz)
export function deLch({ l, c, h }: LCH): RGB {
  const rad = (h * Math.PI) / 180;
  for (let cc = c; cc >= 0; cc -= 0.004) {
    const lr = deOklab(l, cc * Math.cos(rad), cc * Math.sin(rad));
    if (lr.every(v => v >= -0.0005 && v <= 1.0005)) return lr.map(v => Math.round(Math.min(255, Math.max(0, gama(Math.min(1, Math.max(0, v))))))) as RGB;
  }
  const g = Math.round(gama(Math.min(1, Math.max(0, l ** 3))));
  return [g, g, g];
}

export const luminancia = ([r, g, b]: RGB) => 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b);
export function contraste(a: RGB, b: RGB): number {
  const la = luminancia(a), lb = luminancia(b);
  return (Math.max(la, lb) + 0.05) / (Math.min(la, lb) + 0.05);
}

// mistura em OKLab (peso p da cor b)
export function misturar(a: RGB, b: RGB, p: number): RGB {
  const x = paraOklab(a), y = paraOklab(b);
  const m = x.map((v, i) => v + (y[i] - v) * p) as [number, number, number];
  const c = Math.hypot(m[1], m[2]);
  return deLch({ l: m[0], c, h: ((Math.atan2(m[2], m[1]) * 180) / Math.PI + 360) % 360 });
}

// mesma matiz, claridade ajustada até o contraste pedido contra o fundo (sobe se o fundo é escuro, desce se é claro)
export function comContraste(cor: LCH, fundo: RGB, alvo: number): RGB {
  const escuro = luminancia(fundo) < 0.18;
  let lo = escuro ? cor.l : 0, hi = escuro ? 1 : cor.l;
  const ok = (l: number) => contraste(deLch({ ...cor, l }), fundo) >= alvo;
  if (ok(cor.l)) return deLch(cor);
  // fundo escuro: menor claridade que ainda passa (hi sempre passa); fundo claro: maior claridade que passa (lo sempre passa)
  for (let i = 0; i < 22; i++) {
    const meio = (lo + hi) / 2;
    if (ok(meio)) { if (escuro) hi = meio; else lo = meio; }
    else if (escuro) lo = meio; else hi = meio;
  }
  return deLch({ ...cor, l: escuro ? hi : lo });
}

export const hex = (h: string): RGB => {
  const x = h.replace('#', '');
  const n = parseInt(x.length === 3 ? x.split('').map(c => c + c).join('') : x, 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
};
export const css = ([r, g, b]: RGB, a = 1) => a >= 1 ? `rgb(${r} ${g} ${b})` : `rgb(${r} ${g} ${b} / ${a})`;
