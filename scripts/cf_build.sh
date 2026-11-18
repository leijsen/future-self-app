#!/usr/bin/env bash
# Cloudflare 构建启动脚本
#
# Cloudflare 构建机没有预装 Flutter，本脚本负责：
#   1. 下载并安装指定版本的 Flutter SDK（有缓存则跳过）
#   2. 编译 Web 版，产出 future_self_app/build/web
#
# 之后 wrangler.jsonc 里的 assets.directory 会指向该产物目录，
# 由 Cloudflare 默认的 `npx wrangler deploy` 完成发布。
set -euo pipefail

FLUTTER_VERSION="3.47.9"      # 与本地开发一致
SDK_DIR="${HOME}/.flutter-sdk"
FLUTTER_BIN="${SDK_DIR}/flutter/bin"
TARBALL="flutter_linux_${FLUTTER_VERSION}-stable.tar.xz"
URL="https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/${TARBALL}"

echo "==> Flutter ${FLUTTER_VERSION}"
echo "==> SDK 目录: ${SDK_DIR}"

# 安装 SDK（Cloudflare 会尽量保留 $HOME，命中缓存则跳过 1.58GB 下载）
if [ -x "${FLUTTER_BIN}/flutter" ]; then
  echo "==> SDK 已存在，跳过下载"
else
  echo "==> 下载 Flutter SDK（约 1.58GB，首次较慢）..."
  mkdir -p "${SDK_DIR}"
  if ! curl -fL --retry 3 --retry-delay 5 "${URL}" -o /tmp/flutter.tar.xz; then
    echo "!! Flutter SDK 下载失败，检查 URL 是否有效：" >&2
    echo "   ${URL}" >&2
    exit 1
  fi
  echo "==> 解压..."
  tar -xJf /tmp/flutter.tar.xz -C "${SDK_DIR}"
  rm -f /tmp/flutter.tar.xz
fi

export PATH="${FLUTTER_BIN}:${PATH}"
export PUB_CACHE="${SDK_DIR}/.pub-cache"
flutter config --no-analytics >/dev/null 2>&1 || true

echo "==> Flutter 版本:"
flutter --version

echo "==> 进入 future_self_app"
cd future_self_app

echo "==> flutter pub get"
flutter pub get

echo "==> flutter build web --release"
flutter build web --release

echo "==> 构建产物:"
ls -la build/web
test -f build/web/index.html || { echo "!! index.html 未生成，构建失败" >&2; exit 1; }
echo "==> 构建完成，等待 wrangler 发布"
