# Guia Android do Google para o Heisuca — 25/10/2026

Compilado pelo Claude a partir de 6 pesquisas do Gemini (`cgmind pesquisar`, fontes oficiais do Google) e consolidado em
duas partes. **Leia primeiro as correções e verificações abaixo**: elas valem mais que o texto das partes A e B.

## Correções e verificações do Claude (25/10)
- **Live Updates (Android 16) NÃO servem para o player nem para downloads.** Verificado em
  https://developer.android.com/develop/ui/views/notifications/live-update : os usos permitidos são navegação, chamadas,
  corrida/entrega, treino, evento esportivo pedido pelo usuário e evento iminente; a página não inclui mídia nem
  download, e proíbe promover o que não precisa de acompanhamento contínuo. Para mídia, o caminho oficial são os
  **controles de mídia do sistema** (MediaSession + notificação de mídia: painel, tela de bloqueio, fones). Requisitos de
  promoção, para referência: `POST_PROMOTED_NOTIFICATIONS`, `setRequestPromotedOngoing(true)`, `setOngoing(true)`, sem
  `RemoteViews`, sem `setColorized`, chip de até 96 dp com `setShortCriticalText`.
- **Voltar preditivo no Flutter:** o Flutter 3.47 (o nosso) já usa `PredictiveBackPageTransitionsBuilder` como padrão no
  Android (`page_transitions_theme.dart`); ele segue o gesto e cai no `FadeForwardsPageTransitionsBuilder` (estilo Android
  16) quando o sistema não tem o gesto (verificado em api.flutter.dev). O app tem uma versão feita à mão
  (`_CgflixPredictiveBack` em `lib/cgflix/cgflix_theme.dart`) e telas Heisuca com rotas próprias que ignoram o tema:
  **usar a transição oficial**, só com cores do Heisuca; nada de rota própria para telas empurradas.
- **Curvas e durações M3** (conferidas no código do Flutter, `material/motion.dart` e `Durations`):
  Emphasized = `Curves.easeInOutCubicEmphasized` (curva de três pontos, não um cubic só);
  Emphasized Decelerate = `Easing.emphasizedDecelerate` `Cubic(0.05, 0.7, 0.1, 1.0)`;
  Emphasized Accelerate = `Easing.emphasizedAccelerate` `Cubic(0.3, 0.0, 0.8, 0.15)`;
  Standard = `Easing.standard` `Cubic(0.2, 0.0, 0.0, 1.0)`; durações em `Durations` (short1 50 ms … long4 600 ms,
  extralong1–4 700–1000 ms). Usar as constantes do Flutter, nunca números soltos.
- **Motor de vídeo:** o Heisuca toca com **mpv** (e ExoPlayer como alternativa). Itens das partes abaixo que falam de
  `handleAudioFocus`, `DownloadService`/`SimpleCache` do Media3 valem só para o ExoPlayer; para o mpv, o equivalente já
  existe em Kotlin (`AudioFocusManager.kt`, plugin `os_media_controls` com `MediaSessionCompat`, downloads pelo
  `background_downloader`). Não trocar de arquitetura sem decisão do Caio.
- **Container transform × Hero:** o M3 recomenda container transform para abrir o detalhe a partir do cartão. O Heisuca
  usa a capa que "voa" (Hero) para a ficha: mesmo princípio (continuidade da arte tocada). Manter, com as curvas M3.
- Fontes não oficiais citadas pelo Gemini (Stack Overflow, Medium, dev.to, blogs) e links que ele não abriu estão
  marcados como `[verificar]`. Na dúvida, abrir a página oficial antes de virar regra.

## Como usar este guia
- Base da **varredura do app** (fazer depois da rodada atual): cada item dos checklists vira "ok / falha / não se aplica",
  com o arquivo e a correção. Junto com a auditoria antiga `apps/app/docs/cgflix/AUDITORIA_GOOGLE_1D.md`.
- Sempre adaptado aos `docs/PILARES_HEISUCA.md`: o comportamento é o do Google; a aparência é a do Heisuca.

---
# Parte A — princípios, navegação, edge-to-edge, movimento, componentes
---

Este guia consolida as diretrizes oficiais do Google extraídas dos relatórios técnicos (`01_qualidade.md`, `02_material3_movimento.md` e `03_navegacao_voltar.md`), com foco no aplicativo de streaming de vídeo Heisuca (desenvolvido em Flutter para celular, dispositivos dobráveis/telas grandes e Android TV), com arquitetura de reprodução direta sem transcodificação e identidade visual minimalista e refinada.

---

### 1. Princípios: Qualidade de Aplicativo, Telas Grandes e Google Play

A fundação do aplicativo baseia-se em três pilares oficiais: estabilidade operacional (*Core App Quality*), adaptabilidade de tela (*Adaptive App Quality*) e conformidade com a experiência de sala de estar (*Android TV Quality*).

*   **Fundação de Qualidade Central (*Core App Quality*):** O aplicativo deve garantir estabilidade, segurança e eficiência de recursos. Isso exige preservação confiável do estado da interface em transições de ciclo de vida, consumo controlado de memória e bateria (liberação de *wakelocks* fora da reprodução ativa), suporte à navegação padrão do sistema operacional e adoção estrita do princípio do privilégio mínimo para permissões (`01_qualidade.md#1`, `01_qualidade.md#2D`).
*   **Telas Grandes e Dobráveis (*Adaptive App Quality*):** A interface deve responder às classes de tamanho de janela (*WindowSizeClass*), categorizadas oficialmente em:
    *   *Compact*: largura inferior a 600 dp (celulares em orientação retrato);
    *   *Medium*: largura entre 600 dp e 839 dp (tablets pequenos e dobráveis em modo retrato);
    *   *Expanded*: largura de 840 dp a 1199 dp (tablets em paisagem e desktops) (`01_qualidade.md#3`).
    O aplicativo não deve bloquear a orientação em modo retrato em telas grandes nem esticar listas verticalmente. A continuidade do estado da reprodução e da interface deve ocorrer sem reinicialização durante o desdobramento da tela ou entrada em modo multijanela (`01_qualidade.md#2A`).
*   **Qualidade para Android TV (Experiência de 10 Pés):** O consumo de mídia em telas de televisão (distância média de 3 metros) é estritamente governado por controles remotos direcionais (D-Pad). A aplicação deve:
    *   Declarar que não requer tela sensível ao toque no manifesto nativo;
    *   Fornecer um *Launcher Banner* de 320 × 180 pixels (`drawable-xhdpi`) para a categoria `CATEGORY_LEANBACK_LAUNCHER`;
    *   Respeitar a margem de segurança de *Overscan* de 5% (48 dp nas laterais e 27 dp no topo e rodapé) para evitar corte de elementos em televisores;
    *   Garantir navegação 100% acionável via D-Pad, com indicador de foco visual de alto contraste e sem pontos cegos (`01_qualidade.md#2C`, `01_qualidade.md#3`).
*   **Métricas Operacionais e Limiares do Android Vitals (Play Store):** A distribuição orgânica e a aprovação na Play Store dependem da manutenção dos indicadores de integridade abaixo dos limiares críticos (*bad behavior thresholds*):
    *   *Crash Rate* perceptível: máximo de 1,09% dos usuários diários globais e teto de 8,0% por modelo de dispositivo;
    *   *ANR Rate* perceptível: máximo de 0,47% dos usuários diários e teto de 8,0% por modelo de dispositivo;
    *   *Renderização de Quadros:* orçamento máximo de 16 ms por quadro (meta de 60 fps) e contenção de quadros congelados (*frozen frames*, duração > 700 ms);
    *   *Tempo de Inicialização:* inicialização a frio (*cold start*) abaixo de 5 segundos; morna (*warm start*) abaixo de 2 segundos; quente (*hot start*) abaixo de 1,5 segundo;
    *   *Target SDK:* alinhamento à API mais recente da janela de conformidade anual do Google (`01_qualidade.md#3`).
