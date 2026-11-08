import { VERSAO } from '../api/contas.ts';
// Páginas do menu do usuário (PLANO §9–§12), todas na moldura simples de Pagina.tsx (← + título):
//  Minha conta (§10, ref/app_completo/…minha_conta) · Como usar (§11) · Baixar os apps (§12) · Sobre (§9) ·
//  Meus pedidos (só com Seerr) · Apoiar o Heisuca ("Em breve").
// Nada do CGSERVER aqui (sem CGFLIX, sem endereço, sem regras da casa, sem Stremio): o site serve a qualquer servidor.
import type { ComponentChildren } from 'preact';
import { useEffect, useRef, useState } from 'preact/hooks';
import { euMesmo, fotoUsuario, pode, removerFoto, trocarFoto, trocarSenha, type Sessao } from '../api/servidor.ts';
import { detalhe, meusPedidos, poster, SELO, temSeerr, type Pedido } from '../api/seerr';
import { avisar } from '../comp/Aviso';
import { Icone } from '../comp/Icone';
import { aoMudarInstalar, instalar, jaInstalado, podeInstalar } from '../comp/instalar';
import { Logo } from '../comp/Logo';
import { AJUDA_COMPLETA } from '../comp/MenuUsuario';
import { alternarFeito, lerFeitos, passosDaConta, progresso, type IdPasso } from '../dados/passos.ts';
import { erroDaSenha, sucessoDaSenha, TIPOS_FOTO, validarFoto, validarSenha, type CampoSenha, type Senhas } from '../dados/conta.ts';
import { irPagina, irTitulo } from '../rota';
import pixQrSvg from '../marca/pix_qrcode.svg';
import { Pagina } from './Pagina';
import './paginas.css';

const ler = (k: string) => { try { return localStorage.getItem(k); } catch { return null; } };
const gravar = (k: string, v: string | null) => { try { if (v === null) localStorage.removeItem(k); else localStorage.setItem(k, v); } catch { /* modo privado */ } };

