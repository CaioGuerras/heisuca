#!/bin/bash
# Traz a marca (tokens, fontes, ícones, abertura) do repositório da pesquisa para o site.
# Fonte única: ~/cgflix/pesquisa_apps/marca. Rodar de novo quando a marca mudar.
set -euo pipefail
M=${MARCA:-$HOME/cgflix/pesquisa_apps/marca}
D=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$D/src/marca/temas" "$D/src/marca/fontes"
cp "$M/tokens/saida/css/base.css" "$D/src/marca/"
cp "$M"/tokens/saida/css/temas/*.css "$D/src/marca/temas/"
cp "$M"/animacoes/fontes/*.woff2 "$M"/animacoes/fontes/OFL_*.txt "$D/src/marca/fontes/" 2>/dev/null || true
cp "$M"/icones/web/* "$D/public/"
# A abertura: só o <svg> e as regras de animação do abertura.html
python3 -I - "$M/animacoes/abertura.html" "$D/src/marca" <<'PY'
import re, sys
h = open(sys.argv[1], encoding='utf-8').read()
svg = re.search(r'<svg class="marca".*?</svg>', h, re.S).group(0)
css = re.search(r'<style>(.*?)</style>', h, re.S).group(1)
css = '\n'.join(l for l in css.splitlines() if not l.startswith(('@font-face', 'html, body')))
open(sys.argv[2] + '/abertura.svg', 'w', encoding='utf-8').write(svg)
open(sys.argv[2] + '/abertura.css', 'w', encoding='utf-8').write(css)
PY
echo "marca sincronizada de $M"
