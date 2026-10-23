#!/usr/bin/env bash
# Executar no host onde o ai-memory de Caio está instalado e autenticado.
# Usar workspace/projeto existentes no briefing ou marker.
set -euo pipefail
if [ "$#" -ne 2 ]; then
  printf '%s\n' 'Uso: bash docs/importar-ai-memory.sh WORKSPACE_EXISTENTE PROJETO_EXISTENTE' >&2
  exit 2
fi
command -v ai-memory >/dev/null
handoff_dir="$(cd "$(dirname "$0")" && pwd)"
handoff_readback="$(mktemp)"
trap 'rm -f "$handoff_readback"' EXIT
handoff_files=(HANDOFF_ANDROID_2026-10-22.md PROXIMA_ETAPA_TITULO_FONTES_AJUSTES_2026-10-23.md HANDOFF_FICHA_FONTES_PLAYER_2026-10-23.md)
handoff_pages=(handoffs/heisuca-android-2026-10-22.md handoffs/heisuca-proposta-ficha-2026-10-23.md handoffs/heisuca-ficha-fontes-player-2026-10-23.md)
for handoff_index in "${!handoff_files[@]}"; do
  handoff_source="$handoff_dir/${handoff_files[$handoff_index]}"
  handoff_page="${handoff_pages[$handoff_index]}"
  ai-memory write-page --workspace "$1" --project "$2" --path "$handoff_page" \
    --title "Heisuca — ${handoff_files[$handoff_index]}" --body - < "$handoff_source"
  ai-memory read-page --workspace "$1" --project "$2" --path "$handoff_page" > "$handoff_readback"
  python3 - "$handoff_source" "$handoff_readback" <<'PY'
from pathlib import Path
import sys
source = Path(sys.argv[1]).read_text().strip()
readback = Path(sys.argv[2]).read_text()
if source not in readback:
    raise SystemExit('A leitura não confirmou o corpo integral. Conferir no ai-memory antes de declarar sucesso.')
print(f'Importação e leitura integral confirmadas: {Path(sys.argv[1]).name}')
PY
done
