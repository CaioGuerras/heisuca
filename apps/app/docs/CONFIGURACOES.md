# Configurações do CGFLIX

O CGFLIX segue a ideia "omakase": o app já vem pronto do jeito que o dono usaria, com poucas escolhas na cara de quem só
quer assistir. O avançado existe, mas fica escondido.

**Como é a tela** (versão 1.6.1, refino 2b — padrão das Configurações do Android / Material 3):

- **Lista plana**, sem cartões nem sanfonas: grupos com **cabeçalho na cor do tema** (Isis lilás, Heitor verde).
- Cada item mostra no resumo o **valor atual** ("Português (Brasil)", "Original", "Mostrar botão"); liga/desliga é um
  **switch** à direita (o item inteiro alterna); item que abre outra tela **não tem seta** (como no Android).
- Escolhas curtas abrem um diálogo com botões de opção; números são **controles deslizantes**; cores são **círculos**.
- **Avançado** é um item no fim, **fechado**, que abre uma subtela; depois dele só o **Apoie o CGFLIX**.
- Só a apresentação foi reorganizada: nenhuma opção foi removida do código.

## Padrões já escolhidos para o CGFLIX

| Assunto | Padrão |
|---|---|
| Tema | **Isis** (escuro OLED, roxo); Heitor (claro, verde) e Automático na tela principal |
| Idioma | **português (Brasil)**; aparelho em outro idioma traduzido (ex.: espanhol) é respeitado, inglês vira português |
| Reprodução | **direta** (qualidade original; o servidor não transcodifica vídeo) |
| Player | **mpv** (necessário para legenda ASS com estilo) |
| Áudio e legenda | **seguem a preferência do usuário no servidor** (`por`), também ao trocar de episódio |
| Baixar só no Wi-Fi | **ligado** (refino 2) |
| Servidor Jellyfin | campo **vazio** (nada pré-preenchido), dica `https://seu.servidor.com` |

## Tela principal (1.6.1)

| Grupo | Itens (resumo = valor atual) |
|---|---|
| **Conta** (só com Jellyfin conectado ou vários perfis) | Minha conta (foto e senha) · Perfis (com vários perfis) |
| **Aparência** | Tema (Isis/Heitor/Automático) · Idioma do app · Mais opções de aparência (cartões, bibliotecas, efeitos) |
| **Assistir** | Áudio e legenda (idiomas da conta, com "?") · Estilo das legendas · Ao assistir (pular abertura e créditos, próximo episódio, gestos, janelinha, avançar e voltar) · Qualidade padrão (com "?") · Qualidade nos dados móveis |
| — | Baixados (subtela: pasta, só no Wi-Fi com "?", apagar o que já assisti, baixar em segundo plano) |
| **Ajuda** | Dicas do CGFLIX · Sobre |
| — | **Avançado** (subtela, fechado) · **Apoie o CGFLIX** (sempre o último) |

## Avançado (subtela; tudo que o usuário comum não precisa)

| Grupo | Itens |
|---|---|
| Contas e servidores | Adicionar conexão (Plex, Jellyfin ou Emby) · Perfis (com um perfil só) · Organizar bibliotecas · Serviços (Trakt) |
| Recursos extras | Assistir juntos · Controle remoto (outro aparelho com o CGFLIX, mesma rede e conta; não reconhece TV comum) · atalhos de teclado e controle pelo celular (quando o aparelho suporta) |
| Ao assistir (técnico) | **Reprodução avançada** (subtela: Comportamento — inclui "Modo aleatório começa do início" —, Reprodutor, Vídeo e tela, Áudio, Qualidade técnica, Lembrar ajustes) · Opções do mpv · Espera antes de pular · Sempre detectar abertura pelos capítulos · Nome do capítulo de abertura · Nome do capítulo de créditos |
| Legendas (técnico) | Estilo das legendas ASS (anime) · Resolução da legenda |
| Este aparelho | Geral (subtela: forçar modo TV, perfil ao abrir, som de abertura, seção inicial na TV, tela cheia no computador) |
| Atualizações | (só quando o build tem o verificador) |
| Diagnóstico | Servidor do Assistir juntos · Registros de diagnóstico · Esconder o painel de desempenho · Ver registros · Limpar memória de imagens · Restaurar configurações |
| Cópia de segurança | Exportar e importar configurações (fora da TV) |

Na **Início**, o botão Recarregar virou **puxar para atualizar** (além da atualização automática que já existe).

