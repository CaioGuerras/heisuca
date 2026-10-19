// Páginas do menu do usuário (PLANO §9–§12), todas na moldura simples de Pagina.tsx (← + título):
//  Minha conta (§10, ref/app_completo/…minha_conta) · Como usar (§11) · Baixar os apps (§12) · Sobre (§9) ·
//  Meus pedidos (só com Seerr) · Apoiar o Heisuca ("Em breve").
// Nada do CGSERVER aqui (sem CGFLIX, sem endereço, sem regras da casa, sem Stremio): o site serve a qualquer servidor.
import type { ComponentChildren } from 'preact';
import { useEffect, useRef, useState } from 'preact/hooks';
import { euMesmo, fotoUsuario, removerFoto, trocarFoto, trocarSenha, VERSAO, type Sessao } from '../api/jellyfin';
import { detalhe, meusPedidos, poster, SELO, temSeerr, type Pedido } from '../api/seerr';
import { avisar } from '../comp/Aviso';
import { Icone } from '../comp/Icone';
import { aoMudarInstalar, instalar, jaInstalado, podeInstalar } from '../comp/instalar';
import { Logo } from '../comp/Logo';
import { AJUDA_COMPLETA } from '../comp/MenuUsuario';
import { irPagina, irTitulo } from '../rota';
import { Pagina } from './Pagina';
import './paginas.css';

const ler = (k: string) => { try { return localStorage.getItem(k); } catch { return null; } };
const gravar = (k: string, v: string | null) => { try { if (v === null) localStorage.removeItem(k); else localStorage.setItem(k, v); } catch { /* modo privado */ } };

// ---------------------------------------------------------------- Minha conta (§10)
export function Conta({ s, aoMudar }: { s: Sessao; aoMudar: (s: Sessao) => void }) {
  const [ocupado, setOcupado] = useState<'' | 'foto' | 'senha'>('');
  const [senhas, setSenhas] = useState({ atual: '', nova: '', confirma: '' });
  const [erro, setErro] = useState<{ campo: 'atual' | 'nova' | 'confirma'; texto: string } | null>(null);
  const arquivo = useRef<HTMLInputElement>(null);
  const foto = fotoUsuario(s, 360);

  // a foto nova muda o tag no servidor: relê o usuário e guarda o tag na sessão (o avatar da ilha e do menu acompanham)
  const reler = () => euMesmo(s).then(u => aoMudar({ ...s, fotoTag: u.PrimaryImageTag || undefined }));
  const escolher = (e: Event) => {
    const f = (e.target as HTMLInputElement).files?.[0];
    (e.target as HTMLInputElement).value = '';
    if (!f) return;
    if (!f.type.startsWith('image/')) { avisar('Escolha uma imagem (JPG, PNG ou WebP).'); return; }
    if (f.size > 10 * 1024 * 1024) { avisar('Imagem grande demais (máximo 10 MB).'); return; }
    setOcupado('foto');
    trocarFoto(s, f).then(reler).then(() => avisar('Foto trocada.'), () => avisar('Não deu para trocar a foto. Tente de novo.')).finally(() => setOcupado(''));
  };
  const remover = () => {
    setOcupado('foto');
    removerFoto(s).then(() => aoMudar({ ...s, fotoTag: undefined })).then(() => avisar('Foto removida.'), () => avisar('Não deu para remover a foto. Tente de novo.')).finally(() => setOcupado(''));
  };
  const salvar = (e: Event) => {
    e.preventDefault();
    setErro(null);
    if (!senhas.nova) { setErro({ campo: 'nova', texto: 'Digite a nova senha.' }); return; }
    if (senhas.nova !== senhas.confirma) { setErro({ campo: 'confirma', texto: 'As duas senhas novas não são iguais.' }); return; }
    setOcupado('senha');
    trocarSenha(s, senhas.atual, senhas.nova)
      .then(() => { setSenhas({ atual: '', nova: '', confirma: '' }); avisar('Senha trocada. Os outros aparelhos vão pedir para entrar de novo.'); })
      .catch((x: Error) => {
        if (/: 40[03]$/.test(x.message)) setErro({ campo: 'atual', texto: 'Senha atual incorreta.' });
        else avisar('Não deu para trocar a senha. Tente de novo.');
      })
      .finally(() => setOcupado(''));
  };
  const campo = (k: 'atual' | 'nova' | 'confirma', rotulo: string, auto: string) => (
    <CampoSenha rotulo={rotulo} valor={senhas[k]} auto={auto} erro={erro?.campo === k ? erro.texto : ''}
      mudar={v => { setSenhas(x => ({ ...x, [k]: v })); if (erro?.campo === k) setErro(null); }} />
  );

  return (
    <Pagina titulo="Minha conta" classe="conta">
      <section class="conta-perfil">
        {foto ? <img class="conta-foto" src={foto} alt="Sua foto" width={120} height={120} />
          : <span class="conta-foto conta-sem-foto" aria-hidden="true"><Icone nome="person" cheio tamanho={64} /></span>}
        <h2 class="conta-nome">{s.nome}</h2>
        <div class="conta-acoes">
          <button class="pilula pilula-clara" disabled={!!ocupado} onClick={() => arquivo.current?.click()}>
            <Icone nome="photo_camera" cheio tamanho={22} />{ocupado === 'foto' ? 'Enviando…' : 'Trocar foto'}</button>
          {s.fotoTag && <button class="pilula conta-remover" disabled={!!ocupado} onClick={remover}><Icone nome="delete" cheio tamanho={22} />Remover foto</button>}
          <input ref={arquivo} type="file" accept="image/jpeg,image/png,image/webp,image/gif" hidden onChange={escolher} />
        </div>
      </section>
      <hr class="conta-linha" />
      <form class="conta-senha" onSubmit={salvar} noValidate>
        <h2>Trocar senha</h2>
        <p class="texto-2">A senha vale para todos os aparelhos. Depois da troca, os outros aparelhos pedem para entrar de novo.</p>
        {/* o navegador associa a senha ao usuário certo */}
        <input type="text" autocomplete="username" value={s.nome} hidden readOnly />
        {campo('atual', 'Senha atual (vazia se você não tem)', 'current-password')}
        {campo('nova', 'Nova senha', 'new-password')}
        {campo('confirma', 'Confirmar nova senha', 'new-password')}
        <button type="submit" class="pilula pilula-clara conta-salvar" disabled={!!ocupado}>{ocupado === 'senha' ? 'Salvando…' : 'Salvar nova senha'}</button>
      </form>
    </Pagina>
  );
}

