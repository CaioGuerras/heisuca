#!/usr/bin/env bash
# Portão antes de qualquer push do app Android: 0 erros no analyze (Flutter local em ~/sdk/flutter).
set -euo pipefail
export PATH="/home/caioguerras/sdk/flutter/bin:$HOME/sdk/flutter/bin:$PATH"
cd "$(dirname "$0")/.."
flutter pub get --no-example >/dev/null
saida=$(flutter analyze --no-fatal-infos --no-fatal-warnings lib 2>&1 || true)
erros=$(grep -cE '^ *error' <<<"$saida" || true)
if [ "$erros" -gt 0 ]; then grep -E '^ *error' <<<"$saida"; echo "REPROVADO: $erros erro(s). Não faça push."; exit 1; fi
echo "APROVADO: 0 erros no analyze."
