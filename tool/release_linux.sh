#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   bash tool/release_linux.sh build
#   bash tool/release_linux.sh patch
#   bash tool/release_linux.sh minor
#   bash tool/release_linux.sh major
#   bash tool/release_linux.sh none   # não altera a versão
#
# Faz:
# 1) Bump da versão (pubspec + AppVersion)
# 2) Build linux release
# 3) Gera um .zip do bundle em /dist
# 4) Gera um manifest JSON em /dist e atualiza também /docs (GitHub Pages)
#
# Pré-requisitos:
# - zip instalado
# - remote origin apontando para GitHub (para gerar o link automaticamente)

BUMP_KIND="${1:-build}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

die() {
  echo "Erro: $*" >&2
  exit 1
}

command -v zip >/dev/null 2>&1 || die "comando 'zip' não encontrado. Instale com: sudo apt install zip"

detect_github_repo() {
  local remote
  remote="$(git remote get-url origin 2>/dev/null || true)"
  remote="${remote%.git}"

  # Formatos suportados:
  # - https://github.com/OWNER/REPO
  # - git@github.com:OWNER/REPO
  if [[ "$remote" =~ github\.com[:/]+([^/]+)/([^/]+)$ ]]; then
    echo "${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
    return 0
  fi

  echo ""
  return 1
}

REPO_SLUG="$(detect_github_repo || true)"
if [[ -z "$REPO_SLUG" ]]; then
  # Fallback (ajuste se necessário)
  REPO_SLUG="Thiag0silvap/OficinaApp"
fi

# 1) version bump
if [[ "$BUMP_KIND" != "none" ]]; then
  dart run tool/bump_version.dart "$BUMP_KIND"
fi

# 2) build
flutter build linux --release

# 3) zip
VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"
SAFE_VERSION="${VERSION//+/_}"
ZIP_NAME="oficinaapp_linux_${SAFE_VERSION}.zip"
TAG_NAME="v${SAFE_VERSION}"

rm -f "$DIST_DIR/$ZIP_NAME"
(
  cd build/linux/x64/release/bundle
  zip -r "$DIST_DIR/$ZIP_NAME" .
)

# 4) manifest
MANIFEST_PATH="$DIST_DIR/update_manifest.json"

DOWNLOAD_URL="https://github.com/$REPO_SLUG/releases/download/$TAG_NAME/$ZIP_NAME"

cat > "$MANIFEST_PATH" <<EOF
{
  "latestVersion": "$VERSION",
  "downloadUrl": "$DOWNLOAD_URL",
  "notes": "- Descreva aqui as mudanças desta versão"
}
EOF

# Mantém o manifest também em /docs para o GitHub Pages servir
DOCS_DIR="$ROOT_DIR/docs"
DOCS_MANIFEST_PATH="$DOCS_DIR/update_manifest.json"
mkdir -p "$DOCS_DIR"
cp "$MANIFEST_PATH" "$DOCS_MANIFEST_PATH"

echo "OK"
echo "- Zip: $DIST_DIR/$ZIP_NAME"
echo "- Manifest: $MANIFEST_PATH"
echo "- Manifest (Pages): $DOCS_MANIFEST_PATH"
echo ""
echo "Próximo passo no GitHub:"
echo "1) Crie um Release com a tag: $TAG_NAME"
echo "2) Anexe o arquivo: $ZIP_NAME"
echo "3) Commit + push do docs/update_manifest.json (o script já atualizou)"