function CampoSenha({ rotulo, valor, mudar, auto, erro }: { rotulo: string; valor: string; mudar: (v: string) => void; auto: string; erro: string }) {
  const [ver, setVer] = useState(false);
  return (
    <div class="campo-senha-bloco">
      <label class={`campo-senha${erro ? ' com-erro' : ''}`}>
        <input type={ver ? 'text' : 'password'} placeholder={rotulo} aria-label={rotulo} autocomplete={auto} value={valor}
          aria-invalid={erro ? 'true' : undefined} onInput={e => mudar((e.target as HTMLInputElement).value)} />
        <button type="button" class="campo-olho" aria-label={ver ? 'Esconder senha' : 'Mostrar senha'} aria-pressed={ver} onClick={() => setVer(v => !v)}>
          <Icone nome={ver ? 'visibility_off' : 'visibility'} cheio tamanho={22} /></button>
      </label>
      {erro && <p class="campo-erro" role="alert">{erro}</p>}
    </div>
  );
}

// ---------------------------------------------------------------- instalar o site como app (§11 passo 4 e §12; o aviso do navegador: comp/instalar.ts)
const NAVEGADORES = [
  { id: 'android', icone: 'android', nome: 'Android', sub: 'Chrome', passos: [
    'Abra o site no Chrome.', <>Toque em <Icone nome="more_vert" tamanho={18} classe="em-linha" /> no canto de cima, à direita.</>,
    <>Toque em <strong>Adicionar à tela inicial</strong> (ou <strong>Instalar app</strong>).</>, <>Confirme em <strong>Instalar</strong>. O Heisuca aparece junto dos outros apps.</>] },
  { id: 'iphone', icone: 'mobile', nome: 'iPhone e iPad', sub: 'Safari', passos: [
    'Abra o site no Safari.', <>Toque em Compartilhar <Icone nome="ios_share" tamanho={18} classe="em-linha" /> (o quadrado com a seta para cima).</>,
    <>Role e toque em <strong>Adicionar à Tela de Início</strong>.</>, <>Toque em <strong>Adicionar</strong>. O ícone do Heisuca fica na tela de início.</>] },
  { id: 'windows', icone: 'desktop_windows', nome: 'Windows', sub: 'Edge', passos: [
    'Abra o site no Edge.', <>Clique no ícone de instalar <Icone nome="install_desktop" tamanho={18} classe="em-linha" />, na barra de endereço (ou no menu ··· → <strong>Aplicativos</strong> → <strong>Instalar este site como aplicativo</strong>).</>,
    <>Clique em <strong>Instalar</strong>. O Heisuca abre em janela própria e fica no menu Iniciar.</>] },
];
const deste = () => /iPhone|iPad|iPod/.test(navigator.userAgent) || (navigator.platform === 'MacIntel' && navigator.maxTouchPoints > 1) ? 'iphone'
  : /Android/.test(navigator.userAgent) ? 'android' : /Windows/.test(navigator.userAgent) ? 'windows' : '';