# Tabelas por tela

> Até a 1.6.0 as seções eram cartões ("aberta"/"fechada" abaixo). Desde a 1.6.1 tudo é lista plana; onde cada
> opção mora agora está nas duas tabelas de cima e em `docs/cgflix/REFINO_2B.md`.

As tabelas abaixo foram geradas a partir do código das telas e dos textos em português. "padrão do app" significa que o
valor padrão é o do Plezy (sem alteração do CGFLIX).

## Geral

### Idioma e Região (aberta)

| Opção | O que faz | Padrão |
|---|---|---|
| Idioma | Idioma do app | **Português (Brasil)** |

### Inicialização (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Seção inicial | Aba que abre primeiro | Início |
| Pedir perfil ao abrir o app | Mostrar a seleção de perfil sempre que o app for aberto | desligado |
| Forçar modo TV | Forçar o layout de TV em dispositivos sem detecção automática. Requer reiniciar o app. | desligado |

### Janela (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Iniciar em tela cheia | Abrir o CGFLIX em modo de tela cheia ao iniciar | desligado |

## Aparência

### Tela (aberta)

| Opção | O que faz | Padrão |
|---|---|---|
| Tema | Claro, escuro ou OLED (preto puro) | **OLED** (preto `#07060a`) |
| Efeitos visuais | Automático, completos ou reduzidos (menos animações) | automático |

### Biblioteca e Cards (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Modo de Visualização | — | grid |
| Espaçamento da grade | — | tight |
| Estilo do pôster do episódio | — | padrão do app |
| Mostrar Número do Episódio nos Cards | Mostrar temporada e episódio nos cartões de episódio | ligado |
| Mostrar Pôsteres de Temporada nas Abas | Mostrar o pôster de cada temporada acima da aba | desligado |
| Ocultar spoilers de episódios não assistidos | Desfocar miniaturas e descrições de episódios não assistidos | desligado |
| Mostrar Indicadores de Assistidos | Exibir uma marca de verificação em filmes, séries e episódios assistidos | ligado |
| Cartões TV completos | Usar cartões de TV só com imagem e nomes dos atores sobrepostos | desligado |
| Imagem de destaque no canto | Mostrar a imagem de destaque no canto superior direito em vez de preencher a tela | desligado |
| Brilho de foco | Mostrar um brilho suave ao redor do cartão em foco | ligado |

### Tela inicial (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Mostrar Seção de Destaque | Exibir carrossel de conteúdo em destaque na tela inicial | ligado |
| Ação da seção Continuar assistindo | — | play |
| Ação do episódio | — | play |
| Usar layout inicial | Mostrar hubs iniciais unificados. Caso contrário, usar recomendações da biblioteca. | ligado |
| Mostrar Nome do Servidor nos Hubs | Sempre mostrar nomes dos servidores nos títulos dos hubs. | desligado |

### Navegação (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Mostrar aba Explorar | Exibir a aba Explorar com conteúdo do Plex Discover e dos rastreadores conectados | ligado |
| Manter Barra Lateral Sempre Aberta | A barra lateral fica expandida e a área de conteúdo se ajusta | desligado |
| Agrupar Bibliotecas por Servidor | Agrupar bibliotecas da barra lateral por servidor de mídia. | ligado |
| Mostrar Rótulos da Barra de Navegação | Exibir rótulos de texto sob os ícones da barra de navegação | ligado |
| Mostrar Contagem de Não Assistidos | Exibir contagem de episódios não assistidos em séries e temporadas | ligado |

### TV ao Vivo (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Canais favoritos por padrão | Mostrar apenas os canais favoritos ao abrir a TV ao vivo | desligado |

## Reprodução

### Reprodutor (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Mecanismo de reprodução | — | desligado |
| Decodificação por Hardware | Usar aceleração por hardware quando disponível | ligado |
| Buffer de reprodução | Faz buffer extra contra conexões instáveis. Também limitado pelo tamanho do buffer. | auto |
| Reprodução em túnel | Usar o tunelamento de vídeo. Desative se o vídeo ficar preto ao reproduzir em HDR ou o movimento travar. | desligado |
| Picture-in-picture automático | Entrar automaticamente no modo picture-in-picture ao sair do app durante a reprodução | padrão do app |

