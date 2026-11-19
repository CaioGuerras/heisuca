#!/usr/bin/env bash
set -euo pipefail

# 1. Validação de variáveis obrigatórias
: "${REPO_BASE:?Variavel REPO_BASE nao definida}"
: "${PUBLIC_FINGERPRINT:?Variavel PUBLIC_FINGERPRINT nao definida}"

FIXED_OLD_BASE="https://heisuca.docaio.com.br"
OLD_DEB_URL="${FIXED_OLD_BASE}/pacotes/linux/teste-46df8e02/heisuca-linux-x64.deb"
EXPECTED_VERSION="2.0.45-2"
SENTINEL_FILE="/root/.local/share/app.heisuca.player.desktop/fixture-perfil.txt"

# 2. Pré-checagem de disco em KiB (evita falha de int no df -h)
FREE_KIB=$(df -k / | awk 'NR==2 {print $4}')
if [ "${FREE_KIB}" -lt 512000 ]; then
    echo "Espaco insuficiente em disco: ${FREE_KIB} KiB disponiveis." >&2
    exit 1
fi

# 3. Bootstrap mínimo em imagem limpa Ubuntu 24
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends curl ca-certificates gnupg

# 4. Instalação do pacote legado
TMP_OLD_DEB="/tmp/heisuca-old.deb"
curl -fsSL "${OLD_DEB_URL}" -o "${TMP_OLD_DEB}"
dpkg -i "${TMP_OLD_DEB}" || apt-get install -f -y --no-install-recommends
rm -f "${TMP_OLD_DEB}"

# 5. Criação do arquivo sentinela de fixture antes da atualização
mkdir -p "$(dirname "${SENTINEL_FILE}")"
echo "fixture-payload-verificacao-upgrade" > "${SENTINEL_FILE}"

# 6. Configuração do repositório APT e chave pública
KEYRING_DIR="/etc/apt/keyrings"
KEYRING_PATH="${KEYRING_DIR}/heisuca-archive-keyring.gpg"
mkdir -p "${KEYRING_DIR}"

curl -fsSL "${REPO_BASE}/apt/heisuca-archive-keyring.gpg" -o "${KEYRING_PATH}"

# Validação do fingerprint sem manipular chaves privadas
FINGERPRINT_CHECK=$(gpg --no-default-keyring --keyring "${KEYRING_PATH}" --list-keys --with-colons 2>/dev/null | awk -F: '/^fpr:/ {print $10}' | head -n 1)
NORMALIZED_EXPECTED=$(echo "${PUBLIC_FINGERPRINT}" | tr -d ' ' | tr '[:lower:]' '[:upper:]')
NORMALIZED_FOUND=$(echo "${FINGERPRINT_CHECK}" | tr -d ' ' | tr '[:lower:]' '[:upper:]')

if [ -z "${NORMALIZED_FOUND}" ] || [ "${NORMALIZED_FOUND}" != "${NORMALIZED_EXPECTED}" ]; then
    echo "Fingerprint da chave APT invalido. Esperado: ${NORMALIZED_EXPECTED}, Encontrado: ${NORMALIZED_FOUND}" >&2
    exit 1
fi

echo "deb [signed-by=${KEYRING_PATH}] ${REPO_BASE}/apt stable main" > /etc/apt/sources.list.d/heisuca.list

# 7. Atualização via repositório
apt-get update
apt-get install -y --no-install-recommends --only-upgrade heisuca

# 8. Asserts de integridade e versão
INSTALLED_VERSION=$(dpkg-query -W -f='${Version}' heisuca)
if [ "${INSTALLED_VERSION}" != "${EXPECTED_VERSION}" ]; then
    echo "Versao instalada invalida: ${INSTALLED_VERSION} != ${EXPECTED_VERSION}" >&2
    exit 1
fi

if [ ! -f "${SENTINEL_FILE}" ] || [ "$(<"${SENTINEL_FILE}")" != "fixture-payload-verificacao-upgrade" ]; then
    echo "Arquivo sentinela corrompido ou ausente apos o upgrade." >&2
    exit 1
fi

# 9. Emissão JSON final de sucesso
cat <<EOF
{"status":"success","distro":"ubuntu","package":"heisuca","version":"${INSTALLED_VERSION}","sentinel":true}
EOF
