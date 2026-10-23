#!/usr/bin/env bash
# Falha se a ferramenta, a análise ou os testes falharem. Não interpreta texto de logs.
set -euo pipefail
export PATH="/home/caioguerras/sdk/flutter/bin:$HOME/sdk/flutter/bin:$PATH"
cd "$(dirname "$0")/.."
flutter pub get --no-example
flutter analyze --no-fatal-infos --no-fatal-warnings lib
flutter test test/heisuca test/services/track_selection_service_test.dart
printf '%s\n' 'APROVADO: análise e testes concluídos.'
