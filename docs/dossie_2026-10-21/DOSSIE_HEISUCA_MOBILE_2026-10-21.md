# Dossiê Heisuca Mobile Flagship — 21 de Outubro de 2026
> **Documento para alinhamento entre Caio Guerras, Claude e Gemini.**  
> Compilado em 21/10/2026 às 19:00 SP.  
> Contém todas as decisões, esboços aprovados, especificações visuais, regras de UX, arquitetura de hardware (Motorola Edge 60 Pro), análise dos erros de compilação e orientações para reconstrução limpa.

---

## 1. Diretiva Central do Caio (18:56 SP)

> *"Continua não funcionando, novamente você apenas colocou a tela de login por cima do outro app, vamos parar de tentar compilar por cima, pois voltamos aos erros de antes. Consegue organizar tudo o que passamos e falamos hoje desde as 6:43? Pois foi durante o dia de hoje que definimos tudo, coloque tudo em ordem, o que decidimos, cada imagens, cada ideia, tudo, deixe separado em um repositório ou algum lugar, vou pedir para o Claude ver"*

### Princípio Fundamental
Não remendar widgets novos por cima da árvore de UI antiga do Plezy/CGFLIX.
O modelo que funcionou no site web do Heisuca deve ser replicado no app móvel:
- **Motor e infraestrutura reaproveitados:** `libmpv` (reprodução nativa acelerada por hardware), decodificadores Vulkan/MediaCodec, cache local, proxy HTTP local para streaming, clientes de API (`JellyfinClient`, WebDAV, SMB);
- **Interface e navegação criadas do zero:** toda a árvore de widgets, navegação de rotas, telas, cards, tipografia, micro-interações de mola e design tokens devem ser 100% Heisuca, sem herdar telas antigas (`AuthScreen`, `AddJellyfinScreen`, `SetupScreen` legado, layouts antigos com botões pretos empilhados).

---

## 2. Cronologia Completa das Decisões de Hoje (21/10/2026)

