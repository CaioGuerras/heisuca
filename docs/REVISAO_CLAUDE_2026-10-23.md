# Heisuca Android — revisão e polimento do Claude — 23/10/2026

Pedido do Caio (23/10, após o 2.0.4): não avançar o projeto, e sim polir, corrigir e conferir o que já
foi feito contra os pilares (desenhos aprovados, site como referência, honestidade, fluidez, flagship de
intermediário premium para cima). Branch `codex/heisuca-home-site`; sem merge nem release.

Legenda: **feito** = no código e nos testes; **aparelho** = depende do teste físico do Caio.

## 1. Ficha do título (2.0.5, `17894e5`) — feito, aparelho

| Retorno do Caio | O que mudou |
|---|---|
| "Mais" distante, parecia ícone | "… mais" dentro da última linha (medido com a fonte herdada; os testes acharam um erro de medição que deixava o "mais" numa 5ª linha cortada). |
| Temporada desalinhada, Ver tudo no canto | "Temporada 4 ⌄" na margem esquerda, "Ver tudo ›" na mesma linha (como o site e o Esboço 04). |
| Folha de temporadas com "Temporadas" parecendo item | Título de folha + ✕; opções em cartões com nº de episódios e ano; a escolhida com borda e ✓. |
| Relacionados só com nomes | Fileira de pôsteres da Home (mesmo cartão), carrega sozinha e some se vazia. |
| Info mídia: lateral e sem caminho do arquivo | Cartões lado a lado (Vídeo · Áudio N · Legendas); o caminho do arquivo saiu. |
| Botão pílula mal polido | Vidro translúcido do site; ao rolar encaixa ao lado do ← sobre um véu da cor da página. |

Também: faixa de episódios de ponta a ponta com encaixe por cartão; "Continuar" só com posição salva
(regra do site, 19/10); elenco e gêneros nas medidas do site; uma chamada que falha não derruba a ficha.

## 2. Player (2.0.6, `853a628`) — feito, aparelho

Esboço 07A no celular: proporção, velocidade, janelinha, rotação e travar em pílulas no topo direito; embaixo
da linha do tempo, "Áudio: Japonês 5.1 · Legendas: Português (ASS) · Episódios · Ajustes · Próximo". Play na cor
do tema; ±N mostram o salto configurado. Mesmos callbacks e painéis reais (TrackControlsState, VideoSettingsSheet,
TrackSheet); tablet, desktop e TV seguem a régua original. Gestos de brilho e volume já eram do motor.

Não feito: gaveta lateral de episódios do 07B (o "Episódios" abre a faixa de conteúdo existente, que sobe de baixo)
e os chips de proporção/velocidade dentro de Ajustes (estão nas pílulas do topo). Paridade pixel a pixel dos painéis:
não declarada.

## 3. Fontes e servidores (2.0.7, `49a2d06`) — feito, aparelho

Causa no código: a escolha de fonte feita durante o rebind do perfil (logo depois de adicionar um servidor) era
descartada em silêncio, e nada passava a mostrar a fonte nova. Agora: espera o binding; porta única "Adicionar fonte"
(Fonte atual e Configurações) com o fluxo real do upstream (Plex, Jellyfin, Emby); ao dar certo, espera o servidor
aparecer e já o seleciona (pergunta qual se a conta Plex trouxe vários). SMB, WebDAV e arquivos locais aparecem
"Em breve", desativados. **O sintoma exato do Caio não foi reproduzido em aparelho**: se ainda falhar, anotar o passo
e a mensagem (ou exportar o log em Configurações > Diagnóstico).

## 4. Modo infantil (2.0.7) — feito, aparelho

- Servidor: a rota `/__kids/` tinha sumido do nginx da VPS (serviço ativo, endereço com 404). Reinstalada com
  `cgf-kids instalar` (backup, `nginx -t`, reload); `cgf-kids testar`: RESULTADO OK (Toy Story e Patrulha Canina
  aparecem; Yojimbo e Metrópolis somem; nada acima do teto nem sem classificação). Aviso no Telegram.
- App: Você > Modo infantil. 1ª vez em 3 passos (o que muda; Ichigo/Sorairo e teto Livre/10; PIN do responsável,
  só em hash). Ativa no cgflix-kids, cria um perfil local ligado ao usuário-sombra e troca pelo caminho oficial de
  perfis, sob a abertura kids do `kids.html`. Temas Ichigo e Sorairo com as cores dos tokens oficiais.
- No modo infantil somem Trocar perfil, Fonte atual, Configurações, Baixados, pedidos e o Em breve (o calendário é
  do servidor inteiro, não filtrado). O app não pergunta "quem está assistindo" com perfil infantil ativo.
- Limites conhecidos: esqueceu o PIN = sair da conta no aparelho (não há recuperação pelo servidor ainda); o
  StreamLimiter conta o usuário infantil à parte (até 4 telas por família); ícone de app infantil não foi feito.

## 5. Fluidez e pilares técnicos (2.0.8) — conferido

| Item do estudo de 20/10 / auditoria Google | Estado |
|---|---|
| Impeller (Vulkan com GLES de reserva) | padrão do Flutter 3.47, nada o desliga |
| UI na taxa máxima do painel (120/144 Hz) | já pedia (MainActivity); **corrigido**: ao fechar o player o modo da tela era zerado e a UI caía no padrão do fabricante até voltar do 2º plano; agora reaplica |
| Cache de imagem calibrado e decodificação no tamanho exibido | já existia (device_performance, OptimizedMediaImage) |
| Rolagem com mola (ProMotion) | global; fileiras de episódios com encaixe por cartão |
| Não anunciar capacidade não verificada | "GPU 144Hz" saiu das Configurações; varredura sem outros casos |

Não medido em aparelho: p90/p99 de quadros, memória e partida fria (usar o Medidor Android em `~/cgflix/medidor-android`).

## 6. Login → configurações — conferido

- **Corrigido:** a conexão rápida usava escondido `https://netflix.docaio.com.br` com o campo vazio (fere a regra do
  fork e a decisão de 21/10: player neutro). Agora pede o endereço.
- Login direto, sem telas legadas empilhadas, abertura única: mantidos.
- **Pendente:** no caso raro de recuperação do banco local, a tela de login ainda é a do upstream (ela exige a
  confirmação antes de recriar os dados; portar com cuidado).
- Biblioteca e Busca de `lib/heisuca` continuam protótipos fora da navegação (dados fixos); a navegação usa as telas reais.
- HDR, ASS/libass, PiP, rotação, retomada e múltiplos serviços: dependem do aparelho.
