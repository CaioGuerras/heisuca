# P4 — Inventário do código herdado do Plezy sem uso (27/10/2026)

Somente leitura: nada foi removido. Caminhos relativos a `apps/app/`. Linhas são aproximadas (ramo `claude/heisuca-p`).
Método: busca por nome em `lib/`, `android/`, `assets/`, `pubspec.yaml`, `lib/i18n/*.i18n.json` (44 idiomas) e `test/`.

## Resumo

| Item | Visível hoje? | Alcançável? | Tamanho (lib, linhas) | Dependência exclusiva |
|---|---|---|---|---|
| Discord | não | não | 0 | nenhuma (só um comentário no pubspec.yaml:61) |
| Sentry | não | não | 0 | nenhuma (já removido na etapa L) |
| Letterboxd | não | não | 0 | nenhuma |
| MyAnimeList / AniList | não | parcial (só tipos/ids) | restos ~200 | nenhuma |
| Trakt | só com credenciais no build (hoje vazio = oculto) | sim (main.dart, detalhe do título) | ~3,5 mil + modelos | nenhuma |
| Simkl | não (oculto) | sim, como código morto atrás de flag | ~2,5 mil com modelos | nenhuma |
| MDBList | não (oculto) | idem | ~0,6 mil | nenhuma |
| Assistir juntos + relay | SIM (Configurações > Recursos extras; Início) | sim | ~5,4 mil | `web_socket_channel` é compartilhada |
| Controle remoto (companion) | SIM (Recursos extras; Início) | sim | ~3,6 mil | `web_socket_channel` compartilhada |
| Atualizador herdado | não (compilação desliga por padrão) | sim, atrás de flag | ~320 | `auto_updater` + 4 sobrescritas de git |

## Detalhe

### Discord, Sentry, Letterboxd
Nenhuma ocorrência em `lib/`, `android/`, `assets/`, workflows ou i18n. Único vestígio: comentário em `pubspec.yaml:61`
(nota de versão que cita Discord, sem pacote correspondente). Nada a remover além do comentário.

### MyAnimeList e AniList
Telas, clientes e autenticação já foram removidos (nota em `lib/cgflix/cgflix_trakt.dart:6-7`). Restos:
- `lib/services/trackers/tracker_constants.dart:27` — `enum TrackerService { mal, anilist, simkl, trakt, mdblist }`.
- `lib/models/trackers/anime_ids.dart`, `anime_list_snapshot.dart`, `anime_lists_mapping.dart`, `fribb_mapping_row*.dart`,
  `lib/services/trackers/fribb_mapping_store.dart`, `anime_lists_mapping_store.dart`, `anime_episode_progress_resolver.dart`
  (mapeamento de ids de anime entre catálogos; servem a Simkl/Trakt também).
- Chaves de sessão em `lib/services/sensitive_prefs.dart:42-46` e leitura em `lib/services/prefs_recovery.dart:~599`.
- Rótulos em i18n (`en.i18n.json:77-80`, replicado nos 44 idiomas) e menções em `lib/screens/media_detail*`, `utils/external_ids.dart`.
Risco: baixo para código; manter as chaves `mal_session`/`anilist_session` na lista de limpeza/recuperação enquanto houver
instalações antigas (para o app continuar apagando/ignorando dados antigos sem erro).

### Trakt
- Arquivos: `lib/services/trackers/trakt/` (4), `lib/models/trakt/` (~13 com gerados), `lib/services/catalog/trakt_catalog_source.dart` (393),
  `lib/screens/settings/trakt_settings_screen.dart`, `tracker_*` em `lib/screens/settings/`, `lib/providers/trackers_provider.dart` (487),
  `lib/services/trackers/tracker_coordinator.dart` (1230), `tracker_write_queue.dart` (679), `tracker_id_resolver.dart` (440),
  `lib/cgflix/cgflix_trakt.dart` (170, comentários do Trakt na página do título e a regra de exibição).
- Visibilidade: `cgflixShowsTracker` só liga o Trakt se o build tiver `TRAKT_CLIENT_ID/SECRET`; sem eles (estado atual) não há tela.
  `cgflixShowsServicesTile` esconde Configurações > Serviços (`settings_screen.dart:~447`).
- Alcançável: `TrackerCoordinator.instance.initialize` em `lib/main.dart:855` e parada em `main.dart:~1133`; `video_player_screen.dart`,
  `watch_actions.dart`, `offline_watch_sync_service.dart` chamam o coordenador (scrobble). Testes dedicados em `test/services/trackers/` e
  `test/providers/trackers_provider*`.
- Dependências exclusivas: nenhuma no pubspec (usa http/json_annotation/freezed, compartilhados).
- Risco: médio. Mexe em main.dart, player, `settings_service.dart:~1403,1472` (preferências por serviço: `scrobblePref`, filtros) e
  `prefs_recovery`. Manter leitura de `trakt_session`, `enable_trakt_watched_sync` e filtros até decidir pela remoção definitiva.