function PassosInstalar() {
  const [, atualizar] = useState(0);
  useEffect(() => aoMudarInstalar(() => atualizar(n => n + 1)), []);
  const aqui = deste();
  const pedir = () => instalar().then(ok => { if (ok) avisar('Pronto: o Heisuca foi instalado.'); }, () => null);
  return (
    <div class="instalar">
      {jaInstalado() ? <p class="instalar-ja"><Icone nome="check_circle" cheio tamanho={20} />Você já está usando o Heisuca como app neste aparelho.</p>
        : podeInstalar() && <button class="pilula pilula-tema instalar-botao" onClick={pedir}><Icone nome="install_desktop" tamanho={22} />Instalar o Heisuca</button>}
      {NAVEGADORES.map(n => (
        <details key={n.id} class="instalar-nav" open={n.id === aqui}>
          <summary><Icone nome={n.icone} tamanho={22} /><span><strong>{n.nome}</strong><small>{n.sub}</small></span><Icone nome="keyboard_arrow_down" tamanho={22} classe="instalar-seta" /></summary>
          <ol>{n.passos.map((p, k) => <li key={k}>{p}</li>)}</ol>
        </details>
      ))}
    </div>
  );
}

// ---------------------------------------------------------------- Como usar (§11)
const FEITOS = 'heisuca.ajuda.feitos';
type Passo = { id: string; titulo: string; texto: ComponentChildren; acao?: { rotulo: string; ir: () => void }; extra?: ComponentChildren };

