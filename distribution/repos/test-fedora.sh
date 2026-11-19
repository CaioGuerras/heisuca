#!/usr/bin/env bash
set -euo pipefail

# 1. Validação de variáveis obrigatórias
: "${REPO_BASE:?Variavel REPO_BASE nao definida}"
: "${PUBLIC_FINGERPRINT:?Variavel PUBLIC_FINGERPRINT nao definida}"

FIXED_OLD_BASE="https://heisuca.docaio.com.br"
OLD_RPM_URL="${FIXED_OLD_BASE}/pacotes/linux/teste-e3a2f56a/heisuca-linux-x64.rpm"
EXPECTED_VERSION="2.0.45-2.fc45"
SENTINEL_FILE="/root/.local/share/app.heisuca.player.desktop/fixture-perfil.txt"

# 2. Pré-checagem de disco em KiB
FREE_KIB=$(df -k / | awk 'NR==2 {print $4}')
if [ "${FREE_KIB}" -lt 512000 ]; then
    echo "Espaco insuficiente em disco: ${FREE_KIB} KiB disponiveis." >&2
    exit 1
fi

# 3. Bootstrap mínimo em Fedora 45 (compatível com curl-minimal/curl)
dnf install -y --setopt=install_weak_deps=False ca-certificates gnupg2 rpm-sign
if ! command -v curl >/dev/null 2>&1; then
    dnf install -y --setopt=install_weak_deps=False curl-minimal || dnf install -y --setopt=install_weak_deps=False curl
fi

# 4. Instalação do pacote legado (unsigned local, sem usar --nogpgcheck)
TMP_OLD_RPM="/tmp/heisuca-old.rpm"
curl -fsSL "${OLD_RPM_URL}" -o "${TMP_OLD_RPM}"
dnf install -y "${TMP_OLD_RPM}"
rm -f "${TMP_OLD_RPM}"

# 5. Configuração do sentinela
mkdir -p "$(dirname "${SENTINEL_FILE}")"
echo "fixture-payload-verificacao-upgrade" > "${SENTINEL_FILE}"

# 6. Validação e importação da chave GPG pública
GPG_KEY_PATH="/etc/pki/rpm-gpg/RPM-GPG-KEY-heisuca.asc"
mkdir -p "$(dirname "${GPG_KEY_PATH}")"
curl -fsSL "${REPO_BASE}/rpm/RPM-GPG-KEY-heisuca.asc" -o "${GPG_KEY_PATH}"

FINGERPRINT_CHECK=$(gpg --show-keys --with-colons "${GPG_KEY_PATH}" 2>/dev/null | awk -F: '/^fpr:/ {print $10}' | head -n 1)
NORMALIZED_EXPECTED=$(echo "${PUBLIC_FINGERPRINT}" | tr -d ' ' | tr '[:lower:]' '[:upper:]')
NORMALIZED_FOUND=$(echo "${FINGERPRINT_CHECK}" | tr -d ' ' | tr '[:lower:]' '[:upper:]')

if [ -z "${NORMALIZED_FOUND}" ] || [ "${NORMALIZED_FOUND}" != "${NORMALIZED_EXPECTED}" ]; then
    echo "Fingerprint da chave RPM invalido. Esperado: ${NORMALIZED_EXPECTED}, Encontrado: ${NORMALIZED_FOUND}" >&2
    exit 1
fi

rpm --import "${GPG_KEY_PATH}"

# 7. Verificação prévia do pacote assinado baixado via rpmkeys
RPMSIGNED="/tmp/heisuca-${EXPECTED_VERSION}.x86_64.rpm"
curl -fsSL "${REPO_BASE}/rpm/packages/heisuca-${EXPECTED_VERSION}.x86_64.rpm" -o "${RPMSIGNED}"

CHECK_OUTPUT=$(LC_ALL=C rpmkeys --checksig -v "${RPMSIGNED}")
echo "${CHECK_OUTPUT}" | grep -Eiq "Header.*RSA.*signature.*: OK" || {
    echo "Falha na validacao da assinatura RSA do pacote RPM." >&2
    exit 1
}

if echo "${CHECK_OUTPUT}" | grep -E -q "NOTOK|NOKEY|NOT OK"; then
    echo "Presenca de status de assinatura invalido (NOKEY/NOTOK) na saida do rpmkeys:" >&2
    echo "${CHECK_OUTPUT}" >&2
    exit 1
fi
rm -f "${RPMSIGNED}"

# 8. Configuração do repositório DNF com gpgcheck=1 e repo_gpgcheck=1
cat <<EOF > /etc/yum.repos.d/heisuca.repo
[heisuca]
name=Heisuca Repository
baseurl=${REPO_BASE}/rpm
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=file://${GPG_KEY_PATH}
EOF

# 9. Atualização via DNF
dnf upgrade -y heisuca

# 10. Asserts
INSTALLED_VERSION=$(rpm -q --qf '%{VERSION}-%{RELEASE}' heisuca)
if [ "${INSTALLED_VERSION}" != "${EXPECTED_VERSION}" ]; then
    echo "Versao instalada invalida: ${INSTALLED_VERSION} != ${EXPECTED_VERSION}" >&2
    exit 1
fi

if [ ! -f "${SENTINEL_FILE}" ] || [ "$(<"${SENTINEL_FILE}")" != "fixture-payload-verificacao-upgrade" ]; then
    echo "Arquivo sentinela corrompido ou ausente apos o upgrade." >&2
    exit 1
fi

# 11. Emissão JSON final de sucesso
cat <<EOF
{"status":"success","distro":"fedora","package":"heisuca","version":"${INSTALLED_VERSION}","sentinel":true}
EOF