// ---------------------------------------------------------------- Minha conta (§10)
// Desenho do app completo (ref/app_completo/…minha_conta): foto grande no centro, nome, Trocar foto (pílula clara) e
// Remover foto (lixeira); abaixo, Trocar senha. Regras e mensagens em dados/conta.ts. Plex: foto e senha são do plex.tv.
export function Conta({ s, aoMudar }: { s: Sessao; aoMudar: (s: Sessao) => void }) {
  const [ocupado, setOcupado] = useState<'' | 'foto' | 'senha'>('');
  const [senhas, setSenhas] = useState<Senhas>({ atual: '', nova: '', confirma: '' });
  const [erro, setErro] = useState<{ campo?: CampoSenha; texto: string } | null>(null);
  const [ok, setOk] = useState('');
  const [semSenha, setSemSenha] = useState(false);   // 2º clique confirma deixar a conta sem senha
  const [temSenha, setTemSenha] = useState<boolean | undefined>(undefined);
  const arquivo = useRef<HTMLInputElement>(null);
  const viva = useRef(true);
  useEffect(() => () => { viva.current = false; }, []);
  const foto = fotoUsuario(s, 360);
  const podeFoto = pode(s, 'foto'), podeSenha = pode(s, 'trocarSenha');

  // o servidor diz se a conta tem senha (sem senha: some o campo "Senha atual" e o título vira "Criar senha")
  useEffect(() => { if (podeSenha) euMesmo(s).then(u => { if (viva.current) setTemSenha(u.HasPassword); }, () => null); }, [s.servidor, s.usuarioId]);

  // a foto nova muda o tag no servidor: relê o usuário e guarda o tag na sessão (o avatar da ilha e do menu acompanham)
  const reler = async () => {
    if (!viva.current) return;
    const u = await euMesmo(s);
    if (viva.current) aoMudar({ ...s, fotoTag: u.PrimaryImageTag || undefined });
  };
  const escolher = (e: Event) => {
    const f = (e.target as HTMLInputElement).files?.[0];
    (e.target as HTMLInputElement).value = '';
    if (!f) return;
    const problema = validarFoto(f);
    if (problema) { avisar(problema); return; }
    setOcupado('foto');
    trocarFoto(s, f).then(reler).then(() => { if (viva.current) avisar('Foto trocada.'); },
      () => { if (viva.current) avisar('Não deu para trocar a foto. Tente de novo.'); }).finally(() => { if (viva.current) setOcupado(''); });
  };
  const remover = () => {
    setOcupado('foto');
    removerFoto(s).then(() => { if (viva.current) aoMudar({ ...s, fotoTag: undefined }); })
      .then(() => { if (viva.current) avisar('Foto removida.'); }, () => { if (viva.current) avisar('Não deu para remover a foto. Tente de novo.'); })
      .finally(() => { if (viva.current) setOcupado(''); });
  };
  const salvar = (e: Event) => {
    e.preventDefault();
    setErro(null); setOk('');
    const v = validarSenha(temSenha === false ? { ...senhas, atual: '' } : senhas, temSenha);
    if (!v.ok) { setErro(v); setSemSenha(false); return; }
    if (v.semSenha && !semSenha) { setSemSenha(true); return; }
    setOcupado('senha');
    trocarSenha(s, temSenha === false ? '' : senhas.atual, senhas.nova)
      .then(() => { if (viva.current) { setSenhas({ atual: '', nova: '', confirma: '' }); setOk(sucessoDaSenha(v.semSenha)); setTemSenha(!v.semSenha); } })
      .catch((x: unknown) => { if (viva.current) setErro(erroDaSenha(x)); })
      .finally(() => { if (viva.current) { setOcupado(''); setSemSenha(false); } });
  };
  const campo = (k: CampoSenha, rotulo: string, auto: string) => (
    <CampoSenha rotulo={rotulo} valor={senhas[k]} auto={auto} erro={erro?.campo === k ? erro.texto : ''}
      mudar={v => { setSenhas(x => ({ ...x, [k]: v })); setSemSenha(false); setOk(''); if (erro?.campo === k) setErro(null); }} />
  );

  return (
    <Pagina titulo="Minha conta" classe="conta">
      <section class="conta-perfil">
        {foto ? <img class="conta-foto" src={foto} alt="Sua foto" width={144} height={144} />
          : <span class="conta-foto conta-sem-foto" aria-hidden="true"><Icone nome="person" cheio tamanho={72} /></span>}
        <h2 class="conta-nome">{s.nome}</h2>
        {s.nomeServidor && <p class="texto-2 conta-servidor"><Icone nome="dns" tamanho={16} classe="em-linha" />{s.nomeServidor}</p>}
        {podeFoto && <div class="conta-acoes">
          <button class="pilula pilula-clara conta-trocar" disabled={!!ocupado} onClick={() => arquivo.current?.click()}>
            <Icone nome="photo_camera" cheio tamanho={20} />{ocupado === 'foto' ? 'Enviando…' : 'Trocar foto'}
          </button>
          {s.fotoTag && (
            <button class="pilula conta-remover" disabled={!!ocupado} onClick={remover}>
              <Icone nome="delete" cheio tamanho={20} />Remover foto
            </button>
          )}
          <input ref={arquivo} type="file" accept={TIPOS_FOTO.join(',')} hidden onChange={escolher} />
        </div>}
      </section>

      {podeSenha ? <form class="conta-senha" onSubmit={salvar} noValidate>
        <h2>{temSenha === false ? 'Criar senha' : 'Trocar senha'}</h2>
        <p class="texto-2 conta-explica">A senha vale para todos os aparelhos. Depois da troca, os outros aparelhos pedem para entrar de novo.</p>
        {/* o navegador associa a senha ao usuário certo */}
        <input type="text" autocomplete="username" value={s.nome} hidden readOnly />
        <div class="conta-campos">
          {temSenha !== false && campo('atual', 'Senha atual (vazia se você não tem)', 'current-password')}
          {campo('nova', 'Nova senha', 'new-password')}
          {campo('confirma', 'Confirmar nova senha', 'new-password')}
        </div>
        {semSenha && <p class="conta-alerta" role="alert"><Icone nome="info" cheio tamanho={20} />
          A nova senha está vazia: a conta vai ficar sem senha, e qualquer pessoa com o seu usuário entra. Toque de novo para confirmar.</p>}
        {erro && !erro.campo && <p class="conta-alerta" role="alert"><Icone nome="info" cheio tamanho={20} />{erro.texto}</p>}
        {ok && <p class="conta-ok" role="status"><Icone nome="check_circle" cheio tamanho={20} />{ok}</p>}
        <button type="submit" class="pilula pilula-clara conta-salvar" disabled={!!ocupado}>
          {ocupado === 'senha' ? 'Salvando…' : semSenha ? 'Salvar sem senha' : temSenha === false ? 'Salvar senha' : 'Salvar nova senha'}
        </button>
      </form>
        : s.tipo === 'plex' && <p class="texto-2 conta-plex"><Icone nome="info" tamanho={18} classe="em-linha" />Nesta conta do Plex, a foto e a senha são trocadas no site do Plex.</p>}
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
    'Abra o site no Edge.', <>Clique no ícone de instalar <Icone nome="install_desktop" tamanho={18} classe="em-linha" />, na barra de endereço (ou no menu ··· → <strong>Aplicativos</strong> → <strong>Instalar este site como um aplicativo</strong>).</>,
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
// Conteúdo só do que o Heisuca faz em qualquer servidor (AJUDA_FATOS + ajuda.html de referência, sem nada do CGSERVER).
// Regras (quais passos valem, o que já foi marcado, progresso) em dados/passos.ts.
const FEITOS = 'heisuca.ajuda.feitos';
type Passo = { icone: string; titulo: string; texto: ComponentChildren; acao?: { rotulo: string; ir: () => void }; extra?: ComponentChildren };

export function ComoUsar({ s }: { s: Sessao }) {
  const [seerr, setSeerr] = useState<boolean | null>(null);
  const [feitos, setFeitos] = useState<string[]>(() => lerFeitos(ler(FEITOS)));
  useEffect(() => { temSeerr(s).then(setSeerr, () => setSeerr(false)); }, [s.servidor]);

  const conta = { rotulo: 'Abrir Minha conta', ir: () => irPagina('conta') };
  const PASSOS: Record<IdPasso, Passo> = {
    entrar: { icone: 'account_circle', titulo: 'Entrar no site', texto: <>Você entra com o endereço do servidor, o seu usuário e a senha, ou com o código
      do <strong>Quick Connect</strong>, no ícone do canto da tela de entrada. A sessão fica salva neste aparelho: da próxima vez, o Heisuca já abre direto.</> },
    senha: { icone: 'mobile_lock_portrait', titulo: 'Criar ou trocar a senha', texto: 'Se a sua conta ainda não tem senha, crie uma. Ela vale para todos os aparelhos.', acao: conta },
    foto: { icone: 'photo_camera', titulo: 'Pôr uma foto no perfil', texto: 'A foto aparece na barra de baixo e no menu, e ajuda a reconhecer a sua conta.', acao: conta },
    instalar: { icone: 'install_desktop', titulo: 'Instalar no aparelho', texto: 'O site vira um app: ícone na tela de início e tela inteira, sem a barra do navegador.',
      extra: <PassosInstalar />, acao: { rotulo: 'Ver os apps do Heisuca', ir: () => irPagina('apps') } },
    pedir: { icone: 'playlist_add_check', titulo: 'Pedir filmes e séries', texto: <>Não achou o que queria? Busque pelo nome. O que o servidor ainda não tem aparece em
      <strong> Disponível para pedir</strong>: toque em <strong>Pedir</strong>. Os seus pedidos ficam em <strong>Meus pedidos</strong>, na própria busca.</>,
      acao: { rotulo: 'Abrir a busca', ir: () => irPagina('busca') } },
  };
  const ids = passosDaConta({ senha: pode(s, 'trocarSenha'), foto: pode(s, 'foto'), seerr: !!seerr });
  const p = progresso(ids, feitos);
  // com todos marcados, o Como usar sai do menu e passa para o Sobre (PLANO §9); só decide depois de saber se há Seerr
  useEffect(() => { if (seerr !== null) gravar(AJUDA_COMPLETA, p.completo ? '1' : null); }, [p.completo, seerr]);
  const alternar = (id: string) => setFeitos(f => { const n = alternarFeito(f, id); gravar(FEITOS, JSON.stringify(n)); return n; });

  return (
    <Pagina titulo="Como usar" classe="ajuda">
      <section class={`ajuda-hero${p.completo ? ' completo' : ''}`}>
        <div class="ajuda-hero-texto">
          <p class="ajuda-hero-conta"><strong>{p.feitos}</strong> de {p.total}</p>
          <h2>{p.completo ? 'Tudo pronto.' : 'Primeiros passos'}</h2>
          <p class="texto-2">{p.completo ? 'Este guia saiu do menu e agora fica no Sobre. Desmarque um passo para ele voltar.'
            : 'Marque o que já fez: fica guardado neste aparelho.'}</p>
        </div>
        <div class="ajuda-progresso" role="progressbar" aria-valuemin={0} aria-valuemax={p.total} aria-valuenow={p.feitos}
          aria-label={`${p.feitos} de ${p.total} passos feitos`}><span style={{ transform: `scaleX(${p.pct / 100})` }} /></div>
      </section>
      <ol class="ajuda-passos">
        {ids.map((id, n) => {
          const x = PASSOS[id], feito = feitos.includes(id);
          return (
            <li key={id} class={`cartao-pagina ajuda-passo${feito ? ' feito' : ''}${p.proximo === id ? ' proximo' : ''}`}>
              <div class="ajuda-cabeca">
                <span class="ajuda-icone" aria-hidden="true"><Icone nome={feito ? 'check' : x.icone} tamanho={24} /></span>
                <div class="ajuda-titulo"><small>Passo {n + 1}</small><h2>{x.titulo}</h2></div>
                <label class="ajuda-feito">
                  <input type="checkbox" checked={feito} onChange={() => alternar(id)} />
                  <span class="ajuda-caixa" aria-hidden="true"><Icone nome="check" tamanho={16} /></span>Feito
                </label>
              </div>
              <div class="ajuda-corpo">
                <p class="ajuda-texto">{x.texto}</p>
                {x.extra}
                {x.acao && <button class="ajuda-acao" onClick={x.acao.ir}>{x.acao.rotulo}<Icone nome="chevron_right" tamanho={20} /></button>}
              </div>
            </li>
          );
        })}
      </ol>

      <section class="cartao-pagina ajuda-avisos">
        <span class="ajuda-icone" aria-hidden="true"><Icone nome="notifications" tamanho={24} /></span>
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
// Plataformas do README do Heisuca; só o site instalado existe hoje. Nada de apps de terceiros (eram dicas do CGSERVER).
const EM_BREVE = [
  { id: 'android', icone: 'android', nome: 'Android', sub: 'Celulares e tablets' },
  { id: 'tv', icone: 'tv', nome: 'Android TV', sub: 'TVs e TV boxes com Google TV' },
  { id: 'tvs', icone: 'connected_tv', nome: 'TVs Samsung e LG', sub: 'Tizen e webOS' },
  { id: 'iphone', icone: 'mobile', nome: 'iPhone e iPad', sub: 'iOS e iPadOS' },
];
export function Apps() {
  const aqui = deste();
  return (
    <Pagina titulo="Baixar os apps" classe="apps">
      <section class="apps-hero">
        <h2>O Heisuca em cada tela</h2>
        <p class="texto-2">Hoje, o Heisuca se instala pelo navegador e vira um app no aparelho. Os apps próprios estão a caminho.</p>
      </section>
      <section class="cartao-pagina apps-destaque">
        <div class="apps-cabeca">
          <span class="apps-icone apps-icone-ativo"><Icone nome="install_desktop" tamanho={26} /></span>
          <div>
            <h2>Instalar o site como app</h2>
            <small class="texto-2">Ícone na tela de início e tela inteira, sem a barra do navegador</small>
          </div>
          <span class="selo-disponivel">Disponível agora</span>
        </div>
        <PassosInstalar />
      </section>
      <h2 class="titulo-secao apps-titulo">Em breve</h2>
      <ul class="apps-grade">
        {EM_BREVE.map(a => {
          const atual = a.id === aqui;
          return (
            <li key={a.id} class={`cartao-pagina apps-app${atual ? ' apps-app-atual' : ''}`}>
              <span class="apps-icone"><Icone nome={a.icone} tamanho={26} /></span>
              <div>
                <h3>{a.nome}{atual && <span class="apps-badge-atual">Seu aparelho</span>}</h3>
                <small class="texto-2">{a.sub}</small>
              </div>
              <span class="selo-em-breve">Em breve</span>
            </li>
          );
        })}
      </ul>
    </Pagina>
  );
}

// ---------------------------------------------------------------- Sobre (§9)
// Nome, versão, "Nada entre você e o filme.", GPL-3.0 com o link do código, créditos (bibliotecas, Rosiel Victor e a Locadora
// só pelo nome, sem endereço) e a dedicatória sem nomes da família (NOVA_FASE/BASE_MARCA).
const CODIGO = 'https://github.com/CaioGuerras/heisuca';
const BIBLIOTECAS = [
  ['Preact', 'MIT', 'a base do site'], ['hls.js', 'Apache-2.0', 'vídeo em partes (HLS)'], ['JASSUB', 'MIT', 'legendas ASS'],
  ['blurhash', 'MIT', 'as cores tiradas do pôster'], ['Material Symbols', 'Apache-2.0', 'os ícones'],
  ['Inter', 'OFL-1.1', 'a letra do texto'], ['Sora', 'OFL-1.1', 'a letra dos títulos'],
];
export function Sobre() {
  const completa = ler(AJUDA_COMPLETA) === '1';
  return (
    <Pagina titulo="Sobre" classe="sobre">
      <section class="sobre-marca">
        <h2 class="visualmente-oculto">Heisuca. Nada entre você e o filme.</h2>
        <Logo classe="sobre-logo" comSlogan />
        <p class="sobre-versao">Versão {VERSAO}</p>
      </section>

      {/* com os passos todos marcados, o Como usar sai do menu e fica aqui (revisão de 19/10: "vai pra dentro das configurações") */}
      {completa && <button class="cartao-pagina sobre-linha" onClick={() => irPagina('ajuda')}>
        <span class="sobre-icone" aria-hidden="true"><Icone nome="help" tamanho={22} /></span>
        <span class="sobre-linha-texto"><strong>Como usar</strong><small class="texto-2">Os passos e as dúvidas</small></span>
        <Icone nome="chevron_right" tamanho={22} classe="sobre-seta" /></button>}

      <section class="cartao-pagina sobre-codigo">
        <div class="sobre-cabeca">
          <span class="sobre-icone" aria-hidden="true"><Icone nome="code" tamanho={22} /></span>
          <div><h2>Código aberto</h2><small class="texto-2">Licença GPL-3.0</small></div>
        </div>
        <p class="texto-2">O Heisuca é software livre: qualquer pessoa pode ver, estudar e melhorar o código.</p>
        <a class="pilula pilula-clara sobre-botao" href={CODIGO} target="_blank" rel="noopener noreferrer">
          Ver o código no GitHub<Icone nome="open_in_new" tamanho={18} /></a>
      </section>

      <h2 class="titulo-secao sobre-titulo">Agradecimentos</h2>
      <ul class="sobre-agradece">
        <li class="cartao-pagina">
          <span class="sobre-icone" aria-hidden="true"><Icone nome="favorite" cheio tamanho={20} /></span>
          <div><h3>Rosiel Victor</h3><p class="texto-2">Por sempre apoiar a fazer essas coisas rsrs.</p>
            <a class="sobre-link" href="https://all.dev.br" target="_blank" rel="noopener noreferrer">all.dev.br<Icone nome="open_in_new" tamanho={16} /></a></div>
        </li>
        <li class="cartao-pagina">
          <span class="sobre-icone" aria-hidden="true"><Icone nome="movie" cheio tamanho={20} /></span>
          <div><h3>Locadora</h3><p class="texto-2">Por até rir às vezes mas sempre me encorajar a evoluir, mesmo que cheio de HnR no site.</p></div>
        </li>
      </ul>

      <details class="cartao-pagina sobre-retratil">
        <summary><span><strong>Bibliotecas e licenças</strong><small class="texto-2">O que o Heisuca usa, com crédito</small></span>
          <Icone nome="keyboard_arrow_down" tamanho={22} classe="sobre-seta" /></summary>
        <ul class="sobre-creditos">
          {BIBLIOTECAS.map(([nome, lic, uso]) => <li key={nome}><strong>{nome}</strong><span class="texto-2">{uso}</span><small>{lic}</small></li>)}
        </ul>
      </details>

      <p class="sobre-selo texto-2">Feito em parceria com IA: Claude, Codex e Gemini.</p>

      <p class="sobre-dedicatoria"><Icone nome="favorite" cheio tamanho={18} />Para a família, que sempre se reuniu diante da tela.</p>
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
  const [vez, setVez] = useState(0);   // "Tentar de novo" pede tudo outra vez
  const tentar = () => { setErro(false); setLista(null); setVez(v => v + 1); };
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
  }, [s.servidor, vez]);

  return (
    <Pagina titulo="Meus pedidos" classe="pedidos">
      {erro ? <div class="pagina-vazia" role="alert"><Icone nome="cloud_off" tamanho={40} /><p>Não deu para ver os pedidos agora.</p>
            <button class="pilula pilula-clara pagina-vazia-botao" onClick={tentar}>Tentar de novo</button></div>
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

// ---------------------------------------------------------------- Apoiar o Heisuca
const PAYLOAD_PIX = '00020126360014br.gov.bcb.pix0114+55229815996475204000053039865802BR5906CGFLIX6014RIO DE JANEIRO62070503***6304030A';
const CHAVE_PIX_TELEFONE = '+5522981599647';

export function Apoiar() {
  const copiarPix = () => {
    navigator.clipboard.writeText(PAYLOAD_PIX)
      .then(() => avisar('Código Pix Copia e Cola copiado! Cole no app do seu banco.'))
      .catch(() => avisar('Não deu para copiar o código Pix.'));
  };

  const copiarChave = () => {
    navigator.clipboard.writeText(CHAVE_PIX_TELEFONE)
      .then(() => avisar('Chave Pix copiada (+55 22 98159-9647)!'))
      .catch(() => avisar('Não deu para copiar a chave Pix.'));
  };

  return (
    <Pagina titulo="Apoiar o Heisuca" classe="apoiar">
      <section class="cartao-pagina apoiar-hero">
        <div class="apoiar-coracao" aria-hidden="true">
          <Icone nome="favorite" cheio tamanho={36} />
        </div>
        <h2>Ajude a manter o Heisuca vivo</h2>
        <p class="texto-2">
          O Heisuca é independente, gratuito e feito com carinho para quem ama cinema e boas histórias.
          Se você gosta do projeto e quer dar uma força para custear os servidores e manter as melhorias contínuas,
          qualquer contribuição faz toda a diferença.
        </p>
      </section>

      <section class="cartao-pagina apoiar-card-pix">
        <div class="apoiar-qr-container">
          <div class="apoiar-qr-moldura">
            <img class="apoiar-qr-img" src={pixQrSvg} alt="QR Code Pix Heisuca" width={260} height={260} />
          </div>
        </div>

        <p class="apoiar-instrucao texto-2">
          No app do seu banco, escolha <strong>Pix</strong> e aponte a câmera para o QR Code ou use o Pix Copia e Cola. O valor é você quem escolhe.
        </p>

        <div class="apoiar-botoes">
          <button class="pilula pilula-tema apoiar-botao" onClick={copiarPix}>
            <Icone nome="content_copy" tamanho={20} />
            <span>Copiar Pix Copia e Cola</span>
          </button>
          <button class="pilula pilula-clara apoiar-botao" onClick={copiarChave}>
            <Icone nome="key" tamanho={20} />
            <span>Copiar chave (telefone)</span>
          </button>
        </div>

        <div class="apoiar-rodape-dados">
          <p><strong>Chave (telefone):</strong> +55 22 98159-9647</p>
          <p><strong>Titular:</strong> CGFLIX · Rio de Janeiro</p>
        </div>
      </section>
    </Pagina>
  );
}
