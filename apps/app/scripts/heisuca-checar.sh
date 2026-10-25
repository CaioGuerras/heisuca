#!/usr/bin/env bash
# Falha se a ferramenta, a análise ou os testes falharem. Não interpreta texto de logs.
set -euo pipefail
export PATH="/home/caioguerras/sdk/flutter/bin:$HOME/sdk/flutter/bin:$PATH"
cd "$(dirname "$0")/.."
flutter pub get --no-example
flutter analyze --no-fatal-infos --no-fatal-warnings lib
flutter test test/heisuca test/cgflix/cgflix_dicas_test.dart test/services/track_selection_service_test.dart test/cgflix/cgflix_home_test.dart test/cgflix/cgflix_cards_test.dart test/cgflix/cgflix_seerr_test.dart test/startup_bootstrap_test.dart test/widgets/video_controls_test.dart test/screens/actor_media_screen_test.dart test/services/plex_library_details_test.dart test/services/jellyfin_favorites_isolation_test.dart test/screens/video_player/player_route_exit_test.dart test/utils/video_player_navigation_test.dart
# A2: a listra só foi reproduzida com Impeller; o teste padrão sozinho não detecta a regressão.
flutter test --enable-impeller test/heisuca/heisuca_art_edge_test.dart
printf '%s\n' 'APROVADO: análise e testes concluídos.'
