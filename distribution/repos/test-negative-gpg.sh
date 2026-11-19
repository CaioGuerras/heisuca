#!/usr/bin/env bash
set -euo pipefail

: "${REPO_BASE:?Variavel REPO_BASE nao definida}"

echo "[TEST] Verificando rejeicao de pacote com assinatura adulterada/ausente..."
TMP_CORRUPT="/tmp/corrupt-test.rpm"
curl -fsSL "${REPO_BASE}/rpm/packages/heisuca-2.0.45-2.fc45.x86_64.rpm" -o "${TMP_CORRUPT}"

# Adultera o payload mantendo o tamanho
tamanho=$(stat -c %s "$TMP_CORRUPT")
offset=$((tamanho / 2))
printf '\xff\xff\xff\xff' | dd of="$TMP_CORRUPT" bs=1 seek="$offset" count=4 conv=notrunc 2>/dev/null

CHECK_RESULT=0
LC_ALL=C rpmkeys --checksig -v "${TMP_CORRUPT}" > /tmp/checksig.log 2>&1 || CHECK_RESULT=$?

rm -f "${TMP_CORRUPT}"

if [ "${CHECK_RESULT}" -ne 0 ] || grep -E -q "BAD|NOTOK|NOT OK" /tmp/checksig.log; then
    echo '{"status":"success","test":"negative_gpg_rejection","verified":true}'
    exit 0
else
    echo '{"status":"failure","test":"negative_gpg_rejection","error":"rpmkeys_accepted_corrupted_payload"}' >&2
    exit 1
fi