| Horário (SP) | Autor | Mensagem / Pauta | Decisão / Resultado Aprovado |
|---|---|---|---|
| **06:45** | Caio | *"Cadê o resultado? O apk está pronto?"* | APK v2.0.1+2 compilado na madrugada estava na VPS. |
| **07:36** | Caio | *"O app não está assim, ele ainda foi construído encima do app do CGFLIX, isso não faz sentido... Vamos montando parte a parte, apenas no esboço, depois de termos montado todo o esboço da estrutura, nós começamos a montar o app. Primeiro me mande aqui a animação que criou para a abertura..."* | **Pivô do projeto:** Parar implementações diretas. Fazer o ciclo de aprovação visual tela por tela em esboços/storyboards ilustrativos. |
| **07:46** | Caio | *"Ok, eu aprovo abertura, só me garanta que a versão pro outro tema também esteja assim. E vamos agora para a tela de login..."* | **Esboço 01 Aprovado:** Abertura Única de 2200ms a 144Hz com carimbo carmim `炳素華`, halo radial OKLCH e suporte idêntico em ambos os temas: **Shikkoku** (Escuro `#0E0B14`) e **Hisui** (Claro `#F7F3EC`). |
| **08:21** | Caio | *"A tela ficou boa, mas faltou as opções de outros servidores"* | Apresentadas duas alternativas para servidores alternativos: pílulas no topo vs botão discreto inferior. |
| **08:31** | Caio | *"Prefiro o botão discreto"* | **Esboço 02/02B Aprovado:** Tela de Login com Card Quick Connect no topo, 3 campos limpos (Servidor, Usuário, Senha) e botão discreto `+ Outros servidores e pastas locais` abrindo gaveta inferior (SMB/WebDAV). |
| **09:34** | Caio | *"Eu aprovo, mas tem 2 pontos: primeiro, o nome heisuca está deslocado, ele deve ficar junto da logo no canto superior esquerdo; e no menu não precisamos dar ênfase para os temas, ele pode ir para a área de configurações que precisamos criar, pois o app tem mais opções de configurações do que o site, baseado no VidHub, Plezy e Infuse... No menu fica Perfil, Baixados e Configurações"* | **Esboço 03/03B Aprovado:** Home com topo alinhado à esquerda (`炳 HEISUCA`), Ilha Flutuante de 4 abas (Início, Biblioteca, Buscar, Você) e Menu do Usuário enxuto. Criação de tela dedicada de Configurações. |
| **10:45** | Caio | Validação da Ficha Técnica do Título e Menu de Contexto | **Esboço 04/04B Aprovado:** Modal Bottom Sheet com 9-stop cubic scrim, sinopse, elenco, badges técnicos, botão "Assistir" gradiente, lista de episódios, menu de toque longo (500ms) com haptics e folha de pedidos no Seerr. |
| **11:45** | Caio | Validação de Biblioteca e Busca | **Esboço 05/05B Aprovado:** Biblioteca com chips de filtro rápido (Filmes, Séries, Animes) e seletor de ordenação. Busca com histórico recente, chips em alta e divisão clara entre "No Servidor" e "Pedir via Seerr". |
| **13:00** | Caio | Validação da Tela de Configurações | **Esboço 06 Aprovado:** Tela de Configurações Heisuca inspirada no VidHub, Plezy e Infuse. Card de topo *"Aparelho Reconhecido"* detectando automaticamente o Motorola Edge 60 Pro, abas de Reprodução, Interface, Downloads e Avançado (Vulkan zero-copy). |
| **14:32** | Caio | *"Gere novamente o esboço, ele veio muito esticado, pode fazer em duas imagens se necessário"* | Ajuste do esboço do player para proporção ultra-wide 20:9 real em alta definição. |
| **15:02** | Caio | *"Ficou bom, mas as setas de pular abertura estão pro lado contrário, e as opções de aspect ratio e velocidade de reprodução são clicáveis na tela? o resto está ok"* | **Esboço 07/07B Aprovado:** Setas corrigidas para a direita (`▶▶ Pular Abertura`). Confirmado que os botões de proporção (20:9, 16:9, Zoom) e velocidade (0.5x a 2.0x) são interativos com feedback tátil. |
| **15:06** | Caio | *"Sim, está tudo de acordo"* | Aprovação formal de todos os 7 esboços de interface do Heisuca Mobile. |
| **15:10** | Caio | *"Sim, se não faltar mais detalhes, vamos avançar, lembre-se que ontem eu pedi pra aprofundar ainda mais nas questões que você trouxe como efeito mola e outros"* | Aprofundamento da engenharia de física de mola (`HeisucaSpringPhysics`) e micro-interações táteis aos 200ms de toque. |
| **15:20** | Caio | *"Só não esqueça de tudo que fizer, me trazer uma imagem para eu ler e ver o que foi feito"* | Geração e envio da Prancha Técnica de Engenharia (Física de Mola, Haptics e Reconhecimento de Hardware). |
| **15:51** | Caio | *"Está ótimo, vamos avançar, e só para ter certeza, se 3.8 bater a cota, você troca para outra conta né"* | Confirmação da rotação de contas do Gemini via `cgmind`. Início da implementação em código. |
| **17:31** | Caio | Envio da Foto 249: *"Acabei de baixar e instalar e é o app antigo que acabamos de mudar, ele está com a mesma tela de entrada de antes, que na verdade são duas uma por cima da outra..."* | Identificado que a rota raiz do `main.dart` ainda caiu no `AuthScreen` antigo com botões pretos empilhados. |
| **18:13** | Caio | Envio do Vídeo 254: *"Não funcionou, gravei um vídeo pra mostrar, está completamente bugado..."* | Vídeo mostrou que a tela Heisuca apareceu, mas ao clicar "Conectar ao Servidor", o botão chamou a tela legada `AddJellyfinScreen` em branco, descartando o que foi digitado. |
| **18:56** | Caio | *"Continua não funcionando, novamente você apenas colocou a tela de login por cima do outro app, vamos parar de tentar compilar por cima... Consegue organizar tudo o que passamos e falamos hoje desde as 6:43? Deixe separado em um repositório ou algum lugar, vou pedir para o Claude ver"* | **Pausa definitiva de compilações sobrepostas e compilação do presente Dossiê Completo.** |

