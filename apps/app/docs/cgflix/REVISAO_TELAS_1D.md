# Revisão das telas — Etapa 1D

Relatório tela a tela (detalhe abaixo, retrato do começo da etapa) e o que foi corrigido nesta etapa.

## Corrigido nesta etapa

| Tela | O que estava errado | Corrigido |
|---|---|---|
| Navegação (todas) | Barra inferior + chips do topo desalinhados + botão Início duplicando o Voltar | Uma barra no topo: emblema (menu do usuário) à esquerda; Filmes · Séries · Animes, Busca e Pedir alinhados (36 dp, mesma linha, 12 dp entre todos) e centralizados na tela; em tela estreita só os chips rolam |
| Paisagem (todas) | Tela preta ao girar (exceção na altura do destaque) e trilho lateral que não conhecia as abas do CGFLIX | Mesma barra do topo deitado, destaque compacto à esquerda, recorte da câmera respeitado |
| Menu do usuário (novo) | Perfil escondido na aba "Você" | Folha com perfil, Trocar perfil/usuário, **Baixados**, Configurações, Sobre o CGFLIX e Sair; dedicatória no topo |
| Busca | Abria como aba, sem Voltar | Abre por cima da Início com Voltar e o campo com foco |
| Busca sem resultado | "Pedir" estourava deitado/teclado aberto; texto mandava para "Você › Configurações" (que não existe mais) | Rola em vez de estourar; sem Seerr, o botão leva a "Conectar os Pedidos" |
| Configurações › Aparência | Escolha de tema (claro/escuro/sistema) quebrava as telas do CGFLIX; grupos Tela inicial, Navegação e TV ao vivo sem efeito no celular | Tema único OLED; esses grupos somem no celular (TV/PC continuam vendo) |
| Configurações › Geral | "Seção inicial" sem sentido sem abas | Some no celular; o app abre sempre na Início |
| Configurações › Logs | "Enviar logs" mandava para o servidor do Plezy | Botão escondido |
| Configurações › Avançado | — | Novo: "Mostrar dedicatória" (padrão ligado) |
| Textos | 47 chaves vazias caíam no inglês ("People", "Audio Channels", filtros avançados, Simkl citando "Plezy"…), "Downloads" | Traduzidas; "Baixados"; "Cópia de segurança" |
| Página do título | Classificação indicativa aparecia como "Avaliação"; "Continuar S02E05" × cartões "T2:E5" | "Classificação indicativa"; sempre "T2:E5" |
| Erro de play | Diálogos de HTTP 500/403 falavam de transcodificação | Mensagem clara do limite de 2 telas e o que fazer |
| Início | Linha presa no esqueleto sem rede | Some quando não há dados |
| Abertura | Círculo de carregamento laranja (Plex) | Roxo do CGFLIX, com a dedicatória |

## Identidade própria (o que denunciava o Plezy)

| Vestígio | Situação |
|---|---|
| Textos com "Plezy" em português | Nenhum na interface (só nomes internos de chave) |
| Simkl em inglês citando "Plezy" | Traduzido com "CGFLIX" |
| "Enviar logs" para `ice.plezy.app` | Escondido |
| Carregamento laranja na abertura | Roxo |
| Esquema `plezy://` | Mantido (sem `BROWSABLE`); trocar exige mexer em 4 arquivos do upstream — decidir com o Caio |
| Nome "Plezy" no perfil de dispositivo do Jellyfin e no User-Agent das imagens | Pendente (aparece só no painel do servidor) |
| Créditos ao Plezy no Sobre e no README | **Mantidos** (licença GPL-3.0) |
| Tela de boas-vindas/onboarding do Plezy | Não existe |

## Recursos que o público espera

Tabela "Recursos esperados" no detalhe abaixo. Feito nesta etapa: **Pedir (Seerr) no topo** e **aviso das 2 telas**.
Lista para a próxima etapa (do mais barato ao mais caro): linha "Minha lista" na Início; selos Dublado/Legendado nos
cartões; classificação indicativa com selo ClassInd (L/10/12/14/16/18); trailers do YouTube (`RemoteTrailers`); Chromecast.

## Detalhe da revisão

Revisão feita só lendo o código (nada foi editado). As linhas valem para o estado atual da árvore.
**Atenção:** durante a revisão, `lib/cgflix/cgflix_about.dart` e `lib/cgflix/cgflix_navigation.dart` estavam sendo
alterados por outra sessão, e surgiu um arquivo novo, `lib/cgflix/cgflix_user_menu.dart`. As linhas desses três arquivos podem mudar.

Detalhe importante sobre o i18n: o `slang.yaml` usa `fallback_strategy: base_locale_empty_string`. Então **toda chave
vazia (`""`) no `pt.i18n.json` aparece em INGLÊS** para o usuário. Há 47 chaves assim (lista na seção "Textos").

---

## 1. Login / escolha de servidor