*   **Lacunas e Limitações das Fontes:**
    *   Prazos de conformidade de Target SDK posteriores ao ciclo do Android 16 (API 36) `[verificar]`.
    *   A fórmula algorítmica exata de ranqueamento da Play Store além das regras divulgadas para telas grandes `[verificar]`.

---

### 2. Arquitetura de Navegação e Retorno Preditivo

A arquitetura de rotas deve seguir o modelo de navegação estruturada da plataforma Android (`03_navegacao_voltar.md#1`):

*   **Destino Inicial Fixo (*Fixed Starting Destination*):** O catálogo principal atua como a base imutável da pilha de retorno (*back stack* LIFO). Toda navegação de retorno em profundidade deve convergir para esse destino inicial antes que o comando de saída do aplicativo seja disparado.
*   **Separação entre "Up" e "Back":** O botão de navegação ascendente (*Up*, na barra superior de detalhes de mídia) desce na hierarquia estrutural interna sem nunca encerrar a aplicação. O botão/gesto *Back* percorre a cronologia reversa de telas.
*   **Deep Links com Reconstituição de Pilha:** Links diretos para vídeos ou itens do catálogo devem sintetizar a pilha de navegação intermediária, impedindo que o retorno feche o app no primeiro recuo.
*   **Voltar Preditivo Antecipado (*Ahead-of-Time Predictive Back*):** A partir do Android 13 e consolidado no Android 14/15/16, o sistema operacional renderiza transições preditivas em tempo real (como o gesto de retorno gradual à tela inicial ou tela anterior).
    *   *Manifesto Nativo:* É obrigatório declarar `android:enableOnBackInvokedCallback="true"` na tag `<application>` do `AndroidManifest.xml` (`03_navegacao_voltar.md#2A`).
    *   *Tratamento no Flutter:* A aplicação deve abandonar o obsoleto `WillPopScope` e migrar para o widget `PopScope`. A propriedade `canPop` deve retornar um valor booleano síncrono. O uso de `canPop: false` deve ser temporário, ativado exclusivamente quando houver estado efêmero dentro da rota que precise ser desfeito primeiro (ex.: menu de áudio/legenda aberto, player em tela cheia voltando ao modo janela ou modal sobreposto), manipulado via `onPopInvokedWithResult` (`03_navegacao_voltar.md#2A`, `03_navegacao_voltar.md#4`).
    *   *Proibições Estruturais:* Não interceptar eventos físicos `KeyEvent.KEYCODE_BACK` ou sobrescrever `Activity.onBackPressed()` de maneira síncrona no código nativo, pois isso impede que o motor gráfico do sistema realize a prévia fluida da tela anterior.
    *   *Desempilhamento Hierárquico no Player:* O retorno deve seguir uma ordem estrita para evitar o fechamento inadvertido do catálogo: (1) fechar painéis de seleção de faixas; (2) ocultar controles de transporte se visíveis; (3) desativar tela cheia e voltar ao modo padrão; (4) finalizar a rota de reprodução retornando à tela de detalhes do catálogo (`03_navegacao_voltar.md#4`).
*   **Particularidades de Plataforma (Celular vs. TV):**
    *   No celular, o gesto de voltar é contínuo, mapeado de `0.0` a `1.0` a partir de ambas as bordas (esquerda e direita) da tela (`03_navegacao_voltar.md#2C`, `03_navegacao_voltar.md#3`).
    *   Na Android TV, o retorno opera de forma discreta através do botão físico "Back" do controle remoto, desfazendo hierarquias sem animação contínua de arrasto (`03_navegacao_voltar.md#2E`).
*   **Lacunas e Limitações das Fontes:**
    *   Suporte da documentação oficial de Android TV a animações preditivas com progresso contínuo de arrasto (0.0 a 1.0) acionadas por hardware de controle remoto D-Pad `[verificar]`.

---

### 3. Layout Borda a Borda (*Edge-to-Edge*), Barras e Insets

O Android 15 (API 35+) impõe o desenho de ponta a ponta por padrão e remove mecanismos de recusa no Android 16 (`03_navegacao_voltar.md#2B`, `01_qualidade.md#2A`):

*   **Configuração de Sistema:** A aplicação Flutter deve inicializar com `SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge)`, configurando a barra de status e a barra de navegação gestual com transparência total.
*   **Consumo Dinâmico de Insets:** Elementos visuais decorativos (como o próprio feed de vídeo e planos de fundo de catálogo) devem estender-se sob as barras e recortes de câmera (*cutouts*). Em contrapartida, todos os elementos clicáveis, cabeçalhos, títulos e barras de navegação devem respeitar os insets via `SafeArea` ou dinamicamente via `MediaQuery.paddingOf(context)`. É proibido usar compensações estáticas (como paddings arbitrários de 24 dp), devido à variação de geometria entre fabricantes (`03_navegacao_voltar.md#2B`).
*   **Player em Tela Cheia e Modo Imersivo:**
    *   A reprodução em tela cheia deve acionar `SystemUiMode.immersiveSticky` (`BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE`).
    *   A ativação de controles de reprodução deve sincronizar a revelação dos controles do Heisuca com a exibição translúcida temporária das barras de sistema via alternância por toque (*tap-to-toggle*), sem deslocar a proporção do vídeo (`03_navegacao_voltar.md#2B`).
*   **Conflitos entre Gestos do Player e Gestos do Sistema:**
    *   *Bordas Laterais:* A navegação do Android reconhece o retorno deslizando tanto na borda esquerda quanto na direita. Controles deslizantes contínuos de volume ou brilho colados nas extremidades da tela colidem com o voltar do SO (`03_navegacao_voltar.md#2C`).
    *   *Borda Inferior:* O rodapé da tela abriga a zona de gestos obrigatórios (`mandatorySystemGestures`), dedicada ao retorno à tela inicial e alternância de tarefas, que o sistema operacional nunca cede à aplicação. A barra de rolagem de tempo (*scrubber*) do Heisuca deve ser recuada acima dessa faixa de proteção (`03_navegacao_voltar.md#2C`, `03_navegacao_voltar.md#4`).
    *   *Exclusão de Gestos:* Quando o usuário manipular ativamente o ponto de arraste da timeline, o app pode acionar temporariamente `setSystemGestureExclusionRects()`. Essa exclusão é restrita à caixa delimitadora daquele controle e limitada pelo teto máximo imposto pelo Android de 200 dp verticais acumulados por borda, devendo ser desfeita ao soltar o toque (`03_navegacao_voltar.md#2C`, `03_navegacao_voltar.md#3`).

---

### 4. Sistema de Movimento: Transições por Cenário, Durações e Curvas M3

O movimento no Material 3 e Material 3 Expressive expressa continuidade física, direciona a atenção e confere elegância espacial sem ornamentação excessiva (`02_material3_movimento.md#1`).

#### A. Tokens Oficiais de Movimento do M3
(`02_material3_movimento.md#3A`, `03_navegacao_voltar.md#3`)

*   **Tabela de Durações:**
    *   `short1` (50 ms), `short2` (100 ms), `short3` (150 ms), `short4` (200 ms): microinterações, seletores e descarte rápido;
    *   `medium1` (250 ms), `medium2` (300 ms), `medium3` (350 ms), `medium4` (400 ms): transições utilitárias, abas e entradas de superfície;
    *   `long1` (450 ms), `long2` (500 ms), `long3` (550 ms), `long4` (600 ms): expansões de contêiner de tela cheia.