### Vídeo e Tela (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Ajustar à taxa de quadros do conteúdo | Ajustar a taxa de atualização da tela ao conteúdo de vídeo | desligado |
| Ajustar à resolução do conteúdo | Muda a tela para a resolução nativa do vídeo para que a TV cuide do upscaling. Menus e legendas também são ampliados durante a reprodução | desligado |
| Ajustar à taxa de atualização | Ajustar a taxa de atualização da tela em tela cheia | desligado |
| Ajustar à faixa dinâmica | Ativar HDR para conteúdo HDR e depois voltar para SDR | desligado |
| Atraso na troca do modo de exibição | — | padrão do app |
| Desativar Dolby Vision | Reproduzir a camada HDR10 ou HLG do arquivo em vez de Dolby Vision, quando houver | desligado |
| Conversão Dolby Vision | Escolha como os arquivos Dolby Vision Profile 7 são tratados. | auto |
| Conversão de HDR para SDR | Escolha o que converte vídeos HDR quando a tela não consegue exibir HDR. | auto |
| Dispositivo | O hardware de vídeo do dispositivo faz a conversão. Mais rápido, mas as cores dependem do dispositivo | — |
| Reprodutor | O reprodutor faz a conversão. Cores consistentes, mas o 4K pode travar em TV boxes mais simples | — |
| Desentrelaçamento | Remover artefatos de pente de vídeo entrelaçado (apenas no reprodutor mpv) | desligado |

### Áudio (aberta)

| Opção | O que faz | Padrão |
|---|---|---|
| Passagem direta de áudio | Enviar o áudio Dolby/DTS ao receptor ou à TV sem recodificação, preservando o som surround. Desative se não houver som. | padrão do app |
| Reforço do canal central | — | padrão do app |
| Normalizar volume na conversão para estéreo | Reduzir o volume da mixagem para evitar saturação. Desative para manter o volume original, que pode distorcer em cenas muito altas. | ligado |
| Volume Máximo | Permitir aumento de volume acima de 100% para mídias silenciosas | 100 |

### Qualidade (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Qualidade padrão | — | original |
| Qualidade padrão nos dados móveis | — | padrão do app |
| Igual à qualidade padrão | — | — |
| Reproduzir Vídeos Menores na Qualidade Original | Reproduzir diretamente os vídeos que já estão dentro do limite de qualidade em vez de transcodificá-los | ligado |
| Codecs de vídeo | Codecs desmarcados são transcodificados pelo servidor | — |
| Qualidade da música | — | original |

### Legendas (aberta)

| Opção | O que faz | Padrão |
|---|---|---|
| Estilo de Legendas | Personalizar aparência das legendas | — |

### Busca e tempo (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Duração do Avanço Curto | — | 10 |
| Duração do Avanço Longo | — | 30 |
| Rebobinar ao retomar | — | padrão do app |
| Temporizador de suspensão padrão | — | 30 |

### Lembrar alterações do reprodutor (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Velocidade de reprodução | — | global |
| Predefinição de shader | — | global |
| Proporção da tela | — | global |
| Sincronização de áudio e legendas | — | global |

### Comportamento (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Lembrar seleção de faixas por série/filme | Lembrar escolhas de áudio e legendas por título | ligado |
| Usar a seleção de faixas do servidor por episódio | Ao mudar de episódio, aplicar o áudio e as legendas selecionados no servidor em vez de manter a escolha atual | ligado |
| Lembrar a sessão de música | Ao iniciar a aplicação, reabrir a última música em pausa onde parou | ligado |
| Mostrar marcadores de capítulos na barra de reprodução | Segmentar a barra de reprodução nos limites dos capítulos | ligado |
| Especiais na ordem dos episódios | Onde os especiais são reproduzidos na ordem de exibição de uma série | respectServer |
| Clicar no vídeo para alternar reprodução/pausa | Clicar no vídeo para reproduzir ou pausar em vez de mostrar os controles. | desligado |
| Sair da tela cheia ao fechar o reprodutor | Sair automaticamente da tela cheia ao fechar o reprodutor de vídeo | desligado |

### Reprodução automática e pulos (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Reproduzir próximo episódio automaticamente | Iniciar o próximo episódio automaticamente quando um terminar | ligado |
| Reprodução Aleatória Começa do Início | Iniciar cada episódio do início na reprodução aleatória em vez de retomá-lo | desligado |
| Contagem regressiva do próximo episódio | — | 5 |
| Pular Abertura | — | padrão do app |
| Pular Créditos | — | padrão do app |
| Forçar marcadores alternativos | Usar padrões de títulos de capítulos mesmo quando o Plex tiver marcadores | desligado |
| Atraso para pular automaticamente | Aguardar ${seconds} segundos antes de pular automaticamente | 5 |
| Padrão do marcador de introdução | Expressão regular que identifica marcadores de introdução nos títulos dos capítulos | defaultIntroPattern |
| Padrão do marcador de créditos | Expressão regular que identifica marcadores de créditos nos títulos dos capítulos | defaultCreditsPattern |