| Problema | Arquivo:linha | Sugestão |
|---|---|---|
| O corpo não fica dentro de `SafeArea`. Com o celular deitado e com entalhe (notch), o emblema da coluna esquerda pode ficar sob o recorte da câmera, e o `padding` de cima ignora a barra de status. | lib/screens/auth_screen.dart:272-276 | Envolver o `Center` em `SafeArea` (ou somar `MediaQuery.paddingOf(context)` ao padding). |
| A partir de 700 dp de largura o layout vira o "desktop" de duas colunas. Celular deitado (~780–900 dp) cai nesse layout, que foi pensado para o PC. Funciona, mas o emblema de 120 + o título ocupam metade da tela. | auth_screen.dart:267, 277-309 | Usar `width > 700 && height > 500` ou reduzir o emblema quando `cgflixIsLandscape`. |
| Rótulo "URLs do servidor" e ajuda "Várias URLs são permitidas, separadas por vírgulas." confundem o público leigo. O campo aceita até 4 linhas. | pt.i18n.json:2286-2287; add_jellyfin_screen.dart:507-508, 524-527 | Trocar por "Endereço do servidor" e "Ex.: o endereço que o Caio te passou". Usar `maxLines: 1` no celular. |
| A dica do campo é `https://seu.servidor.com`, e o campo começa vazio. Isso foi uma decisão consciente (CGFLIX.md:26), mas o leigo não sabe o que digitar. | lib/media/media_browser_dialect.dart:60 | Pelo menos um texto de ajuda "Peça o endereço a quem te convidou". |
| As mensagens de erro mostram a exceção crua (`${error}` = `e.toString()`), muitas vezes em inglês ou técnica ("SocketException…"). | add_jellyfin_screen.dart:261, 300, 347; pt.i18n.json `addServer.couldNotReachServer`/`signInFailed`/`quickConnectFailed` | Mapear para frases curtas ("Não achamos o servidor. Confira o endereço e a internet.") e mandar o detalhe só para o log. |
| "Quick Connect" e "Usar Quick Connect" ficaram sem tradução. A instrução "Abra o Quick Connect no Jellyfin e insira este código." não diz ONDE fazer isso. | pt.i18n.json:16-17; lib/widgets/quick_connect_code_panel.dart:46-47 | "Entrar com código". Instrução: "Num aparelho onde você já entrou, abra Configurações › Quick Connect e digite este código". Acrescentar um botão "Copiar código". |
| `waitingForAuth` fala "Entre pelo navegador." e serve só ao Plex. Hoje aparece também no estado genérico de autenticação. | pt.i18n.json:11; auth_screen.dart:340-341 | Texto neutro ("Conectando…") ou separar a mensagem do Plex. |
| Literais em inglês só no modo debug ("Debug: Enter Plex Token", "Plex Auth Token", "Auth service not ready"). Não vão no APK release. | auth_screen.dart:472, 537, 569, 576-577 | Baixa prioridade. Pode ficar. |

## 2. Início (lib/cgflix/home/*)

| Problema | Arquivo:linha | Sugestão |
|---|---|---|
| **Sem servidor online (sem internet), o esqueleto fica girando para sempre.** Com `repository == null` e `!_hasOnlineServer`, a tela mostra só o esqueleto. Antes não aparecia porque a aba Início sumia offline. Com a nova navegação (sem barra inferior) a Início fica sempre na tela. | cgflix_home_screen.dart:139-142, 230-235 | Estado vazio "Sem conexão com o servidor" com os botões "Tentar de novo" e "Ver baixados". |
| **Linha que falha fica em esqueleto eterno.** O `onError` só registra no log e `_data` continua null. | cgflix_home_screen.dart:315-317 | No erro, guardar o estado e mostrar `SizedBox.shrink()` (ou um "Tentar de novo" discreto). |
| O fluxo de gêneros não tem `onError`: um erro vira "unhandled stream error" e a lista de gêneros fica vazia sem aviso. | cgflix_home_screen.dart:529-531 | Acrescentar `onError` como nas outras linhas. |
| Tudo vazio (servidor sem nada ou filtro sem títulos): o destaque vira `SizedBox(top+72)` e não aparece nenhuma mensagem. A tela fica preta. | cgflix_home_screen.dart:255-256 | Quando destaque e linhas vierem vazios, mostrar "Nada por aqui ainda". |
| O topo usa `left: 16` fixo e ignora `padding.left` (entalhe deitado). O destaque compacto já usa `padding.left`, então o emblema e o texto do destaque ficam desalinhados. | cgflix_home_screen.dart:656; cgflix_hero.dart:128 | Usar `EdgeInsets.fromLTRB(16 + pad.left, top + 8, 16 + pad.right, 20)`. |
| O padding lateral das linhas (16) também ignora o entalhe. Deitado, o 1º pôster e o título da linha ficam sob a câmera. | cgflix_cards.dart:94, 102, 146, 159 | Somar `MediaQuery.paddingOf(context).left/right` ou envolver as linhas em `SliverSafeArea(top:false, bottom:false)`. |
| O `edgeOffset` do "puxar para atualizar" (top+56) não bate com a altura real do topo (~top+8+36+20 = top+64). A bolinha aparece por baixo dos chips. | cgflix_home_screen.dart:224 | Usar uma constante só para a altura do topo. |
| Na folha "segurar o cartão" de Continuar assistindo, o subtítulo é `cgflixEpisodeLabel(item)`, que fica vazio em filme: sobra uma linha em branco. | cgflix_home_screen.dart:436-441 | `subtitle: label.isEmpty ? null : Text(label)`. |
| Remover de Continuar assistindo falha em silêncio (só log). | cgflix_home_screen.dart:461-465 | `showErrorSnackBar(context, 'Não deu para remover agora')`. |
| Filtro Séries ou Animes em Continuar assistindo, quando o item vem sem `libraryId`: o filtro cai em "não é filme", e séries e animes se misturam. | cgflix_home_screen.dart:469-473 | Aceitável. Anotar ou usar o `parentId`. |
| Cartão de pôster sem imagem fica só um retângulo, sem o título (não há texto alternativo). | cgflix_cards.dart:243-262 | Mostrar `displayTitle` centralizado quando `imagePath` for nulo. |
| Destaque em pé: a `Row` com dois botões de no mínimo 132 dp + 12 de espaço = 276 dp. Em celular de 320 dp sobra 288 dp, no limite. Com fonte grande do sistema estoura. | cgflix_hero.dart:199-223 | Usar `Wrap` ou `Expanded` nos botões, ou limitar a escala do texto como no cartão largo. |
| Títulos das linhas de gênero vêm crus do servidor ("Action", "Science Fiction" se os metadados estiverem em inglês). | cgflix_home_screen.dart:552; cgflix_home_logic.dart:33 | Garantir idioma dos metadados PT-BR no Jellyfin ou ter uma tabela de tradução dos gêneros comuns. |
| Painel de prévia: `artHeight = (width*9/16).clamp(160,300)` usa a largura da TELA, mas a folha do Material 3 tem largura máxima de 640. Deitado: ~300 dp de arte num celular de 360 dp de altura, e o botão Assistir fica fora da tela (precisa rolar). Usa `SafeArea(top:false)` com `isScrollControlled: true`, então a folha pode encostar na barra de status. | cgflix_preview_sheet.dart:108-110, 121-122, 47-53 | Calcular com `LayoutBuilder` e `min(…, altura*0.4)`. Passar `useSafeArea: true` no `showModalBottomSheet`. |
| No painel, o logo vai até `right: 64`, mas `fallbackWidth` usa `width - 80`, outra conta. | cgflix_preview_sheet.dart:151-160 | Usar a mesma medida. |
| "Minha lista" não muda de nome (só o ícone vira ✓). | cgflix_preview_sheet.dart:244-245 | "Na minha lista" quando já estiver salvo. |

