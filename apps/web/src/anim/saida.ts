// Saída de tela (H3, ESTUDO_MOVIMENTO_2026-11 §2): antes de a rota trocar, a tela atual (.troca-tela) é copiada para uma camada
// fixa, congelada onde estava, e some em 180 ms (opacidade + escala 0,98). A tela nova monta na hora e entra por
// baixo, 60 ms depois (transicoes.css). A cópia não tem ids, não recebe toque e sai do DOM no fim.
import { reduzido } from './voo';

const SAI = 180;                                   // --m-curto
const CURVA_SAI = 'cubic-bezier(0.3, 0, 0.8, 0.15)'; // --c-sai (escala)
const CURVA_PADRAO = 'cubic-bezier(0.2, 0, 0, 1)';   // --c-padrao (opacidade)
let camadaAtual: HTMLElement | null = null;

export function congelarSaida(doc: Document = document): void {
  camadaAtual?.remove(); camadaAtual = null;
  const troca = doc.querySelector<HTMLElement>('.casca > .troca-tela'), casca = troca?.parentElement;
  if (!troca || !casca || !troca.animate || doc.hidden) return;
  const caixa = troca.getBoundingClientRect();
  if (!caixa.width || caixa.bottom <= 0) return;

  // fixed e sticky dependem da rolagem e do viewport: mede antes de copiar e prende a cópia no mesmo lugar
  const orig = troca.querySelectorAll<HTMLElement>('*');
  // o que está todo abaixo ou à direita do viewport não aparece e sai da cópia (menos para pintar); tirar não
  // desloca o que está antes. Acima e à esquerda ficam, senão o resto subiria.
  const presos: { k: number; fixo: boolean; r: DOMRect }[] = [], fora: number[] = [];
  const vh = innerHeight, vw = innerWidth;
  for (let k = 0; k < orig.length; k++) {
    const p = getComputedStyle(orig[k]).position;
    if (p === 'fixed' || p === 'sticky') { presos.push({ k, fixo: p === 'fixed', r: orig[k].getBoundingClientRect() }); continue; }
    if (p === 'absolute') continue;
    const r = orig[k].getBoundingClientRect();
    if (r.top > vh || r.left > vw) fora.push(k);
  }

  const copia = troca.cloneNode(true) as HTMLElement;
  const todos = copia.querySelectorAll<HTMLElement>('*');
  for (const k of fora) todos[k].remove();
  for (const el of Array.from(copia.querySelectorAll('[id]'))) el.removeAttribute('id');
  for (const el of Array.from(copia.querySelectorAll('iframe'))) el.remove();
  for (const el of Array.from(copia.querySelectorAll<HTMLMediaElement>('video, audio'))) { el.removeAttribute('autoplay'); el.muted = true; }
  copia.removeAttribute('id');

  // a casca vai rasa (só as classes), para os seletores .tela-x / .com-ilha continuarem valendo
  const corpo = casca.cloneNode(false) as HTMLElement;
  corpo.classList.add('saida-tela-corpo');
  corpo.style.top = `${caixa.top}px`;
  corpo.appendChild(copia);

  const camada = doc.createElement('div');
  camada.className = 'saida-tela';
  camada.setAttribute('aria-hidden', 'true');
  camada.setAttribute('inert', '');
  camada.appendChild(corpo);
  doc.body.appendChild(camada);

  // fixed: no retângulo medido (a camada cobre o viewport). sticky: fica no fluxo e é deslocado até onde estava.
  for (const { k, fixo, r } of presos) {
    const el = todos[k];
    if (!el) continue;
    if (fixo) Object.assign(el.style, { position: 'fixed', top: `${r.top}px`, left: `${r.left}px`, width: `${r.width}px`, height: `${r.height}px`, right: 'auto', bottom: 'auto', margin: '0', transform: 'none' });
    else Object.assign(el.style, { position: 'relative', top: '0', bottom: 'auto' });
  }
  const soltos = presos.filter(p => !p.fixo && todos[p.k]).map(p => ({ el: todos[p.k], dy: p.r.top }));
  for (const p of soltos) p.dy -= p.el.getBoundingClientRect().top; // só leituras (um layout)
  for (const p of soltos) p.el.style.top = `${p.dy}px`;

  camadaAtual = camada;
  const fim = () => { camada.remove(); if (camadaAtual === camada) camadaAtual = null; };
  const opac = camada.animate([{ opacity: 1 }, { opacity: 0 }], { duration: SAI, easing: CURVA_PADRAO, fill: 'forwards' });
  if (!reduzido()) camada.animate([{ transform: 'none' }, { transform: 'scale(0.98)' }], { duration: SAI, easing: CURVA_SAI, fill: 'forwards' });
  opac.onfinish = fim;
  opac.oncancel = fim;
  setTimeout(fim, SAI + 400); // aba em segundo plano pode segurar o onfinish
}
