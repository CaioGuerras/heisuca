#!/usr/bin/env bash
# Marca oficial Heisuca: variante 1 aprovada, nunca o asset antigo do Plezy.
set -euo pipefail
python3 "$(dirname "$0")/generate_heisuca_android_icons.py" "$@"
