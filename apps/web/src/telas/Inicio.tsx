import { useEffect, useRef, useState } from 'preact/hooks';
import { bibliotecas, continuar, fundo, novidades, sair, type Item, type Sessao } from '../api/jellyfin';
import { Fileira } from '../comp/Fileira';
import { Icone } from '../comp/Icone';
import { aoVoltarNaRaiz, irTitulo, irVer } from '../rota';
import { ehTV } from '../tv';

type Linha = { titulo: string; itens: Item[]; tocar?: boolean };

// TV: a fileira focada sobe para o topo da área das fileiras e o cartão focado fica na margem esquerda (como Netflix e
// Prime Video). Só transform (regra de desempenho da TV); offsetTop/offsetLeft não mudam com transform, então a conta
// não depende do estado anterior. scrollTop/Left = 0 porque o Chromium 56 do Tizen 3 ignora focus({ preventScroll }).
// onde o foco estava (fileira, cartão), para voltar do título no mesmo lugar
let ultimo: [number, number] = [0, 0];

function posicionar(caixa: HTMLElement, pista: HTMLElement, cartao: HTMLElement) {
  const fileira = cartao.closest('.fileira') as HTMLElement | null;
  const trilho = cartao.parentElement as HTMLElement | null;
  if (!fileira || !trilho) return;
  const primeiro = trilho.firstElementChild as HTMLElement;
  ultimo = [Array.prototype.indexOf.call(pista.children, fileira), Array.prototype.indexOf.call(trilho.children, cartao)];
  pista.style.transform = `translateY(${-fileira.offsetTop}px)`;
  trilho.style.transform = `translateX(${primeiro.offsetLeft - cartao.offsetLeft}px)`;
  caixa.scrollTop = 0; caixa.scrollLeft = 0; trilho.scrollLeft = 0;
}

export function Inicio({ s }: { s: Sessao }) {
  const [linhas, setLinhas] = useState<Linha[]>([]);
  const [destaque, setDestaque] = useState<Item | null>(null);
  const [erro, setErro] = useState('');
  const [rolado, setRolado] = useState(false);
  const caixa = useRef<HTMLDivElement>(null), pista = useRef<HTMLDivElement>(null);
  // troca do fundo espera a navegação parar: decodificar um fundo 1080p a cada seta pesa na TV
  const espera = useRef(0);
  const focar = (i: Item) => { clearTimeout(espera.current); espera.current = setTimeout(() => setDestaque(i), ehTV ? 300 : 150) as unknown as number; };

  useEffect(() => {
    const f = () => setRolado(scrollY > 40);
    addEventListener('scroll', f, { passive: true });
    return () => removeEventListener('scroll', f);
  }, []);

  useEffect(() => {
    (async () => {
      try {
        const [cont, libs] = await Promise.all([continuar(s), bibliotecas(s)]);
        const vids = libs.filter(l => l.CollectionType === 'movies' || l.CollectionType === 'tvshows');
        const nov = await Promise.all(vids.map(l => novidades(s, l.Id).then(itens => ({ titulo: `Novidades em ${l.Name}`, itens }))));
        const todas = [{ titulo: 'Continuar assistindo', itens: cont, tocar: true }, ...nov].filter(l => l.itens.length);
        setLinhas(todas);
        setDestaque(todas[0]?.itens[0] ?? null);
      } catch (e) { setErro(e instanceof Error ? e.message : String(e)); }
    })();
  }, [s.token]);

  useEffect(() => {
    if (!ehTV || !linhas.length || !caixa.current || !pista.current) return;
    const c = caixa.current, p = pista.current;
    const primeiro = () => c.querySelector<HTMLElement>('.cartao');
    const f = (ev: FocusEvent) => { const e = ev.target as HTMLElement; if (e.classList.contains('cartao')) posicionar(c, p, e); };
    c.addEventListener('focusin', f);
    const a = document.activeElement;
    if (!a || a === document.body) {
      const fl = p.children[ultimo[0]]?.querySelector('.fileira-trilho')?.children[ultimo[1]] as HTMLElement | undefined;
      (fl || primeiro())?.focus();
    }
    aoVoltarNaRaiz(() => {
      const um = primeiro();
      if (!um || document.activeElement === um) return false;
      um.focus();
      c.querySelectorAll<HTMLElement>('.fileira-trilho').forEach(t => { t.style.transform = ''; });
      p.style.transform = '';
      return true;
    });
    return () => { c.removeEventListener('focusin', f); aoVoltarNaRaiz(null); };
  }, [linhas]);

  const img = destaque ? fundo(s, destaque) : '';
  return (
    <div class="inicio">
      <header class={rolado ? "topo rolado" : "topo"}>
        <span class="marca-texto pequena">HEISUCA</span>
        <nav>
          <button data-foco class="aba ativa"><Icone nome="home" cheio /><span>Início</span></button>
          <button data-foco class="aba"><Icone nome="search" /><span>Buscar</span></button>
        </nav>
        <button data-foco class="aba" onClick={() => { sair(); location.reload(); }}><Icone nome="logout" /><span>Sair</span></button>
      </header>
      <div class="destaque" aria-live="polite">
        {img && <img key={img} class="destaque-img" src={img} alt="" />}
        <div class="destaque-texto">
          <h1>{destaque ? (destaque.Type === 'Episode' ? destaque.SeriesName : destaque.Name) : ''}</h1>
          <p>{destaque?.Overview}</p>
        </div>
      </div>
      {erro && <p class="erro">{erro}</p>}
      <div class="fileiras" ref={caixa} data-rola-sozinho={ehTV ? '' : undefined}>
        <div class="fileiras-pista" ref={pista}>
          {linhas.map(l => <Fileira key={l.titulo} s={s} titulo={l.titulo} itens={l.itens} aoFocar={focar}
            aoAbrir={i => l.tocar ? irVer(i.Id, i.UserData?.PlaybackPositionTicks) : irTitulo(i.Id)} />)}
        </div>
      </div>
    </div>
  );
}
