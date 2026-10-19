// Menu do usuário (PLANO §9; base ref/app_completo/…menu_usuario, enxugado): nasce da foto na ilha.
// Itens: Minha conta (cabeçalho) · Como usar (no topo até completar) · Meus pedidos (só com Seerr) · Tema · Baixar os apps ·
// Sobre · Apoiar o Heisuca · Sair. Saem do app completo: Favoritos/Bibliotecas (na ilha), Baixados, Configurações, Trocar usuário.
import { useEffect, useState } from 'preact/hooks';
import type { Sessao } from '../api/jellyfin';
import { temSeerr } from '../api/seerr';
import { escolhaAtual, escolherTema, type Escolha } from '../tema';
import { irPagina } from '../rota';
import { Folha } from './Folha';
import { Icone } from './Icone';
import { Avatar } from './Navegacao';
import './menu-usuario.css';

export const AJUDA_COMPLETA = 'heisuca.ajuda.completa';
const ajudaCompleta = () => { try { return localStorage.getItem(AJUDA_COMPLETA) === '1'; } catch { return false; } };
const NOMES: Record<Escolha, string> = { roxo: 'Roxo', verde: 'Verde', auto: 'Automático' };

export function MenuUsuario({ s, ancora, fechar, sair }: { s: Sessao; ancora: HTMLElement | null; fechar: () => void; sair: () => void }) {
  const [seerr, setSeerr] = useState(false);
  const [temas, setTemas] = useState(false);
  const [escolha, setEscolha] = useState(escolhaAtual);
  useEffect(() => { temSeerr(s).then(setSeerr); }, [s.servidor]);
  const ir = (p: Parameters<typeof irPagina>[0]) => { fechar(); irPagina(p); };
  const completa = ajudaCompleta();
  const linha = (icone: string, rotulo: string, acao: () => void, extra?: string) => (
    <li><button class="opcao-linha" onClick={acao}><Icone nome={icone} tamanho={22} /><span class="opcao-texto"><strong>{rotulo}</strong></span>
      {extra && <small class="mu-extra">{extra}</small>}<Icone nome="chevron_right" tamanho={20} classe="mu-seta" /></button></li>
  );
  return (
    <>
      <Folha aberta={!!ancora && !temas} fechar={fechar} ancora={ancora} variante="balao" semCabeca titulo="Menu do usuário" classe="mu">
        <button class="mu-conta" onClick={() => ir('conta')}>
          <Avatar s={s} tamanho={48} />
          <span class="opcao-texto"><strong class="uma-linha">{s.nome}</strong><small>Minha conta: foto e senha</small></span>
          <Icone nome="chevron_right" tamanho={20} classe="mu-seta" />
        </button>
        <ul class="lista-opcoes">
          {!completa && linha('help', 'Como usar', () => ir('ajuda'))}
          {seerr && linha('playlist_add_check', 'Meus pedidos', () => ir('pedidos'))}
          {linha('palette', 'Tema', () => setTemas(true), NOMES[escolha])}
          {linha('download', 'Baixar os apps', () => ir('apps'))}
          {linha('info', 'Sobre', () => ir('sobre'))}
          {completa && linha('help', 'Como usar', () => ir('ajuda'))}
          {linha('volunteer_activism', 'Apoiar o Heisuca', () => ir('apoiar'))}
          <li><hr /></li>
          <li><button class="opcao-linha" onClick={() => { fechar(); sair(); }}><Icone nome="logout" tamanho={22} /><span class="opcao-texto"><strong>Sair</strong></span></button></li>
        </ul>
      </Folha>
      <Folha aberta={!!ancora && temas} fechar={() => setTemas(false)} titulo="Tema">
        <ul class="lista-opcoes">
          {(['roxo', 'verde', 'auto'] as Escolha[]).map(e => (
            <li key={e}><button class="opcao-linha" aria-current={escolha === e ? 'true' : undefined} onClick={() => { escolherTema(e); setEscolha(e); }}>
              <span class="opcao-texto"><strong>{NOMES[e]}</strong>{e === 'auto' && <small>Segue o aparelho: escuro fica Roxo, claro fica Verde</small>}</span>
              {escolha === e && <Icone nome="check" tamanho={22} classe="opcao-marca" />}
            </button></li>
          ))}
        </ul>
      </Folha>
    </>
  );
}
