#!/usr/bin/env bash
# Preparação do ambiente do Codex (nuvem da OpenAI) para o Heisuca. No campo "setup script" do ambiente,
# coloque só: bash scripts/codex-setup.sh
# Instala o Flutter na versão do CI (.github/workflows/heisuca-android.yml) em $HOME/sdk/flutter, o caminho que
# apps/app/scripts/heisuca-checar.sh já procura, e baixa as dependências. Não precisa de Android SDK: o APK sai no
# GitHub Actions; aqui é só análise e testes.
set -euo pipefail
FLUTTER_VERSION="3.47.1"
FLUTTER_DIR="$HOME/sdk/flutter"
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  mkdir -p "$HOME/sdk"
  git clone --depth 1 -b "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"
grep -q 'sdk/flutter/bin' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/sdk/flutter/bin:$PATH"' >> "$HOME/.bashrc"
flutter config --no-analytics >/dev/null
flutter --version
cd "$(dirname "$0")/../apps/app"
flutter pub get
echo "Ambiente pronto: rode 'bash apps/app/scripts/heisuca-checar.sh' antes de cada push."
