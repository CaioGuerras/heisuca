// Entrada: endereço do servidor, usuário e senha, ou Quick Connect. Lab: só as contas de teste entram.
import { useEffect, useRef, useState } from 'preact/hooks';
import { entradaJellyfin, type Sessao } from '@w/api/servidor';
import { esquecerSessao, ultimoServidor, type Servidor } from '@w/api/contas';
import { Chama } from '../comp/Marca';
import { Ic } from '../comp/Icone';

const { descobrir, entrarComSenha, ErroEntrada, esperarQuickConnect, iniciarQuickConnect, quickConnectLigado } = entradaJellyfin;
const SO = ((import.meta.env.VITE_SO_USUARIO as string | undefined) || '').split(',').map(x => x.trim().toLowerCase()).filter(Boolean);
const liberado = (u: string) => !SO.length || SO.includes(u.trim().toLowerCase());
type Erro = { campo: string; msg: string } | null;

export function Entrada({ pronto }: { pronto: (s: Sessao) => void }) {
  const anterior = ultimoServidor();
  const [endereco, setEndereco] = useState(anterior?.url.replace(/^https:\/\//, '') || '');
  const [srv, setSrv] = useState<Servidor | null>(anterior);
  const [usuario, setUsuario] = useState('');
  const [senha, setSenha] = useState('');
  const [erro, setErro] = useState<Erro>(null);
  const [indo, setIndo] = useState(false);
  const [qcLigado, setQcLigado] = useState(false);
  const [qc, setQc] = useState<{ codigo: string; segredo: string } | null>(null);
  const procura = useRef(0);

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

  const terminou = (s: Sessao) => {
    if (!liberado(s.nome)) { esquecerSessao(); setErro({ campo: 'geral', msg: 'Este laboratório ainda está fechado para esta conta.' }); return; }
    pronto(s);
  };

  async function enviar(ev: Event) {
    ev.preventDefault();
    if (indo) return;
    setErro(null);
    if (!liberado(usuario)) { setErro({ campo: 'geral', msg: 'Este laboratório ainda está fechado para esta conta.' }); return; }
    setIndo(true);
    try {
      const x = srv || await conferir();
      if (!x) return;
      terminou(await entrarComSenha(x, usuario, senha));
    } catch (e) {
      setErro(e instanceof ErroEntrada ? { campo: (e as InstanceType<typeof ErroEntrada>).campo, msg: e.message } : { campo: 'geral', msg: 'Não deu para entrar agora. Tente de novo.' });
    } finally { setIndo(false); }
  }

  useEffect(() => {
    if (!qc || !srv) return;
    let cancelado = false;
    esperarQuickConnect(srv, qc, () => cancelado).then(s => { if (s && !cancelado) { setQc(null); terminou(s); } })
      .catch(e => { if (!cancelado) { setQc(null); setErro({ campo: 'geral', msg: e instanceof Error ? e.message : 'O código venceu.' }); } });
    return () => { cancelado = true; };
  }, [qc]);

  const erroDe = (c: string) => erro?.campo === c ? <p class="campo-erro" role="alert">{erro.msg}</p> : null;
  return (
    <main class="entrada">
      <div class="entrada-luz" aria-hidden="true" />
      <section class="entrada-cartao">
        <div class="entrada-marca"><Chama t={44} /><h1>Lume</h1><p>Seu cinema, aceso.</p></div>
        {qc ? (
          <div class="entrada-qc" role="status">
            <p>Em outro aparelho já conectado, abra <b>Configurações → Quick Connect</b> e digite:</p>
            <p class="entrada-codigo" aria-label={`Código ${qc.codigo.split('').join(' ')}`}>{qc.codigo}</p>
            <button type="button" class="botao fantasma" onClick={() => setQc(null)}>Voltar</button>
          </div>
        ) : (
          <form onSubmit={enviar} noValidate>
            <label class="campo"><span>Servidor</span>
              <input value={endereco} onInput={e => setEndereco((e.currentTarget as HTMLInputElement).value)} onBlur={() => !srv && conferir()}
                inputMode="url" autocomplete="url" autocapitalize="off" spellcheck={false} placeholder="servidor.exemplo.com" aria-invalid={erro?.campo === 'servidor'} />
              {srv && <span class="campo-ok"><Ic n="check_circle-fill" t={18} />{srv.nome || 'Encontrado'}</span>}
            </label>
            {erroDe('servidor')}
            <label class="campo"><span>Usuário</span>
              <input value={usuario} onInput={e => setUsuario((e.currentTarget as HTMLInputElement).value)} autocomplete="username" autocapitalize="off" spellcheck={false} aria-invalid={erro?.campo === 'usuario'} />
            </label>
            {erroDe('usuario')}
            <label class="campo"><span>Senha</span>
              <input type="password" value={senha} onInput={e => setSenha((e.currentTarget as HTMLInputElement).value)} autocomplete="current-password" aria-invalid={erro?.campo === 'senha'} />
            </label>
            {erroDe('senha')}{erroDe('geral')}
            <button class="botao primario largo" disabled={indo}>{indo ? <Ic n="progress_activity" t={20} classe="girando" /> : 'Entrar'}</button>
            {qcLigado && srv && <button type="button" class="botao fantasma largo" onClick={async () => {
              try { setQc(await iniciarQuickConnect(srv)); } catch (e) { setErro({ campo: 'geral', msg: e instanceof Error ? e.message : 'Quick Connect indisponível.' }); }
            }}>Entrar com código (Quick Connect)</button>}
          </form>
        )}
      </section>
      <p class="entrada-pe">Laboratório do Heisuca · versão de teste</p>
    </main>
  );
}
