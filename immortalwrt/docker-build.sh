#!/bin/bash
set -euxo pipefail

WORKDIR=$(pwd)

docker run --rm \
  --user root \
  -v "$WORKDIR/bin:/home/build/immortalwrt/bin" \
  -v "$WORKDIR/files:/home/build/immortalwrt/files" \
  -v "$WORKDIR/build.sh:/home/build/immortalwrt/build.sh" \
  immortalwrt/imagebuilder:armsr-armv7-openwrt-24.10 \
  /home/build/immortalwrt/build.sh

# ✅ 修复权限 & 调试输出
sudo chmod -R 777 bin || true
echo "=== Bin 目录内容 ==="
ls -R bin || true