export function ComoUsar({ s }: { s: Sessao }) {
  const [seerr, setSeerr] = useState(false);
  const [feitos, setFeitos] = useState<string[]>(() => { try { return JSON.parse(ler(FEITOS) || '[]'); } catch { return []; } });
  useEffect(() => { temSeerr(s).then(setSeerr); }, [s.servidor]);

  const passos: Passo[] = [
    { id: 'entrar', titulo: 'Entrar no site', texto: 'Você entra com o endereço do servidor, o seu usuário e a senha. A sessão fica salva neste aparelho: da próxima vez, o Heisuca já abre direto.' },
    { id: 'senha', titulo: 'Criar ou trocar a senha', texto: 'Se a sua conta ainda não tem senha, crie uma. Ela vale para todos os aparelhos.', acao: { rotulo: 'Abrir Minha conta', ir: () => irPagina('conta') } },
    { id: 'foto', titulo: 'Pôr uma foto no perfil', texto: 'A foto aparece na barra de baixo e no menu, e ajuda a reconhecer a sua conta.', acao: { rotulo: 'Abrir Minha conta', ir: () => irPagina('conta') } },
    { id: 'instalar', titulo: 'Instalar no aparelho', texto: 'O site vira um app: ícone na tela de início e tela inteira, sem a barra do navegador.',
      extra: <PassosInstalar />, acao: { rotulo: 'Ver os apps do Heisuca', ir: () => irPagina('apps') } },
    ...(seerr ? [{ id: 'pedir', titulo: 'Pedir filmes e séries', texto: <>Não achou o que queria? Busque pelo nome. O que o servidor ainda não tem aparece em <strong>Disponível para pedir</strong>: toque em <strong>+ Pedir</strong> e avisamos quando chegar.</>,
      acao: { rotulo: 'Abrir a busca', ir: () => irPagina('busca') } }] : []),
  ];
  const marcados = passos.filter(p => feitos.includes(p.id)).length;
  // com todos marcados, o menu move o Como usar para o fim (PLANO §9)
  useEffect(() => { gravar(AJUDA_COMPLETA, marcados === passos.length ? '1' : null); }, [marcados, passos.length]);
  const alternar = (id: string) => setFeitos(f => {
    const n = f.includes(id) ? f.filter(x => x !== id) : [...f, id];
    gravar(FEITOS, JSON.stringify(n));
    return n;
  });

  return (
    <Pagina titulo="Como usar" classe="ajuda">
      <p class="ajuda-intro texto-2">Alguns passos para aproveitar o Heisuca. Marque o que já fez: fica guardado neste aparelho.</p>
      <div class="ajuda-progresso" role="progressbar" aria-valuemin={0} aria-valuemax={passos.length} aria-valuenow={marcados}
        aria-label={`${marcados} de ${passos.length} passos feitos`}>
        <span style={{ width: `${(marcados / passos.length) * 100}%` }} /></div>
      <p class="ajuda-conta texto-2">{marcados === passos.length ? 'Tudo feito.' : `${marcados} de ${passos.length} feitos`}</p>
      <ol class="ajuda-passos">
        {passos.map((p, n) => {
          const feito = feitos.includes(p.id);
          return (
            <li key={p.id} class={`cartao-pagina ajuda-passo${feito ? ' feito' : ''}`}>
              <div class="ajuda-cabeca">
                <span class="ajuda-numero" aria-hidden="true">{feito ? <Icone nome="check" tamanho={18} /> : n + 1}</span>
                <h2>{p.titulo}</h2>
                <label class="ajuda-feito">
                  <input type="checkbox" checked={feito} onChange={() => alternar(p.id)} />
                  <span class="ajuda-caixa" aria-hidden="true"><Icone nome="check" tamanho={16} /></span>Feito
                </label>
              </div>
              <p class="ajuda-texto">{p.texto}</p>
              {p.extra}
              {p.acao && <button class="ajuda-acao" onClick={p.acao.ir}>{p.acao.rotulo}<Icone nome="chevron_right" tamanho={20} /></button>}
            </li>
          );
        })}
      </ol>

      <section class="cartao-pagina ajuda-avisos">
        <Icone nome="notifications" tamanho={24} />
        <div><h2>Avisos no aparelho</h2><p class="texto-2">Avisar quando um pedido chegar ou sair um episódio novo.</p></div>
        <span class="selo-em-breve">Em breve</span>
      </section>

      <h2 class="titulo-secao ajuda-duvidas-titulo">Dúvidas</h2>
      <div class="ajuda-duvidas">
        <details class="duvida"><summary>Esqueci a senha. E agora?<Icone nome="keyboard_arrow_down" tamanho={22} /></summary>
          <p>Fale com quem administra o seu servidor: só essa pessoa pode apagar a senha antiga. Depois, entre sem senha e crie uma nova em Minha conta.</p></details>
        <details class="duvida"><summary>Como eu saio da conta?<Icone nome="keyboard_arrow_down" tamanho={22} /></summary>
          <p>Toque na sua foto, na barra de baixo, e escolha <strong>Sair</strong>. O endereço do servidor fica lembrado para a próxima entrada.</p></details>
        <details class="duvida"><summary>Como troco as cores?<Icone nome="keyboard_arrow_down" tamanho={22} /></summary>
          <p>Toque na sua foto e escolha <strong>Tema</strong>: Roxo (escuro), Verde (claro) ou Automático, que segue o aparelho.</p></details>
      </div>
    </Pagina>
  );
}