### Gestos (fechada)

| Opção | O que faz | Padrão |
|---|---|---|
| Deslize para brilho | Deslize para cima ou para baixo na borda esquerda para ajustar o brilho | ligado |
| Lembrar Nível de Brilho | Iniciar a reprodução com o brilho definido pelo último deslize | desligado |
| Deslize para volume | Deslize para cima ou para baixo na borda direita para ajustar o volume | ligado |
| Pinça para zoom | Pince o vídeo para ampliar ou reduzir | ligado |

## Serviços (Etapa 1E)

| Item | Situação |
|---|---|
| Trakt | único serviço na tela; usa o app **CGFLIX** do trakt.tv (secrets do CI). Sem os secrets, o item Serviços some |
| MyAnimeList, AniList, Simkl, MDBList | fora da interface (o código do upstream fica; as chaves do Plezy saíram) |
| Seerr (pedidos) | fora dos Serviços: a busca entra sozinha pelo Quick Connect ("Disponível para pedir"); "Meus pedidos" fica no menu do usuário |

A dedicatória ("Feito com amor, para Isis e Heitor") fica **somente no Sobre**; o interruptor "Mostrar dedicatória" saiu.

## Refino 1 (versão 1.5.0)

| Item | Onde | Padrão |
|---|---|---|
| Apoie o CGFLIX | último item das Configurações (coração rosa), menu do usuário e uma linha no Sobre | sempre visível no APK; o AAB da Play sai sem (até entrar o Play Billing) |
| Minha conta (foto e senha) | topo do menu do usuário, só com Jellyfin conectado | — |
| Ícone do app | segue o Tema: Heitor = verde; Isis e Automático = roxo (troca quando o app sai da tela) | roxo |
| Relatório de erros | saiu do Avançado (não fazia nada: os builds do CGFLIX não ligam o Sentry) | — |
| Aparência (resumo) | mostra só o tema, ex.: "Isis (escuro, roxo)" | — |
| Sincronia de áudio/legenda | aparece em segundos ("+0,15 s"); continua guardada em milissegundos | 0 s |
| Música tema / som do trailer | não existe no app (o Plezy não toca nenhum dos dois sozinho) | — |

## Refino 2 (versão 1.6.0)

As tabelas acima seguem valendo para cada opção; mudou a **ordem** e o lugar de algumas (detalhes em
`docs/cgflix/REFINO_2.md`):

- **Tela principal**: Ao assistir · Áudio, legenda e conta · Aparência · Geral ─ Baixados ─ Contas e servidores
  (fechado; com Organizar bibliotecas e Serviços) ─ Avançado (agora com a Cópia de segurança) ─ Sobre ─ Apoie.
- **Ao assistir** (era "Reprodução de vídeo"): Pular abertura e próximo episódio (aberta) · Legendas (aberta) ·
  Gestos · Avançar e voltar · Comportamento · Reprodutor · Vídeo e tela · Áudio (agora **fechada**) · Qualidade ·
  Lembrar ajustes.
- **Avançado** ganha: Sempre detectar abertura pelos capítulos, Nome do capítulo de abertura e de créditos.
- **Padrão novo**: Baixar só no Wi-Fi = **ligado** (antes desligado).
- Itens com "?" (dica): Pular abertura, Áudio, legenda e conta, Baixar só no Wi-Fi, Gestos, Abrir a janelinha ao
  sair, Qualidade padrão. Todas as dicas: Sobre › Dicas do CGFLIX.

## Refino 2b (versão 1.6.1)

Configurações no padrão do Android/Material 3: lista plana com cabeçalhos, sem sanfonas nem setas, switch M3 com
check, números em controle deslizante, cores em círculos, prévia ao vivo da legenda, Avançado fechado no fim. A
subtela Geral saiu da frente (o idioma foi para Aparência; o resto está em Avançado › Este aparelho). Tabela completa
"item → onde estava → onde ficou → por quê" em `docs/cgflix/REFINO_2B.md`.