## 3. Busca (search_screen.dart + lib/cgflix/search/*)

| Problema | Arquivo:linha | Sugestão |
|---|---|---|
| **Chip "Pessoas" aparece como "People"**: `search.people` está vazio, então cai no inglês. | pt.i18n.json:448; search_screen.dart:453 | `"people": "Pessoas"`. |
| A dica do campo diz "Buscar filmes, séries, músicas..." (não temos música). | pt.i18n.json:444 | "Buscar filmes, séries, animes ou atores". |
| **"Pedir" estoura deitado ou com o teclado aberto**: `Column(Expanded(StateMessageWidget) + texto/botão)` dentro de `SliverFillRemaining` (`hasScrollBody` padrão true). O StateMessage tem ~220 dp (ícone 80 + textos + padding 48) e não rola. | cgflix_search_extras.dart:159-189; search_screen.dart:602-614 | `SliverFillRemaining(hasScrollBody: false)` e `SingleChildScrollView` no lugar do `Expanded`, ou ícone menor quando `cgflixIsLandscape`. |
| Mesma coisa no estado inicial e no de erro (ícone de 80 dp, sem rolagem). | search_screen.dart:584-600 | `hasScrollBody: false`. |
| O texto aponta para "Você › Configurações", mas a aba Você deixa de existir na navegação nova. | cgflix_search_extras.dart:166 | "…conecte os Pedidos (Seerr) em Configurações (toque no logo › Configurações)". |
| Estado de erro sem botão "Tentar de novo". | search_screen.dart:597-600 | Usar `onAction`/`actionLabel` do `StateMessageWidget` chamando `runSearch(lastSearchedQuery)`. |
| A snackbar de erro mostra a exceção crua: "Falha na busca: ${error}". | search_screen.dart:178-181; pt `errors.searchFailed` | Mostrar só "Falha na busca. Verifique sua conexão." e mandar o detalhe para o log. |
| Literal em inglês na exceção interna "Search was cancelled before any server completed". Só aparece se vazar para a snackbar acima. | search_screen.dart:155 | Some se o item acima for corrigido. |
| Folha "Assistir de qual servidor?" usa uma `Column` sem rolagem (com muitos servidores, estoura deitado). | cgflix_sources.dart:71-90 | `SingleChildScrollView` ou `ListView(shrinkWrap)`. |

## 4. Página do título / temporada / episódio (media_detail_screen.dart, cgflix_detail.dart)

