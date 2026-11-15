#!/usr/bin/env bash
# Ramo de frente da V2 (claude/heisuca-v2-*, codex/heisuca-v2-*, gemini/heisuca-v2-*) só compila e testa
# se já tiver a ponta de claude/heisuca-v2. Sem isso, a bancada e as revisões rodam código velho e voltam a
# apontar falhas já corrigidas. Outros ramos passam direto.
# Uso: scripts/heisuca-ramo-em-dia.sh <nome-do-ramo>
set -euo pipefail

ramo="${1:?informe o ramo}"
base="claude/heisuca-v2"

case "$ramo" in
  claude/heisuca-v2-* | codex/heisuca-v2-* | gemini/heisuca-v2-*) ;;
  *)
    echo "Ramo $ramo fora das frentes da V2: sem conferência."
    exit 0
    ;;
esac

# O checkout do Actions é raso: busca o histórico sem os arquivos (rápido) e a ponta da V2.
if [ "$(git rev-parse --is-shallow-repository)" = "true" ]; then
  git fetch --quiet --no-tags --filter=blob:none --unshallow origin
fi
git fetch --quiet --no-tags --filter=blob:none origin "+refs/heads/$base:refs/remotes/origin/$base"

ponta="$(git rev-parse "origin/$base")"
if git merge-base --is-ancestor "$ponta" HEAD; then
  echo "Em dia: $ramo já contém a ponta de $base (${ponta:0:8})."
  exit 0
fi

faltam="$(git rev-list --count "HEAD..origin/$base")"
echo "::error title=Ramo atrasado::$ramo está $faltam commit(s) atrás de $base (${ponta:0:8})."
echo "Antes de compilar ou testar: git fetch origin && git merge origin/$base, e envie de novo."
exit 1
