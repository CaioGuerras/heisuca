import { useEffect, useState } from 'preact/hooks';
import { bibliotecas, continuar, fundo, novidades, sair, type Item, type Sessao } from '../api/jellyfin';
import { Fileira } from '../comp/Fileira';
import { Icone } from '../comp/Icone';

type Linha = { titulo: string; itens: Item[] };

export function Inicio({ s }: { s: Sessao }) {
  const [linhas, setLinhas] = useState<Linha[]>([]);
  const [destaque, setDestaque] = useState<Item | null>(null);
  const [erro, setErro] = useState('');
  const [rolado, setRolado] = useState(false);

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
        const todas = [{ titulo: 'Continuar assistindo', itens: cont }, ...nov].filter(l => l.itens.length);
        setLinhas(todas);
        setDestaque(todas[0]?.itens[0] ?? null);
      } catch (e) { setErro(e instanceof Error ? e.message : String(e)); }
    })();
  }, [s.token]);

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
      <div class="fileiras">
        {linhas.map(l => <Fileira key={l.titulo} s={s} titulo={l.titulo} itens={l.itens} aoFocar={setDestaque} />)}
      </div>
    </div>
  );
}