| Problema | Arquivo:linha | Sugestão |
|---|---|---|
| Classificação indicativa aparece com o rótulo "**Avaliação**". O mesmo `discover.rating` é usado para nota. | media_detail_screen.dart:3589-3590; pt.i18n.json:1080 | Chave própria "Classificação indicativa" (ou trocar o texto em `discover.rating`). |
| Códigos de episódio inconsistentes: cartões e painel usam "T2:E5", o botão usa "Continuar S02E05" e a TV usa `discover.playEpisode` = "S${season}E${episode}". "S" (season) não faz sentido em PT. | cgflix_actions.dart:18-33; cgflix_detail.dart:20-30; pt.i18n.json:1075 | Padronizar em "T2:E5" (ou "T2 E5"). Mudar `cgflixEpisodeCode` e `playEpisode` para `T${season}:E${episode}`. |
| Os selos Dublado/Legendado ficam na linha de gêneros, a primeira a sumir quando o destaque é baixo (deitado: `showGenres` falso). Celular deitado não mostra os selos. | media_detail_screen.dart:4694-4712 | Pôr os selos na linha de chips de metadados (`_buildFittedHeroChips`) com prioridade alta, ou repeti-los abaixo da sinopse. |
| "Assistir"/"Continuar" são literais em Dart, fora do i18n. Funciona porque o app é PT, mas quebra os outros idiomas (vão ver PT). | cgflix_detail.dart:22-29 | Aceitável (decisão do fork). Anotar no CGFLIX.md. |
| `discover.continueWatching` = "Continuar **A**ssistindo" (maiúscula no meio), diferente da Início ("Continuar assistindo"). | pt.i18n.json:1066 | Minúscula. |
| `discover.tvShow` = "Série de TV". | pt.i18n.json:1084 | "Série". |
| Coluna de rótulo das linhas de informação com largura fixa de 120. Rótulos longos ("Classificação indicativa") quebram em 2 linhas. | media_detail_screen.dart:4945-4951 | `IntrinsicWidth` ou 150 dp. |
| Temporadas e episódios ficam na mesma tela (não há tela de temporada separada). Os estados vazio e de erro já existem ("Nenhum episódio encontrado", "Não foi possível carregar os episódios" + Tentar). | media_detail_screen.dart:2831-2960 | OK. |

## 5. Pessoa (actor_media_screen.dart)

| Problema | Arquivo:linha | Sugestão |
|---|---|---|
| O nome aparece duas vezes: na AppBar fixada e no cabeçalho. | actor_media_screen.dart:182 e 147-152 | Título da AppBar vazio até rolar, ou tirar o nome do cabeçalho. |
| O personagem aparece sozinho ("Tony Stark"), sem "como". | actor_media_screen.dart:153-160 | `'como ${characterName}'`. |
| Não mostra a biografia nem a data de nascimento (o Jellyfin tem `Overview`). | actor_media_screen.dart:123-176 | Próxima etapa: "Biografia" recolhível. |
| O cabeçalho usa padding 16 fixo (entalhe deitado). | actor_media_screen.dart:127 | `SliverSafeArea`. |
| `explore.creditRole.actor` está vazio, então aparece "Actor" (na ficha de catálogo/Seerr). | pt.i18n.json:1427 | "Ator/Atriz". |

## 6. Player (lib/screens/video_player*, lib/widgets/video_controls)

| Problema | Arquivo:linha | Sugestão |
|---|---|---|
| **Não há mensagem do limite de 2 telas.** Quando o StreamLimiter recusa, o usuário vê "Erro do servidor (HTTP 500). Um limite de largura de banda ou **transcodificação**…" ou "(HTTP 403)… rede local". | lib/utils/dialogs.dart:222, 243; pt.i18n.json:842, 848; playback_initialization_types.dart:222 | Trocar os textos PT: "Você já está assistindo em 2 telas. Feche uma delas e tente de novo." Melhor ainda: detectar a mensagem do plugin e mostrar um diálogo próprio do CGFLIX. |
| Mensagens de reprodução citam "HTTP 404/503" e "reexaminar a biblioteca", linguagem técnica. | pt.i18n.json (`mediaUnreadableBody`, `serverBusyBody`) | Encurtar e falar com o usuário: "Este vídeo está indisponível agora. Avise o Caio." |
| Literais de debug em inglês ("Trigger MPV Fallback", "Simulate HTTP…"). Só aparecem com `kDebugMode`. | video_settings_sheet.dart:1003-1017 | Pode ficar. |
| Barra de ícones do canto (ajustes, faixas, capítulos, fila, PiP, rotação, cadeado, camadas, tela cheia): muitos ícones para o leigo. O botão de legenda e áudio é o mesmo, e o ícone muda conforme o estado. | track_chapter_controls.dart:163-360 | Avaliar esconder Capítulos, Fila e Camadas no celular e deixar "Legendas e áudio" com rótulo. |

## 7. Baixados (lib/screens/downloads/*)

| Problema | Arquivo:linha | Sugestão |
|---|---|---|
| O título da tela é "**Downloads**", mas o menu do usuário chama "Baixados". | downloads_screen.dart:146; pt.i18n.json:1752 (`downloads.title`), 306 (`settings.downloads`), 1301 (`navigation.downloads`) | Trocar as três chaves para "Baixados" (ou "Downloads" em todo lugar, mas um só). |
| Aba "**Música**" (não temos música) e "Séries de TV". | downloads_screen.dart:135-141, 210-216; pt.i18n.json:1754, 1756 | Esconder a aba Música no CGFLIX (gancho `// CGFLIX`) e usar "Séries". |
| A primeira aba é "Gerenciar" (fila técnica). O leigo espera ver os filmes baixados primeiro. | downloads_screen.dart:135, 210 | Abrir em Filmes/Séries ou renomear para "Baixando". |
| O ícone "Regras de sincronização" no topo é jargão. | downloads_screen.dart:169-175; pt `activeSyncRules` | Esconder no celular ou chamar de "Baixar novos episódios automaticamente". |
| Deitado: AppBar fixada + aviso de segundo plano + chips + `TabBarView` dentro de `SliverFillRemaining`/`Column`. Sobram ~180 dp para a lista. | downloads_screen.dart:150-220 | Deixar o AppBar `pinned:false` deitado e mover os chips para dentro da AppBar. |
| `downloads.backgroundWarning.stillNotWorkingDescription` manda para "Configurações › Ver Logs" (o caminho mudou: agora está em Avançado). | pt.i18n.json:1844 | "Configurações › Avançado › Ver registros". |
| `CgflixAboveNavBar` fica obsoleto sem a barra inferior. | cgflix_navigation.dart (classe `CgflixAboveNavBar`) | Remover o gancho quando a barra sair. |