### Simkl e MDBList
- Simkl: `lib/services/trackers/simkl/` (4 arquivos), `lib/models/simkl/` (~14), `lib/services/catalog/simkl_catalog_source.dart` (637).
- MDBList: `lib/services/trackers/mdblist/` (client, tracker), `lib/services/catalog/mdblist_catalog_source.dart`.
- Invisíveis: `heisucaTrackerServices` (`tracker_constants.dart:30`) ainda os lista, mas `cgflixShowsTracker` os filtra.
  Alcançáveis só pelo coordenador e pelo registro de fontes de catálogo (`providers/catalog_sources_provider.dart`, `explore_provider.dart`).
- Sem dependência exclusiva. Risco: médio-baixo; chaves `simkl_session`/`mdblist_*` ficam na lista de credenciais.

### Assistir juntos (relay)
- `lib/watch_together/` (providers, screens, services, widgets; ~4,2 mil), `lib/screens/video_player/parts/watch_together.dart` (286),
  ganchos em `video_player/parts/playback_*.dart`, `main_screen.dart:~581,874-980`, `navigation/profile_session_screen.dart:271` (provider),
  `lib/cgflix/cgflix_advanced.dart:~56`, `screens/discover_screen.dart:~805-880`.
- Visível: sim — "Recursos extras > Assistir juntos" e botão no Início. Há também a opção de endereço do relay em
  `settings_screen.dart:~676,1072-1125` e `watch_together_relay_endpoint.dart` (o endereço é configurado pelo usuário; não há padrão do Plezy no código).
- i18n: bloco `watchTogether*` nos 44 idiomas. Testes: `test/watch_together/` (~6 mil linhas) e `test/test_helpers/watch_together_fakes.dart`.
- Risco: ALTO — é recurso visível e tem ganchos no player; remover exige decisão de produto. Sem preferência crítica de dados.

### Controle remoto (companion)
- `lib/services/companion_remote/` (~1,9 mil), `lib/providers/companion_remote_provider.dart` (1237), `lib/screens/companion_remote/`,
  `lib/widgets/companion_remote/`, `lib/models/companion_remote/`, `screens/video_player/companion_remote_binding.dart` e `parts/companion_remote.dart`,
  `main_screen.dart:~1024-1130`, `cgflix_advanced.dart:~63`, `discover_screen.dart:~866`.
- Visível: sim ("Recursos extras > Controle remoto"); servidor sobe sozinho no desktop (`enableCompanionRemoteServer`, `settings_service.dart:906`,
  padrão = desktop). Android do app não tem código nativo exclusivo.
- Risco: ALTO (visível e ligado ao ciclo de vida da tela principal). Manter a chave `enable_companion_remote_server` lida.

### Atualizador herdado
- `lib/services/update_service.dart` (258), `lib/utils/update_dialog.dart` (64), uso em `main_screen.dart:~639,842-870` e
  `settings_screen.dart:~126,375,754` (seção "Atualizações"), testes `test/services/update_service_test.dart`.
- Não visível: depende de `--dart-define=ENABLE_UPDATE_CHECK=true`, desligado por padrão; feed vem de `HEISUCA_UPDATE_FEED`; o repositório
  consultado é o nosso (`CaioGuerras/heisuca`), não o do Plezy.
- Dependências exclusivas: `auto_updater` e as sobrescritas `auto_updater_platform_interface/_macos/_windows` (pubspec.yaml:74-139, git do upstream).
- Risco: baixo no código; antes de remover, confirmar se o Windows/macOS usará atualização própria. Chaves `update_skipped_version`,
  `update_last_check_time`, `check_for_updates`, `auto_check_updates_on_startup` podem ficar órfãs sem prejuízo.

### Outros restos
- Nomes "Plezy" em `android/app/build.gradle.kts:22,107,351` (propriedade `plezy.testBuildType`, `PLEZY_LOCAL_MPV_DIR`),
  testes `android/app/src/androidTest/**/Plezy*.kt|java` e `assets/licenses/heisuca_gpl.txt` (aviso obrigatório: manter).
  Renomear propriedades do Gradle exige alinhar scripts de build; sem impacto para o usuário.
- Fonte `Seerr` (`lib/services/seerr/`, `providers/seerr_account_provider.dart`) é herdada mas está em uso (pedidos pela busca): fora do escopo.

## Ordem de remoção sugerida
1. Comentário do Discord em `pubspec.yaml` e nomes "Plezy" em Gradle/testes nativos (risco nulo).
2. Atualizador herdado + `auto_updater` (flag desligada; remove 4 sobrescritas de git).
3. Simkl e MDBList (invisíveis; tirar de `heisucaTrackerServices`, do registro de catálogos e dos testes).
4. Restos de MAL/AniList (valores do enum, ids de anime não usados, i18n), mantendo as chaves de sessão na limpeza.
5. Trakt (maior; só depois de decidir se haverá credencial própria) junto com o coordenador/fila de escrita e ganchos do player.
6. Assistir juntos e Controle remoto por último e só com decisão do produto (são visíveis e têm ganchos no player e na tela principal).
Em todos: remover tradução (44 idiomas) com o script do slang e conferir `flutter analyze` e as suítes; preservar leitura das chaves
históricas de preferências.
