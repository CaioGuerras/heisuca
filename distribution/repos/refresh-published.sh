#!/usr/bin/env bash
set -euo pipefail
umask 077

# Bloqueio exclusivo para evitar execuções concorrentes
LOCK_FILE="/root/heisuca-package-repository/refresh.lock"
exec 200>"$LOCK_FILE"
flock -n 200 || { echo "ERRO: Processo de refresh já em execução." >&2; exit 1; }

# Definições de caminhos
BASE_DIR="/root/heisuca-package-repository"
GPG_DIR="$BASE_DIR/gpg"
FINGERPRINT_FILE="$BASE_DIR/KEY-FINGERPRINT.txt"
BUILDER_SCRIPT="$BASE_DIR/source/build_repos.py"
DOCKER_IMAGE="heisuca-repo-builder:20261119"

WEB_ROOT="/var/www/heisuca"
SYMLINK_PUB="$WEB_ROOT/pacotes/repos"
SNAPSHOT_DIR="$WEB_ROOT/repository-snapshots"

# Verificações de pré-requisitos
[[ $EUID -eq 0 ]] || { echo "ERRO: Execução permitida apenas para root." >&2; exit 1; }
[[ -d "$GPG_DIR" ]] || { echo "ERRO: Diretório GPG não encontrado: $GPG_DIR" >&2; exit 1; }
[[ -f "$FINGERPRINT_FILE" ]] || { echo "ERRO: Arquivo de fingerprint ausente: $FINGERPRINT_FILE" >&2; exit 1; }
[[ -f "$BUILDER_SCRIPT" ]] || { echo "ERRO: Script de build ausente: $BUILDER_SCRIPT" >&2; exit 1; }

KEY_ID="$(tr -d '[:space:]' < "$FINGERPRINT_FILE")"
[[ -n "$KEY_ID" ]] || { echo "ERRO: Fingerprint da chave GPG está vazio." >&2; exit 1; }

# Validação do symlink atual de publicação
[[ -L "$SYMLINK_PUB" ]] || { echo "ERRO: $SYMLINK_PUB não é um symlink." >&2; exit 1; }
CURRENT_TARGET="$(readlink -f "$SYMLINK_PUB")"
REAL_SNAPSHOT_DIR="$(readlink -f "$SNAPSHOT_DIR")"

if [[ "$CURRENT_TARGET" != "$REAL_SNAPSHOT_DIR"/* ]] || [[ ! -d "$CURRENT_TARGET" ]]; then
    echo "ERRO: O symlink de produção não aponta para um snapshot válido em $SNAPSHOT_DIR" >&2
    exit 1
fi

# Criação do novo snapshot via cópia integral (sem hardlinks)
NEW_TIMESTAMP="$(date -u +%Y%m%dT%H%M%S%NZ)"
NEW_SNAPSHOT="$SNAPSHOT_DIR/$NEW_TIMESTAMP"

echo "[INFO] Copiando snapshot atual para $NEW_SNAPSHOT..."
cp -a "$CURRENT_TARGET" "$NEW_SNAPSHOT"

# Atualização de metadados via container Docker
echo "[INFO] Iniciando build de metadados no container..."
if ! docker run --rm --network none \
    --mount type=bind,source="$GPG_DIR",target=/heisuca-signing-home \
    --mount type=bind,source="$(dirname "$BUILDER_SCRIPT")",target=/source,readonly \
    --mount type=bind,source="$NEW_SNAPSHOT",target=/work/output \
    "$DOCKER_IMAGE" \
    python3 /source/build_repos.py \
        --refresh-metadata \
        --output /work/output \
        --gpg-home /heisuca-signing-home \
        --key-id "$KEY_ID" \
        --base-url https://heisuca.docaio.com.br/pacotes/repos \
        --valid-days 90; then
    echo "ERRO: Falha ao gerar metadados. Produção inalterada. Snapshot retido em: $NEW_SNAPSHOT" >&2
    exit 1
fi

# Ajuste estrito de permissões públicas somente no novo snapshot
echo "[INFO] Ajustando permissões (pastas 755 / arquivos 644)..."
find "$NEW_SNAPSHOT" -xdev -type d -exec chmod 755 {} +
find "$NEW_SNAPSHOT" -xdev -type f -exec chmod 644 {} +

# Publicação atômica via substituição de symlink
TMP_LINK="$WEB_ROOT/pacotes/repos.tmp.$$"
ln -s "$NEW_SNAPSHOT" "$TMP_LINK"
mv -T "$TMP_LINK" "$SYMLINK_PUB"

echo "[SUCESSO] Repositório atualizado e publicado em $NEW_SNAPSHOT"