## 8. Configurações (lib/screens/settings/*)

| Problema | Arquivo:linha | Sugestão |
|---|---|---|
| **Reprodução › Áudio (aberto por padrão) mostra "Audio Channels · Mix decoded audio down…"** em inglês: as 9 chaves `audioChannelLimit*` estão vazias. | playback_settings_screen.dart:104-113, 527-535; pt.i18n.json:351-358 | Traduzir ("Canais de áudio", "Original", "Até 5.1", "Estéreo" + descrições). |
| `settings.resetShortcutsConfirm` vazio (inglês). | pt.i18n.json:265 | Traduzir. |
| `profiles.signOutPlexDeleteDownloads(+Description)` vazios (inglês). | pt.i18n.json:922-923 | Traduzir. |
| Textos com maiúsculas em todas as palavras (estilo inglês): "Mostrar Rótulos da Barra de Navegação", "Log de Depuração", "Ver Logs", "Limpar Logs"… | pt.i18n.json:244, 246, 397 e seção `logs` | Só a 1ª maiúscula. "Logs" → "Registros". |
| "Backup" como título de seção. | pt.i18n.json:254 | "Cópia das configurações" (ou esconder, ver seção 2). |
| `generalDescription` = "Idioma, inicialização e comportamento da janela" ("janela" não existe no celular). | pt.i18n.json:405 | "Idioma e inicialização". |
| Os Pedidos (Seerr) ficam escondidos em "Serviços" junto com MAL, AniList, Simkl, Trakt (rastreadores que o público não usa). | settings_screen.dart:210, 330-347 | Item próprio "Pedidos (Seerr)" no grupo principal. "Serviços" vai para Avançado. |
| O nome "Opções do mpv" e o seletor ExoPlayer/mpv ficam visíveis. Trocar para ExoPlayer **perde o estilo das legendas ASS** dos animes. | playback_settings_screen.dart:74; cgflix_advanced.dart:46-51 | Esconder o seletor de backend no celular (ou mover para Avançado com aviso). |
| Itens de música: "Qualidade da música", "Retomar música ao abrir". | playback_settings_screen.dart:132, 260-263 | Esconder no CGFLIX. |
| "Relatório de falhas" (crashReporting) aparece, mas o Sentry está desligado no APK (`ENABLE_SENTRY` só no upstream). Se fosse ligado, mandaria os dados para `bugs.plezy.app`. | settings_screen.dart:561-564; main.dart:109-110 | Esconder no CGFLIX (`if (_enableSentry)`). |

## 9. Sobre (about_screen.dart, cgflix_about.dart)

| Problema | Arquivo:linha | Sugestão |
|---|---|---|
| "CGFLIX" aparece duas vezes seguidas: o nome do app e "CGFLIX 1.1.0". | about_screen.dart:41-47; cgflix_version.dart:5 | Mostrar só "Versão 1.1.0" abaixo do nome. |
| O crédito "github.com/edde746/plezy" não é tocável. | cgflix_about.dart (`CgflixCredits`, ~fim do arquivo) | Torná-lo um link (`url_launcher`, já no pubspec). **Manter o texto.** |
| A GPL-3.0 pede que o código-fonte da versão modificada esteja disponível. O Sobre não tem link para o repositório do CGFLIX. | about_screen.dart:64-77 | Item "Código-fonte do CGFLIX" apontando para o repositório do fork. |

## 10. Perfis (lib/screens/profile/*)

| Problema | Arquivo:linha | Sugestão |
|---|---|---|
| "Adicionar perfil CGFLIX" cria um perfil local **sem conexão**. O leigo cai em "Sem conexões — adicione uma…" e não sabe o que fazer. Entrar com outro usuário do Jellyfin passa por Configurações › Conexões. | profile_switch_screen.dart:102-118; add_local_profile_screen.dart | No CGFLIX, trocar por "Entrar com outro usuário", que abre `AddJellyfinScreen` direto. |
| Lista vazia: "Entre em contato com o administrador do servidor para adicionar perfis" (genérico). | profile_switch_screen.dart:90-98; pt `messages.contactAdminForProfiles` | "Fale com o Caio para criar seu usuário". |
| Textos de Plex Home ("plex.tv", "Plex Home") aparecem mesmo para quem só usa Jellyfin. | profile_detail_screen.dart:312 | OK, só aparecem em perfil Plex. |

## 11. Telas de erro

| Problema | Arquivo:linha | Sugestão |
|---|---|---|
| Em release, um erro de build de widget vira uma **caixa preta** (`ColoredBox(0xFF000000)`), sem nenhum texto. Em fundo OLED isso fica invisível ou parece um "buraco". | main.dart:165-168 | Caixa com ícone e "Algo deu errado aqui" (sem detalhes). |
| A falha de inicialização oferece "Enviar detalhes", que manda o log para o **servidor do Plezy** (`https://ice.plezy.app/logs`). | startup_failure_view.dart:102, 250; log_upload_service.dart:6 | Esconder "Enviar" no CGFLIX (deixar só "Copiar detalhes") ou apontar para um endpoint nosso. |
| Os detalhes copiados começam com "Plezy startup failure" e os logs com "Plezy v…". | startup_diagnostics.dart:217; main.dart:1070 | Trocar para "CGFLIX" (gancho de 1 linha). |

