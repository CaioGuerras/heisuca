// "Trocar servidor" discreto (Caio 19/10; 07/11: Jellyfin e Plex, o Plex com selo pequeno). Lista os servidores já usados; tocar troca na hora se a sessão
// dele estiver guardada, senão abre a entrada com o endereço preenchido. "Adicionar servidor" abre a entrada vazia.
import type { Sessao } from '../api/servidor.ts';
import { servidoresSalvos, trocarPara, type Servidor } from '../api/contas.ts';
import { Folha } from './Folha';
import { Icone } from './Icone';

export function TrocarServidor({ s, aberta, fechar, aoTrocar, aoEntrar }: {
  s: Sessao; aberta: boolean; fechar: () => void; aoTrocar: (nova: Sessao) => void; aoEntrar: (srv: Servidor | null) => void;
}) {
  const lista = servidoresSalvos();
  return (
    <Folha aberta={aberta} fechar={fechar} titulo="Servidores">
      <ul class="lista-opcoes">
        {lista.map(srv => {
          const atual = srv.id === s.servidorId;
          return (
            <li key={srv.id}>
              <button class="opcao-linha" aria-current={atual ? 'true' : undefined} onClick={() => {
                if (atual) { fechar(); return; }
                const nova = trocarPara(srv.id);
                fechar();
                if (nova) aoTrocar(nova); else aoEntrar(srv);
              }}>
                <Icone nome="dns" tamanho={22} />
                <span class="opcao-texto"><strong class="uma-linha">{srv.nome}{srv.tipo === 'plex' && <span class="selo-plex">Plex</span>}</strong><small class="uma-linha">{srv.url.replace(/^https?:\/\//, '')}</small></span>
                {atual && <Icone nome="check" tamanho={22} classe="opcao-marca" />}
              </button>
            </li>
          );
        })}
        <li><button class="opcao-linha" onClick={() => { fechar(); aoEntrar(null); }}>
          <Icone nome="add" tamanho={22} /><span class="opcao-texto"><strong>Adicionar servidor</strong></span>
        </button></li>
      </ul>
    </Folha>
  );
}