*   **Curvas Cúbicas de Bézier (Easing):**
    *   *Emphasized:* **[corrigido pelo Claude]** `Curves.easeInOutCubicEmphasized` (curva de três pontos) — transições expressivas completas no interior da janela (duração recomendada: 500 ms);
    *   *Emphasized Decelerate:* `Cubic(0.05, 0.7, 0.1, 1.0)` — entrada e expansão de novos elementos na tela (duração recomendada: 400 ms);
    *   *Emphasized Accelerate:* `Cubic(0.3, 0.0, 0.8, 0.15)` — saída e recolhimento de elementos (duração recomendada: 200 ms);
    *   *Standard:* `Cubic(0.2, 0.0, 0.0, 1.0)` — transições utilitárias neutras (duração recomendada: 300 ms).

#### B. Padrões de Transição por Cenário

1.  **Abrir Detalhe de um Cartão de Vídeo:**
    *   *Padrão:* **Container Transform** (implementado no Flutter com o widget `OpenContainer` do pacote `animations`).
    *   *Comportamento:* Transforma o contêiner do card da grade de catálogo diretamente na tela de detalhes, expandindo suas bordas de forma fluida com a curva `Emphasized` em 500 ms (`long2`).
    *   *Regra:* Não utilizar transições de deslizamento lateral simples (*slide/push*), que quebram a ancoragem da capa do vídeo (`02_material3_movimento.md#2A`, `02_material3_movimento.md#Exemplo`).
2.  **Troca de Abas do Catálogo e Destinos Principais:**
    *   *Padrão 1 (Destinos Principais da Barra Inferior):* **Fade Through**. O destino atual esmaece até 0% de opacidade antes que o novo destino entre com leve escalonamento, evitando sobreposição confusa de layouts em 300 ms (`medium2`) (`02_material3_movimento.md#2A`).
    *   *Padrão 2 (Abas de Conteúdo no Mesmo Nível):* **Shared Axis (Eixo X)**. Ao alternar abas irmãs na tela de um título (ex.: "Episódios", "Trailers", "Semelhantes"), o deslocamento lateral simultâneo em 300 ms reforça a contiguidade física (`02_material3_movimento.md#2A`).
3.  **Painéis Deslizantes (*Modal Bottom Sheets*):**
    *   *Padrão:* Transição vertical utilizando `Emphasized Decelerate` (400 ms, `medium4`) para subida e `Emphasized Accelerate` (200 ms, `short4`) para recolhimento. Destinado a menus secundários contextuais (seletores de faixa de áudio, legendas e opções de temporada) (`02_material3_movimento.md#2C`, `02_material3_movimento.md#3A`).
4.  **Diálogos Críticos:**
    *   *Padrão:* Entrada centralizada com curva `Emphasized Decelerate` em 400 ms, com cantos arredondados padronizados em 28 dp (`extraLarge`) ou 32 dp no M3 Expressive. Reservados estritamente para confirmações bloqueantes (como cancelamentos ou exclusões de armazenamento local) (`02_material3_movimento.md#2C`, `02_material3_movimento.md#3C`).
5.  **Microinterações de Transporte do Player:**
    *   *Padrão:* Animações ultrarrápidas de 100 ms a 150 ms (`short2` a `short3`) para alternância entre play/pause e botões de avanço. Durações longas (> 250 ms) no player transmitem lentidão de resposta e devem ser evitadas (`02_material3_movimento.md#2A`, `03_navegacao_voltar.md#3`).
*   **Lacunas e Limitações das Fontes:**
    *   Tokens numéricos oficiais de amortecimento (*damping ratio*) e rigidez (*stiffness*) das molas (*spring physics*) do M3 Expressive no ecossistema Flutter `[verificar]`.
    *   Tokens de curvas e tempos dedicados exclusivamente a decodificadores/componentes específicos de vídeo player no M3 `[verificar]`.

---

### 5. Componentes Material 3 e Adaptação Minimalista (Heisuca)

A identidade visual do Heisuca (minimalismo refinado, estética nipo-escandinava / nível Apple) exige depuração formal sem violar os padrões funcionais do ecossistema Android:

*   **Elevação Tonal contra Sombras Físicas:** Em interfaces escuras para vídeo, sombras pretas projetadas perdem função. O Heisuca deve adotar o sistema de contêineres de superfície do M3 (`surfaceContainer` tokens), estabelecendo hierarquia pela luminosidade da superfície sobreposta (fundo geral em `surfaceContainerLowest`, cards e trilhas em `surfaceContainerLow` ou `surfaceContainer`), operando com elevação física zero (`elevation: 0`) no `OpenContainer` para preservar uma estética plana e pura (`02_material3_movimento.md#1`, `02_material3_movimento.md#2B`, `02_material3_movimento.md#separacao-entre-fatos`).
*   **Contenção da Cor Dinâmica (*Dynamic Color*):** A paleta dinâmica do sistema não pode sobrepor ou distorcer a direção de arte das capas cinematográficas e da reprodução de vídeo. No Heisuca, a cor dinâmica deve ser neutralizada ou restrita a acentos utilitários e estados ativos, garantindo molduras escuras e fundos estritamente neutros (`02_material3_movimento.md#2B`).
*   **Barra de Navegação Estrutural:**
    *   *Mobile:* Utilização de `NavigationBar` contendo de 3 a 5 destinos principais, com altura de 80 dp e alvos de toque mínimos de 48 × 48 dp (espaçamento de 8 dp entre alvos). O estado das pilhas internas de cada aba deve ser preservado ao navegar entre elas (`02_material3_movimento.md#2C`, `03_navegacao_voltar.md#2D`, `03_navegacao_voltar.md#3`).
    *   *Telas Grandes e Android TV:* Transição arquitetural para `NavigationRail` lateral contendo de 3 a 7 destinos, mantendo as áreas verticais desobstruídas para a grade de pôsteres (`02_material3_movimento.md#2C`).
*   **Contraste de Acessibilidade e Proteção de Arte (*Scrims*):**
    *   Manter a proporção mínima de contraste de 4,5:1 para textos informativos normais (< 18 sp ou < 14 sp negrito) e 3,0:1 para textos destacados (≥ 18 sp) e ícones funcionais (`01_qualidade.md#3`, `02_material3_movimento.md#3B`).
    *   Textos, títulos e metadados sobrepostos diretamente a pôsteres ou ao vídeo exigem uma camada de gradiente de proteção escurecedora (*scrim*), prevenindo perda de legibilidade em artes claras (`02_material3_movimento.md#4`).
*   **Foco Direcional Elegante para Android TV:** O minimalismo não autoriza a remoção do retorno de foco. Na TV, perder a indicação visual isola o usuário. A abordagem elegante consiste em utilizar uma animação contínua e suave de ampliação de escala (1,05× a 1,08× via `AnimatedScale`), combinada com iluminação sutil de borda de alto contraste ou elevação tonal do contêiner ativo, sem decorações excessivas (`01_qualidade.md#4`, `02_material3_movimento.md#4`).
*   **Sessão de Mídia, Foco de Áudio e Janela PiP:**
    *   O reprodutor deve vincular-se integralmente à `MediaSession` nativa para expor metadados e controles de transporte na tela de bloqueio, no painel do sistema e fones Bluetooth (`01_qualidade.md#2B`).
    *   O gerenciamento de `AudioFocus` deve chamar `requestAudioFocus()` antes de reproduzir áudio e acatar as regras restritivas do Android 15 (requerendo app em primeiro plano ou serviço associado) para evitar sobreposição com chamadas ou outros apps (`01_qualidade.md#2B`).
    *   A atividade principal deve declarar `android:supportsPictureInPicture="true"` e tratar mudanças de configuração nativas (`android:configChanges="orientation|screenSize|smallestScreenSize|screenLayout"`), impedindo a recriação da `Activity` e cortes no streaming ao entrar em Picture-in-Picture (`01_qualidade.md#2B`, `01_qualidade.md#4`).
    *   A flag de manter tela ligada (*keep screen on*) deve ser suspensa imediatamente quando o vídeo for pausado ou finalizado, evitando consumo indevido de bateria (`01_qualidade.md#2B`).