---

## Configurações sem sentido (celular, nova navegação)

| Opção | Arquivo:linha | Chave do SettingsService | Por quê |
|---|---|---|---|
| Tema (Sistema/Claro/Escuro/OLED) | appearance_settings_screen.dart:38, 185-198 | `themeMode` (settings_service.dart:888-893, padrão OLED) | As telas do CGFLIX têm cores fixas (`CgflixColors.background`, texto branco). Escolher Claro mistura Início preta com telas claras e texto branco sobre branco. Tema único OLED. |
| Mostrar rótulos da barra de navegação | appearance_settings_screen.dart:151-157 | `showNavBarLabels` (797) | Não existe mais barra inferior. |
| Mostrar aba Explorar | appearance_settings_screen.dart:130-136 | `showExploreTab` (783) | Não há abas. O Explorar do upstream nem é acessível. |
| Manter barra lateral sempre aberta / Agrupar bibliotecas por servidor | appearance_settings_screen.dart:137-150 | `alwaysKeepSidebarOpen` (784), `groupLibrariesByServer` (580) | Só na navegação lateral (TV/PC). Já escondidas no celular. OK. |
| Mostrar contagem de não assistidos | appearance_settings_screen.dart:158-163 | `showUnwatchedCount` (789) | Afeta as abas de biblioteca do upstream, que não aparecem na nova navegação. |
| Grupo "Tela inicial": Mostrar seção de destaque, Usar layout inicial (global hubs), Mostrar nome do servidor nos hubs, Ação de Continuar assistindo, Ação do episódio | appearance_settings_screen.dart:100-123, 306-322 | `showHeroSection` (575), `useGlobalHubs` (578), `showServerNameOnHubs` (579), `continueWatchingAction` (919), `episodeAction` (924) | Valem só para a `DiscoverScreen` do upstream. A Início do CGFLIX ignora todas (sempre tem destaque e sempre toca direto). Enganam o usuário. |
| Grupo "Biblioteca e cartões": modo de visualização, densidade, espaçamento da grade, pôster do episódio | appearance_settings_screen.dart:44-50, 274-302 | `viewMode` (571), `libraryDensity` (910), `gridSpacing` (911), `episodePosterMode` (918) | Afetam só as grades do upstream (bibliotecas). Na nova navegação o leigo quase não as vê. Mover para Avançado. A densidade também aparece no resumo da tile Aparência (settings_screen.dart:296). |
| Grupo "TV ao vivo › Favoritos por padrão" | appearance_settings_screen.dart:166-176 | `liveTvDefaultFavorites` (821) | O CGFLIX não tem TV ao vivo. O grupo aparece sempre, sem condição. |
| Seção inicial | general_settings_screen.dart:41, 104-119 | `startupSection` (774) | Opções Início/Bibliotecas/TV ao vivo/Buscar. Sem abas não faz sentido. Abrir sempre na Início. |
| Forçar modo TV | general_settings_screen.dart:51-57 | `forceTvMode` (801) | No celular, um toque transforma o app em interface de TV. Arriscado para o leigo. Esconder fora de TV box (ou mover para Avançado). |
| Exigir seleção de perfil ao abrir | general_settings_screen.dart:44-50 | `requireProfileSelectionOnOpen` (799) | Faz sentido (só aparece com 2+ perfis). OK. |
| Visual effects (Auto/Completo/Reduzido) | appearance_settings_screen.dart:40, 330-348 | `visualEffects` | Útil em celular fraco. Manter, mas com texto mais claro. |
| Mostrar pôsteres das temporadas nas abas | appearance_settings_screen.dart:57-63 | `showSeasonPostersOnTabs` (795) | Opcional. Pode ficar em Avançado. |
| Backup (exportar/importar configurações) | settings_screen.dart:222, 625-645 | (arquivo) | O leigo não usa. Mover para Avançado. |
| Atualizações (verificar atualizações) | settings_screen.dart:218, 645-700 | `autoCheckUpdatesOnStartup` | Hoje está desligado (`ENABLE_UPDATE_CHECK` só no build.yml do upstream). Se ligar, consulta `edde746/plezy` (update_service.dart:18-19). Garantir que o workflow do CGFLIX nunca defina isso até termos o nosso servidor de atualização. |
| Apoie o CGFLIX (doação) | settings_screen.dart:204, 275-289 | (`ENABLE_DONATIONS`) | Desligado no nosso APK, mas se ligado abre `liberapay.com/edde746` com o texto "Apoie o CGFLIX" (pt.i18n.json:120), o que é enganoso. |
| Controles de teclado / controle remoto do player | settings_screen.dart:516-540 | `videoPlayerNavigationEnabled`, `enableCompanionRemoteServer` | Já em Avançado. OK. |

## Vestígios do Plezy

**Texto em PT (pt.i18n.json): limpo.** As 2 ocorrências são só NOMES de chave: `addPlezyProfile` = "Adicionar perfil CGFLIX"
(912) e `startup.quitPlezy` = "Sair do CGFLIX" (1282). Nenhum texto mostra "Plezy". Mesmo assim, há vestígios visíveis:

