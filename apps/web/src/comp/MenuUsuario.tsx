// Menu do usuário (PLANO §9; base ref/app_completo/…menu_usuario, enxugado): nasce da foto na ilha (balão).
// Itens: Minha conta (cabeçalho) · Como usar (no topo enquanto houver passo sem marcar; completo, sai do menu e vira link no
// Sobre) · Tema · Baixar os apps · Sobre · Apoiar o Heisuca · Sair. Saem do app completo: Favoritos/Bibliotecas (na ilha),
// Baixados, Configurações, Trocar usuário e Meus pedidos (fica na Busca, junto de "Disponível para pedir"; revisão de 19/10).
// Tema: abre ali mesmo, dentro do balão, só com os nomes (sem amostra de cor; §2.1); a tela muda na hora.
import type { JSX } from 'preact';
import { useEffect, useState } from 'preact/hooks';
import type { Sessao } from '../api/jellyfin';
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
  const [temas, setTemas] = useState(false);
  const [escolha, setEscolha] = useState(escolhaAtual);
  useEffect(() => { if (!ancora) setTemas(false); }, [ancora]);
  const ir = (p: Parameters<typeof irPagina>[0]) => { fechar(); irPagina(p); };
  const completa = ajudaCompleta();
  const linha = (icone: string, rotulo: string, acao: () => void, classe = '') => (
    <li key={rotulo}><button class={`opcao-linha mu-item ${classe}`} onClick={acao}><Icone nome={icone} tamanho={24} classe="mu-icone" />
      <span class="opcao-texto"><strong>{rotulo}</strong></span></button></li>
  );
  // grupos separados por linha fina (como no app completo); grupo vazio não deixa linha sobrando
  const grupos: JSX.Element[][] = [
    completa ? [] : [linha('help', 'Como usar', () => ir('ajuda'))],
    [
      <li key="tema">
        <button class="opcao-linha mu-item" aria-expanded={temas} onClick={() => setTemas(t => !t)}>
          <Icone nome="palette" tamanho={24} classe="mu-icone" /><span class="opcao-texto"><strong>Tema</strong></span>
          <small class="mu-extra">{NOMES[escolha]}</small><Icone nome="keyboard_arrow_down" tamanho={20} classe={`mu-seta${temas ? ' aberta' : ''}`} />
        </button>
        {temas && (
          <div class="mu-temas" role="radiogroup" aria-label="Tema">
            {(['roxo', 'verde', 'auto'] as Escolha[]).map(e => (
              <button key={e} role="radio" aria-checked={escolha === e} class={`mu-tema${escolha === e ? ' ativo' : ''}`}
                onClick={() => { escolherTema(e); setEscolha(e); }}>{NOMES[e]}</button>
            ))}
          </div>
        )}
      </li>,
      linha('download', 'Baixar os apps', () => ir('apps')),
      linha('info', 'Sobre', () => ir('sobre')),
    ],
    [linha('volunteer_activism', 'Apoiar o Heisuca', () => ir('apoiar'), 'mu-apoiar')],
    [linha('logout', 'Sair', () => { fechar(); sair(); })],
  ].filter(g => g.length);
  return (
    <Folha aberta={!!ancora} fechar={fechar} ancora={ancora} variante="balao" semCabeca titulo="Menu do usuário" classe="mu">
      <button class="mu-conta" onClick={() => ir('conta')}>
        <Avatar s={s} tamanho={52} />
        <span class="opcao-texto"><strong class="uma-linha">{s.nome}</strong><small>Minha conta: foto e senha</small></span>
        <Icone nome="chevron_right" tamanho={22} classe="mu-seta" />
      </button>
      <ul class="lista-opcoes">
        {grupos.map((g, n) => [n > 0 && <li key={`hr${n}`} role="separator"><hr /></li>, ...g])}
      </ul>
    </Folha>
  );
}
