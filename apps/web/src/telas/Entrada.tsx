// Tela única de entrada (Caio 19/10; PLANO §3.2; base ref/streamyfin com os cortes do Caio):
// logo · "Digite o endereço do servidor" (✓ nome do servidor quando responde) · Usuário · Senha · Iniciar sessão.
// Quick Connect no ícone do canto superior direito. Sem "Guardar esta conta", sem URL repetida, sem cabeçalhos avançados.
// Caio 07/11: seletor "Jellyfin | Plex" no topo do formulário; Jellyfin é o padrão e segue idêntico. Plex entra por PIN
// (app.plex.tv numa nova aba); a lógica fica em api/fluxo-plex.ts (testada), aqui só os passos na tela.
import type { ComponentChildren } from 'preact';
import { useEffect, useLayoutEffect, useRef, useState } from 'preact/hooks';
import type { Autorizacao, RecursoPlex, Sessao, TipoServidor } from '../api/servidor.ts';
import { autorizarPlex, cancelada, conectarPlex, entradaJellyfin, ErroEntradaPlex, passoSeguinte } from '../api/servidor.ts';
import type { PedidoQC } from '../api/entrada-jellyfin.ts';
import { ultimoServidor, type Servidor } from '../api/contas.ts';
const { descobrir, entrarComSenha, ErroEntrada, esperarQuickConnect, iniciarQuickConnect, quickConnectLigado } = entradaJellyfin;
import { esmaecer, voar } from '../anim/voo';
import { usePaleta } from '../cor/paleta';
import { Folha } from '../comp/Folha';
import { Icone } from '../comp/Icone';
import { areaDaLogo, Logo } from '../comp/Logo';
import { prepararInicio } from '../dados/inicio';
import './entrada.css';

// build de teste (regra R1): só os logins listados entram (o Caio e a conta da bancada)
const SO = ((import.meta.env.VITE_SO_USUARIO as string | undefined) || '').split(',').map(x => x.trim().toLowerCase()).filter(Boolean);
const liberado = (nome: string) => !SO.length || SO.includes(nome.trim().toLowerCase());

