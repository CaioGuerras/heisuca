# CGFLIX — o que mudou em relação ao Plezy

O CGFLIX é um fork do [Plezy](https://github.com/edde746/plezy) (GPL-3.0). A regra é **diferença mínima**: tudo que é nosso
fica em arquivos próprios e os arquivos do upstream recebem só ganchos de uma linha, para puxar as atualizações sem conflito.
Licença e créditos do Plezy continuam no `LICENSE`, no README e na tela "Sobre".

## Etapa 0 — arquivos alterados/criados

| Arquivo | Mudança |
|---|---|
| `lib/cgflix/cgflix_defaults.dart` (novo) | idioma padrão (português) e constantes do CGFLIX (cabeçalho da Início, busca) |
| `lib/services/settings_service.dart` | `_AppLocalePref.resolvedDefault` chama `cgflixResolveDefaultLocale` |
| `android/app/build.gradle.kts` | `applicationId = br.com.docaio.cgflix` (o `namespace`/pacote Kotlin continua `com.edde746.plezy`); release sem keystore assina com a chave de debug |
| `android/app/src/main/AndroidManifest.xml` | nome exibido "CGFLIX"; autoridades dos providers trocadas para o novo applicationId (evita conflito com o Plezy instalado) |
| `android/.../ExternalPlayerChannel.kt`, `SystemShelfArtworkProvider.kt` e seus testes | mesma troca das autoridades `fileprovider` / `systemshelf.artwork` |
| `android/app/src/main/res/` | ícone adaptativo (fundo `#07060a`, emblema "C com play" em vetor), ícone monocromático, mipmaps legados, banner de TV, cores do splash `#07060a` |
| `.github/workflows/cgflix-android.yml` (novo) | gera o APK de release (push no `main` e PRs; somente leitura, sem segredos) |
| `.github/workflows/cgflix-release.yml` (novo) | em tags `v*` compila, assina com keystore dos secrets (se houver) e anexa à Release |
| `.github/workflows/build.yml`, `update-packages.yml` | neutralizados fora do repositório `edde746/plezy` (usam segredos de assinatura, Sentry, winget que não temos) |
| `README.md`, `CGFLIX.md` | aviso do fork e esta página |

Mantidos de propósito: o esquema de deep link `plezy://` e a pasta de código `com.edde746.plezy` (renomear geraria conflito em todo merge).

## Etapa 1A — ajustes do teste no aparelho

O servidor **não** vem mais pré-preenchido (segurança): o campo do Jellyfin começa vazio, com a dica `https://seu.servidor.com`;
`add_jellyfin_screen.dart` voltou a ser idêntico ao upstream.

| Arquivo | Mudança |
|---|---|
| `lib/cgflix/cgflix_logo.dart`, `assets/cgflix_emblema.svg`, `pubspec.yaml` | emblema CGFLIX nas telas de marca (splash do Flutter, entrada, Sobre) |
| `lib/main.dart`, `lib/screens/auth_screen.dart`, `lib/screens/settings/about_screen.dart` | trocam o logo do Plezy pelo `CgflixEmblem` |
| `lib/screens/auth_screen.dart` | entrada só com Jellyfin (destaque) e Plex; QR/navegador do Plex dentro do fluxo do Plex; Emby não é oferecido (código mantido) |
| `lib/media/media_browser_dialect.dart` | dica neutra do campo de servidor |
| `lib/services/jellyfin_auth_header.dart`, `plex_client.dart`, `plex_auth_service.dart`, `plex_discover_client.dart`, `models/plex/plex_config.dart` | nome do app no servidor: `CGFLIX`, `CGFLIX Android`, `CGFLIX Android TV`; `X-Plex-Product: CGFLIX` |
| `lib/screens/video_player/parts/playback_services.dart` | cancela o tracker de progresso antigo antes de recriar (evita sessão duplicada) |
| `lib/screens/discover_screen.dart`, `lib/cgflix/cgflix_advanced.dart` | Início sem Recarregar/Assistir juntos/Controle remoto; puxar para atualizar; os dois recursos vão para Avançado |
| `lib/widgets/settings_section.dart`, `lib/widgets/settings_page.dart`, `lib/cgflix/cgflix_collapsible.dart` | seções recolhíveis (cartões) nas Configurações |
| `lib/screens/settings/{settings,general_settings,appearance_settings,playback_settings}_screen.dart` | usam as seções recolhíveis; cartão Avançado; mpv só em Avançado |
| `lib/services/settings_service.dart` | padrões: tema OLED, áudio/legenda do servidor (`followServerTrackSelections`), idioma português |
| `lib/cgflix/cgflix_about.dart` | dedicatória e crédito ao Plezy no Sobre |
| `lib/mixins/debounced_media_search.dart`, `lib/services/data_aggregation_service.dart`, `lib/utils/search_relevance.dart` | busca: debounce 300 ms, 5 pessoas por termo, teto de 40 resultados |
| `lib/i18n/*.i18n.json` e `strings_*.g.dart` | `app.title` = CGFLIX em todos os idiomas; português sem "Plezy" (regenerado com `dart run slang`) |
| `docs/CONFIGURACOES.md` | cada opção, onde ficou e o padrão |

Ao sincronizar com o upstream, os conflitos novos esperados estão nesses arquivos; conferir `grep -rn "CGFLIX" lib`.

## Etapa 1B — redesenho (versão 1.0.0, versionCode 200)

Tudo novo fica em `lib/cgflix/`; os arquivos do upstream recebem só ganchos marcados com `// CGFLIX`.

| Arquivo | Mudança |
|---|---|
| `pubspec.yaml` | `version: 1.0.0+200` (a Play já tinha o 152 da 1A) |
| `lib/cgflix/cgflix_version.dart`, `lib/screens/settings/about_screen.dart` | Sobre mostra "CGFLIX 1.0.0" (a chave `about.versionLabel` segue no leitor de tela) |
| `lib/cgflix/cgflix_style.dart` (novo) | cores e movimento (250–350 ms, ease-out) das telas novas |
| `lib/cgflix/cgflix_navigation.dart`, `lib/cgflix/cgflix_you_screen.dart` (novos) | barra do celular **Início · Buscar · Baixados · Você**; "Você" = perfil, Configurações, Sobre |
| `lib/screens/main_screen.dart` | ganchos: abas do celular, aba "Você" e Início do CGFLIX (só celular; TV/computador iguais ao upstream) |
| `lib/cgflix/home/` (novos) | Início "só o nosso acervo": destaque, Continuar, Em alta (Top 10), Lançamentos, Novos episódios, Novidades, gêneros, chips Filmes/Séries/Animes, prévia em painel, cache no aparelho |
| `lib/services/jellyfin_client.dart` | 1 linha: `part` de `lib/cgflix/home/cgflix_jellyfin_queries.dart` (consultas da Início) |
| `lib/services/jellyfin_client/parts/images_downloads.dart` | imagens dimensionadas pedem `quality=80` |
| `lib/cgflix/cgflix_detail.dart` (novo), `lib/screens/media_detail_screen.dart` | página do título: Hero do pôster, botão "Assistir"/"Continuar S02E05", selos Dublado/Legendado, rótulos alinhados |
| `lib/i18n/pt.i18n.json` + `strings_pt.g.dart` | "Mais como este" |
| `test/screens/media_detail_screen_test.dart` | 4 expectativas do rótulo do botão (S1E2 → "Continuar S01E02") |
| `lib/cgflix/cgflix_intro.dart` (novo), `lib/main.dart` | abertura animada (~1,4 s) no splash do Flutter; espera a animação antes da Início; pula em aberturas < 30 s |
| `lib/screens/settings/settings_screen.dart` | chave "Som da abertura" (Android) |
| `android/.../res/drawable/splash_icon.xml`, `values-v31/styles.xml`, `values-night-v31/styles.xml` | ícone animado da Splash Screen API (Android 12+) |
| `android/.../CgflixIntroSoundChannel.kt` (novo), `MainActivity.kt` (1 linha), `res/raw/cgflix_intro.wav` | "tum" da abertura, só fora do silencioso/vibrar |
| `cgflix-brand/som/gerar_tum.py` (novo) | gera o `cgflix_intro.wav` (som procedural, sem direitos de terceiros) |
| `docs/prints/` | quadros da abertura |

**Em alta no Brasil**: o app lê `GET <servidor>/cgflix/emalta.json` no formato
`{"titulo": "...", "itens": [{"id": "<id do Jellyfin>", "nome": "...", "tipo": "Movie|Series"}]}` (já ordenado). Se o arquivo
não existir, usa a coleção do Jellyfin chamada "Em alta no Brasil"; se nenhum dos dois existir, a linha some. Vale 1 h no aparelho.

## Etapa 1C — remodelagem (versão 1.1.0, versionCode 300)

Pedido do dono depois do 1.0.0 (200) no motorola edge 70: busca sem repetição, navegação sem nada duplicado e visual
mais polido e integrado ao Android. Ordem de serviço em `docs/ORDEM_1C.md`.

| Arquivo | Mudança |
|---|---|
| `pubspec.yaml` | `version: 1.1.0+300`; fonte **Inter** (pesos 400–800) |
| `assets/fonts/Inter-*.ttf`, `Inter-LICENSE.txt` (novos) | Inter 4.1 (licença OFL, igual ao site) |
| `lib/cgflix/search/cgflix_search_grouping.dart` (novo) | agrupa a busca: títulos por tmdb/imdb/tvdb/guid `plex://` ou título normalizado + ano + tipo (IDs conflitantes nunca juntam); pessoas pelo nome; fonte preferida = CGFLIX → progresso → resolução → ordem; ordem Títulos → Pessoas → Coleções |
| `lib/cgflix/search/cgflix_sources.dart` (novo) | seletor "Disponível em N servidores" na página do título; filmografia da pessoa juntando todos os servidores |
| `lib/cgflix/search/cgflix_search_extras.dart` (novo) | buscas recentes, "Pedir" (Seerr) quando não acha nada, esqueleto no lugar do círculo |
| `lib/screens/search_screen.dart` | ganchos: resultado unificado, sem nome de servidor, histórico, Pedir, esqueleto, sem barra de título no celular |
| `lib/services/jellyfin_client/parts/browse.dart` | busca pede `ProviderIds` (1 linha) |
| `lib/screens/media_detail_screen.dart` | 1 linha: seletor de servidor acima da sinopse |
| `lib/screens/actor_media_screen.dart` | gancho: filmografia de todos os servidores |
| `lib/screens/catalog_search_screen.dart` | `initialQuery` (o "Pedir" abre com o termo) |
| `lib/cgflix/cgflix_navigation.dart` | barra compacta só com ícones (60 dp, sem rótulos, TalkBack/dica com o nome), translúcida com desfoque, indicador roxo, háptico; `CgflixAboveNavBar` |
| `lib/screens/main_screen.dart` | ganchos: `extendBody` e a barra do CGFLIX no celular; Baixados termina acima da barra |
| `lib/cgflix/home/cgflix_home_screen.dart` | sem avatar; chips filtram a própria Início (× volta a Tudo, troca de 300 ms); topo some ao rolar para baixo, sobre gradiente |
| `lib/cgflix/home/cgflix_home_logic.dart`, `cgflix_home_repository.dart`, `cgflix_jellyfin_queries.dart` | consultas com filtro de biblioteca (`ParentId`), cache separado por filtro |
| `lib/cgflix/cgflix_you_screen.dart` | respeita a barra translúcida |
| `lib/cgflix/cgflix_theme.dart` (novo), `lib/theme/mono_theme.dart` (1 linha), `lib/main.dart` (1 linha) | Inter, cores do site no modo OLED (`#07060a`/`#120e1a`), transições 300/250 ms ease-out no Android, barras do sistema transparentes (ponta a ponta) |
| `lib/cgflix/home/cgflix_actions.dart` | háptico leve ao tocar "Assistir" |
| `test/cgflix/*`, `test/providers/theme_provider_test.dart` | testes do agrupamento, do filtro, da barra e do histórico; fundo OLED = `#07060a` |

**Voltar preditivo** (situação até a 1.6.0; ligado na 1.6.1, ver o refino 2b abaixo): o `android:enableOnBackInvokedCallback` continuava sem declarar: com ele, o Android deixa de entregar a tecla VOLTAR do controle remoto como tecla, e a navegação da TV
do upstream depende disso. Continua pendente na 1D (precisa de teste numa TV box; ver `docs/cgflix/AUDITORIA_GOOGLE_1D.md`).

## Etapa 1D — barra única no topo, paisagem, tema único e auditorias (versão 1.2.0, versionCode 400)

Pedido do dono depois do 1.1.0 (300) no motorola edge 70: acabar com a barra inferior, alinhar os chips, tirar o botão
Início, um tema só e funcionar deitado. Mais as auditorias (Google, telas, código) e a dedicatória em destaque.

**Causa da tela preta deitado**: a altura do destaque da Início era `clamp(360, altura × 0,68)`; deitado, 68% da altura fica
abaixo de 360, o `clamp` lança `ArgumentError` e o `ErrorWidget` do release pinta a tela de preto. O trilho lateral do
upstream em paisagem também não conhecia as abas do CGFLIX.

| Arquivo | Mudança |
|---|---|
| `pubspec.yaml`, `lib/cgflix/cgflix_version.dart` | `version: 1.2.0+400` |
| `lib/cgflix/cgflix_layout.dart` (novo) | altura do destaque em pé e deitado (sem a exceção), destaque compacto |
| `lib/cgflix/cgflix_navigation.dart` | barra única do topo (`CgflixTopBar`): emblema = menu do usuário; chips, Busca e Pedir alinhados (36 dp de desenho, 48 dp de toque, 12 dp entre todos) e centralizados na tela; só os chips rolam em tela estreita; páginas (`CgflixPages`) de Busca, Baixados, Configurações e Pedir; topo sem conexão; Configurações escondidas no celular |
| `lib/cgflix/cgflix_user_menu.dart` (novo), `cgflix_you_screen.dart` (removido) | menu do usuário: Trocar perfil/usuário, Baixados, Configurações, Sobre, Sair, com a dedicatória |
| `lib/screens/main_screen.dart` | ganchos: celular sem barra inferior nem trilho lateral (também deitado); sem conexão, Baixados com topo próprio; Seção inicial ignorada no celular |
| `lib/screens/search_screen.dart` | 1 linha: aberta por cima da Início, mostra a barra com Voltar |
| `lib/cgflix/home/cgflix_home_screen.dart`, `cgflix_hero.dart` | topo = `CgflixTopBar`; destaque compacto deitado; rodapé com a dedicatória; destaque parado com TalkBack/"remover animações"; linha que falha some (não fica no esqueleto) |
| `lib/cgflix/home/cgflix_home_repository.dart` | emite vazio quando o cache vazio + rede fora; teto de 30 s |
| `lib/cgflix/cgflix_theme.dart`, `lib/main.dart`, `settings/appearance_settings_screen.dart` | tema único `cgflixAppTheme()` (OLED fixo, mesmo com o Android claro); sem escolha de tema; transição seca com "remover animações"; película na navegação de 3 botões |
| `lib/cgflix/cgflix_about.dart`, `cgflix_advanced.dart`, `lib/main.dart` | dedicatória na abertura, no menu e no rodapé da Início; Avançado › "Mostrar dedicatória" (padrão ligado); carregamento roxo |
| `settings/appearance_settings_screen.dart`, `general_settings_screen.dart` | 1 linha cada: no celular somem Tela inicial, Navegação, TV ao vivo e Seção inicial |
| `settings/logs_screen.dart`, `lib/cgflix/cgflix_defaults.dart` | sem "Enviar logs" para o servidor do Plezy (`cgflixAllowLogUpload`) |
| `android/app/src/main/AndroidManifest.xml` | `allowBackup="false"`; `plezy://play`/`live` sem `BROWSABLE` |
| `lib/cgflix/search/cgflix_search_extras.dart`, `cgflix_sources.dart` | Pedir da busca rola deitado e leva a conectar o Seerr; prazo de 10 s por servidor na filmografia; 48 dp no seletor |
| `lib/cgflix/home/cgflix_actions.dart`, `cgflix_preview_sheet.dart`, `cgflix_detail.dart` | "Assistir" em `#9333ea` (contraste 5,4:1) e 48 dp; episódio sempre "T2:E5"; prazo de 10 s |
| `lib/i18n/pt.i18n.json` + `strings_pt.g.dart` | 52 textos que caíam no inglês; "Baixados"; "Classificação indicativa"; aviso das 2 telas |
| `.github/workflows/cgflix-android.yml` | job novo **Emulador**: Android 34 com tela do edge 70, roteiro, giro e capturas (artifact `cgflix-capturas`) |
| `scripts/cgflix/emulador_navegacao.py`, `test_emulador_navegacao.py` (novos) | roteiro (uiautomator/adb), detector de tela preta e filtro do logcat (só biblioteca padrão) |
| `test/cgflix/emulador/app_navegacao.dart` (novo) | app de teste do emulador: peças reais do CGFLIX, dados falsos, sem servidor |
| `test/cgflix/*`, `test/screens/...` | barra do topo em 360/412/800 dp em pé e deitado, menu, Voltar, Pedir, destaque, dedicatória, tema; testes do upstream olham as Configurações completas |
| `docs/cgflix/AUDITORIA_GOOGLE_1D.md`, `REVISAO_TELAS_1D.md`, `AUDITORIA_CODIGO_1D.md` (novos) | relatórios E, F e H |

## Etapa 1E — busca com pedidos embutidos, categorias certas e limpeza (versão 1.3.0, versionCode 500)

Pedido do dono depois do 1.2.0 (400): pedidos dentro da busca sem tela de login, Filmes/Séries/Animes
sem misturar, dedicatória só no Sobre, som de abertura no Avançado, Serviços só com o Trakt e sem
"Plezy", e a Início sem "Novos episódios". Ordem de serviço em `docs/ORDEM_1E.md`.

**Por que os Pedidos caíam no login do Seerr**: o ícone "Pedir" da 1C/1D abria a tela de conectar do
upstream (`SeerrConnectScreen`) sempre que não havia sessão salva; não existia entrada automática.
Agora o app acha o Seerr ao lado do Jellyfin (troca o primeiro nome do domínio: `netflix.docaio.com.br` →
`pedidos.docaio.com.br`; tenta também `seerr.`, `jellyseerr.`, `requests.`, `overseerr.`), chama
`POST /api/v1/auth/jellyfin/quickconnect/initiate`, aprova o código no Jellyfin com o token da própria
pessoa (`POST /QuickConnect/Authorize`) e troca o secret pelo cookie `connect.sid`
(`.../quickconnect/authenticate`). Nada de servidor pré-preenchido no código.

**Por que as categorias trocavam**: "Em alta" da categoria pedia `/Items?Ids=...&ParentId=<biblioteca>`, mas o
Jellyfin ignora o `ParentId` quando recebe `Ids`; o filtro de reserva era pelo tipo do item, e "Series"
serve para Séries e Animes. O "Continuar assistindo" filtrava pelo tipo porque os itens do Jellyfin não
trazem a biblioteca. Agora tudo é pela biblioteca (`ParentId`) e o "Em alta" vem do ranking da categoria.

| Arquivo | Mudança |
|---|---|
| `pubspec.yaml`, `lib/cgflix/cgflix_version.dart`, `test/cgflix/cgflix_version_test.dart` | `version: 1.3.0+500` |
| `lib/cgflix/requests/cgflix_seerr.dart` (novo) | Seerr sem login: acha o endereço, Quick Connect automático, cookie no armazenamento seguro, renova em 401/403; busca (status 1/ausente = pedir, 2 = "Pedido", 3 = "Baixando", 4/5 não repetem), temporadas, pedido, "Meus pedidos" |
| `lib/cgflix/requests/cgflix_requests_ui.dart` (novo) | seção "Disponível para pedir", escolha de temporadas (padrão: todas), confirmação "Pedido feito. Avisamos quando chegar.", aviso "Pedidos indisponíveis agora", tela "Meus pedidos" |
| `lib/cgflix/requests/cgflix_secure_store.dart` (novo), `android/.../CgflixSecureStoreChannel.kt` (novo), `MainActivity.kt` (1 linha) | armazenamento seguro: AES-GCM com chave do Android Keystore (sem dependência nova); fora do Android, só memória |
| `lib/cgflix/home/cgflix_jellyfin_queries.dart` | `cgflixAuthorizeQuickConnect`, `cgflixBaseUrl`, `cgflixFetchContinueWatchingIn` (Resume + NextUp com `ParentId`) |
| `lib/cgflix/search/cgflix_search_extras.dart`, `lib/screens/search_screen.dart` (1 linha) | "Disponível para pedir" abaixo dos resultados e no "nada encontrado"; sem botão de conectar |
| `lib/cgflix/cgflix_navigation.dart` | barra: emblema · Filmes · Séries · Animes · Busca (sai o "Pedir"); `cgflixOpenMyRequests`; medida dos chips conta a borda |
| `lib/cgflix/cgflix_user_menu.dart` | "Meus pedidos" no menu; sem a dedicatória |
| `lib/cgflix/home/cgflix_home_logic.dart`, `cgflix_home_repository.dart`, `cgflix_home_screen.dart` | `porBiblioteca` do emalta.json; "Em alta" por categoria (some com menos de 3); Continuar da categoria pelo servidor; sem "Novos episódios"; sem a dedicatória no rodapé |
| `lib/cgflix/cgflix_about.dart`, `cgflix_advanced.dart`, `lib/main.dart` | dedicatória só no Sobre; saem o interruptor e a preferência `cgflix_show_dedication` |
| `lib/cgflix/cgflix_intro.dart`, `cgflix_advanced.dart`, `settings/settings_screen.dart`, `CgflixIntroSoundChannel.kt` | "Som de abertura" no Avançado; `MediaPlayer.create` fora da thread de UI |
| `lib/cgflix/cgflix_trakt.dart` (novo) | credenciais do Trakt por `--dart-define`; só o Trakt nos Serviços; comentários do Trakt na página do título |
| `lib/services/trackers/trakt/trakt_constants.dart` | client id/secret = os do build (sem o do Plezy) |
| `lib/services/trackers/{mal,mdblist,simkl}/*_constants.dart` | chaves do Plezy removidas (serviços escondidos) |
| `lib/screens/settings/tracker_service_info.dart`, `services_settings_screen.dart`, `settings_screen.dart`, `lib/screens/media_detail_screen.dart` | 1 gancho cada: lista filtrada, sem a linha do Seerr, item Serviços só com o Trakt, comentários |
| `.github/workflows/cgflix-android.yml`, `cgflix-release.yml` | `--dart-define=TRAKT_CLIENT_ID/TRAKT_CLIENT_SECRET` a partir dos secrets `CGFLIX_TRAKT_CLIENT_ID`/`CGFLIX_TRAKT_CLIENT_SECRET`; nome do passo do roteiro |
| `test/cgflix/emulador/app_navegacao.dart`, `scripts/cgflix/emulador_navegacao.py` | roteiro: barra sem "Pedir", Filmes/Séries/Animes, busca com "Disponível para pedir" (Seerr falso), Pedir, Meus pedidos |
| `test/cgflix/cgflix_seerr_test.dart`, `cgflix_request_section_test.dart`, `cgflix_categorias_test.dart`, `cgflix_trakt_test.dart` (novos) e testes ajustados | Seerr de mentira (disponível, pedido, baixando, fora do ar, 401 que renova), telas, 3 bibliotecas falsas, Trakt sem secrets; `settings_screen_test`/`rating_bottom_sheet_test` do upstream ligam `cgflixDebugShowAllServices` |
| `docs/CONFIGURACOES.md`, `docs/ORDEM_1E.md` | Serviços, som de abertura, dedicatória; ordem de serviço |

**Em alta por categoria**: o `emalta.json` pode trazer `"porBiblioteca": {"filmes": [...], "series": [...], "animes": [...]}`
(até 10 itens `{"id","nome","tipo","biblioteca"}` cada, na ordem do ranking). Sem esse campo, o app filtra os `itens`
pelo campo `biblioteca`; sem nenhum dos dois, Filmes separa pelo tipo e Séries/Animes escondem a linha.

### Trakt: o que o dono precisa fazer (uma vez)

1. Entrar em <https://trakt.tv/oauth/applications> com a conta do CGFLIX e clicar em **New Application**.
2. **Name**: `CGFLIX`. **Description**: "App do CGFLIX (servidor de família)". Ícone: `cgflix-brand/cgflix-icone-512.png`.
3. **Redirect uri**: `urn:ietf:wg:oauth:2.0:oob` (o app entra pelo código de aparelho em `trakt.tv/activate`; não abre
   navegador de volta para o app). Deixe **Javascript (cors) origins** vazio e marque só o necessário (`/checkin` e `/scrobble`).
4. Salvar e copiar o **Client ID** e o **Client Secret**.
5. No GitHub: repositório `cgflix-app` › Settings › Secrets and variables › Actions › **New repository secret**:
   `CGFLIX_TRAKT_CLIENT_ID` = Client ID e `CGFLIX_TRAKT_CLIENT_SECRET` = Client Secret.
6. Rodar de novo o workflow "CGFLIX Android" (ou fazer um push): o APK novo mostra **Configurações › Serviços › Trakt**.
   Sem os secrets, o Trakt fica escondido (o app nunca usa a chave do Plezy).

## Tema Heitor (claro, verde) e escolha de tema (versão 1.4.0, versionCode 600)

O app tinha um tema só, **Isis** (escuro, preto e roxo). Entra o **Heitor**: claro (fundo `#f4fcee`, nunca
branco puro), verde no lugar do roxo e logo própria. Escolha em **Configurações → Aparência → Tema**:
Isis (escuro, roxo) / Heitor (claro, verde) / Automático (segue o aparelho). Padrão: Isis. Fica guardado no
aparelho (preferência `themeMode` do upstream: Isis = `oled`, Heitor = `light`, Automático = `system`) e troca na
hora. TV fica sempre Isis; **player, abertura do vídeo e controles do player são sempre escuros**.

Paleta do Heitor (Material 3, semente `#34C759`, `SchemeContent`, escrita à mão): surface `#f4fcee`, cartões
`#ffffff`, barras `#e8f0e3`/`#e2ebde`, texto `#161d16` (16,4:1) e `#3d4a3c` (8,9:1), primary `#006e28` (botões, aba
ativa, foco), primaryContainer `#34c759`, secondaryContainer `#b0efb0`, outline `#6d7b6b`/`#bccbb8`, tertiary
`#006495`, error `#ba1a1a`. Contraste conferido em `test/cgflix/cgflix_contraste_test.dart`.

| Arquivo | Mudança |
|---|---|
| `pubspec.yaml`, `lib/cgflix/cgflix_version.dart`, `test/cgflix/cgflix_version_test.dart` | `version: 1.4.0+600`; asset `cgflix_emblema_heitor.svg` |
| `lib/cgflix/cgflix_palette.dart` (novo) | `ColorScheme` Isis (fundo `#000`, OLED) e Heitor; `CgflixPalette` (`ThemeExtension`: véus sobre foto, vidro da barra, estados, foco, selos, sombra dos cartões, degradês e emblema da marca) e o atalho `context.cgflix` |
| `lib/cgflix/cgflix_theme.dart`, `lib/main.dart` | `cgflixAppTheme(variante)`; Heitor com botões, campos, abas, navegação (ícone ativo preenchido em `primary`), chips, barras do sistema com ícones escuros; `cgflixAlwaysDark` (player), `cgflixSystemBars` |
| `lib/cgflix/cgflix_theme_picker.dart` (novo), `settings/appearance_settings_screen.dart`, `settings/settings_screen.dart` | linha "Tema" (Isis / Heitor / Automático) e o nome do tema no resumo da Aparência |
| `lib/utils/video_player_navigation.dart` | player sempre escuro (1 linha) |
| `lib/cgflix/cgflix_navigation.dart`, `cgflix_logo.dart`, `cgflix_intro.dart`, `cgflix_about.dart`, `cgflix_detail.dart`, `cgflix_user_menu.dart`, `cgflix_trakt.dart`, `home/*`, `search/*`, `requests/cgflix_requests_ui.dart` | nenhuma cor solta: tudo de `context.cgflix`; véu claro no destaque e na prévia, barra do topo translúcida, sombra suave nos cartões (no lugar do brilho roxo), emblema Heitor, abertura animada nas cores do tema, coração roxo + verde nos dois temas |
| `cgflix-brand/heitor/*` (novo), `gerar_heitor.py`, `assets/cgflix_emblema_heitor.svg` | marca Heitor: o mesmo desenho, só a troca de cores da ordem |
| `android/.../res/drawable/splash_icon_heitor.xml` (novo), `drawable-television/…`, `values*/colors.xml`, `values*-v31/styles.xml`, `shared/ThemeHelper.kt` (1 linha) | abertura do sistema segue o aparelho: escura com a marca Isis, clara (`#f4fcee`) com a Heitor; TV sempre Isis |
| `cgflix-brand/gerar_icone_android.py` (novo), `drawable/ic_launcher_foreground.xml`, `ic_launcher_monochrome.xml`, `mipmap-*/ic_launcher.png` | ícone adaptativo: emblema a 70% da zona segura (escala 0,529), nada fora dela, fundo `#07060a`, camada monocromática (Android 13+); ícone único (Isis) |
| `test/cgflix/cgflix_contraste_test.dart`, `cgflix_temas_telas_test.dart` (novos), `cgflix_theme_test.dart` | contraste (texto ≥ 4,5:1, bordas/ícones ≥ 3:1); Início, Detalhes, Configurações e Login nos dois temas; troca na hora |
| `test/cgflix/emulador/app_navegacao.dart`, `scripts/cgflix/emulador_navegacao.py` | app de teste segue o modo do aparelho; roteiro captura Início, título, Configurações e Entrada nos dois temas (`heitor-*`) |

## Refino 1: paridade com o CGFLIX Lite (versão 1.5.0, versionCode 700)

O que o irmão leve (`cgflix-lite`, 1.4.0–1.4.2) ganhou e fazia falta aqui, no jeito Flutter (sem copiar Kotlin
e **sem o Modo Maryanne**), mais uma passada de acabamento no app inteiro. Ordem de serviço: "refino 1".

| Item | Mudança | Arquivos |
|---|---|---|
| Versão | `1.5.0+700` | `pubspec.yaml`, `lib/cgflix/cgflix_version.dart`, `test/cgflix/cgflix_version_test.dart` |
| A. Apoie o CGFLIX | Tela própria com Pix: BR Code **estático** do Banco Central (EMV 00/26/52/53/58/59/60/62/63, CRC16-CCITT `0xFFFF`), sem valor, QR desenhado no app (`qr_flutter`, já era dependência), "Copiar Pix copia e cola" e "Copiar chave". Gorjeta opcional: sem pop-up, sem lembrete, não destrava nada. Entradas: último item das Configurações, último item do menu do usuário (coração rosa `#ec4899` nos dois temas) e uma linha discreta no Sobre. **Para trocar a chave: só `apoio_pix.dart`** (mesma chave, nome e cidade do Lite). O Liberapay do autor do Plezy nunca aparece (`cgflixHidesUpstreamDonation`), com ou sem `ENABLE_DONATIONS` | `lib/cgflix/apoio/` (`apoio.dart` = interface `Apoio`, `apoio_pix.dart`, `br_code.dart`, `apoio_pix_view.dart`, `cgflix_apoio_screen.dart`), `lib/cgflix/cgflix_defaults.dart`, `lib/services/donation_service.dart` (1 linha), `settings/settings_screen.dart` (1 linha), `settings/about_screen.dart` (1 linha) |
| A. Play | A tela fala com a interface `Apoio` (`disponivel`, `conteudo`). `--dart-define=CGFLIX_APOIO=play` troca o Pix por "sem apoio" e o compilador tira o Pix do pacote. O **AAB da Play já sai assim** (a política da Play proíbe Pix/link externo para coisa digital); o APK do GitHub/servidor tem Pix. **Play Billing não foi feito**: quando for, é uma classe nova que implementa `Apoio` para o sabor `play` (produtos como no Lite: `gorjeta_pequena`, `gorjeta_media`, `gorjeta_grande`) | `.github/workflows/cgflix-android.yml` |
| B. Minha conta | Só com Jellyfin conectado (no Plex e sem conexão o topo do menu não abre nada). Foto: seletor do sistema (`file_picker`, sem permissão de armazenamento), quadrado central de 512 px em JPEG com a rotação do EXIF (canal nativo), enviado em base64; "Remover foto". Senha: atual + nova + confirmar; 401/403 = "Senha atual errada… a conta é bloqueada depois de várias tentativas". A sessão deste aparelho continua (o servidor derruba as outras). "A senha vale para o app, o site e a TV." Rotas: primeiro as novas (`POST/DELETE /UserImage?userId=`, `POST /Users/Password?userId=`, testadas pelo Lite no 10.11.11); se o servidor responder 404/405, as clássicas `/Users/{id}/Images/Primary` e `/Users/{id}/Password`. Depois da foto, o app relê o usuário e o avatar do menu troca na hora | `lib/cgflix/conta/` (`cgflix_conta.dart`, `cgflix_minha_conta_screen.dart`), `lib/cgflix/home/cgflix_jellyfin_queries.dart` (`cgflixFetchMe`, `cgflixUploadUserImage`, `cgflixDeleteUserImage`, `cgflixChangePassword`), `android/.../CgflixPhotoChannel.kt` (novo), `MainActivity.kt` (1 linha) |
| C. Menu do usuário | Topo: foto, nome e "Minha conta: foto e senha". Ordem: Favoritos · Bibliotecas · Meus pedidos · Baixados ─ Configurações · Trocar usuário · Sobre · Sair ─ Apoie o CGFLIX. Sem conexão somem Favoritos, Bibliotecas e Meus pedidos. **Baixados e Sair ficaram** (no app completo não há outro caminho para eles). Favoritos = tela nova (grade com a "Minha lista" do Jellyfin, vazio com orientação, recarrega sem piscar ao voltar do título). Bibliotecas = a tela do upstream aberta por cima. As Bibliotecas do Plezy não tinham atalho de Favoritos: nada a tirar | `lib/cgflix/cgflix_user_menu.dart`, `lib/cgflix/you/cgflix_favorites_screen.dart` (novo), `lib/cgflix/cgflix_navigation.dart` (`CgflixPages.libraries`) |
| D. "Aperte o play" | Slogan discreto (texto suave do tema) no login e na abertura; na abertura entra depois do play do emblema; com "remover animações" aparece parado | `lib/cgflix/cgflix_slogan.dart` (novo), `lib/main.dart` (2 ganchos), `lib/screens/auth_screen.dart` (2 ganchos) |
| E. Ícone do tema | Dois `activity-alias` (`.IconeIsis`, ligado por padrão e com a entrada da TV; `.IconeHeitor`). Heitor liga o verde; Isis e Automático ficam com o roxo. A troca acontece só quando o app sai da tela (alguns aparelhos fecham o app na troca). A `MainActivity` continua exportada para o `am start -n` do CI. **Substitui a regra "ícone único"** do tema Heitor. Ícone verde gerado pelo mesmo script e enquadramento do roxo (adaptativo + monocromático + mipmaps) | `AndroidManifest.xml`, `android/.../CgflixAppIconChannel.kt` (novo), `MainActivity.kt` (1 linha), `lib/cgflix/cgflix_app_icon.dart` (novo), `lib/cgflix/cgflix_theme.dart` (1 linha), `cgflix-brand/gerar_icone_android.py`, `res/drawable/ic_launcher_foreground_heitor.xml`, `res/mipmap-anydpi-v26/ic_launcher_heitor.xml`, `res/mipmap-*/ic_launcher_heitor.png`, `res/values/colors.xml` |
| F. Textos naturais | `pt.i18n.json` revisado inteiro (998 textos; inglês intocado): "Não deu para…" + o que fazer, "Tentar de novo", "Reprodutor de vídeo", "Carregamento antecipado", "Endereços do servidor", "Avançar e voltar", sem Title Case, sem jargão. Erros de login/conexão sem a exceção crua. Ajuste de sincronia de áudio/legenda em **segundos** ("+0,15 s"; o valor guardado continua em ms). Lista completa antes → depois em `docs/cgflix/REVISAO_PT_1.5.md` | `lib/i18n/pt.i18n.json`, `strings_pt.g.dart` (`dart run slang`), `lib/cgflix/cgflix_units.dart` (novo), `lib/utils/formatters.dart` (1 linha), `docs/cgflix/REVISAO_PT_1.5.md` |
| G. Música tema / som do trailer | **Pulado**: o Plezy não toca música tema nem trailer sozinho na página do título (o trailer só toca quando a pessoa aperta o botão). Não há o que desligar | — |
| H. Login | Usuário ou senha vazios: "Preencha o usuário e a senha." sem ir ao servidor. Endereço vazio ou torto (espaço, sem nome, outro protocolo): aviso claro com o exemplo `https://seu.servidor.com` | `lib/cgflix/cgflix_login_checks.dart` (novo), `settings/add_jellyfin_screen.dart` (2 ganchos) |
| I. Testes | BR Code (CRC `1D3D` do manual do BC, payload campo a campo, limites); telas Apoie, Minha conta (conta falsa: foto, senha, 403, sem servidor), menu (ordem, sem conexão, coração rosa, deitado), Favoritos, slogan, nos dois temas; checagens do login; segundos da sincronia. Emulador: menu, Minha conta, Favoritos, Apoie e entrada com slogan, Isis e Heitor | `test/cgflix/apoio/br_code_test.dart`, `test/cgflix/cgflix_refino1_telas_test.dart`, `test/cgflix/cgflix_login_checks_test.dart`, `test/cgflix/cgflix_navigation_test.dart`, `test/cgflix/emulador/app_navegacao.dart`, `scripts/cgflix/emulador_navegacao.py` |
| J. Acabamento | Ver a tabela "Passada de acabamento" abaixo | — |

### Passada de acabamento (item J)

Auditoria tela a tela no celular, nos dois temas, olhando texto, cor, contraste, toque, leitor de tela, erro e
recarga. É acabamento: navegação e fluxos aprovados (1B–1E) não mudaram.

| Tela | O que foi corrigido | Arquivos |
|---|---|---|
| App inteiro | Textos do próprio Material em português (dica "Voltar" da seta, menu Copiar/Colar dos campos, "Fechar" do leitor de tela) — o upstream não carregava `flutter_localizations` | `lib/cgflix/cgflix_locale.dart` (novo), `lib/main.dart` (3 linhas em cada `MaterialApp`), `pubspec.yaml` |
| App inteiro | Avisos (snackbars) nas cores do tema: erro = `error`/`onError`; sucesso = aviso normal (era verde/vermelho fixos, com texto quase branco sobre verde no Heitor) | `lib/cgflix/cgflix_feedback.dart` (novo), `lib/utils/snackbar_helper.dart` (2 linhas) |
| App inteiro (Isis) | Vermelho de erro `#B00020` (2,5:1 no preto) → `#f87171`; borda dos botões com contorno e dos campos de 12% → 38% de branco (visível, 3:1) | `lib/cgflix/cgflix_palette.dart`, `test/cgflix/cgflix_contraste_test.dart` |
| Login / servidor | Olho para mostrar a senha; erro de servidores sem exceção crua; "ou" com contraste no Heitor; mensagens de campo vazio (item H) | `settings/add_jellyfin_screen.dart`, `auth_screen.dart`, `lib/cgflix/cgflix_login_checks.dart` |
| Início | Não pisca mais quando a rede responde depois do cache (o destaque não volta ao 1º título); aviso "Não deu para carregar a Início" quando o servidor está fora (antes: tela vazia); "Detalhes" com 48 dp como o "Assistir"; esqueleto visível no Heitor; aviso se "Tirar de Continuar assistindo" falhar | `lib/cgflix/home/cgflix_home_screen.dart`, `cgflix_hero.dart`, `cgflix_cards.dart` |
| Início (leitor de tela) | Posição no Top 10 ("Em alta, posição 1"); "tocar e segurar: mais opções" nos cartões | `lib/cgflix/home/cgflix_cards.dart` |
| Busca | Erro sem a exceção crua (às vezes em inglês) | `lib/screens/search_screen.dart` (1 linha) |
| Detalhes do título | Botão de download e coração/estrela com cores legíveis no Heitor (âmbar/laranja davam ~1,7:1); no Jellyfin o coração diz "Minha lista"; dica "Opções" no ⋮; "Na Minha lista" para o leitor de tela na prévia | `lib/screens/media_detail_screen.dart`, `media_detail/action_buttons.dart`, `lib/cgflix/home/cgflix_preview_sheet.dart` |
| Player | Falha com motivo curto em português ("arquivo não encontrado no servidor", "formato de vídeo que este aparelho não abre"…) no lugar da linha crua do mpv/ffmpeg (inteira só no log); destaque lilás no lugar do âmbar (folha de ajustes, timer, botão ativo); o leitor de tela diz "Assistir o próximo, 5" na contagem; "T1 E3" em português | `video_player/parts/errors.dart`, `pt.i18n.json`, `widgets/video_controls/**` (4 arquivos), `player_prompt_overlays.dart`, `video_controls_header.dart` |
| Baixados | Botões de cada linha com 48 dp (eram 36); erro e estados com as cores da paleta (azul/laranja/âmbar soltos); Retomar/Tentar de novo com servidor fora agora avisam; regra automática na cor do tema | `widgets/download_tree_view.dart`, `download_status_icon.dart`, `screens/downloads/downloads_screen.dart`, `sync_rules_screen.dart` |
| Bibliotecas / cartões | "T1 E3" (temporada) no lugar de "S1 E3" em português; mensagem dos estados vazio/erro com contraste ≥ 4,5:1 | `widgets/media_card.dart`, `libraries/folder_tree_item.dart`, `libraries/state_messages.dart` |
| Meus pedidos | Puxar para atualizar não troca a lista por um círculo (piscava); erro com botão "Tentar de novo" (antes só "puxe"); temporada sem contagem sem linha vazia | `lib/cgflix/requests/cgflix_requests_ui.dart` |
| Favoritos | Puxar para atualizar também quando está vazio | `lib/cgflix/you/cgflix_favorites_screen.dart` |
| Configurações | Linhas de um texto só com 48 dp (eram 36: cabeçalhos dos cartões, idiomas, opções); leitor de tela diz se o cartão está aberto; Avançado com o mesmo recuo dos outros cartões e respiro entre os grupos; some a chave "Relatório de erros" (não fazia nada sem `ENABLE_SENTRY`); resumo da Aparência só com o tema; abas do seletor de cor em português; diálogos numéricos sem "duração" para tamanho/opacidade; dica no apagar player externo | `widgets/focusable_list_tile.dart`, `lib/cgflix/cgflix_collapsible.dart`, `cgflix_advanced.dart`, `settings/settings_screen.dart`, `settings_utils.dart`, `external_player_screen.dart`, `pt.i18n.json` |
| Sobre | "Versão 1.5.0" (não repete "CGFLIX" logo abaixo do nome); "Gostou? Apoie o CGFLIX" com cor de botão | `lib/cgflix/cgflix_version.dart`, `lib/cgflix/apoio/cgflix_apoio_screen.dart` |
| Voltar das telas | A margem do botão também recebe o toque | `widgets/app_bar_back_button.dart` |

**Vi e decidi não mudar** (e por quê):
- Botões do topo do player: ficam com 40 dp (o 48 mudou o foco do controle remoto da TV nos testes do upstream).
- Opções do mpv: botão de remover linha com 36 dp é de propósito (cabe dentro do campo); tela técnica, só no Avançado.
- Pastas das Bibliotecas: botões Tocar/Aleatório de 36 dp ficam (mudar aumenta a altura de toda linha da árvore; visão pouco usada no celular).
- Tela de registros (logs): cinzas e laranja soltos ficam (tela de diagnóstico, no Avançado; mudar mexe em muitas linhas do upstream).
- Estilo de legenda: continua sem cartões recolhíveis (já é uma subtela curta; mudar a estrutura é redesenho).
- "AO VIVO" vermelho: só existe na TV ao vivo, que o CGFLIX não usa no celular.
- Botão Cancelar do timer de desligar em vermelho: é ação destrutiva no player (sempre escuro), contraste ok.
- Gêneros vêm do servidor: se o Jellyfin estiver com metadados em inglês, aparecem em inglês — o certo é deixar o idioma de metadados do servidor em português (sem tradução no app).
- Aba "Música" em Baixados: precisa de lógica nova (saber se há música baixada); fica para depois.
- "Download" como substantivo ("Download cancelado", "Downloads automáticos") ficou; o verbo virou "baixar" e a lista é "Baixados".

**Capturas**: o job "Emulador" do workflow guarda as telas no artifact `cgflix-capturas` (Isis e `heitor-*`,
retrato e paisagem). "Antes" = artifact da última execução no `main`; "depois" = artifact deste PR.

## Refino 2: menus, ícones, textos e dicas (versão 1.6.0, versionCode 800)

Pedido do dono (11/10): reorganizar os menus pela frequência de uso, trocar os ícones (também no player), melhorar
os textos, tirar "escuro, roxo"/"claro, verde" do lado do nome do tema e dar dicas para as funções complicadas.
Filosofia omakase: nada foi removido; o técnico só saiu da frente (Configurações › Avançado). Detalhes, tabelas e
listas completas em `docs/cgflix/REFINO_2.md`; capturas em `docs/prints/refino2/` (antes × depois, Isis × Heitor).

| Item | Mudança | Arquivos |
|---|---|---|
| Versão | `1.6.0+800` | `pubspec.yaml`, `lib/cgflix/cgflix_version.dart`, `test/cgflix/cgflix_version_test.dart` |
| A. Menu do usuário | Favoritos · Baixados · Meus pedidos · Bibliotecas ─ **Ajustes e ajuda**: Configurações · Sobre e dicas ─ **Conta**: Trocar usuário · Sair ─ Apoie o CGFLIX (último) | `lib/cgflix/cgflix_user_menu.dart` |
| A. Configurações | Topo: Ao assistir · Áudio, legenda e conta (idiomas) · Aparência · Geral; depois Baixados; Contas e servidores (fechado, com Bibliotecas e Serviços); Avançado ganha a Cópia de segurança | `settings/settings_screen.dart` (ganchos `CGFLIX`) |
| A. Ao assistir (Reprodução) | Pular abertura e próximo episódio (aberto) · Legendas (aberto) · Gestos · Avançar e voltar · Comportamento · Reprodutor · Vídeo e tela · Áudio (agora fechado) · Qualidade · Lembrar ajustes. A parte técnica de Pular abertura (capítulos, expressões regulares) foi para o Avançado | `settings/playback_settings_screen.dart`, `lib/cgflix/cgflix_advanced.dart`, `lib/cgflix/cgflix_defaults.dart` (`cgflixSkipTechInAdvanced`) |
| A. Menu do título (cartão e ⋮) | Assistir · Guardar · Marcar · Técnico · Administração · Apagar (sempre o último), com traço entre os grupos; "Detalhes técnicos do arquivo" com ícone próprio (não repete o "i" do Ver detalhes) | `lib/cgflix/cgflix_menus.dart` (novo), `lib/widgets/media_context_menu.dart` (1 gancho + 1 ícone) |
| A. Ajustes do vídeo (player) | Qualidade · Velocidade · Próximo episódio sozinho · Zoom · Desligar automaticamente ─ **Som e legenda** ─ **Imagem e técnico** | `widgets/video_controls/sheets/video_settings_sheet.dart` |
| B. Ícones | Material Symbols Rounded em todo o app (já era); chaves preenchidas quando ligadas e em contorno desligadas; player no celular com 28 dp e 48 dp de toque; engrenagem nos ajustes, `voice_selection` no áudio, `toc` nos capítulos, `playlist_play` na lista, `high_quality` na qualidade, `av_timer` no atraso do áudio, `equalizer` no nivelar volume, `description` nos detalhes do arquivo; Geral = `language`, idiomas = `voice_selection` | `lib/cgflix/cgflix_icones.dart` (novo), `widgets/video_controls/video_control_button.dart` (1 gancho), `widgets/setting_tile.dart` (1 linha) |
| C. Textos | 36 textos do `pt.i18n.json` (lista antes → depois em `docs/cgflix/REFINO_2.md`); temas só com o nome (Isis / Heitor / Automático), a descrição fica só para o leitor de tela | `lib/i18n/pt.i18n.json`, `strings_pt.g.dart`, `lib/cgflix/cgflix_theme_picker.dart`, `settings/settings_utils.dart` (`DialogOption.semanticsHint`), `lib/cgflix/cgflix_locale.dart` |
| D. Dicas | 11 dicas num arquivo só (resumo de 1 linha + 2 a 4 frases); "?" (`help`, 48 dp) que abre uma folha em Pular abertura, idiomas, Baixar só no Wi-Fi, gestos, janelinha e qualidade; dica única dos gestos no player (some sozinha em 8 s ou com um toque, não volta; guardada no aparelho); **Sobre › Dicas do CGFLIX** reúne todas e permite rever a dos gestos; respeita "remover animações" | `lib/cgflix/cgflix_dicas.dart` (novo), `settings/about_screen.dart` (1 linha), `widgets/video_controls/video_controls.dart` (1 gancho) |
| E. Padrões | **Baixar só no Wi-Fi: desligado → ligado** (protege o plano de dados). Os outros padrões ficaram (ver `docs/cgflix/REFINO_2.md`) | `lib/cgflix/cgflix_defaults.dart`, `lib/services/settings_service.dart` (1 linha) |
| F. Testes e capturas | Ordem dos menus, folha das dicas, dica do player (aparece uma vez, some, reabre pelo Sobre, sem animação), ordem de Ao assistir e do Avançado; capturas reais (fontes Inter e Symbols) com `CGFLIX_CAPTURAS=<pasta> flutter test test/cgflix/capturas/capturas_test.dart`; emulador ganha Ao assistir (tela real), dica de Pular abertura, Dicas e a dica dos gestos | `test/cgflix/cgflix_dicas_test.dart`, `cgflix_menus_test.dart`, `capturas/capturas_test.dart` (novos), testes ajustados, `test/cgflix/emulador/app_navegacao.dart`, `scripts/cgflix/emulador_navegacao.py`, `docs/prints/refino2/` |
| G. Passada final | Lista do que foi visto e ficou como está em `docs/cgflix/REFINO_2.md` | — |

**Transmitir para a TV**: o Plezy não tem Chromecast/transmissão; não há botão para trocar. A dica "Ver na TV" explica
o caminho que existe (CGFLIX na TV box com Quick Connect, ou espelhar a tela do Android).

## Refino 2b: Configurações no padrão Material 3 / Android (versão 1.6.1, versionCode 810)

Pedido do dono (11/10, depois de testar a 1.6.0): Configurações bagunçadas, técnico na frente, tema "fora" e sem cara
de Material 3. Detalhes completos (tabela item → antes → depois → por quê, checklist do sistema, o que não mudou) em
`docs/cgflix/REFINO_2B.md`; capturas antes × depois em `docs/prints/refino2b/`.

| Item | Mudança | Arquivos |
|---|---|---|
| Versão | `1.6.1+810` (instala por cima da 1.6.0, mesma chave) | `pubspec.yaml`, `lib/cgflix/cgflix_version.dart`, teste |
| Visual M3 | lista plana, cabeçalhos na cor `primary`, linhas de 56/72 dp, sem chevron, ícones de contorno, switch M3 com check (Isis lilás, Heitor verde, também fora das Configurações), números em `Slider`, cores em círculos, barra de título grande que recolhe | `lib/cgflix/cgflix_configuracoes.dart`, `cgflix_controles.dart` (novos); ganchos de 1–3 linhas em `widgets/settings_section.dart`, `settings_page.dart`, `setting_tile.dart`, `focusable_list_tile.dart`, `app_icon.dart`, `desktop_app_bar.dart`, `cgflix_theme.dart`; `cgflix_collapsible.dart` **removido** |
| Tela principal | Conta · Aparência (Tema, Idioma do app, Mais opções) · Assistir (Áudio e legenda, Estilo das legendas, Ao assistir, Qualidade, Dados móveis) · Baixados · Ajuda (Dicas, Sobre) · Avançado (subtela, fechado) · Apoie o CGFLIX | `settings/settings_screen.dart`, `lib/cgflix/cgflix_config_itens.dart` (novo) |
| Avançado | subtela por assunto: Contas e servidores, Recursos extras, Ao assistir (técnico, com a **Reprodução avançada**), Legendas (técnico), Este aparelho (Geral), Diagnóstico, Cópia de segurança | `lib/cgflix/cgflix_advanced.dart`, `settings/playback_settings_screen.dart` (`cgflixTechnical`), `general_settings_screen.dart` |
| Textos | idiomas em português ("Português", "Inglês", "Japonês"), "Original do título", "Áudio e legenda", estilo das legendas em palavras leigas, sem "salvo em CGFLIX" e sem "Adicionar a <perfil>" | `lib/cgflix/cgflix_idiomas.dart` (novo), `utils/language_codes.dart` (gancho), `account_preferences_detail_screen.dart`, `subtitle_styling_screen.dart`, `pt.i18n.json` |
| Sistema | **voltar preditivo ligado** (a página segue o dedo); cartões da Início com foco de teclado/controle; foco visível nas Configurações; opções de diálogo com semântica de botão de opção | `AndroidManifest.xml`, `cgflix_theme.dart`, `home/cgflix_cards.dart`, `settings/settings_utils.dart` |
| Testes e capturas | `cgflix_configuracoes_test.dart`, `cgflix_voltar_preditivo_test.dart`, `cgflix_cartao_foco_test.dart` (novos), testes do upstream ajustados, `capturas/configuracoes_capturas_test.dart` + `test_helpers/cgflix_config_harness.dart`; emulador com Estilo das legendas e Avançado | `test/`, `scripts/cgflix/emulador_navegacao.py`, `docs/prints/refino2b/` |
| Docs | auditoria Google reaberta item a item ("Refino 2b (1.6.1)"), `docs/CONFIGURACOES.md` com a estrutura nova | `docs/cgflix/AUDITORIA_GOOGLE_1D.md`, `docs/CONFIGURACOES.md`, `docs/cgflix/REFINO_2B.md` |

Ao sincronizar com o upstream, os ganchos novos estão nos widgets compartilhados das Configurações (lista acima); o
resto é arquivo próprio em `lib/cgflix/`.

## Como gerar o APK

- **No GitHub**: aba *Actions* → "CGFLIX Android" → artifact `cgflix-apk` (`cgflix-arm64-v8a.apk` serve para quase todos os celulares e TV box atuais; `armeabi-v7a` para aparelhos antigos de 32 bits).
- **Release**: criar a tag `v*` (ex.: `git tag v0.1.0 && git push origin v0.1.0`); o `cgflix-release.yml` anexa os APKs à Release.
- **Assinatura própria (depois)**: cadastrar os secrets `ANDROID_KEYSTORE_BASE64`, `ANDROID_STORE_PASSWORD`, `ANDROID_KEY_PASSWORD`, `ANDROID_KEY_ALIAS`. Sem eles, o APK sai assinado com a chave de debug (instala, mas **trocar a chave depois obriga a desinstalar o app**; defina o keystore antes de distribuir de verdade).
- **Local**: Flutter 3.47.1, JDK 21, Android SDK/NDK (ver `android/app/build.gradle.kts`) e `flutter build apk --release --split-per-abi`.

## Como sincronizar com o upstream

```bash
git remote add upstream https://github.com/edde746/plezy.git   # uma vez
git fetch upstream
git checkout -b sync/upstream-AAAA-MM-DD main
git merge upstream/main        # resolver conflitos mantendo os ganchos CGFLIX
flutter pub get && flutter analyze && flutter test
```

Abrir PR para o `main` **deste** repositório (nunca para o upstream). Os conflitos esperados são só nos arquivos da tabela acima.
Ao resolver, conferir `grep -rn "CGFLIX" lib android .github`.

## Próximos passos sugeridos

1. Nome "CGFLIX" também dentro do app (título, tela "Sobre") e logo na tela de entrada; textos em PT para o que ainda estiver em inglês.
2. Selos **Dublado / Legendado** nos cartões e na tela de detalhes (a partir das faixas de áudio/legenda).
3. ~~**Pedidos (Seerr)** com login por Quick Connect~~ (feito na 1E: dentro da busca, sem tela de login).
4. ~~Aviso claro em PT quando o servidor recusar o play por limite de **2 telas**~~ (feito na 1D).
4b. Selo "Novo episódio" nas capas de "Novidades em séries e animes" (a 1E só tirou a linha de episódios soltos).
5. **Atualização do app pelo nosso servidor** (o verificador de atualização do upstream fica desligado: não definimos `ENABLE_UPDATE_CHECK`).
6. Keystore próprio nos secrets; build do Windows a partir do mesmo código; iPhone depois.
7. **Play Billing** para o "Apoie o CGFLIX" no AAB da Play: uma classe nova que implementa `Apoio`
   (`lib/cgflix/apoio/apoio.dart`) escolhida com `CGFLIX_APOIO=play`; produtos como no Lite (`gorjeta_pequena`,
   `gorjeta_media`, `gorjeta_grande`), consumíveis, sem servidor de verificação. Hoje o AAB sai sem apoio.
