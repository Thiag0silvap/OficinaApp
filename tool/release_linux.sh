#!/usr/bin/env bash
set -euo pipefail

# Uso:
#   bash tool/release_linux.sh build
#   bash tool/release_linux.sh patch
#   bash tool/release_linux.sh minor
#   bash tool/release_linux.sh major
#
# Faz:
# 1) Bump da versão (pubspec + AppVersion)
# 2) Build linux release
# 3) Gera um .zip do bundle em /dist
# 4) Gera um manifest JSON em /dist (você só edita o downloadUrl)

BUMP_KIND="${1:-build}"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

# 1) version bump

dart run tool/bump_version.dart "$BUMP_KIND"

# 2) build
flutter build linux --release

# 3) zip
VERSION="$(grep -E '^version:' pubspec.yaml | awk '{print $2}')"
DIST_DIR="$ROOT_DIR/dist"
mkdir -p "$DIST_DIR"
SAFE_VERSION="${VERSION//+/_}"
ZIP_NAME="oficinaapp_linux_${SAFE_VERSION}.zip"

rm -f "$DIST_DIR/$ZIP_NAME"
(
  cd build/linux/x64/release/bundle
  zip -r "$DIST_DIR/$ZIP_NAME" .
)

# 4) manifest
MANIFEST_PATH="$DIST_DIR/update_manifest.json"
cat > "$MANIFEST_PATH" <<EOF
{
  "latestVersion": "$VERSION",
  "downloadUrl": "https://SEU_LINK_AQUI/$ZIP_NAME",
  "notes": "- Descreva aqui as mudanças desta versão"
}
EOF

echo "OK"
echo "- Zip: $DIST_DIR/$ZIP_NAME"
echo "- Manifest: $MANIFEST_PATH"