// ---------------------------------------------------------------- Baixar os apps (§12)
const EM_BREVE = [
  { icone: 'android', nome: 'Android', sub: 'Celulares e tablets' },
  { icone: 'tv', nome: 'Android TV', sub: 'TVs e TV boxes com Google TV' },
  { icone: 'connected_tv', nome: 'TVs Samsung e LG', sub: 'Tizen e webOS' },
  { icone: 'mobile', nome: 'iPhone e iPad', sub: 'iOS e iPadOS' },
];
export function Apps() {
  return (
    <Pagina titulo="Baixar os apps" classe="apps">
      <p class="texto-2 apps-intro">O Heisuca terá apps próprios para cada aparelho. Enquanto eles não chegam, o site pode ser instalado como app.</p>
      <section class="cartao-pagina apps-site">
        <div class="apps-cabeca">
          <span class="apps-icone"><Icone nome="install_desktop" tamanho={26} /></span>
          <div><h2>Instalar o site como app</h2><small class="texto-2">Celular, tablet e computador</small></div>
          <span class="selo-disponivel">Disponível</span>
        </div>
        <PassosInstalar />
      </section>
      <h2 class="titulo-secao apps-titulo">Apps</h2>
      <ul class="apps-grade">
        {EM_BREVE.map(a => (
          <li key={a.nome} class="cartao-pagina apps-app">
            <span class="apps-icone"><Icone nome={a.icone} tamanho={26} /></span>
            <div><h3>{a.nome}</h3><small class="texto-2">{a.sub}</small></div>
            <span class="selo-em-breve">Em breve</span>
          </li>
        ))}
      </ul>
    </Pagina>
  );
}

// ---------------------------------------------------------------- Sobre (§9)
const CODIGO = 'https://github.com/caioguerras/heisuca';
const BIBLIOTECAS = [
  ['Preact', 'MIT', 'a base do site'], ['hls.js', 'Apache-2.0', 'vídeo em partes (HLS)'], ['JASSUB', 'MIT', 'legendas ASS'],
  ['blurhash', 'MIT', 'as cores tiradas do pôster'], ['Material Symbols', 'Apache-2.0', 'os ícones'],
  ['Inter', 'OFL-1.1', 'a letra do texto'], ['Sora', 'OFL-1.1', 'a letra dos títulos'],
];
export function Sobre() {
  return (
    <Pagina titulo="Sobre" classe="sobre">
      <section class="sobre-marca">
        <Logo classe="sobre-logo" />
        <p class="sobre-slogan">Nada entre você e o filme.</p>
        <p class="texto-2 sobre-versao">Versão {VERSAO}</p>
      </section>
      <section class="cartao-pagina sobre-bloco">
        <h2>Código aberto</h2>
        <p class="texto-2">O Heisuca é software livre, sob a licença GPL-3.0: qualquer pessoa pode ver, estudar e melhorar o código.</p>
        <a class="ajuda-acao" href={CODIGO} target="_blank" rel="noopener noreferrer"><Icone nome="code" tamanho={20} />Ver o código<Icone nome="open_in_new" tamanho={18} /></a>
      </section>
      <section class="cartao-pagina sobre-bloco">
        <h2>Créditos</h2>
        <ul class="sobre-creditos">
          {BIBLIOTECAS.map(([nome, lic, uso]) => <li key={nome}><strong>{nome}</strong><span class="texto-2">{uso}</span><small>{lic}</small></li>)}
        </ul>
        <p class="sobre-gente"><span class="texto-2">Com a ajuda de</span> Rosiel Victor <span class="texto-2">·</span> Locadora</p>
      </section>
      <p class="sobre-dedicatoria">Para a família, que sempre se reuniu diante da tela.</p>
    </Pagina>
  );
}