| Vestígio | Onde | Quem vê | Ação |
|---|---|---|---|
| Texto em inglês **com "Plezy"** por fallback: `services.simklReconnect.title/subtitle` estão vazios, então aparece "Reconnect Simkl… approve Plezy — Plezy never sees your password". | pt.i18n.json:2248-2251 | Usuário que conectar o Simkl | Traduzir trocando o nome por CGFLIX. |
| "Enviar logs" / "Enviar detalhes" mandam o log para `https://ice.plezy.app/logs` (servidor do autor do Plezy). Fere a regra 3 (telemetria). | log_upload_service.dart:6; startup_failure_view.dart:250; logs_screen | Todo usuário | Esconder o envio no CGFLIX ou trocar o endpoint. |
| "Assistir juntos" usa o relay padrão `https://ice.plezy.app`. | watch_together_relay_endpoint.dart:8 | Quem usar Assistir juntos | Documentar, ou relay próprio/opção escondida. |
| "Relatório de falhas" iria para `bugs.plezy.app` (desligado no build). | main.dart:109-110; settings_screen.dart:561 | Opção visível em Avançado | Esconder. |
| Cabeçalho do log "Plezy v1.1.0+300" e "Plezy startup failure" nos detalhes copiados. | main.dart:1070; startup_diagnostics.dart:217 | Quem copia ou manda o log | Trocar para CGFLIX. |
| Esquema de deep link `plezy://play` e `plezy://live`: com o Plezy instalado, o Android pergunta "abrir com CGFLIX ou Plezy?". | android/app/src/main/AndroidManifest.xml:73, 80 | Raro (links externos) | Trocar para `cgflix://` ou remover. |
| Nome do perfil de dispositivo no Jellyfin `'Name': 'Plezy'` (aparece nos logs/sessões do servidor), `User-Agent: Plezy` nas imagens e `DisplayPreferences client = 'Plezy'`. | jellyfin_client/parts/playback.dart:907; media_image_helper.dart:410; jellyfin_display_preferences.dart:23 | O Caio, no painel do Jellyfin | DeviceProfile e User-Agent → "CGFLIX". O `client` das DisplayPreferences só muda com migração (senão as preferências salvas se perdem). O nome do cliente na autenticação já é "CGFLIX …" (jellyfin_auth_header.dart:52-57). |
| Assets `plezy.png` e `plezy_adaptive_foreground.svg` ainda no pubspec. Nenhuma tela os usa (o emblema é `cgflix_emblema.svg`). | pubspec.yaml:147-148; assets/ | Ninguém (só aumentam o APK) | Tirar do pubspec (mantendo os arquivos para sincronizar com o upstream). |
| Mensagem em inglês com "Plezy" em comando de agente ("An external application cannot be stopped or observed by Plezy."). | services/agent_playback_commands.dart:361 | Muito raro | Baixa prioridade. |
| Créditos ao Plezy no Sobre: **devem ficar** (licença). | cgflix_about.dart (`CgflixCredits`) | Todos | Manter. Só tornar o link tocável e acrescentar o link do nosso código-fonte. |
| Não há tela de boas-vindas ou onboarding do Plezy (grep por onboarding/welcome em screens/widgets/cgflix não achou nada). | — | — | — |

## Textos em inglês (resumo das chaves vazias que caem no inglês)

47 chaves vazias no pt.i18n.json. As mais visíveis primeiro:
`search.people` (448, chip da busca), `settings.audioChannelLimit*` (351-358, Reprodução › Áudio, aberta por padrão),
`settings.resetShortcutsConfirm` (265), `profiles.signOutPlexDeleteDownloads(+Description)` (922-923),
`explore.creditRole.actor` (1427), `services.simklReconnect.*` (2248-2251, com "Plezy"),
`libraries.filterCategories.filePath` (1181), `libraries.advancedFilters.*` (1208-…, 24 chaves: filtros avançados das
bibliotecas), `performanceOverlay.dvRoute*` (2011-…, sobreposição técnica).
Chaves iguais ao inglês que valem a troca: `settings.backup` "Backup", `screens.logs` "Logs", `settings.downloads` /
`navigation.downloads` / `downloads.title` "Downloads", `discover.playEpisode` "S…E…", `explore.badge.rankPopular` "#n popular".

---

## Recursos esperados