---

### 6. Checklist Prático Integrado: "Deve / Não Deve"

1.  **DEVE implementar layout Borda a Borda (*Edge-to-Edge*) consumindo insets dinâmicos:** A janela deve preencher toda a tela, e elementos acionáveis devem ser compensados via `SafeArea` ou `MediaQuery.paddingOf(context)` contra sobreposições de barras e recortes de tela.  
    *Fonte:* [developer.android.com - Edge-to-Edge](https://developer.android.com/about/versions/15/behavior-changes-15#edge-to-edge)
2.  **NÃO DEVE aplicar espaçamentos ou paddings estáticos fixos para barras de sistema:** Tamanhos de barra variam entre aparelhos; usar valores fixos causa sobreposição ou quebra de alinhamento visual.  
    *Fonte:* [developer.android.com - WindowInsets InsetsAnimation](https://developer.android.com/reference/android/view/WindowInsetsAnimation)
3.  **DEVE habilitar `android:enableOnBackInvokedCallback="true"` e migrar para `PopScope` no Flutter:** Prepara o Heisuca para animações antecipadas do retorno do sistema e substitui o modelo assíncrono do obsoleto `WillPopScope`.  
    *Fonte:* [developer.android.com - Predictive Back Gesture](https://developer.android.com/guide/navigation/custom-back/predictive-back-gesture)
4.  **NÃO DEVE interceptar `KeyEvent.KEYCODE_BACK` ou sobrescrever `onBackPressed()` manualmente:** Essas APIs legadas violam a arquitetura *ahead-of-time* e bloqueiam transições fluidas no Android 14+.  
    *Fonte:* [developer.android.com - Custom Back Navigation](https://developer.android.com/guide/navigation/custom-back)
5.  **DEVE afastar controles do player das faixas de gestos do sistema:** A barra de progresso não deve encostar na base (`mandatorySystemGestures`), e seletores verticais não devem invadir as bordas laterais direita ou esquerda.  
    *Fonte:* [developer.android.com - Gestural Navigation](https://developer.android.com/design/ui/mobile/guides/foundations/gestural-navigation)
6.  **NÃO DEVE exceder o limite de 200 dp verticais em `setSystemGestureExclusionRects()`:** Ultrapassar a cota cumulativa de exclusão de gestos faz com que o sistema ignore a instrução do aplicativo e restaure o voltar do SO.  
    *Fonte:* [developer.android.com - System Gesture Exclusion](https://developer.android.com/reference/android/view/View#setSystemGestureExclusionRects(java.util.List%3Candroid.graphics.Rect%3E))
7.  **DEVE usar *Container Transform* na abertura de itens do catálogo:** Ancora visualmente o card de capa à tela cheia de detalhes através do widget `OpenContainer` (duração de 500 ms com curva `Emphasized`).  
    *Fonte:* [m3.material.io - Motion Patterns](https://m3.material.io/styles/motion/transitions/transition-patterns)
8.  **NÃO DEVE usar transições laterais de slide comum para abrir detalhes a partir de cards:** Deslocamentos laterais genéricos destroem a relação espacial entre a arte tocada e a tela seguinte.  
    *Fonte:* [m3.material.io - Container Transform](https://m3.material.io/styles/motion/transitions/transition-patterns#container-transform)
9.  **DEVE usar *Fade Through* para alternar destinos na barra inferior e *Shared Axis (X)* para abas irmãs:** Garante desacoplamento visual suave entre seções independentes e alinhamento dimensional em abas de conteúdo sequencial em 300 ms.  
    *Fonte:* [m3.material.io - Fade Through](https://m3.material.io/styles/motion/transitions/transition-patterns#fade-through)
10. **NÃO DEVE aplicar durações acima de 250 ms para microinterações do player:** Animações lentas em comandos de play/pause ou scrubbers comprometem a agilidade operacional do streaming.  
    *Fonte:* [m3.material.io - Motion Duration & Easing](https://m3.material.io/styles/motion/easing-and-duration/tokens)
11. **DEVE garantir alvos mínimos de toque de 48 × 48 dp e espaçamento de 8 dp:** Dimensão física essencial para botões de controle de vídeo e ícones de navegação rápida.  
    *Fonte:* [developer.android.com - Touch Target Size](https://developer.android.com/guide/topics/ui/accessibility/apps#touch-targets)
12. **DEVE resguardar contrastes mínimos de 4,5:1 (texto regular) e 3,0:1 (texto grande e ícones):** Exige inclusão de gradientes de proteção (*scrims*) sob textos sobrepostos a pôsteres ou ao vídeo.  
    *Fonte:* [developer.android.com - Color Contrast](https://developer.android.com/guide/topics/ui/accessibility/apps#text-contrast)
13. **NÃO DEVE utilizar sombras físicas pronunciadas para separar cartões em temas escuros:** Use os tons semânticos de superfície `surfaceContainer` do Material 3, reservando elevação zero para um visual minimalista.  
    *Fonte:* [m3.material.io - Elevation & Surface](https://m3.material.io/styles/color/the-color-system/color-roles)
14. **NÃO DEVE deixar a paleta de cores dinâmicas dominar os componentes de vídeo e arte:** A extração tonal do papel de parede deve ser neutralizada nas molduras de mídia e pôsteres para preservar a estética cinematográfica.  
    *Fonte:* [m3.material.io - Dynamic Color Guidelines](https://m3.material.io/styles/color/dynamic-color/user-expression)
15. **DEVE limitar a `NavigationBar` de 3 a 5 itens e usar `NavigationRail` em telas expandidas/TV:** Impede a perda de ergonomia do polegar no mobile e distribui os itens lateralmente em telas largas.  
    *Fonte:* [m3.material.io - Navigation Bar](https://m3.material.io/components/navigation-bar/guidelines)
16. **DEVE integrar com a `MediaSession` e implementar controle de `AudioFocus`:** Exige registro de sessão de transporte para PiP e fones Bluetooth, bem como cessação de áudio em chamadas recebidas.  
    *Fonte:* [developer.android.com - MediaSession](https://developer.android.com/media/optimize/media-session) e [developer.android.com - Audio Focus](https://developer.android.com/media/optimize/audio-focus)
17. **DEVE suportar Picture-in-Picture (PiP) declarando `android:configChanges`:** Evita o reinício da `Activity` e pausas no fluxo de mídia ao transicionar o vídeo para janela flutuante.  
    *Fonte:* [developer.android.com - Picture-in-Picture](https://developer.android.com/develop/ui/views/picture-in-picture)
18. **NÃO DEVE reter `keepScreenOn` com o vídeo pausado:** Travar a tela ligada sem consumo de mídia ativo drena a bateria do dispositivo e penaliza os índices vitais do app.  
    *Fonte:* [developer.android.com - Core App Quality](https://developer.android.com/docs/quality-guidelines/core-app-quality)
19. **DEVE declarar `<uses-feature android:name="android.hardware.touchscreen" android:required="false" />` no manifesto para Android TV:** Sem essa declaração explícita, a Play Store presume a exigência de tela sensível ao toque e bloqueia a publicação para TVs.  
    *Fonte:* [developer.android.com - TV Manifest](https://developer.android.com/training/tv/start/start)
20. **DEVE fornecer Launcher Banner de 320 × 180 pixels (`drawable-xhdpi`) para TV:** Necessário para correta exibição do ícone inicial na interface Leanback do Android TV / Google TV.  
    *Fonte:* [developer.android.com - TV Apps Requirements](https://developer.android.com/training/tv/start/start#banner)
21. **DEVE respeitar a margem de 5% de *Overscan* na TV (48 dp horizontal, 27 dp vertical):** Garante que controles de navegação e títulos não sofram corte nas bordas físicas de televisores analógicos ou monitores com processamento de imagem.  
    *Fonte:* [developer.android.com - TV Design Principles](https://developer.android.com/design/ui/tv)
22. **DEVE garantir foco visual inequívoco em todos os componentes navegáveis por D-Pad na TV:** A identidade minimalista deve recorrer a ampliações suaves de escala (1,05× a 1,08×) e iluminação de contorno sutil, impedindo que o usuário perca o cursor visual na tela.  
    *Fonte:* [developer.android.com - TV Navigation](https://developer.android.com/training/tv/start/navigation)
23. **NÃO DEVE bloquear a UI thread do Flutter com processamento de catálogo:** Desserialização de payloads JSON volumosos ou leitura pesada de disco devem ser executadas em isolates (`compute()`) para manter quadros abaixo de 16 ms e evitar quadros congelados (> 700 ms).  
    *Fonte:* [developer.android.com - Android Vitals Jank](https://developer.android.com/topic/performance/vitals/render)
24. **DEVE manter as taxas de falha (Crash < 1,09%) e congelamento (ANR < 0,47%) abaixo dos limiares de mau comportamento do Android Vitals:** A integridade contra exceções não tratadas em Dart e bibliotecas nativas protege o aplicativo de perda de visibilidade e advertências na Play Store.  
    *Fonte:* [developer.android.com - Bad Behavior Thresholds](https://developer.android.com/topic/performance/vitals/core)

---
# Parte B — desempenho, acessibilidade, mídia, TV, Flutter
---
**Projeto:** CGMIND / Heisuca  
**Contexto Operacional:** Player e catálogo de streaming de alta fidelidade desenvolvido em Flutter (mobile Android e futura expansão para Android TV), fork independente do Plezy, operando sobre servidor sem transcodificação. Identidade visual própria, minimalista e elegante (estética japonesa, nível Apple).  
**Base Documental:** Consolidação dos relatórios técnicos de pesquisa oficial do Google (`04_desempenho_acessibilidade.md`, `05_midia_tv.md` e `06_flutter.md`).

---

## 6. Desempenho

### Abertura e Splash Screen API
* **Métricas Oficiais (Android Vitals):** O Google Play Console audita ativamente a inicialização em três limiares críticos: inicialização a frio (*Cold start*) excessiva em 5 segundos ou mais; inicialização morna (*Warm start*) em 2 segundos ou mais; e inicialização quente (*Hot start*) em 1,5 segundo ou mais (`04_desempenho_acessibilidade.md`, Seção 3).
* **Splash Screen Oficial:** Deve-se utilizar a biblioteca `androidx.core:core-splashscreen` integrando o callback `setKeepOnScreenCondition`, mantendo a tela do sistema visível estritamente enquanto a árvore do Flutter desenha o primeiro frame útil (`04_desempenho_acessibilidade.md`, Seção 2.A).
* **Baseline Profiles & Startup Profiles:** A adoção de Baseline Profiles pré-compila as rotinas críticas de execução para compilação AOT nativa (eliminando compilação JIT inicial), reduzindo o tempo de inicialização a frio em até 30% e prevenindo falhas de página (*page faults*) no layout dos arquivos DEX (`04_desempenho_acessibilidade.md`, Seções 2.A e 3).
* **Anti-pattern:** É expressamente vetada a inserção de temporizadores artificiais (ex.: `delay(3000)`) para expor logotipos ou identidades visuais (`04_desempenho_acessibilidade.md`, Seção 2.A).

### Jank e Taxas de Atualização (60, 90 e 120 Hz)
* **Orçamentos de Renderização por Quadro:**
  * 60 Hz: orçamentos de quadro superiores a 16 ms (ou ~16,6 ms) são classificados como quadros lentos (*slow frames*).
  * 90 Hz: orçamento de aproximadamente 11 ms.
  * 120 Hz: orçamento de aproximadamente 8 ms (ou ~8,3 ms).
  * Quadros congelados (*frozen frames*): quadros com tempo de renderização superior a 700 ms (`04_desempenho_acessibilidade.md`, Seção 3; `06_flutter.md`, Seção 3).
* **Isolamento de Pintura (`RepaintBoundary`):** Elementos visuais com mutação contínua de alta frequência — especificamente o controle deslizante de progresso (*seek slider*) e o contador de milissegundos do player de vídeo — devem ser isolados em um `RepaintBoundary`. Isso impede que o avanço a cada segundo repinte os metadados do vídeo e o fundo do catálogo (`04_desempenho_acessibilidade.md`, Seções 2.B e 5).
* **Parcimônia de Camadas:** Não aplicar `RepaintBoundary` em componentes estáticos, evitando a alocação supérflua de texturas na GPU e elevação do consumo de RAM (`04_desempenho_acessibilidade.md`, Seção 2.B).

### Imagens e Memória
* **Downsampling na Decodificação:** Imagens de pôsteres e miniaturas de streaming devem ter suas dimensões de decodificação limitadas através de `cacheWidth` e `cacheHeight` ou envelopamento com `ResizeImage`. Evita-se alocar dezenas de megabytes para bitmaps em tamanho real de câmeras/servidor quando o elemento de tela possui dimensões físicas reduzidas (`04_desempenho_acessibilidade.md`, Seção 2.C).
* **Controle Global do `ImageCache`:** O motor do Flutter mantém por padrão tetos de 1.000 imagens e 100 MB (`PaintingBinding.instance.imageCache`), demandando controle consciente para evitar coletas de lixo (*garbage collection*) volumosas que causem engasgos na rolagem (`04_desempenho_acessibilidade.md`, Seções 2.C e 3).
* **Virtualização de Layout:** Construção de catálogos via `ListView.builder` e `GridView.builder` para destruição automática de elementos fora da área de exibição (`04_desempenho_acessibilidade.md`, Seção 2.C).

### Rede, Bateria e Offline
* **Tarefas em Segundo Plano:** Sincronizações de metadados e histórico diferido devem usar `WorkManager`, declarando restrições de conectividade não medida e bateria suficiente, em respeito ao modo Doze (`04_desempenho_acessibilidade.md`, Seção 2.D).
* **Cessação de Conexões:** Não manter conexões HTTP abertas nem sockets desnecessários em estados pausados ou minimizados (`04_desempenho_acessibilidade.md`, Seção 2.D).
* **Arquitetura de Cache Offline:** Integração estruturada via `SimpleCache` e `CacheDataSource` do Jetpack Media3, permitindo leitura contínua e sem re-solicitação de blocos de mídia (`04_desempenho_acessibilidade.md`, Seção 2.D; `05_midia_tv.md`, Seção 2.E). Como o servidor não transcodifica, os fluxos armazenados devem ser gerenciados em seu contêiner nativo.

---

## 7. Acessibilidade

### Alvos de Toque e Espaçamento
* **Dimensões Físicas Mínimas:** No Material 3, todo elemento interativo deve garantir área física de toque de pelo menos 48 × 48 dp (equivalente físico a ~9 × 9 mm), mesmo que o ícone ou traço visual seja minimalista (ex.: 18 a 24 dp) (`04_desempenho_acessibilidade.md`, Seção 3; `05_midia_tv.md`, Seção 3; `06_flutter.md`, Seção 3).
* **Dispositivos Apontadores:** Alvo mínimo de 44 × 44 dp para controles operados por mouse ou caneta stylus (`04_desempenho_acessibilidade.md`, Seção 3; `05_midia_tv.md`, Seção 3).
* **Separação:** Espaçamento mínimo recomendado de 8 dp entre alvos adjacentes para impedir toques acidentais (`04_desempenho_acessibilidade.md`, Seção 2.E).

### Contraste de Cor
* **Texto Convencional:** Contraste mínimo de 4,5:1 para texto normal (menor que 18sp regular ou menor que 14sp negrito) (`04_desempenho_acessibilidade.md`, Seção 3; `05_midia_tv.md`, Seção 3; `06_flutter.md`, Seção 3).
* **Texto Grande e Componentes Gráficos:** Mínimo de 3:1 para texto grande (≥ 18sp regular ou ≥ 14sp negrito), ícones essenciais, bordas de recipientes e indicadores de foco (`04_desempenho_acessibilidade.md`, Seção 3; `05_midia_tv.md`, Seção 3).
* **Alto Contraste:** Relação estendida de 7:1 para modos de acessibilidade avançada (`06_flutter.md`, Seção 3).

### Fonte do Sistema e Redução de Movimento
* **Escala Não Linear (Android 14+):** Suporte a ampliações dinâmicas de texto de até 200%. Proíbe-se fixar dimensões estruturais de cartões em `sp` ou aplicar alturas rígidas sem flexibilidade de quebra de linha ou rolagem (`04_desempenho_acessibilidade.md`, Seções 2.E e 3; `06_flutter.md`, Seção 2.7).
* **Sensibilidade Vestibular:** Obrigatoriedade de consulta ao sinal do sistema de redução de animações (`disableAnimations`), desativando transições contínuas e avançando diretamente ao estado final (`04_desempenho_acessibilidade.md`, Seção 2.E; `06_flutter.md`, Seção 2.7).

### TalkBack e Navegação por Foco
* **Rotulagem Semântica:** Todos os comandos do player (Play, Pausa, Retroceder, Legendas) exigem nós semânticos explícitos com descrição sonora contextual, isolando glifos puramente decorativos com `ExcludeSemantics` (`04_desempenho_acessibilidade.md`, Seção 2.E; `06_flutter.md`, Seção 2.7).
* **Foco Espacial Contínuo:** Componentes visuais personalizados não podem quebrar a árvore semântica. O TalkBack em TVs intercepta o controle remoto D-pad; se o elemento desenhado não for acessível, o foco é bloqueado e a navegação congela (`04_desempenho_acessibilidade.md`, Seção 2.E).
* **Estados Visuais de Foco:** Definição inequívoca dos estados `default`, `focused` e `pressed` combinando elevação tonal, borda com contraste ≥ 3:1 ou fator de escala (`04_desempenho_acessibilidade.md`, Seção 2.E).

---

## 8. Mídia

### Arquitetura de Reprodução e MediaSession
* **Desacoplamento Arquitetural:** O motor de reprodução deve ser unificado sob a abstração de `Player` do Jetpack Media3, isolando a vida útil do player da árvore visual do Flutter (`05_midia_tv.md`, Seção 1).
* **Execução em Segundo Plano:** Para continuidade com a tela apagada ou app em segundo plano, o player e sua `MediaSession` devem residir em um `MediaSessionService` nativo (`05_midia_tv.md`, Seção 2.C).

### Notificação MediaStyle e Tela de Bloqueio
* **Provedor Padrão:** Emprego de `DefaultMediaNotificationProvider` do Media3, que se integra nativamente ao System UI do Android 13+, desenhando a barra de busca contínua, botões de ação customizados e artes do fluxo (`05_midia_tv.md`, Seção 2.C).

### Foco de Áudio (Audio Focus)
* **Delegação ao ExoPlayer:** Configurar `AudioAttributes` e repassá-lo com `handleAudioFocus = true`. O player gerencia ganhos (`AUDIOFOCUS_GAIN`), reduções transitórias de volume (*ducking* via `AUDIOFOCUS_LOSS_TRANSIENT_CAN_DUCK`) e pausas automáticas (`AUDIOFOCUS_LOSS_TRANSIENT`) (`05_midia_tv.md`, Seção 2.C).
* **Anti-pattern:** Não efetuar chamadas manuais com `AudioManager.requestAudioFocus` em paralelo (`05_midia_tv.md`, Seção 2.C).

### Picture-in-Picture (PiP)
* **Transição Fluida (Android 12 / API 31+):** Configurar `PictureInPictureParams.Builder().setAutoEnterEnabled(true)`, permitindo a transição ao gesto de voltar à tela inicial sem congelamento de renderização (`05_midia_tv.md`, Seções 2.D e 3).
* **Ocultação de Controles:** Ao receber `onPictureInPictureModeChanged(true)`, a interface do player deve ocultar todos os elementos (barra de navegação, controles de toque e títulos), mantendo apenas o vídeo puro sob os controles nativos do sistema (`05_midia_tv.md`, Seção 2.D).
* **Proporções Suportadas:** Respeitar a janela de proporções de aspecto entre 1:2.39 e 2.39:1 (`05_midia_tv.md`, Seção 3).
* **Estabilidade da Activity:** Inclusão obrigatória de `android:configChanges="screenSize|smallestScreenSize|screenLayout|orientation"` para impedir recriações da Activity ao miniaturizar (`05_midia_tv.md`, Seção 2.D).

### Downloads e Offline
* **Serviços de Primeiro Plano no Android 14+ (API 34+):** Downloads locais requerem `DownloadService` com `android:foregroundServiceType="dataSync"`, além das permissões `FOREGROUND_SERVICE` e `FOREGROUND_SERVICE_DATA_SYNC` (`05_midia_tv.md`, Seções 2.E e 3).
* **Persistência Estruturada:** Indexação por `DownloadIndex` e gravação em blocos com `SimpleCache` (`05_midia_tv.md`, Seção 2.E).

### HDR (High Dynamic Range)
* **Inspeção de Hardware:** Validação obrigatória das propriedades do display via `Display.getHdrCapabilities()` (HLG10, HDR10, HDR10+ ou Dolby Vision) antes de selecionar faixas de alta faixa dinâmica (`05_midia_tv.md`, Seção 2.F). HLG10 atua como linha de base a partir da API 33 (`05_midia_tv.md`, Seção 3).

### Notificações do Android 16
* **Lacuna Documental:** Não foi possível verificar especificações técnicas de *Live Updates* ou notificações promovidas do Android 16 no material de pesquisa fornecido; a única referência ao Android 16 nos relatórios trata do encerramento inesperado (*crash*) causado pelo uso da flag de cancelamento de *Edge-to-Edge* (`06_flutter.md`, Seção 2.2).

---

## 9. TV (Google TV / Android TV)

### Princípios da "10-Foot UI" e Foco D-Pad
* **Distância Ergonômica:** Interface pensada para visualização a 3 metros (10 pés), baseada em resolução de design de 960 × 540 dp (proporção 16:9 MDPI) (`05_midia_tv.md`, Seção 3; `06_flutter.md`, Seção 3).
* **Foco Unívoco e Destacado:** Exatamente um componente deve reter o foco em cena. A ampliação visual padrão recomendada para cards em foco é de 1.1f (110%) via `CardDefaults.scale()` ou borda com traço contrastante (`05_midia_tv.md`, Seções 2.G e 3; `06_flutter.md`, Seção 2.8).
* **Compose for TV:** O Google adota como direção oficial a biblioteca declarativa `androidx.tv.material3`, substituindo a estrutura legada do Leanback (`05_midia_tv.md`, Seção 2.G).

### Margens Seguras Contra Corte (*Overscan*)
* **Elementos Interativos:** Recuo obrigatório de 5% nas laterais (mínimo de 48 dp) e 27 dp verticalmente no topo e na base (`05_midia_tv.md`, Seção 3; `06_flutter.md`, Seção 3).
* **Imersão de Fundo:** O plano de fundo (pôsteres em degradê e superfícies) deve ocupar 100% da tela física; proíbe-se aplicar overscan em telas cheias para evitar barras pretas falsas (`05_midia_tv.md`, Seção 2.G).

### Integração com o Launcher do Google TV
* **Trilha "Continuar Assistindo" (*Watch Next*):** Atualização pontual disparada em até 5 segundos após a pausa ou término do conteúdo, sem emitir atualizações globais em lote (`05_midia_tv.md`, Seções 2.G e 3).
* **Engage SDK:** Biblioteca nativa `com.google.android.engage:engage-tv` para integrar clusters de recomendação e metadados ao iniciador do sistema (`05_midia_tv.md`, Seção 2.G) [verificar: critérios de aprovação comercial do portal de parceiros].

---

## 10. Flutter: Implementação Técnica de Cada Item

### 1. Voltar Preditivo (*Predictive Back*)
* **Manifesto:** Declarar no arquivo `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <application android:enableOnBackInvokedCallback="true" ...>
  ```
* **Tema de Transição:** Habilitar a física preditiva nativa em `ThemeData`:
  ```dart
  pageTransitionsTheme: const PageTransitionsTheme(
    builders: {
      TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
    },
  )
  ```
* **Controle de Rota:** Substituir o obsoleto `WillPopScope` por `PopScope(canPop: ..., onPopInvokedWithResult: ...)` (`06_flutter.md`, Seção 2.1).

### 2. Imersão Borda a Borda (*Edge-to-Edge*)
* **Ativação:** Executar na inicialização:
  ```dart
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiAnnotation(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
  ));
  ```
* **Posicionamento Seguro:** Utilizar `SafeArea` ou ler `MediaQuery.paddingOf(context)` estritamente sobre controles flutuantes do player e botões interativos, permitindo que a mídia de vídeo e cartazes fluam até a borda física (`06_flutter.md`, Seção 2.2).
* **Proibição:** Não utilizar `android:windowOptOutEdgeToEdgeEnforcement` em builds finais (provoca travamento compulsório no Android 16) (`06_flutter.md`, Seção 2.2).

### 3. Material 3 Minimalista (Estética Heisuca)
* **Estrutura Visual:** Ativar `useMaterial3: true`. Em vez de adotar as cores dinâmicas do sistema (*Monet*), definir uma paleta controlada em `ColorScheme` com tons escuros profundos e contraste nítido, baseando hierarquia em elevação tonal (`surface container`) em vez de sombras projetadas (`06_flutter.md`, Seção 2.3).

### 4. Transições com `package:animations`
* **Expansão de Pôster:** Aplicar `OpenContainer` para abrir cartazes diretamente na página de detalhes ou player (`06_flutter.md`, Seção 2.4).
* **Listas e Menus:** Aplicar `SharedAxisTransition` (eixo X para seletor de episódios/temporadas; eixo Y para filtros de catálogo) (`06_flutter.md`, Seção 2.4).
* **Navegação Principal:** Aplicar `FadeThroughTransition` acoplado ao `PageTransitionSwitcher` entre destinos da barra inferior (`06_flutter.md`, Seção 2.4).
* **Tempos Nominais (M3):** Curvas enfatizadas com 500 ms (tela cheia), 400 ms (entrada) e 200 ms (saída) (`06_flutter.md`, Seção 3).

### 5. Motor Gráfico Impeller e Profiling
* **Execução Padrão:** O Impeller atua com Vulkan 1.1 em Android 10+ (API 29+), mitigando engasgos de compilação de shader via compilação AOT prévia. Dispositivos mais antigos usam fallback para OpenGL ES automaticamente (`06_flutter.md`, Seção 2.5).
* **Perfil de Desempenho:** Testes obrigatórios via `flutter run --profile` em dispositivo físico. O processamento de metadados complexos de catálogo deve ser delegado a `compute` ou *isolates* Dart para proteger a UI Thread (`06_flutter.md`, Seção 2.6).

### 6. Acessibilidade na Interface
* **Rotulagem:**
  ```dart
  Semantics(
    label: 'Reproduzir',
    button: true,
    child: IconButton(...),
  )
  ```
* **Tipografia Não Linear:** Acessar parâmetros com `MediaQuery.textScalerOf(context)` para dimensionar textos sem enclausurá-los em recipientes de altura rígida (`06_flutter.md`, Seção 2.7).
* **Redução de Movimento:** Desativar interpolações espaciais verificando `MediaQuery.disableAnimationsOf(context)` (`06_flutter.md`, Seção 2.7).

### 7. Player e Navegação D-Pad para TV
* **Captura de Hardware Keys:**
  ```dart
  Focus(
    onKeyEvent: (node, event) {
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
        // Disparar ação de seleção
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored; // Não consumir setas direcionais
    },
    child: ...,
  )
  ```
  [verificar: o ecossistema oficial do Flutter carece de documentação dedicada a Android TV, baseando-se nas diretrizes nativas do Google].
* **Prevenção de Foco Fantasma:** Utilizar `FocusScope` com retenção explícita em listas recicladas por `ListView.builder` (`06_flutter.md`, Seção 4).

### 8. Testes de Integração e CI Headless
* **Captura de Tela Confiável no Android:** Em testes com `package:integration_test`, chamar obrigatoriamente:
  ```dart
  await binding.convertFlutterSurfaceToImage();
  await binding.takeScreenshot('tela_detalhes');
  ```
  Evita a geração de imagens completamente pretas no emulador (`06_flutter.md`, Seções 2.9 e 4).
* **Gravação de Vídeo:** Executar no CI:
  ```bash
  adb shell screenrecord /sdcard/video.mp4 &
  # Ao término do teste (respeitando o limite nativo de 180 segundos):
  adb shell pkill -INT screenrecord
  adb pull /sdcard/video.mp4 .
  ```
  Nunca encerrar com `kill -9` sob risco de corrupção do arquivo MP4 (`06_flutter.md`, Seções 2.9 e 3).

---

## 11. Checklist Numerado "Deve / Não Deve"

1. **DEVE** vincular o encerramento da splash screen ao primeiro frame de conteúdo usando `SplashScreen` e `setKeepOnScreenCondition`.  
   *Fonte:* (android.com, link não aberto [verificar])
2. **DEVE** compilar a aplicação com Baseline Profiles e Startup Profiles para otimizar cold starts em até 30%.  
   *Fonte:* (android.com, link não aberto [verificar])
3. **NÃO DEVE** introduzir atrasos artificiais ou loops de espera na abertura do aplicativo.  
   *Fonte:* (android.com, link não aberto [verificar])
4. **DEVE** manter a UI Thread livre de bloqueios para cumprir os orçamentos de quadro (16,6 ms a 60 Hz; 8,3 ms a 120 Hz).  
   *Fonte:* (android.com, link não aberto [verificar])
5. **DEVE** isolar componentes animados frequentes (como o *scrubber* de vídeo) usando `RepaintBoundary`.  
   *Fonte:* (flutter.dev, link não aberto [verificar])
6. **DEVE** redimensionar pôsteres do catálogo no momento da decodificação com `cacheWidth` e `cacheHeight`.  
   *Fonte:* (flutter.dev, link não aberto [verificar])
7. **DEVE** delegar o ciclo de vida e concorrência de foco de áudio ao ExoPlayer configurando `handleAudioFocus = true`.  
   *Fonte:* (android.com, link não aberto [verificar])
8. **NÃO DEVE** executar `AudioManager.requestAudioFocus` manual em conjunto com `handleAudioFocus` ativo no player.  
   *Fonte:* (android.com, link não aberto [verificar])
9. **DEVE** hospedar sessões com execução em segundo plano dentro de um `MediaSessionService`.  
   *Fonte:* (stackoverflow.com, link não aberto [verificar])
10. **DEVE** definir auto-ocultação dos controles de reprodução da tela após 3000 ms na inatividade (`app:show_timeout`).  
    *Fonte:* (android.com, link não aberto [verificar])
11. **DEVE** habilitar entrada automática para Picture-in-Picture com `setAutoEnterEnabled(true)` a partir do Android 12 (API 31+).  
    *Fonte:* (android.com, link não aberto [verificar])
12. **DEVE** ocultar toda a interface de controles quando o player entrar em modo PiP.  
    *Fonte:* (dev.to, link não aberto [verificar])
13. **NÃO DEVE** permitir a destruição da Activity no PiP, configurando `configChanges` de orientação e tela no manifesto.  
    *Fonte:* (medium.com, link não aberto [verificar])
14. **DEVE** estruturar downloads com `DownloadService` declarando `foregroundServiceType="dataSync"` no Android 14+ (API 34+).  
    *Fonte:* [developer.android.com](https://developer.android.com/media/media3/exoplayer/downloading-media)
15. **DEVE** assegurar alvos físicos de toque com dimensões mínimas de 48 × 48 dp e espaçamento de ao menos 8 dp.  
    *Fonte:* (material.io, link não aberto [verificar])
16. **DEVE** cumprir os contrastes mínimos de 4,5:1 (texto padrão) e 3:1 (texto grande e componentes visuais essenciais).  
    *Fonte:* (material.io, link não aberto [verificar])
17. **DEVE** rotular elementos operáveis com `Semantics` e desativar ruídos visuais com `ExcludeSemantics`.  
    *Fonte:* (flutter.dev, link não aberto [verificar])
18. **DEVE** verificar `disableAnimations` e respeitar o sinal de redução de movimento do sistema.  
    *Fonte:* (flutter.dev, link não aberto [verificar])
19. **NÃO DEVE** aplicar margem de overscan ao plano de fundo (background) na Android TV.  
    *Fonte:* (android.com, link não aberto [verificar])
20. **DEVE** resguardar 5% de margem contra overscan (48 dp lateral, 27 dp vertical) para cartões e textos na TV.  
    *Fonte:* (android.com, link não aberto [verificar])
21. **DEVE** atualizar pontualmente a trilha "Continuar Assistindo" (*Watch Next*) em até 5 segundos após a pausa/saída.  
    *Fonte:* (android.com, link não aberto [verificar])
22. **DEVE** habilitar o callback nativo de voltar preditivo declarando `enableOnBackInvokedCallback="true"`.  
    *Fonte:* (flutter.dev, link não aberto [verificar])
23. **NÃO DEVE** utilizar o widget legado `WillPopScope`, adotando obrigatoriamente `PopScope`.  
    *Fonte:* (flutter.cn, link não aberto [verificar])
24. **DEVE** arquitetar a aplicação com `SystemUiMode.edgeToEdge` e manter as barras de sistema transparentes.  
    *Fonte:* (flutter.dev, link não aberto [verificar])
25. **NÃO DEVE** utilizar a flag `android:windowOptOutEdgeToEdgeEnforcement` (causa crash a partir do Android 16).  
    *Fonte:* (flutter.dev, link não aberto [verificar])
26. **DEVE** filtrar estritamente `event is KeyDownEvent` ao manipular eventos de hardware do controle remoto D-pad.  
    *Fonte:* (flutter.dev, link não aberto [verificar])
27. **NÃO DEVE** retornar `KeyEventResult.handled` para setas direcionais, evitando o travamento da navegação nativa.  
    *Fonte:* (flutter.dev, link não aberto [verificar])
28. **DEVE** invocar `await binding.convertFlutterSurfaceToImage()` antes de `binding.takeScreenshot()` em testes de CI.  
    *Fonte:* (keyholesoftware.com, link não aberto [verificar])
29. **NÃO DEVE** abortar o `screenrecord` do emulador com `kill -9`, utilizando obrigatoriamente `pkill -INT`.  
    *Fonte:* (github.com, link não aberto [verificar])

---

## 12. Separação de Fatos vs. Inferências Técnicas e Limitações

### Fatos Comprovados nas Fontes Oficiais
1. Métricas do Android Vitals: 5 s frio, 2 s morno, 1,5 s quente (`04_desempenho_acessibilidade.md`, Seção 3).
2. Dimensões mínimas de toque de 48 × 48 dp e contraste de 4,5:1 e 3:1 (`04_desempenho_acessibilidade.md`, Seção 3).
3. Transição PiP fluida com `setAutoEnterEnabled(true)` (API 31+) e proporções entre 1:2.39 e 2.39:1 (`05_midia_tv.md`, Seção 3).
4. Margens seguras de TV: 5% (48 dp lateral, 27 dp vertical) em 960 × 540 dp (`05_midia_tv.md`, Seção 3).
5. Limite operacional do `screenrecord` de 180 s e obrigatoriedade de `convertFlutterSurfaceToImage()` para evitar capturas pretas (`06_flutter.md`, Seções 3 e 4).

### Inferências Técnicas para o Projeto Heisuca
1. **Padrão de Camada Híbrida Kotlin-Flutter:** Para integrar `DownloadService` com `dataSync`, `MediaSessionService` contínuo e o Engage SDK do Google TV, a abordagem mais confiável é centralizar esses serviços em código nativo Kotlin (via Platform Channels/FFI) e expor para a árvore de widgets Flutter apenas o estado de reprodução e nós semânticos de foco (`05_midia_tv.md`, Seção 5).
2. **Minimalismo e Área de Toque Invisível:** Para preservar o minimalismo estético refinado sem violar as normas de acessibilidade, ícones desenhados visualmente com 20 a 24 dp devem receber espaçamento interno invisível (*padding* transparente) para alcançar 48 × 48 dp (`04_desempenho_acessibilidade.md`, Seção 5).

### Lacunas e Itens Não Verificados nos Relatórios
* **[verificar: Desempenho comparativo de bibliotecas Flutter para vídeo]** Não foi possível verificar benchmarks entre `media_kit` e `video_player` nativo em dispositivos antigos de TV, pois as fontes oficiais do Google cobrem apenas o framework e a arquitetura nativa do ecossistema Android (`04_desempenho_acessibilidade.md`, Seção 5).
* **[verificar: Requisitos de homologação do Engage SDK]** Os trâmites de credenciamento do portal de parceiros do Google TV não puderam ser verificados em fontes abertas (`05_midia_tv.md`, Seção 5).
* **[verificar: Suporte formal a TV na documentação oficial do Flutter]** A documentação oficial do Flutter (`docs.flutter.dev`) não contém guia formal dedicado a Android TV e mapeamento de D-Pad; os padrões descritos foram derivados da documentação nativa do Google (`developer.android.com`) e correlacionados aos widgets do Flutter (`06_flutter.md`, Seção 5).
* **[verificar: Live Updates do Android 16]** Não constam nos relatórios anexos detalhes sobre especificações de notificações promovidas ou *Live Updates* do Android 16.