// ---------------------------------------------------------------- Meus pedidos (só com Seerr)
type Linha = Pedido & { nome?: string; capa?: string; ano?: string };
const situacao = (p: Pedido) => p.status === 3 ? 'Recusado' : p.status === 1 ? 'Aguardando aprovação' : SELO[p.media.status] || 'Pedido';
const quando = (iso: string) => { const d = new Date(iso); return isNaN(+d) ? '' : d.toLocaleDateString('pt-BR', { day: 'numeric', month: 'short', year: 'numeric' }); };

export function MeusPedidos({ s }: { s: Sessao }) {
  const [lista, setLista] = useState<Linha[] | null>(null);
  const [erro, setErro] = useState(false);
  useEffect(() => {
    let vivo = true;
    temSeerr(s).then(tem => { if (!tem) throw new Error('sem seerr'); return meusPedidos(s); })
      .then(async ps => {
        if (vivo) setLista(ps);
        // o pedido só traz o id do TMDB: o nome e o pôster vêm do detalhe (em paralelo)
        const comNome = await Promise.all(ps.map(p => detalhe(s, p.media.mediaType, p.media.tmdbId).then(d => ({ ...p, nome: d.title || d.name, capa: d.posterPath,
          ano: (d.releaseDate || d.firstAirDate || '').slice(0, 4) }), () => p as Linha)));
        if (vivo) setLista(comNome);
      })
      .catch(() => vivo && setErro(true));
    return () => { vivo = false; };
  }, [s.servidor]);

  return (
    <Pagina titulo="Meus pedidos" classe="pedidos">
      {erro ? <p class="texto-2">Não deu para ver os pedidos agora. Tente de novo mais tarde.</p>
        : !lista ? <ul class="pedidos-lista">{[0, 1, 2].map(n => <li key={n} class="pedidos-item"><span class="pedidos-capa esqueleto" /><span class="pedidos-esq"><span class="esqueleto" /><span class="esqueleto" /></span></li>)}</ul>
        : !lista.length ? <div class="pagina-vazia"><Icone nome="playlist_add_check" tamanho={40} /><p>Você ainda não pediu nada.</p>
            <button class="ajuda-acao" onClick={() => irPagina('busca')}>Buscar e pedir<Icone nome="chevron_right" tamanho={20} /></button></div>
        : <ul class="pedidos-lista">{lista.map(p => {
            const img = poster(s, p.capa), chegou = p.media.status === 5 && p.media.jellyfinMediaId;
            const temps = p.type === 'tv' && p.seasons?.length ? `${p.seasons.length === 1 ? 'Temporada' : 'Temporadas'} ${p.seasons.map(t => t.seasonNumber).join(', ')}` : '';
            const corpo = (<>
              {img ? <img class="pedidos-capa" src={img} alt="" loading="lazy" /> : <span class="pedidos-capa pedir-sem" aria-hidden="true"><Icone nome={p.type === 'tv' ? 'tv' : 'movie'} tamanho={24} /></span>}
              <span class="busca-texto">
                <strong class="uma-linha">{p.nome || (p.type === 'tv' ? 'Série' : 'Filme')}</strong>
                <small class="texto-2">{[p.ano, p.nome && (p.type === 'tv' ? 'Série' : 'Filme'), temps].filter(Boolean).join(' · ')}</small>
                <small class="texto-2">Pedido em {quando(p.createdAt)}</small>
              </span>
              <span class={`pedidos-selo s${p.status === 3 ? 'x' : p.media.status}`}>{situacao(p)}</span>
            </>);
            return <li key={p.id}>{chegou ? <button class="pedidos-item" onClick={() => irTitulo(p.media.jellyfinMediaId!)}>{corpo}</button> : <div class="pedidos-item">{corpo}</div>}</li>;
          })}</ul>}
    </Pagina>
  );
}

// ---------------------------------------------------------------- Apoiar o Heisuca ("Em breve" até existir a doação)
export function Apoiar() {
  return (
    <Pagina titulo="Apoiar o Heisuca" classe="apoiar">
      <div class="pagina-vazia">
        <Icone nome="volunteer_activism" tamanho={44} />
        <p class="selo-em-breve">Em breve</p>
        <p class="texto-2">A forma de apoiar o Heisuca ainda está sendo preparada.</p>
      </div>
    </Pagina>
  );
}
