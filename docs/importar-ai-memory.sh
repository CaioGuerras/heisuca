#!/usr/bin/env bash
# Executar no host onde o ai-memory de Caio está instalado e autenticado.
# Os dois argumentos devem vir do briefing/marker existente, nunca de adivinhação.
set -euo pipefail
if [ "$#" -ne 2 ]; then
  printf '%s\n' 'Uso: bash docs/importar-ai-memory.sh WORKSPACE_EXISTENTE PROJETO_EXISTENTE' >&2
  exit 2
fi
command -v ai-memory >/dev/null
handoff_dir="$(cd "$(dirname "$0")" && pwd)"
handoff_source="$handoff_dir/HANDOFF_ANDROID_2026-10-22.md"
handoff_page='handoffs/heisuca-android-2026-10-22.md'
handoff_readback="$(mktemp)"
trap 'rm -f "$handoff_readback"' EXIT
ai-memory write-page --workspace "$1" --project "$2" --path "$handoff_page" \
  --title 'Heisuca Android — Home do site e continuidade — 22/10/2026' --body - < "$handoff_source"
ai-memory read-page --workspace "$1" --project "$2" --path "$handoff_page" > "$handoff_readback"
python3 - "$handoff_source" "$handoff_readback" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text().strip()
readback = Path(sys.argv[2]).read_text()
if source not in readback:
    raise SystemExit('A página foi escrita, mas a leitura não confirmou o corpo integral. Conferir no ai-memory antes de declarar sucesso.')
print('Importação e leitura integral confirmadas no escopo informado.')
PY