// voltar: só quando a entrada abre de dentro do site (Trocar servidor → Adicionar / servidor sem sessão); no primeiro acesso não há
export function Entrada({ de, servidorInicial, pronto, voltar }: {
  de?: DOMRect | null; servidorInicial?: Servidor | null; pronto: (s: Sessao, logo: DOMRect, clique: number) => void; voltar?: () => void;
}) {
  const lembrado = servidorInicial === undefined ? ultimoServidor() : servidorInicial;
  // servidor lembrado Plex abre na aba Plex; o campo de endereço é só do Jellyfin
  const [tipo, setTipo] = useState<TipoServidor>(lembrado?.tipo === 'plex' ? 'plex' : 'jellyfin');
  const inicial = lembrado?.tipo === 'plex' ? null : lembrado;
  const [endereco, setEndereco] = useState(inicial?.url.replace(/^https:\/\//, '') || '');
  const [srv, setSrv] = useState<Servidor | null>(inicial);
  const [qcLigado, setQcLigado] = useState(false);
  const [usuario, setUsuario] = useState('');
  const [senha, setSenha] = useState('');
  const [erro, setErro] = useState<{ campo: string; msg: string } | null>(null);
  const [indo, setIndo] = useState(false);
  const [qc, setQc] = useState<PedidoQC | null>(null);
  const logo = useRef<HTMLDivElement>(null);
  const raiz = useRef<HTMLElement>(null);
  const procura = useRef(0);
  usePaleta(null);   // a entrada é na cor do tema (vinda da casca, a página ainda estaria na cor do pôster da home)

  // a logo chega voando da abertura; o formulário aparece depois que ela pousa
  useLayoutEffect(() => {
    const r = raiz.current!;
    if (!de || !logo.current) { r.classList.add('pronta'); return; }
    voar(logo.current, de).then(() => r.classList.add('pronta'));
  }, []);

  // confere o servidor 600 ms depois de parar de digitar (e ao sair do campo)
  const conferir = async (valor = endereco) => {
    const eu = ++procura.current;
    if (!valor.trim()) { setSrv(null); return null; }
    try {
      const x = await descobrir(valor);
      if (eu !== procura.current) return null;
      setSrv(x); setErro(e => e?.campo === 'servidor' ? null : e);
      quickConnectLigado(x).then(ok => { if (eu === procura.current) setQcLigado(ok); });
      return x;
    } catch (e) {
      if (eu !== procura.current) return null;
      setSrv(null); setQcLigado(false);
      setErro({ campo: 'servidor', msg: e instanceof Error ? e.message : String(e) });
      return null;
    }
  };
  useEffect(() => {
    if (srv && endereco === srv.url.replace(/^https:\/\//, '')) { quickConnectLigado(srv).then(setQcLigado); return; }
    setSrv(null);
    const t = setTimeout(() => { if (endereco.trim().length > 3) conferir(); }, 600);
    return () => clearTimeout(t);
  }, [endereco]);

  // o formulário e o Quick Connect esmaecem primeiro; só a logo fica, e é dela que a 2ª animação parte
  // clique = quando a pessoa pediu para entrar: os 3–5 s da 2ª animação contam daqui (PLANO §3.1), não de quando ela monta
  const terminou = async (s: Sessao, clique = performance.now()): Promise<boolean> => {
    if (!liberado(s.nome)) { setErro({ campo: 'geral', msg: 'Esta versão de teste ainda não está aberta.' }); return false; }
    prepararInicio(s);   // a home começa a carregar já, enquanto o formulário esmaece
    const r = raiz.current!;
    r.classList.add('saindo');
    await Promise.all([esmaecer(r.querySelector('.entrada-form'), 1, 0, 240), esmaecer(r.querySelector('.entrada-topo'), 1, 0, 240)]);
    pronto(s, areaDaLogo(logo.current!), clique);
    return true;
  };

  async function enviar(ev: Event) {
    ev.preventDefault();
    if (indo) return;
    const clique = performance.now();
    setErro(null);
    if (!liberado(usuario)) { setErro({ campo: 'geral', msg: 'Esta versão de teste ainda não está aberta.' }); return; }
    setIndo(true);
    try {
      const x = srv || await conferir();
      if (!x) { setIndo(false); return; }
      await terminou(await entrarComSenha(x, usuario, senha), clique);
    } catch (e) {
      setErro(e instanceof ErroEntrada ? { campo: e.campo, msg: e.message } : { campo: 'geral', msg: 'Não deu para entrar agora. Tente de novo.' });
    } finally { setIndo(false); }
  }

  // Esc também desiste (computador), se não houver a folha do Quick Connect aberta
  useEffect(() => {
    if (!voltar) return;
    const tecla = (e: KeyboardEvent) => { if (e.key === 'Escape' && !qc) voltar(); };
    addEventListener('keydown', tecla);
    return () => removeEventListener('keydown', tecla);
  }, [voltar, qc]);

  // Quick Connect: pede o código e espera alguém autorizar em outro aparelho
  useEffect(() => {
    if (!qc || !srv) return;
    let cancelado = false;
    esperarQuickConnect(srv, qc, () => cancelado).then(s => { if (s && !cancelado) { setQc(null); terminou(s); } })
      .catch(e => { if (!cancelado) { setQc(null); setErro({ campo: 'geral', msg: e instanceof Error ? e.message : 'O código venceu.' }); } });
    return () => { cancelado = true; };
  }, [qc]);
  const abrirQc = async () => {
    if (!srv) return;
    try { setQc(await iniciarQuickConnect(srv)); }
    catch (e) { setErro({ campo: 'geral', msg: e instanceof Error ? e.message : 'Quick Connect indisponível.' }); }
  };

  const erroDe = (c: string) => erro?.campo === c ? <p class="entrada-erro" role="alert">{erro.msg}</p> : null;
  const seletor = (
    <div class="entrada-tipo" role="tablist" aria-label="Tipo de servidor">
      {(['jellyfin', 'plex'] as const).map(t => (
        <button key={t} type="button" role="tab" aria-selected={tipo === t} class={tipo === t ? 'ativo' : ''}
          onClick={() => { if (t !== tipo) { setTipo(t); setErro(null); } }}>{t === 'plex' ? 'Plex' : 'Jellyfin'}</button>
      ))}
    </div>
  );
  return (
    <main class="entrada" ref={raiz}>
      <header class="entrada-topo">
        {voltar ? <button type="button" class="redondo entrada-voltar" onClick={voltar} aria-label="Voltar"><Icone nome="arrow_back" tamanho={22} /></button> : <span />}
        <button type="button" class={`redondo entrada-qc${tipo === 'plex' ? ' oculto' : ''}`} disabled={!srv || !qcLigado} onClick={abrirQc}
          aria-label="Entrar com Quick Connect" title={srv && qcLigado ? 'Entrar com Quick Connect' : 'Digite o endereço do servidor'}>
          <Icone nome="mobile_lock_portrait" tamanho={22} />
        </button>
      </header>
      <div class="entrada-centro">
        <div class="entrada-logo" ref={logo}><Logo modo="marca" /></div>
        {tipo === 'plex' ? <PainelPlex terminou={terminou} topo={seletor} aviso={erroDe('geral')} /> :
        <form class="entrada-form" onSubmit={enviar} novalidate>
          {seletor}
          <label class="campo">
            <span class="visualmente-oculto">Endereço do servidor</span>
            <input type="url" inputMode="url" autocomplete="url" autocapitalize="off" spellcheck={false} enterKeyHint="next"
              placeholder="Digite o endereço do servidor" value={endereco} aria-invalid={erro?.campo === 'servidor'}
              onInput={e => setEndereco(e.currentTarget.value)} onBlur={() => { if (!srv && endereco.trim()) conferir(); }} />
          </label>
          {/* a linha existe sempre (vazia até o servidor responder): o ✓ ou o erro entram sem empurrar a logo */}
          <p class={`entrada-servidor${srv ? '' : ' vazia'}${erro?.campo === 'servidor' ? ' com-erro' : ''}`} aria-live="polite">
            {srv ? <><Icone nome="check_circle" cheio tamanho={15} />{srv.nome}</>
              : erro?.campo === 'servidor' ? <span role="alert">{erro.msg}</span> : null}
          </p>
          <label class="campo">
            <span class="visualmente-oculto">Usuário</span>
            <input autocomplete="username" autocapitalize="off" spellcheck={false} enterKeyHint="next" placeholder="Usuário"
              value={usuario} aria-invalid={erro?.campo === 'usuario'} onInput={e => setUsuario(e.currentTarget.value)} />
          </label>
          {erroDe('usuario')}
          <label class="campo">
            <span class="visualmente-oculto">Senha</span>
            <input type="password" autocomplete="current-password" enterKeyHint="go" placeholder="Senha"
              value={senha} aria-invalid={erro?.campo === 'senha'} onInput={e => setSenha(e.currentTarget.value)} />
          </label>
          {erroDe('senha')}
          {erroDe('geral')}
          <button class="pilula pilula-tema entrada-botao" disabled={indo}>{indo ? 'Entrando…' : 'Iniciar sessão'}</button>
        </form>}
      </div>
      <Folha aberta={!!qc} fechar={() => setQc(null)} titulo="Quick Connect">
        <div class="qc">
          <p>Num aparelho onde você já entrou, autorize este código:</p>
          <p class="qc-codigo" aria-live="polite">{qc?.codigo}</p>
          <p class="qc-espera"><Icone nome="progress_activity" tamanho={18} classe="girando" />Esperando a autorização…</p>
        </div>
      </Folha>
    </main>
  );
}

// ---- Plex: PIN → autorizar no app.plex.tv (nova aba) → servidores → conexão HTTPS → mesma saída do Jellyfin ----
type PassoPlex = { fase: 'parado' } | { fase: 'gerando' } | { fase: 'pin'; codigo: string; url: string } | { fase: 'buscando' }
  | { fase: 'escolher'; a: Autorizacao } | { fase: 'conectando'; nome: string };

function PainelPlex({ terminou, topo, aviso }: { terminou: (s: Sessao) => Promise<boolean>; topo: ComponentChildren; aviso: ComponentChildren }) {
  const [p, setP] = useState<PassoPlex>({ fase: 'parado' });
  const [erro, setErro] = useState<{ msg: string; outro?: boolean } | null>(null);
  const ctl = useRef<AbortController | null>(null);
  // sair da tela ou trocar para Jellyfin desmonta o painel: a espera do PIN para na hora
  useEffect(() => () => ctl.current?.abort(), []);

  const falhou = (x: unknown, volta: PassoPlex) => {
    if (cancelada(x)) return;
    setP(volta);
    setErro(x instanceof ErroEntradaPlex ? { msg: x.message, outro: x.motivo === 'vencido' } : { msg: 'Não deu para entrar com o Plex agora. Tente de novo.' });
  };
  const conectar = async (r: RecursoPlex, a: Autorizacao, sinal: AbortSignal) => {
    const volta: PassoPlex = a.servidores.length > 1 ? { fase: 'escolher', a } : { fase: 'parado' };
    setErro(null); setP({ fase: 'conectando', nome: r.name });
    try { if (!await terminou(await conectarPlex(r, a.conta, sinal))) setP(volta); }
    catch (x) { falhou(x, volta); }
  };
  const comecar = async () => {
    ctl.current?.abort();
    const c = ctl.current = new AbortController();
    setErro(null); setP({ fase: 'gerando' });
    try {
      const a = await autorizarPlex(c.signal, (pin, url) => setP({ fase: 'pin', codigo: pin.code, url }), () => setP({ fase: 'buscando' }));
      // conectarPlex grava a sessão: a restrição da build precisa ser conferida antes disso.
      if (!liberado(a.conta.nome)) throw new ErroEntradaPlex('recusou', 'Esta versão de teste ainda não está aberta.');
      const passo = passoSeguinte(a.servidores);
      if (passo.tipo === 'conectar') await conectar(passo.recurso, a, c.signal);
      else setP({ fase: 'escolher', a: { ...a, servidores: passo.lista } });
    } catch (x) { falhou(x, { fase: 'parado' }); }
  };
  const cancelar = () => { ctl.current?.abort(); setErro(null); setP({ fase: 'parado' }); };
  const esperando = (texto: string) => <p class="qc-espera"><Icone nome="progress_activity" tamanho={18} classe="girando" />{texto}</p>;
  const botaoCancelar = <button type="button" class="pilula entrada-cancelar" onClick={cancelar}>Cancelar</button>;

  return (
    <div class="entrada-form entrada-plex">
      {topo}
      <div class="qc" aria-live="polite">
        {p.fase === 'parado' && <>
          <p>Entre com a sua conta Plex. O site abre o Plex numa nova aba para você autorizar.</p>
          <button type="button" class="pilula pilula-tema entrada-botao" onClick={comecar}>
            {erro?.outro ? 'Gerar outro' : erro ? 'Tentar de novo' : 'Entrar com Plex'}</button>
        </>}
        {p.fase === 'gerando' && esperando('Gerando o código…')}
        {p.fase === 'pin' && <>
          <p>Autorize este código na sua conta Plex:</p>
          <p class="qc-codigo plex-codigo">{p.codigo}</p>
          <a class="pilula pilula-tema entrada-botao" href={p.url} target="_blank" rel="noopener noreferrer">
            <Icone nome="open_in_new" tamanho={20} />Abrir o Plex para autorizar</a>
          {esperando('Esperando a autorização…')}
          {botaoCancelar}
        </>}
        {p.fase === 'buscando' && esperando('Buscando os seus servidores…')}
        {p.fase === 'escolher' && <>
          <p>Escolha o servidor:</p>
          <ul class="lista-opcoes plex-servidores">
            {p.a.servidores.map(r => (
              <li key={r.clientIdentifier}><button type="button" class="opcao-linha" onClick={() => ctl.current && conectar(r, p.a, ctl.current.signal)}>
                <Icone nome="dns" tamanho={22} /><span class="opcao-texto"><strong class="uma-linha">{r.name}</strong></span>
              </button></li>
            ))}
          </ul>
          {botaoCancelar}
        </>}
        {p.fase === 'conectando' && esperando(`Conectando a ${p.nome}…`)}
      </div>
      {erro && <p class="entrada-erro" role="alert">{erro.msg}</p>}
      {aviso}
    </div>
  );
}
