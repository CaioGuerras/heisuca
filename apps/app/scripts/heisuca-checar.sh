#!/usr/bin/env bash
# Falha se a ferramenta, a análise ou os testes falharem. Não interpreta texto de logs.
set -euo pipefail
export PATH="/home/caioguerras/sdk/flutter/bin:$HOME/sdk/flutter/bin:$PATH"
cd "$(dirname "$0")/.."
flutter pub get --no-example
python3 -m unittest discover -s scripts/bancada -p 'test_*.py'
flutter analyze --no-fatal-infos --no-fatal-warnings lib integration_test test_driver test
flutter test test/cgflix/heisuca_palette_p_test.dart test/cgflix/cgflix_contraste_test.dart test/cgflix/cgflix_theme_test.dart test/theme/mono_theme_test.dart test/services/jellyfin_client_urls_test.dart test/services/sleep_timer_service_test.dart test/screens/video_player/still_watching_sleep_timer_test.dart test/screens/video_player/playback_reload_failure_test.dart test/bancada test/screens/video_player/auto_pip_readiness_test.dart test/screens/video_player/video_player_automotive_test.dart test/services/media_controls_manager_test.dart test/heisuca test/utils/android_exit_diagnostics_test.dart test/services/settings_service_test.dart test/services/startup_diagnostics_test.dart test/services/plex_mappers_test.dart test/utils/certificate_trust_test.dart test/android/network_security_config_test.dart test/utils/navigation_transitions_test.dart test/services/jellyfin_endpoint_discovery_test.dart test/cgflix/cgflix_use_you_tab_test.dart test/cgflix/cgflix_dicas_test.dart test/cgflix/cgflix_navigation_test.dart test/services/track_selection_service_test.dart test/cgflix/cgflix_home_test.dart test/cgflix/cgflix_cards_test.dart test/cgflix/cgflix_seerr_test.dart test/startup_bootstrap_test.dart test/widgets/video_controls_test.dart test/screens/actor_media_screen_test.dart test/services/plex_library_details_test.dart test/services/jellyfin_favorites_isolation_test.dart test/screens/video_player/player_route_exit_test.dart test/utils/video_player_navigation_test.dart test/utils/app_binding_composition_test.dart
# A2: a listra só foi reproduzida com Impeller; o teste padrão sozinho não detecta a regressão.
flutter test --enable-impeller test/heisuca/heisuca_art_edge_test.dart
printf '%s\n' 'APROVADO: análise e testes concluídos.'