---

## 3. Catálogo Visual de Telas e Storyboards Aprovados

Todas as imagens geradas e aprovadas durante a sessão de hoje foram preservadas no repositório em:  
`apps/app/docs/dossie_2026-10-21/imagens/` (ou `~/heisuca/docs/dossie_2026-10-21/imagens/`).

### Esboço 01: Abertura Única Cinematográfica (`炳素華`)
- **Arquivo de Imagem:** [`01_abertura_unica_splash.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/01_abertura_unica_splash.png)
- **Especificação:**
  - Duração: 2200 ms travada no Flutter (`CgflixIntro.finished()`);
  - Taxa nativa: 144 Hz (no Motorola Edge 60 Pro);
  - Elementos: Carimbo oriental carmim em relevo com os kanjis `炳素華` (Heisuca), pulso de halo radial OKLCH, expansão do slogan *"Nada entre você e o filme"*;
  - Transição de saída: Voo contínuo da marca do centro da tela em direção ao topo da tela de login (sem corte de tela preta).

---

### Esboço 02 & 02B: Tela de Login e Entrada Heisuca
- **Arquivos de Imagem:**
  - Login Padrão: [`02_tela_login_heisuca.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/02_tela_login_heisuca.png)
  - Alternativa com Pílulas: [`02b_login_multiplos_servidores_pilulas.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/02b_login_multiplos_servidores_pilulas.png)
- **Decisão do Caio (08:31 SP):** Usar o modelo com **botão discreto inferior**, sem poluir o topo com pílulas.
- **Especificação:**
  - Card de topo: **Conexão Rápida (Quick Connect)** com ícone QR e botão *"Usar Conexão Rápida ›"*;
  - Separador sutil: *"OU ACESSO DIRETO"*;
  - 3 Campos Glass translúcidos:
    1. **Servidor Heisuca:** pré-preenchido com `https://netflix.docaio.com.br`;
    2. **Usuário:** campo limpo com ícone de perfil;
    3. **Senha:** campo com botão de olho para exibir/ocultar senha;
  - Botão Primário: *"Conectar ao Servidor"* com gradiente violeta/carmim e sombra de profundidade;
  - Rodapé: Botão discreto `+ Outros servidores e pastas locais` que abre folha inferior com opções para **Rede SMB / Samba** e **Servidor WebDAV**.

---

### Esboço 03 & 03B: Tela Inicial (Home), Ilha Flutuante e Menu do Usuário
- **Arquivos de Imagem:**
  - Versão inicial: [`03_home_ilha_flutuante_menu.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/03_home_ilha_flutuante_menu.png)
  - Versão corrigida: [`03b_home_topo_alinhado_menu_usuario.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/03b_home_topo_alinhado_menu_usuario.png)
- **Ajustes pedidos pelo Caio (09:34 SP):**
  1. A marca `炳 HEISUCA` deve ficar no canto superior esquerdo, sem deslocamento;
  2. Os temas foram removidos do menu rápido e movidos para as Configurações completas;
  3. O menu do usuário fica com: **Perfil**, **Baixados**, **Configurações** e **Sair**.
- **Especificação:**
  - **Iluminação Hero Halo OKLCH:** O fundo superior extrai dinamicamente a cor da arte do banner em destaque e projeta uma aura difusa suave;
  - **Ilha Flutuante (Floating Island):** Pílula de vidro escuro flutuando 14dp acima do rodapé com 4 abas táteis:
    1. `Início` (Discover)
    2. `Biblioteca` (Libraries)
    3. `Buscar` (Search)
    4. `Você` (Perfil / Usuário)

---

### Esboço 04 & 04B: Ficha Técnica do Título e Menu de Contexto 500ms
- **Arquivos de Imagem:**
  - Ficha Técnica Modal: [`04_ficha_titulo_bottom_sheet.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/04_ficha_titulo_bottom_sheet.png)
  - Menu de Contexto & Seerr: [`04b_menu_contexto_toque_longo_seerr.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/04b_menu_contexto_toque_longo_seerr.png)
- **Especificação:**
  - **Ficha Modal (Bottom Sheet):** Abre com física de amortecimento elástico cobrindo 88% da tela. Cabeçalho com banner em fade cúbico de 9 paradas, logotipo ou título em Sora Bold, badges nobres (`4K`, `HDR10+`, `1080p`, `5.1 CH`, `PT-BR`), botão *"Assistir"* em gradiente primário, botão *"Baixar"*, sinopse completa e carrossel de episódios por temporada;
  - **Menu de Toque Longo (500ms):** Ao pressionar qualquer poster por 500ms, o card retrai 3.5% com vibração tátil sutil e abre o menu de contexto suspenso: *"Assistir"*, *"Marcar como Assistido"*, *"Ver Detalhes"*, *"Pedir no Seerr"* e *"Remover de Continuar Assistindo"*.

---

### Esboço 05 & 05B: Biblioteca e Busca Unificada
- **Arquivo de Imagem:** [`05_biblioteca_filtros_busca_unificada.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/05_biblioteca_filtros_busca_unificada.png)
- **Especificação:**
  - **Biblioteca:** Grid adaptativo de 3 colunas (no Edge 60 Pro), chips de filtro rápido no topo (`Todos`, `Filmes`, `Séries`, `Animes`) e menu dropdown de ordenação (`Adicionados Recentemente`, `Título A-Z`, `Ano`, `Nota`);
  - **Busca Unificada:** Campo de busca com ativação imediata do teclado, histórico de pesquisas recentes com botão limpar, chips de buscas populares e resultados separados em duas seções:
    1. *No Acervo CGFLIX* (reprodução instantânea);
    2. *Disponível para Pedir* (integração direta com a API do Seerr).

---

### Esboço 06: Tela de Configurações Heisuca (Inspirada no VidHub, Plezy e Infuse)
- **Arquivo de Imagem:** [`06_configuracoes_aparelho_edge60pro.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/06_configuracoes_aparelho_edge60pro.png)
- **Especificação:**
  - **Card de Topo "Aparelho Reconhecido":**
    - Identifica automaticamente o modelo: *"Motorola Edge 60 Pro"*;
    - Exibe selos de hardware ativo: `OLED 144Hz Nativo` · `Snapdragon 7 Gen 3` · `HDR10+ / HLG` · `Vulkan 1.3`;
  - **Seções de Ajuste:**
    1. **Reprodução & Decodificação:** Decodificador de Hardware (`Vulkan Zero-Copy` / `MediaCodec Direct`), Buffer de Demuxer (`150 MB`), Passthrough de Áudio HD;
    2. **Interface & Aparência:** Alternância de Tema (`Shikkoku` escuro / `Hisui` claro), Taxa de Atualização Forçada a 144Hz, Efeito Mola Heisuca (`Ativado`);
    3. **Downloads & Armazenamento:** Pasta de destino no armazenamento interno, limite de uso de disco e qualidade padrão para download;
    4. **Avançado / Desenvolvedor:** Logs do motor `libmpv`, estatísticas de cache e proxy local.

---

### Esboço 07 & 07B: Player Cinematográfico 20:9
- **Arquivos de Imagem:**
  - Controles e Gestos: [`07_player_20_9_gestos_controles.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/07_player_20_9_gestos_controles.png)
  - Versão Corrigida com Botões Clicáveis: [`07b_player_corrigido_pular_abertura.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/07b_player_corrigido_pular_abertura.png)
- **Correções do Caio (15:02 SP):**
  - Setas do botão *"Pular Abertura"* viradas para a direita: `▶▶ Pular Abertura`;
  - Botões de **Proporção de Tela** (20:9, 16:9, Esticar) e **Velocidade** (1.0x, 1.25x, etc.) são botões clicáveis diretamente na interface do player.
- **Especificação:**
  - **Calibração 20:9:** Ajustado para a tela pOLED curvada do Motorola Edge 60 Pro, preenchendo o display sem barras pretas nas laterais quando selecionado o modo 20:9;
  - **Gestos na Tela:**
    - Lado esquerdo (arrasto vertical): controle de **Brilho** da tela com indicador de barra luminosa;
    - Lado direito (arrasto vertical): controle de **Volume** com indicador;
    - Centro (arrasto horizontal): scrub na linha do tempo com bolha de tempo e miniatura de pré-visualização;
  - **Legendas Nobres:** Renderizador `libass` com suporte a estilos avançados (.ass/.ssa), contorno nítido e sincronia fina em milissegundos.

---

### Prancha Técnica da Engenharia (Física de Mola, Haptics & Calibração)
- **Arquivo de Imagem:** [`08_engenharia_mola_haptics_reconhecimento.png`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/08_engenharia_mola_haptics_reconhecimento.png)
- **Especificação:**
  - **Fórmula da Mola (`HeisucaSpringPhysics`):**
    $$\ddot{x} + 2\zeta\omega_n \dot{x} + \omega_n^2 x = 0$$
    onde coeficiente de amortecimento $\zeta = 0.82$, rigidez $k = 185$ N/m e massa $m = 1.0$;
  - **Micro-interação aos 200ms:** Ao manter o dedo pressionado em qualquer card ou botão por 200ms, ocorre uma pré-tensão elástica com escala de $0.965$ e pulso tátil `HapticFeedback.lightImpact()`.

---

## 4. Diagnóstico Técnico dos Erros de Hoje

### Evidências dos Erros (Anexos do Caio)
1. **Foto 249 (17:31 SP):** [`erro_01_foto_caio_auth_legado.jpg`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/erro_01_foto_caio_auth_legado.jpg)  
   Mostrou que o APK instalado abriu o `AuthScreen` antigo do Plezy com botões pretos empilhados: *"Entrar no Jellyfin"*, *"Entrar com Plex"*, etc.
2. **Vídeo 254 (18:13 SP):**
   - Quadro 01: [`erro_02_video_caio_login_ignorado_q01.jpg`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/erro_02_video_caio_login_ignorado_q01.jpg)
   - Quadro 04: [`erro_02_video_caio_add_jellyfin_legado_q04.jpg`](file:///home/caioguerras/heisuca/docs/dossie_2026-10-21/imagens/erro_02_video_caio_add_jellyfin_legado_q04.jpg)  
   Mostrou que a `HeisucaLoginScreen` apareceu, o Caio digitou `netflix.docaio.com.br`, `caioguerras` e a senha, mas ao clicar em **"Conectar ao Servidor"**, o app abriu a tela cinza antiga `AddJellyfinScreen` em branco, exigindo digitar tudo de novo.

### Raiz do Problema
1. **Acoplamento de Rotas no `main.dart` Legado:**  
   O arquivo [`apps/app/lib/main.dart`](file:///home/caioguerras/heisuca/apps/app/lib/main.dart) foi herdado do Plezy e possui uma máquina de estados complexa de inicialização (`SetupScreen`), com mais de 2.200 linhas de código misturando checagens de migração legada do Plex, recuperação de banco de dados e rotas fixas (`AuthScreen`). Quando o app abria em estado deslogado ou com banco vazio, ele caía em rotas antigas.
2. **Telas Empilhadas (*Stacked Navigation Routes*):**  
   Ao colocar a `HeisucaOpeningSplash` ou `HeisucaLoginScreen` como widgets dentro do `SetupScreen`, os `Navigator.push()` e `Navigator.pushReplacement()` não limpavam a pilha de navegação subjacente. Isso fazia com que uma tela renderizasse por cima da outra ou que um `Navigator.pop()` revelasse a interface crua anterior.
3. **Chamada Incorreta a Telas Legadas:**  
   Em [`heisuca_login_screen.dart`](file:///home/caioguerras/heisuca/apps/app/lib/heisuca/heisuca_login_screen.dart) e [`heisuca_select_service_screen.dart`](file:///home/caioguerras/heisuca/apps/app/lib/heisuca/heisuca_select_service_screen.dart), o botão de login havia sido inicialmente configurado para dar `Navigator.push(AddJellyfinScreen)`, o que jogava o usuário na tela antiga em vez de realizar a autenticação HTTP de forma nativa e silenciosa dentro da própria tela.

---

## 5. Recomendações Técnicas para o Claude

Ao assumir o projeto para construir o Heisuca Mobile de forma limpa, as seguintes orientações devem ser seguidas:

1. **Criar Ponto de Entrada Limpo:**
   - Criar uma inicialização limpa (ex.: `HeisucaApp`) onde o `initialRoute` seja diretamente o `HeisucaRootRouter`:
     - Se não há conexões autenticadas no banco de dados SQLite (`ConnectionRegistry.list().isEmpty`):
       Exibir `HeisucaOpeningSplash` (2200ms) $\rightarrow$ navegar diretamente com `pushReplacement` para `HeisucaLoginScreen`.
     - Se há conexão salva ativa:
       Exibir `HeisucaOpeningSplash` $\rightarrow$ navegar diretamente para `HeisucaShellScreen` (com a `HeisucaFloatingIsland` e as 4 abas).
2. **Autenticação Direta sem Telas Legadas:**
   - A `HeisucaLoginScreen` (já implementada no commit `e7f7a12`) possui toda a lógica de chamada direta à API do Jellyfin (`JellyfinConnectionAuthService`), salvamento transacional (`persistAndBindConnection`) e bind do perfil ativo (`ActiveProfileBinder`). Ela **não depende** e **não deve chamar** `AddJellyfinScreen` ou `AuthScreen`.
3. **Aproveitar os Componentes Heisuca Já Desenvolvidos:**
   No diretório [`apps/app/lib/heisuca/`](file:///home/caioguerras/heisuca/apps/app/lib/heisuca/), foram criados componentes modernos e autônomos que estão prontos para uso:
   - `heisuca_design_system.dart`: tokens de cor, física `HeisucaSpringPhysics`, botões elásticos com pré-tensão aos 200ms;
   - `heisuca_opening_splash.dart`: animação do selo `炳素華` a 144Hz;
   - `heisuca_login_screen.dart`: tela de login direta com Quick Connect;
   - `heisuca_floating_island.dart`: barra flutuante de navegação em formato de pílula de vidro escuro;
   - `heisuca_title_sheet.dart`: ficha técnica modal de título com 9-stop cubic scrim;
   - `heisuca_context_menu.dart`: menu de toque longo de 500ms;
   - `heisuca_seerr_sheet.dart`: integração com a API do Seerr para pedidos;
   - `heisuca_settings_screen.dart`: tela de configurações com detecção do Edge 60 Pro;
   - `heisuca_player_screen.dart`: player 20:9 com controles táteis e botão `▶▶ Pular Abertura`.
4. **Isolar o Motor de Mídia do Upstream:**
   - Tratar todo o código legado de `lib/screens/` apenas como referência para chamadas de serviço (APIs do Jellyfin, cache, player `libmpv`), evitando instanciar qualquer tela antiga na árvore de navegação do usuário.

---
*Dossiê concluído e arquivado com sucesso no repositório Heisuca para auditoria e continuidade pelo Claude.*