| Recurso | Situação | Onde |
|---|---|---|
| Continuar assistindo | **JÁ TEM** | Linha na Início: cgflix_home_screen.dart:420-509 (`DiscoverProvider.onDeck`). Tocar continua; segurar remove. Na TV/Plex, a Discover do upstream. |
| Minha lista / favoritos | **PARCIAL** | Dá para marcar no painel (cgflix_preview_sheet.dart:244-249 → cgflix_actions.dart:103) e no coração da página do título (media_detail_screen.dart:1340-1430). **Falta a linha "Minha lista" na Início** (cgflix_home_logic.dart:7-17 não tem favoritos) e um lugar para ver a lista. |
| Pular abertura / créditos | **JÁ TEM** | Segmentos do Jellyfin `/MediaSegments` (jellyfin_client/parts/playback.dart:61-191) + fallback por nome de capítulo; botão skip_marker_button.dart; opções `skipIntroMode`/`skipCreditsMode`/`autoSkipDelay` (settings_service.dart:623-636; playback_settings_screen.dart:330-370). Depende do servidor ter segmentos (plugin Intro Skipper / Jellyfin 10.10+). |
| Próximo episódio automático | **JÁ TEM** | `autoPlayNextEpisode` (padrão ligado) + contagem `playNextCountdown` de 5 s (settings_service.dart:718-727; playback_settings_screen.dart:304-325). |
| Trocar legenda e áudio fácil | **JÁ TEM** (melhorável) | Botão de faixas no player (track_chapter_controls.dart:190-200) → track_sheet.dart; busca de legendas (subtitle_search_sheet.dart); segue a preferência do servidor (`followServerTrackSelections` = true, settings_service.dart:620). Ícone sem rótulo; áudio e legenda no mesmo botão. |
| Chromecast | **FALTA** | Nenhum pacote de cast no pubspec nem código (grep por cast/chromecast vazio). Só PiP e o "Controle remoto" próprio (outro aparelho com o CGFLIX). |
| Download offline | **JÁ TEM** | lib/screens/downloads/*, DownloadProvider, opções em Configurações › Downloads (só Wi-Fi, apagar assistidos). Ajustar nomes ("Baixados"), aba Música, etc. |
| Notas / classificação indicativa (officialRating) | **PARCIAL** | `OfficialRating` → `contentRating` (jellyfin_mappers.dart:231). Aparece no painel (cgflix_preview_sheet.dart:26-41, junto com ★ nota) e nos chips do título (media_detail_screen.dart:1233). Rótulo errado ("Avaliação"), sem selo colorido no padrão ClassInd (L/10/12/14/16/18). Pode vir "PG-13" se o país dos metadados no Jellyfin não for Brasil. |
| Trailers | **PARCIAL** | Só trailers LOCAIS (arquivos no servidor): media_browser_paths.dart:79 (`/LocalTrailers`), botão em media_detail/action_buttons.dart:115-169, seção "Trailers e extras". Não usa os `RemoteTrailers` (YouTube) que o Jellyfin já tem para quase todo título. |
| Perfis | **PARCIAL** | Perfis locais com PIN + usuários Jellyfin/Plex Home (lib/screens/profile/*, ProfileSwitchScreen). Fluxo confuso para o leigo: "Adicionar perfil CGFLIX" cria perfil sem conexão; outro usuário Jellyfin entra por Configurações › Conexões. Sem avatar escolhível no estilo Netflix. |
| Selos Dublado / Legendado | **PARCIAL** | Só na página do título (cgflix_detail.dart:42-80; media_detail_screen.dart:4697) e somem deitado. Nada nos cartões nem no painel. |
| Pedidos (Seerr) | **PARCIAL** | Só pelo "Pedir" da busca vazia (cgflix_search_extras.dart:149-191). A conexão fica em Configurações › Serviços. O ícone "Pedir" no topo ainda não existe. |
| Aviso do limite de 2 telas | **FALTA** | Cai nos diálogos genéricos HTTP 403/500 (dialogs.dart:222, 243). |

---

## Os 10 problemas mais importantes e baratos de corrigir

1. **Chaves vazias que aparecem em inglês**: chip "People" na busca (pt:448), "Audio Channels…" em Reprodução › Áudio (pt:351-358), "Actor" (pt:1427), confirmação de atalhos (pt:265), Simkl com "Plezy" (pt:2248-2251). Só JSON.
2. **Início presa em esqueleto**: offline (cgflix_home_screen.dart:230-235) e linha com erro (317; gêneros sem `onError` em 529). Pede estado vazio "Sem conexão / Tentar de novo".
3. **Aviso das 2 telas**: trocar os textos `serverLimitBody`/`playbackNotAllowedBody` (pt:842, 848) por uma mensagem clara em PT; depois, detecção própria.
4. **"Pedir" e os estados vazios da busca estouram deitado ou com o teclado aberto** (cgflix_search_extras.dart:159-189; search_screen.dart:584-614 → `hasScrollBody:false` + rolagem). Também corrigir o texto "Você › Configurações" (166).
5. **"Avaliação" → "Classificação indicativa"** (pt:1080 / media_detail_screen.dart:3590).
6. **Downloads × Baixados**, aba "Música" e "Séries de TV" (pt:306, 1301, 1752-1756; downloads_screen.dart:135-141/210-216).
7. **Esconder no celular o que não faz mais sentido**: tema (appearance:38), rótulos da barra (151-157), aba Explorar (130-136), seção inicial (general:41), forçar modo TV (general:51-57), grupo TV ao vivo (appearance:166-176) e o grupo "Tela inicial" que a Início do CGFLIX ignora (appearance:100-123).
8. **Código de episódio único "T2:E5"** (cgflix_actions.dart:26-33, cgflix_detail.dart:24-27, pt:1075).
9. **Envio de logs para ice.plezy.app** e "Relatório de falhas" visível: esconder ou redirecionar (log_upload_service.dart:6; startup_failure_view.dart:250; settings_screen.dart:561-564).
10. **Entalhe e paisagem na Início**: topo e linhas sem `padding.left` (cgflix_home_screen.dart:656; cgflix_cards.dart:146/159), e a altura da prévia baseada só na largura (cgflix_preview_sheet.dart:110). Também a dica da busca "músicas" (pt:444).
