#!/usr/bin/env bash
# Cloudflare build bootstrap script
#
# The Cloudflare build image ships without Flutter. This script:
#   1. Downloads and installs a pinned Flutter SDK (skipped when cached)
#   2. Builds the web release into future_self_app/build/web
#
# wrangler.jsonc then points assets.directory at that output,
# and Cloudflare's default `npx wrangler deploy` publishes it.
set -euo pipefail

FLUTTER_VERSION="3.47.9"      # Keep in sync with local development
SDK_DIR="${HOME}/.flutter-sdk"
FLUTTER_BIN="${SDK_DIR}/flutter/bin"
TARBALL="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${TARBALL}"

echo "==> Flutter ${FLUTTER_VERSION}"
echo "==> SDK directory: ${SDK_DIR}"

# Install the SDK. Cloudflare may retain $HOME between builds; a cache hit skips the 1.58GB download.
if [ -x "${FLUTTER_BIN}/flutter" ]; then
  echo "==> SDK already present, skipping download"
else
  echo "==> Downloading Flutter SDK (~1.58GB, slow on first run)..."
  mkdir -p "${SDK_DIR}"
  if ! curl -fL --retry 3 --retry-delay 5 "${URL}" -o /tmp/flutter.tar.xz; then
    echo "!! Failed to download the Flutter SDK; check that the URL is still valid:" >&2
    echo "   ${URL}" >&2
    exit 1
  fi
  echo "==> Extracting..."
  tar -xJf /tmp/flutter.tar.xz -C "${SDK_DIR}"
  rm -f /tmp/flutter.tar.xz
fi

export PATH="${FLUTTER_BIN}:${PATH}"
export PUB_CACHE="${SDK_DIR}/.pub-cache"
flutter config --no-analytics >/dev/null 2>&1 || true

echo "==> Flutter version:"
flutter --version

echo "==> Entering future_self_app"
cd future_self_app

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build web --release"
flutter build web --release

echo "==> Build output:"
ls -la build/web
test -f build/web/index.html || { echo "!! index.html was not produced; build failed" >&2; exit 1; }
echo "==> Build complete; handing off to wrangler"
