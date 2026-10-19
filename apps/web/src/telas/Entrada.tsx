// Tela única de entrada (Caio 19/10; PLANO §3.2; base ref/streamyfin com os cortes do Caio):
// logo · "Digite o endereço do servidor" (✓ nome do servidor quando responde) · Usuário · Senha · Iniciar sessão.
// Quick Connect no ícone do canto superior direito. Sem "Guardar esta conta", sem URL repetida, sem cabeçalhos avançados.
import { useEffect, useLayoutEffect, useRef, useState } from 'preact/hooks';
import type { Sessao } from '../api/jellyfin';
import { descobrir, entrarComSenha, ErroEntrada, esperarQuickConnect, iniciarQuickConnect, quickConnectLigado, ultimoServidor,
  type PedidoQC, type Servidor } from '../api/servidor';
import { esmaecer, voar } from '../anim/voo';
import { usePaleta } from '../cor/paleta';
import { Folha } from '../comp/Folha';
import { Icone } from '../comp/Icone';
import { areaDaLogo, Logo } from '../comp/Logo';
import './entrada.css';

// build de teste (regra R1): só os logins listados entram (o Caio e a conta da bancada)
const SO = ((import.meta.env.VITE_SO_USUARIO as string | undefined) || '').split(',').map(x => x.trim().toLowerCase()).filter(Boolean);
const liberado = (nome: string) => !SO.length || SO.includes(nome.trim().toLowerCase());

// voltar: só quando a entrada abre de dentro do site (Trocar servidor → Adicionar / servidor sem sessão); no primeiro acesso não há
export function Entrada({ de, servidorInicial, pronto, voltar }: {
  de?: DOMRect | null; servidorInicial?: Servidor | null; pronto: (s: Sessao, logo: DOMRect) => void; voltar?: () => void;
}) {
  const inicial = servidorInicial === undefined ? ultimoServidor() : servidorInicial;
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
  const terminou = async (s: Sessao) => {
    if (!liberado(s.nome)) { setErro({ campo: 'geral', msg: 'Esta versão de teste ainda não está aberta.' }); return false; }
    const r = raiz.current!;
    r.classList.add('saindo');
    await Promise.all([esmaecer(r.querySelector('.entrada-form'), 1, 0, 240), esmaecer(r.querySelector('.entrada-topo'), 1, 0, 240)]);
    pronto(s, areaDaLogo(logo.current!));
    return true;
  };

  async function enviar(ev: Event) {
    ev.preventDefault();
    if (indo) return;
    setErro(null);
    if (!liberado(usuario)) { setErro({ campo: 'geral', msg: 'Esta versão de teste ainda não está aberta.' }); return; }
    setIndo(true);
    try {
      const x = srv || await conferir();
      if (!x) { setIndo(false); return; }
      await terminou(await entrarComSenha(x, usuario, senha));
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
  return (
    <main class="entrada" ref={raiz}>
      <header class="entrada-topo">
        {voltar ? <button type="button" class="redondo entrada-voltar" onClick={voltar} aria-label="Voltar"><Icone nome="arrow_back" tamanho={22} /></button> : <span />}
        <button type="button" class="redondo entrada-qc" disabled={!srv || !qcLigado} onClick={abrirQc}
          aria-label="Entrar com Quick Connect" title={srv && qcLigado ? 'Entrar com Quick Connect' : 'Digite o endereço do servidor'}>
          <Icone nome="mobile_lock_portrait" tamanho={22} />
        </button>
      </header>
      <div class="entrada-centro">
        <div class="entrada-logo" ref={logo}><Logo modo="marca" /></div>
        <form class="entrada-form" onSubmit={enviar} novalidate>
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
        </form>
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
