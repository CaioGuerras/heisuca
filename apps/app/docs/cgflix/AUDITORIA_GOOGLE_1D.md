# Auditoria Google — Etapa 1D (qualidade Android, Material 3, acessibilidade, telas grandes, mídia)

Item · referência · situação (OK / corrigido / pendente) · o que foi feito. O detalhe (mais abaixo) é o retrato do começo
da etapa, com arquivo:linha; esta tabela diz o que mudou depois.

## Situação nesta etapa

| Item | Referência | Situação | O que foi feito |
|---|---|---|---|
| targetSdk/compileSdk 36, minSdk 25 | [Core app quality](https://developer.android.com/docs/quality-guidelines/core-app-quality) | OK | — |
| R8 + shrinkResources no release | [App optimization](https://developer.android.com/topic/performance/app-optimization/enable-app-optimization) | OK | Ligados pelo plugin do Flutter |
| Baseline Profile | [Baseline Profiles](https://developer.android.com/topic/performance/baselineprofiles/overview) | pendente | Ganho pequeno num app Flutter; próxima etapa |
| Backup sem credenciais | [Auto Backup](https://developer.android.com/identity/data/autobackup) | corrigido (parcial) | `allowBackup="false"`; falta `dataExtractionRules` para a transferência entre aparelhos |
| Permissões mínimas | Core app quality | parcial | `REORDER_TASKS` sem uso (upstream) — próxima etapa |
| Ponta a ponta (edge-to-edge) | [Edge-to-edge](https://developer.android.com/develop/ui/views/layout/edge-to-edge) | OK | Barras transparentes (1C); recortes da câmera respeitados no topo deitado (1D) |
| Película da navegação de 3 botões | Edge-to-edge | **corrigido** | `systemNavigationBarContrastEnforced: true` |
| Voltar preditivo | [Predictive back](https://developer.android.com/guide/navigation/custom-back/predictive-back-gesture) | **corrigido na 1.6.1** (ver Refino 2b) | Navegação nova usa rotas com Voltar (botão e gesto). `enableOnBackInvokedCallback` continua sem declarar: precisa de teste numa TV box (a tecla VOLTAR do controle) |
| Splash Screen API e ícone adaptativo + monocromático | [Splash screens](https://developer.android.com/develop/ui/views/launch/splash-screen) | OK | Já da 1B/1C |
| MediaSession / notificação / tela de bloqueio | [Media apps](https://developer.android.com/media/implement/surfaces/mobile) | parcial | Música tem; vídeo pausa em segundo plano (esperado). PiP cobre o "sair do app" |
| PiP | [PiP](https://developer.android.com/develop/ui/views/picture-in-picture) | OK | Entrada automática (upstream); falta `sourceRectHint` |
| Foco de áudio e fone desconectado | [Audio focus](https://developer.android.com/media/optimize/audio-focus) | OK | Upstream |
| Retomar de onde parou | Media apps | OK | Posição do servidor; "Continuar T2:E5" |
| Paisagem no celular | [Large screens](https://developer.android.com/docs/quality-guidelines/large-screen-app-quality) | **corrigido** | Tela preta (exceção no `clamp` da altura do destaque) corrigida; mesma barra do topo deitado; destaque compacto; testes em 360/412/800 dp |
| Tablet/TV | Large screens | OK | Tablet usa a barra do topo; TV continua com o trilho lateral do upstream |
| Alvos de toque ≥ 48 dp | [Accessibility](https://developer.android.com/guide/topics/ui/accessibility/apps) | **corrigido** | Chips, lupa, Pedir, emblema, "Assistir" e seletor de servidor com 48 dp de toque (testado) |
| Contraste de texto ≥ 4,5:1 | [Color contrast](https://m3.material.io/foundations/designing/color-contrast) | **corrigido** | "Assistir" passou para `#9333ea` (5,4:1); texto apagado 9,9:1 |
| TalkBack nos botões só de ícone | Accessibility | OK | Rótulos em português (testado) |
| Destaque que troca sozinho | [WCAG 2.2.2](https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide) | **corrigido** | Para com TalkBack ou "remover animações"; arrastar continua |
| "Remover animações" nas transições | Accessibility | **corrigido** | Transição de página seca |
| Fonte 200% | Accessibility | parcial | Barra do topo, Pedir da busca e destaque testados a 200%; cartões ainda limitam a 1,2× (próxima etapa) |
| Teclado/controle nos cartões da Início | Accessibility | **corrigido na 1.6.1** (ver Refino 2b) | `CgflixPressable` usa `GestureDetector`; só afeta quem não é detectado como TV |
| Estados (pressionado/foco) | [M3 states](https://m3.material.io/foundations/interaction/states/overview) | **corrigido** (parcial) | Botões e chips do CGFLIX mostram pressionado/foco; o tema do upstream desliga o efeito de toque no resto |
| Componentes padrão do M3 | M3 | parcial | Chips da barra são desenho próprio (para 36 dp de desenho com 48 dp de toque); menu do usuário usa `ListTile`/folha padrão |
| Tema e cores | M3 | **corrigido** | Tema único (`cgflixAppTheme`), sem cores soltas para o tema |
| Imagens no tamanho exibido, listas preguiçosas | [Performance](https://developer.android.com/topic/performance) | OK | `OptimizedMediaImage` com tamanho; `SliverList.builder` |
| Nada pesado na thread de UI | Performance | pendente | Cache da Início decodificado na UI; som da abertura com `MediaPlayer.create` síncrono |

## Refino 2b (1.6.1) — cada item reaberto depois do refino 2

Conferido de novo no código da 1.6.1 (11/10). **Mudou** = mexido nesta etapa.

| Item | Situação na 1.6.1 | O que mudou / evidência |
|---|---|---|
| targetSdk/compileSdk 36, minSdk 25 | OK | sem mudança |
| R8 + shrinkResources | OK | sem mudança |
| Baseline Profile | pendente | sem mudança (ganho pequeno em Flutter) |
| Backup sem credenciais | parcial | `allowBackup="false"` continua; `dataExtractionRules` ainda falta |
| Permissões mínimas | parcial | `REORDER_TASKS` ainda declarada (linha a mais de diferença do upstream) |
| Ponta a ponta | OK | **mudou**: Configurações e subtelas com a barra de título grande sob a barra de status e lista até embaixo da barra de navegação (`SliverSystemBottomInset`), sem faixa preta |
| Película da navegação de 3 botões | OK | sem mudança |
| **Voltar preditivo** | **corrigido** | **mudou**: `android:enableOnBackInvokedCallback="true"` no `<application>`; a transição do CGFLIX recebe o gesto e acompanha o dedo (encolhe, arredonda e volta se desistir) — `lib/cgflix/cgflix_theme.dart`, `test/cgflix/cgflix_voltar_preditivo_test.dart`. Risco: TV com Android 13–15 passa a receber o VOLTAR do controle pelo caminho do sistema (o mesmo que o Android 16 já usava; o upstream trata os dois caminhos). TV box com Android 9–12 não muda. Conferir numa TV box com Android 14 |
| Splash Screen API, ícone adaptativo/monocromático | OK | sem mudança |
| MediaSession / PiP | parcial | sem mudança (falta `sourceRectHint`) |
| Foco de áudio, retomar | OK | sem mudança |
| Paisagem | OK | **mudou**: Configurações testadas deitadas (914 × 412) |
| Tablet/TV | parcial | Configurações em duas colunas (≥ 840 dp) **não** feitas: exigiria reescrever a navegação das Configurações |
| Alvos de toque ≥ 48 dp | OK | **mudou**: linhas das Configurações com 56/72 dp; "?" de 48 dp; círculos de cor de 40 dp com toque de 48 dp |
| Contraste | OK | **mudou**: contraste AA das Configurações medido em teste nos dois temas (cabeçalho, título, resumo, switch) |
| TalkBack | OK | **mudou**: cabeçalhos lidos como cabeçalho; switch com papel de switch e estado; opções dos diálogos como botões de opção; cores com nome |
| Destaque que troca sozinho, remover animações | OK | sem mudança; o voltar preditivo também fica seco com "remover animações" |
| Fonte 200% | parcial | **mudou**: Configurações sem corte a 200% (capturas `*-fonte200-*`, teste a 360 dp); cartões da Início continuam limitados a 1,2× |
| **Teclado/controle nos cartões** | **corrigido** | **mudou**: `CgflixPressable` com `FocusableActionDetector`, contorno de foco e Enter/OK — `test/cgflix/cgflix_cartao_foco_test.dart` |
| Estados (pressionado/foco) | parcial | **mudou**: foco das linhas das Configurações com realce `primary` 16% |
| **Componentes padrão do M3** | **corrigido nas Configurações** | **mudou**: `ListTile`/`SwitchListTile` M3, `Switch` com check, `Slider`, diálogo com botões de opção, `SliverAppBar.large`, cabeçalhos e divisores M3 (`docs/cgflix/REFINO_2B.md`). Chips da barra continuam desenho próprio |
| Tema e cores | OK | **mudou**: Configurações pintadas só pelo `ColorScheme` (Isis com `primary` lilás nas Configurações e nos controles; Heitor verde); cor fixa da marca, sem cor dinâmica |
| Ícones | OK | **mudou**: Configurações só com Material Symbols Rounded em contorno, 24 dp, `onSurfaceVariant` |
| Imagens, listas preguiçosas | OK | sem mudança |
| Nada pesado na thread de UI | parcial | som da abertura já roda fora da thread principal (1E); cache da Início ainda decodifica na UI |

## Detalhe da auditoria

Retrato do código em 07/10/2026 às ~15:52. Os arquivos `lib/cgflix/cgflix_navigation.dart`, `cgflix_user_menu.dart`,
`cgflix_about.dart`, `cgflix_layout.dart`, `home/cgflix_home_screen.dart` e `home/cgflix_hero.dart` estavam sendo editados
durante a auditoria, então confira de novo as linhas citadas nesses arquivos. Nenhum arquivo do repositório foi alterado.

Legenda: **OK** = atende · **parcial** = atende em parte · **pendente** = não atende.

Referências usadas (resumo):
- Core app quality: https://developer.android.com/docs/quality-guidelines/core-app-quality
- Large screens: https://developer.android.com/docs/quality-guidelines/large-screen-app-quality
- Mudanças do Android 15 e 16 (o app usa targetSdk 36): https://developer.android.com/about/versions/15/behavior-changes-15 e https://developer.android.com/about/versions/16/behavior-changes-16
- Acessibilidade: https://developer.android.com/guide/topics/ui/accessibility/apps
- Material 3: https://m3.material.io

---

## 1. Core app quality

| Item | Referência (URL da diretriz) | Situação | O que foi feito / o que falta (arquivo:linha) |
|---|---|---|---|
| targetSdk / compileSdk / minSdk | https://developer.android.com/google/play/requirements/target-sdk | **OK** | `android/app/build.gradle.kts:233` `compileSdk = flutter.compileSdkVersion`, `:250` `targetSdk = flutter.targetSdkVersion`. No Flutter instalado (`/opt/flutter/packages/flutter_tools/gradle/src/main/kotlin/FlutterExtension.kt:23,34`) os dois valem **36**, ou seja, Android 16 e acima do mínimo do Play (35). `minSdk = 25` (`:249`, Fire OS 6) fica acima do padrão do Flutter (24). Consequência: as regras do Android 15 e 16 já valem para o app (ponta a ponta obrigatório, voltar preditivo ligado por padrão, orientação ignorada em tela ≥600 dp). Veja as seções 3 e 5. |
| Permissões declaradas | https://developer.android.com/training/permissions/evaluating | **parcial** | `AndroidManifest.xml`: `INTERNET` (:9, necessária); `MODIFY_AUDIO_SETTINGS` (:10, usada pela saída de áudio do mpv/ExoPlayer, permissão normal); `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PLAYBACK` (:13-14, usadas pelo serviço do `os_media_controls` na música em segundo plano); **`REORDER_TASKS` (:15) não é usada** por nada no app nem nos plugins (nenhum `moveTaskToFront`; só aparece no manifest); `POST_NOTIFICATIONS` (:17, notificações de download e de mídia, pedida em tempo de execução em `lib/utils/notification_permission.dart`); `FOREGROUND_SERVICE_DATA_SYNC` (:18, serviço `dataSync` do `background_downloader`; no Android 15 tem limite de 6 h e, no Play, exige declaração do tipo de serviço em primeiro plano); `WRITE_EPG_DATA` (:28) e `RECEIVE_BOOT_COMPLETED` (:29), usadas pela fileira "Watch Next" da TV (só servem na TV). As permissões de mídia e de armazenamento foram removidas corretamente (:21-24). Os plugins acrescentam ainda `ACCESS_NETWORK_STATE` (connectivity_plus) e `WAKE_LOCK` (WorkManager). Falta tirar `REORDER_TASKS`, que é opcional, porque é uma linha a mais de diferença em relação ao upstream. |
| R8 / minify / shrinkResources no release | https://developer.android.com/build/shrink-code | **OK** | O bloco `release` de `build.gradle.kts:295-308` não liga isso diretamente, mas o plugin do Flutter liga: `FlutterPlugin.kt:216-227` define `isMinifyEnabled = true`, `isShrinkResources = true`, `proguard-android-optimize.txt` e anexa `android/app/proguard-rules.pro`. Existe ainda a variante `minified` (`build.gradle.kts:322-339`), que testa o R8 nos testes instrumentados. |
| Regras ProGuard | https://developer.android.com/build/shrink-code#keep-code | **OK** | `android/app/proguard-rules.pro` (37 linhas) mantém o decodificador FFmpeg do Media3 (carregado por reflexão/JNI), `SimpleDecoderOutputBuffer` e os campos do `MatroskaExtractor` lidos por `getDeclaredField` (legendas ASS no MKV). Cada regra vem com o motivo comentado. |
| ANR / estabilidade (thread principal) | https://developer.android.com/topic/performance/vitals/anr | **parcial** | O que está bom: as operações do mpv passam por uma fila serializada com prazo (`mpv/MpvOperationQueue.kt`), o diagnóstico de saída roda num executor próprio (`MainActivity.kt:73-76,365,407`) e o WatchNext usa um executor (`watchnext/WatchNextPlugin.kt:46`). Pontos menores: (a) `MainActivity.onCreate` lê `SharedPreferences` de forma síncrona (`MainActivity.kt:339-340,491-492`); são leituras pequenas, de risco baixo; (b) **CGFLIX**: `CgflixIntroSoundChannel.kt:34` chama `MediaPlayer.create(...)`, que faz `prepare()` síncrono na thread principal durante a abertura. O arquivo é um WAV curto, então o risco é pequeno, mas o certo é `SoundPool` ou `MediaPlayer` com `prepareAsync()`. Ele também usa `USAGE_MEDIA` sem pedir foco de áudio e toca por cima da música do usuário; `USAGE_ASSISTANCE_SONIFICATION` seria mais adequado. |
| Partida a frio (antes do 1º frame) | https://developer.android.com/topic/performance/vitals/launch-time | **parcial** | `lib/main.dart:173-198`: `runApp` roda imediatamente com `StartupBootstrap`. O fundo transparente deixa a splash nativa à mostra enquanto `_initializeApplication` (`main.dart:255-1000`) espera, em sequência: preferências (:256), Sentry (:259-298, **desligado** porque `ENABLE_SENTRY` é falso por padrão, :109), idioma (:929-932), detecção de TV, desempenho e decodificadores em paralelo (:949-955), certificados do usuário (:957-959), armazenamento (:961), **abertura do banco Drift com recuperação de downloads** (:965-973) e o orçamento do cache de imagens (:977). O que não é essencial fica para depois do 1º frame (`_startNonessentialInitialization`, :992-1000). O desenho é bom e cada fase tem prazo, mas o banco continua no caminho crítico. Falta medir: `adb shell am start -W` e, no Play, o Android vitals. Não há `reportFullyDrawn()`. |
| Backup (allowBackup / dataExtractionRules) | https://developer.android.com/identity/data/autobackup | **pendente** | O `<application>` (`AndroidManifest.xml:34-42`) não declara `allowBackup`, `fullBackupContent` nem `dataExtractionRules`, então vale o padrão **allowBackup=true**. O Auto Backup copia `shared_prefs/` e `databases/`. Os tokens do servidor ficam cifrados no banco, mas **a chave fica nas SharedPreferences** (`lib/services/credential_vault.dart:5-8`), de modo que o backup e a transferência entre aparelhos levam as credenciais junto. Falta criar `res/xml/cgflix_data_extraction_rules.xml` (Android 12+) e `res/xml/cgflix_backup_rules.xml` (Android ≤11) excluindo `sharedpref` e `database`, e referenciar os dois no `<application>`. Veja as correções. |
| Declaração de dados (Data safety) / telemetria | https://support.google.com/googleplay/android-developer/answer/10787469 | **parcial** | Telemetria: o Sentry só entra com `--dart-define=ENABLE_SENTRY=true` (`main.dart:109`). O workflow do upstream só passa isso no repositório `edde746/plezy` (`.github/workflows/build.yml:36`), e o `cgflix-android.yml:82` não passa, então está desligado. A constante do DSN do upstream continua no código (`main.dart:110`); é inofensiva, mas parece uma "chave". A checagem de atualização também fica desligada (`ENABLE_UPDATE_CHECK` não é passado). Não há política de privacidade nem rascunho do formulário Data safety; isso só será necessário se o app for para o Play. Também há `usesCleartextTraffic="true"` (`AndroidManifest.xml:42`) com HTTP liberado no `base-config` (`res/xml/network_security_config.xml`). O upstream precisa disso para servidores na rede local; o nosso servidor é HTTPS. |

## 2. Baseline Profile

| Item | Referência | Situação | O que foi feito / o que falta |
|---|---|---|---|
| Baseline Profile / profileinstaller | https://developer.android.com/topic/performance/baselineprofiles/overview | **pendente (baixa prioridade)** | Não existe `baseline-prof.txt` no projeto e não há dependência direta de `androidx.profileinstaller` (`build.gradle.kts:428-460`); ele pode vir indiretamente pelo AndroidX. Num app Flutter, a interface é Dart compilado AOT, e um Baseline Profile só acelera o código Kotlin/Java (MainActivity, Media3, plugins). O ganho é pequeno; deixe para quando houver Macrobenchmark. |

## 3. Plataforma: ponta a ponta, voltar preditivo, splash e ícone

| Item | Referência | Situação | O que foi feito / o que falta |
|---|---|---|---|
| Ponta a ponta (edge-to-edge) | https://developer.android.com/develop/ui/views/layout/edge-to-edge · https://developer.android.com/about/versions/15/behavior-changes-15#edge-to-edge | **parcial** | `lib/main.dart:173` chama `cgflixEnableEdgeToEdge()` (`lib/cgflix/cgflix_theme.dart:100-104`: `SystemUiMode.edgeToEdge` + barras transparentes, `:86-97`). Com targetSdk 36 isso é obrigatório no Android 16 (`windowOptOutEdgeToEdgeEnforcement` não é usado, o que está correto). Problemas: (a) `systemNavigationBarContrastEnforced: false` (`cgflix_theme.dart:92`) tira a película que o sistema põe atrás da **navegação de 3 botões**, e os botões podem sumir sobre pôsteres claros. O Google recomenda manter a película com 3 botões. (b) Passar `statusBarColor`, `systemNavigationBarColor` e `systemNavigationBarDividerColor` (:89-91) faz o motor do Flutter chamar `Window.setStatusBarColor`, `setNavigationBarColor` e `setNavigationBarDividerColor`, que foram descontinuadas no API 35. O Play Console mostra o aviso "APIs descontinuadas de ponta a ponta". É só um aviso, sem bloqueio. As telas do CGFLIX respeitam os recuos com `MediaQuery.paddingOf` (home, navegação, perfil). |
| Voltar preditivo | https://developer.android.com/guide/navigation/custom-back/predictive-back-gesture · https://developer.android.com/about/versions/16/behavior-changes-16 | **pendente** | O manifest **não** tem `android:enableOnBackInvokedCallback` (`AndroidManifest.xml:46-55`). Com targetSdk 36, **no Android 16 o voltar preditivo já vem ligado por padrão**: "`onBackPressed` não é chamado e `KEYCODE_BACK` não é mais entregue". O receio registrado em `CGFLIX.md:102-104` (o controle da TV perde a tecla VOLTAR) **já vale hoje em aparelhos com Android 16**, e no Android 13-15 o comportamento é o antigo, então o app se comporta de dois jeitos. Além disso, a frase "as transições já acompanham o gesto" (`CGFLIX.md:102`, `cgflix_theme.dart:12`) não confere: `CgflixPageTransitionsBuilder` (`cgflix_theme.dart:13-40`) substitui o `PredictiveBackPageTransitionsBuilder` padrão do Flutter no Android (`flutter/lib/src/material/page_transitions_theme.dart:766`), e só ele chama `route.handleStartBackGesture` (`predictive_back_page_transitions_builder.dart:256-263`). Portanto a animação **não** segue o dedo. Falta decidir de forma explícita: `enableOnBackInvokedCallback="true"` com teste numa TV box Android 14/16, ou `"false"` provisório para o comportamento ser igual em todas as versões. |
| Splash Screen API | https://developer.android.com/develop/ui/views/launch/splash-screen | **OK** | `res/values-v31/styles.xml` e `values-night-v31/styles.xml`: `windowSplashScreenAnimatedIcon=@drawable/splash_icon` com duração de 900 ms (o limite é 1000 ms). O fundo vem do `windowBackground` `#07060a` (`res/values/colors.xml`). `drawable/splash_icon.xml` é um AVD com o ícone reduzido a 62% (cabe no círculo de 2/3). `MainActivity.kt:500-502` remove a animação de saída para não piscar antes do Flutter. No Android ≤11 (minSdk 25) aparece só a cor, sem ícone, porque não se usa `androidx.core:core-splashscreen`. Isso é aceitável. |
| Ícone adaptativo + monocromático (ícones temáticos) | https://developer.android.com/develop/ui/views/launch/icon_design_adaptive | **OK** | `res/mipmap-anydpi-v26/ic_launcher.xml` tem `<background>`, `<foreground>` e `<monochrome android:drawable="@drawable/ic_launcher_monochrome"/>`; o drawable existe. Há banner de TV (`drawable*/tv_banner.png`, manifest :38). |

## 4. Mídia

| Item | Referência | Situação | O que foi feito / o que falta |
|---|---|---|---|
| MediaSession / notificação / tela de bloqueio | https://developer.android.com/media/media3/session/control-playback · https://developer.android.com/media/media3/session/background-playback | **parcial** | O plugin `os_media_controls` (fork do upstream, `pubspec.yaml:38-41`) cria um `MediaSessionCompat` com botões de mídia (`~/.pub-cache/git/media_controls-a27208e…/android/.../OsMediaControlsPlugin.kt:87-141`) e um `MediaPlaybackService` com `foregroundServiceType="mediaPlayback"` e notificação MediaStyle (`MediaPlaybackService.kt:301`). No Dart, `lib/services/media_controls_manager.dart` também o usa no player de vídeo (`lib/screens/video_player/parts/playback_services.dart`). A notificação e a tela de bloqueio só existem com `setBackgroundMode(true)`, que hoje só a **música** liga (`lib/services/music/music_playback_service_impl.dart:516,1332`). No vídeo, ir para segundo plano **pausa** (`lib/screens/video_player/parts/lifecycle.dart:107-151`), a menos que entre em PiP. Isso está de acordo com o esperado para app de vídeo. É a API legada (`MediaSessionCompat`), não a `MediaSession` do Media3. Funciona, mas o Google recomenda o Media3. Não é para mexer no fork. |
| Picture-in-Picture | https://developer.android.com/develop/ui/views/picture-in-picture | **parcial** | `supportsPictureInPicture="true"` (`AndroidManifest.xml:52`); `enterPictureInPictureMode` (`MainActivity.kt:1008`), entrada automática no Android 12+ com `setAutoEnterEnabled` (`:1189-1191`) e `onUserLeaveHint` no Android 8-11 (`:1143-1158`); a proporção fica limitada a 2,39:1 (`:1176-1193`). Falta `setSourceRectHint` (transição suave) e `setSeamlessResizeEnabled(false)` para vídeo. Não há `RemoteAction` próprio; o sistema usa os botões da MediaSession. |
| Foco de áudio | https://developer.android.com/media/optimize/audio-focus | **OK** | `shared/AudioFocusManager.kt:57-98` (`AudioFocusRequest` com `AUDIOFOCUS_GAIN`); perda pausa e ganho retoma (`mpv/MpvPlayerCore.kt:885-893,2302-2330`). Exceção: o "tum" da abertura do CGFLIX não pede foco (veja Core/ANR). |
| Pausar ao desconectar o fone (BECOMING_NOISY) | https://developer.android.com/media/platform/output#becoming-noisy | **OK** | `OsMediaControlsPlugin.kt:147-175` registra `ACTION_AUDIO_BECOMING_NOISY`, pausa se estiver tocando e ignora o caso na TV (HDMI dispara à toa). |
| Retomar de onde parou | https://developer.android.com/docs/quality-guidelines/core-app-quality (preservação de estado) | **OK** | A posição vem do servidor (`viewOffsetMs`): `lib/screens/video_player/parts/playback_open.dart:78-85,217`. O progresso é reportado ao Jellyfin em `/Sessions/Playing`, `/Progress` e `/Stopped` (`lib/services/jellyfin_client/parts/playback.dart:1112-1182`). O "Continuar assistindo" do CGFLIX mostra a barra de progresso (`lib/cgflix/home/cgflix_cards.dart:283-341`). |

## 5. Telas grandes

| Item | Referência | Situação | O que foi feito / o que falta |
|---|---|---|---|
| resizeableActivity / screenOrientation | https://developer.android.com/docs/quality-guidelines/large-screen-app-quality · https://developer.android.com/about/versions/16/behavior-changes-16 | **OK** | O manifest não declara nenhum dos dois (`AndroidManifest.xml:46-55`), então vale redimensionável e sem orientação fixa. A orientação é pedida em tempo de execução: liberada no app (`lib/utils/orientation_helper.dart:24-27`) e travada em paisagem só no player (`:31-44`). No Android 16, em telas ≥600 dp, a trava é ignorada; o player já se adapta. |
| configChanges | https://developer.android.com/guide/topics/resources/runtime-changes | **OK** | `AndroidManifest.xml:53` cobre orientation, screenSize, smallestScreenSize, screenLayout, density, uiMode, fontScale, locale e outros, o que evita recriar a Activity e o motor Flutter. `MainActivity.kt:755` trata `onConfigurationChanged`, incluindo dobráveis. |
| Window size classes (compacto/médio/expandido) | https://m3.material.io/foundations/layout/applying-layout/window-size-classes | **parcial** | `lib/utils/platform_detector.dart:252-256`: `isMobile` depende da **plataforma**, não da largura; `isTablet` usa a diagonal ≥7" (`:334-342`). O CGFLIX liga a navegação dele com `cgflixUseYouTab = isMobile` (`lib/cgflix/cgflix_navigation.dart:25`), então celular e tablet recebem o mesmo layout de barra no topo. Não há trilho nem layout de 2 painéis para larguras ≥600/840 dp. `cgflix_layout.dart` já trata paisagem (destaque mais baixo, `cgflixHeroHeight`/`cgflixHeroCompact`). Falta, no futuro, usar `MediaQuery.sizeOf(context).width` com 600/840 dp para colunas e fileiras maiores no tablet. |
| Paisagem | Large screens, Tier 3 | **OK** | O destaque se adapta (`lib/cgflix/cgflix_layout.dart`); o shell do upstream troca para `NavigationRail` em paisagem fora do CGFLIX (`platform_detector.dart:237-239`). |

## 6. Acessibilidade (lib/cgflix/**)

Contraste calculado pela fórmula WCAG 2.x (alfa misturado sobre o fundo):

| Par | Razão | Mínimo | Resultado |
|---|---|---|---|
| `textMuted 0xB3FFFFFF` sobre `#07060a` | 9,86:1 | 4,5 | OK |
| `textMuted` sobre `#120e1a` | 9,54:1 | 4,5 | OK |
| `textMuted` sobre `#1c1626` | 9,13:1 | 4,5 | OK |
| `Colors.white70` (texto em `cgflix_hero.dart:196`) sobre `#07060a` | 9,78:1 | 4,5 | OK, mas o texto fica sobre a arte com gradiente, e a razão varia com a imagem |
| `Colors.white38` (só **contorno** de chip e botão redondo) sobre `#07060a`/`#120e1a` | 3,47 / 3,57:1 | 3,0 (componente) | OK, por pouco. Não usar como cor de texto |
| `Colors.white24` (trilho da barra de progresso) | 2,02:1 | não é informação | OK; quem informa é a barra roxa, 5,11:1 |
| texto **branco sobre `#a855f7`** (botão "Assistir": `cgflix_hero.dart:203-210`, `cgflix_preview_sheet.dart:222-226`) | **3,96:1** | 4,5 (rótulo de 14 sp) | **REPROVA** |
| texto branco sobre `#9333ea` | 5,38:1 | 4,5 | OK |
| `#a855f7` sobre `#07060a` (ícone ativo, barra de progresso) | 5,11:1 | 3,0 | OK |
| `#9333ea` sobre `#07060a` | 3,75:1 | 4,5 se for texto | Não usar como texto sobre o preto |
| lilás `#c084fc` sobre `#120e1a` (gêneros na prévia, ícones do perfil) | 7,20:1 | 4,5 | OK |
| texto branco sobre `#c084fc` | 2,64:1 | 4,5 | Não usar |

| Item | Referência | Situação | O que foi feito / o que falta |
|---|---|---|---|
| Botões só de ícone com rótulo | https://developer.android.com/guide/topics/ui/accessibility/apps#describe-ui-element | **OK** | Lupa, "Pedir" e "×": `Tooltip` + `Semantics(label)` (`cgflix_navigation.dart:262-299`); menu do emblema (`:170-200`); "Fechar" com `tooltip` (`home/cgflix_preview_sheet.dart:175-176`); "Tirar do histórico" (`search/cgflix_search_extras.dart:127-129`); emblema com `semanticsLabel` (`cgflix_logo.dart:15`); cartões com `semanticLabel` = título (`home/cgflix_cards.dart:195-197`); número do Top 10 com `ExcludeSemantics` (`:421`). |
| Alvos de toque ≥ 48 dp | https://m3.material.io/foundations/designing/structure#dab862b1-e042-4c40-b680-b484b9077f6f · https://support.google.com/accessibility/android/answer/7101858 | **pendente** | O comentário promete "36 dp desenhados, 48 dp de toque" (`cgflix_navigation.dart:257`), mas o `InkWell` está **dentro** do círculo de 36 dp (`:282-293`: `SizedBox.square(48)` → `Center` → `Material` → `InkWell` → `SizedBox.square(36)`). Toques na margem não acertam nada, então **o alvo real é 36×36 dp**. O mesmo acontece em `_TopChip` (`:220-256`): o `InkWell` fica no contêiner de 36 dp de altura (`:229`) dentro do `SizedBox(height: 48)`. Outros abaixo de 48: seletor "Disponível em N servidores" (`search/cgflix_sources.dart:42-58`, padding vertical 6 + ícone de 16-18 ≈ 30 dp) e `IconButton` de 18 dp no histórico (`cgflix_search_extras.dart:127`), que fica OK porque o `IconButton` garante 48. Os botões "Assistir" e "Detalhes" do destaque (`cgflix_hero.dart:206,217`, 44 dp) ficam OK porque o `FilledButton` usa `MaterialTapTargetSize.padded` e completa os 48. |
| Contraste | https://m3.material.io/foundations/designing/color-contrast | **parcial** | Veja a tabela: só o **branco sobre `#a855f7`** reprova (3,96:1). |
| Fonte do sistema a 200% | https://developer.android.com/guide/topics/ui/accessibility/apps#text-visibility | **parcial** | O texto é limitado de propósito: cartão largo com `withClampedTextScaling(maxScaleFactor: 1.2)` dentro de `SizedBox(height: 44)` (`home/cgflix_cards.dart:346-370`) e chips do topo com `clamp(maxScaleFactor: 1.3)` numa barra fixa de 56 dp (`cgflix_navigation.dart:91,247`). Nada estoura nem corta pela metade, mas quem usa 200% recebe no máximo 120-130% e reticências. Títulos de fileira e itens de lista têm `maxLines: 1` sem altura fixa (`cgflix_cards.dart:146-151`, `cgflix_you_screen.dart:50-54`), o que está OK. O número do Top 10 (`fontSize: 128`, `cgflix_cards.dart:405`) é decorativo. Falta subir os limites (1.2 → 1.5) e deixar o bloco de título crescer (altura calculada pelo `TextScaler`), em vez de altura fixa. |
| Conteúdo que se move sozinho / leitor de tela | https://www.w3.org/WAI/WCAG22/Understanding/pause-stop-hide | **pendente** | O destaque troca a cada 8 s (`home/cgflix_hero.dart:54-58`, `cgflix_home_logic.dart:74`) mesmo com TalkBack ligado, então o foco do leitor muda de título sozinho. A troca manual é só por arrastar (`cgflix_hero.dart:78-84`), sem alternativa acessível. A animação de entrada respeita "remover animações" (`cgflix_intro.dart:99`), mas o destaque e as transições de página não (`cgflix_theme.dart:13-40`). |
| Teclado / controle (D-pad) | https://developer.android.com/develop/ui/views/touch-and-input/keyboard-input/navigation | **parcial** | A TV usa a navegação do upstream (`isMobile` exclui TV), e por isso não é afetada. Nas telas do CGFLIX, os **cartões** (`CgflixPressable`, `home/cgflix_cards.dart:175-220`) usam `GestureDetector`, que **não recebe foco** nem Enter/D-pad. Celular com teclado ou mouse, Chromebook e uma TV box que não se declara TV não conseguem abrir um título pelo teclado. Chips, botões redondos, `ListTile` e `FilledButton` usam `InkWell`/Material e recebem foco; o anel de foco é o `focusColor` de 12% (`lib/theme/mono_theme.dart:113`). |

## 7. Material 3

| Item | Referência | Situação | O que foi feito / o que falta |
|---|---|---|---|
| `useMaterial3` | https://m3.material.io/develop/flutter | **OK** | `lib/theme/mono_theme.dart:75` `useMaterial3: true`; a marca entra por cima com `cgflixBrandTheme` (`mono_theme.dart:15-18`, `cgflix_theme.dart:43-83`). |
| Componentes refeitos à mão | https://m3.material.io/components/chips/guidelines | **parcial** | Os chips de filtro são `AnimatedContainer` + `Material` + `InkWell` (`cgflix_navigation.dart:209-258`), no lugar de `FilterChip`/`ChoiceChip`. A semântica foi feita à mão e está correta (`selected`, `button`, rótulo, `:214-219`). O botão redondo (`:262-299`) poderia ser `IconButton.outlined` com `style: IconButton.styleFrom(fixedSize: Size.square(36))`, que já dá 48 dp de toque, foco, hover e pressionado. `_SecondaryAction` (`home/cgflix_preview_sheet.dart:271-300`) faz o papel de um botão de texto vertical. Não precisa trocar tudo; basta resolver o alvo de toque e os estados. |
| Estados pressionado / foco / desabilitado | https://m3.material.io/foundations/interaction/states/overview | **parcial** | O tema do upstream tira o "ripple" e o destaque: `splashFactory: NoSplash.splashFactory` e `highlightColor: Colors.transparent` (`mono_theme.dart:109-110`). Por isso os `InkWell` do CGFLIX (chips, botões redondos, ações da prévia, seletor de servidor) **não mostram estado pressionado**. Os cartões têm escala de 0,95 (`cgflix_cards.dart:209-214`). O botão "Assistir" troca a cor ao pressionar (`overlayColor` = `#9333ea`, `cgflix_hero.dart:207`). Foco: `focusColor` de 12% (`mono_theme.dart:113`). Desabilitado: só "Reconectar" (`cgflix_navigation.dart:322`) usa `onPressed: null`, com o estilo padrão. Falta passar `overlayColor` (pressionado ≈ branco 12%) nos `InkWell` do CGFLIX, sem mexer no tema do upstream. |
| Movimento | https://m3.material.io/styles/motion/easing-and-duration/tokens-specs | **parcial** | `lib/cgflix/cgflix_style.dart:25-37`: 150/250/300/350/600 ms com `Curves.easeOutCubic`, perto do "emphasized decelerate" do M3 (`Cubic(0.05, 0.7, 0.1, 1.0)`) e dentro de short/medium. Faltam respeitar `MediaQuery.disableAnimationsOf` (veja Acessibilidade) e o voltar preditivo (seção 3). |

## 8. Desempenho

| Item | Referência | Situação | O que foi feito / o que falta |
|---|---|---|---|
| Imagens no tamanho exibido, com cache | https://developer.android.com/topic/performance/graphics · https://docs.flutter.dev/perf/best-practices | **OK** | Todas as imagens do CGFLIX passam por `OptimizedMediaImage` (`cgflix_cards.dart:244-251,317-325`, `cgflix_hero.dart:96-103`, `cgflix_preview_sheet.dart:132-138`). Ela pede ao servidor a imagem já redimensionada (`maxWidth`/`width` × DPR, `lib/utils/media_image_helper.dart:181-186,244-268`), decodifica redimensionada (`optimized_media_image.dart:303-363`) e guarda em disco com `cached_network_image_ce`. O orçamento do cache de imagens é por aparelho (`main.dart:977`). |
| Listas preguiçosas | https://docs.flutter.dev/perf/best-practices#build-and-display-frames-in-16ms | **OK** | As fileiras horizontais usam `ListView.separated` com construtor (`cgflix_cards.dart:156-163`). As fileiras de gênero usam `SliverList.builder` (`home/cgflix_home_screen.dart:549`). As fileiras fixas do topo são `SliverToBoxAdapter` (poucas, OK). "Buscas recentes" é uma `Column` em `SingleChildScrollView` (`cgflix_search_extras.dart:101-135`), com no máximo 8 itens, OK. O perfil usa `SliverList.list` com 3 itens, OK. |

---

## Correções baratas e seguras sugeridas para esta etapa

Todas ficam em arquivos do CGFLIX ou em 1-2 linhas marcadas `// CGFLIX`, sem reformatar código do upstream.

1. **Alvo de toque real de 48 dp** em `lib/cgflix/cgflix_navigation.dart`:
   - `_RoundIconButton` (`:280-296`): pôr o `InkWell` no `SizedBox.square(48)` (com `customBorder: const CircleBorder()`) e desenhar o círculo de 36 dp como filho decorativo (`Center` → `DecoratedBox` 36×36 com o contorno `white38`). Alternativa: `IconButton.outlined(style: IconButton.styleFrom(fixedSize: const Size.square(36), tapTargetSize: MaterialTapTargetSize.padded), …)`.
   - `_TopChip` (`:220-256`): o mesmo; o `InkWell` (ou um `GestureDetector` com `behavior: HitTestBehavior.opaque`) envolve o `SizedBox(height: 48)` e o `AnimatedContainer` de 36 dp fica só como desenho.
   - `search/cgflix_sources.dart:44-46`: `ConstrainedBox(constraints: const BoxConstraints(minHeight: 48))` em volta do `Padding`.
2. **Contraste do botão roxo**: em `cgflix_hero.dart:204` e `cgflix_preview_sheet.dart:223`, `backgroundColor: CgflixColors.accentPressed` (`#9333ea`, 5,38:1) e, no pressionado, `overlayColor` = `Color(0x1FFFFFFF)`. Outra opção: criar `CgflixColors.button = Color(0xFF9333EA)` em `cgflix_style.dart` e manter `#a855f7` para ícones e destaques (5,11:1 sobre o preto, OK).
3. **Película da navegação de 3 botões**: em `cgflix_theme.dart:92`, apagar `systemNavigationBarContrastEnforced: false` (ou trocar para `true`); na navegação por gestos não muda nada.
4. **Destaque acessível**: em `cgflix_hero.dart:54-58`, `_restartTimer()` sai cedo quando `MediaQuery.accessibleNavigationOf(context) || MediaQuery.disableAnimationsOf(context)`. Como `initState` não tem `context` com `MediaQuery`, mova a primeira chamada para `didChangeDependencies`.
5. **Transição respeitando "remover animações"**: em `CgflixPageTransitionsBuilder.buildTransitions` (`cgflix_theme.dart:23-39`), `if (MediaQuery.disableAnimationsOf(context)) return child;`.
6. **Cartões com foco** (teclado/controle): em `CgflixPressable` (`home/cgflix_cards.dart:195-218`), envolver com `FocusableActionDetector(actions: {ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) => widget.onTap?.call())}, onShowFocusHighlight: …)` e desenhar um contorno roxo de 2 dp quando focado.
7. **Backup sem credenciais**: criar `android/app/src/main/res/xml/cgflix_data_extraction_rules.xml`
   (`<data-extraction-rules><cloud-backup><exclude domain="sharedpref" path="."/><exclude domain="database" path="."/></cloud-backup><device-transfer><exclude domain="sharedpref" path="."/><exclude domain="database" path="."/></device-transfer></data-extraction-rules>`)
   e `cgflix_backup_rules.xml` (`<full-backup-content><exclude domain="sharedpref" path="."/><exclude domain="database" path="."/></full-backup-content>`). No `<application>` (`AndroidManifest.xml:34`) acrescentar
   `android:dataExtractionRules="@xml/cgflix_data_extraction_rules" android:fullBackupContent="@xml/cgflix_backup_rules"`.
   Mais simples ainda: `android:allowBackup="false"`, mas, com targetSdk ≥31, isso não bloqueia a transferência entre aparelhos. Por isso as regras são o caminho certo.
8. **Voltar preditivo, decisão explícita**: no `<activity>` (`AndroidManifest.xml:46`), `android:enableOnBackInvokedCallback="false"` **provisório**, para o comportamento ser igual do Android 13 ao 16 enquanto não houver teste numa TV box. O plano de destino é `"true"` com `CgflixPageTransitionsBuilder` delegando ao `PredictiveBackPageTransitionsBuilder` durante o gesto (ou envolvendo-o). Corrigir também a frase de `CGFLIX.md:102` e o comentário de `cgflix_theme.dart:12`.
9. **Som da abertura fora da thread principal**: em `CgflixIntroSoundChannel.kt:34-44`, trocar `MediaPlayer.create` por `MediaPlayer()` + `setDataSource(context.resources.openRawResourceFd(R.raw.cgflix_intro))` + `setOnPreparedListener { it.start() }` + `prepareAsync()`, com `USAGE_ASSISTANCE_SONIFICATION`.
10. **Fonte grande**: em `home/cgflix_cards.dart:349-350`, `maxScaleFactor: 1.2` → `1.5` e `titleBlockHeight` calculado como `44 * MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 1.5).scale(1)` (e a altura da fileira acompanhando, em `CgflixRow`).
11. (Opcional, 1 linha) remover `REORDER_TASKS` (`AndroidManifest.xml:15`), que não é usada.
