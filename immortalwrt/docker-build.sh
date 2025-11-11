#!/bin/bash
set -euxo pipefail

WORKDIR=$(pwd)

echo "[Host] 启动 ARMv7 镜像构建环境..."

docker run --rm --platform linux/arm/v7 \
  --user root \
  -v "$WORKDIR/bin:/home/build/immortalwrt/bin" \
  -v "$WORKDIR/files:/home/build/immortalwrt/files" \
  -v "$WORKDIR/build.sh:/home/build/immortalwrt/build.sh" \
  ghcr.io/adjlevis/immortalwrt-imagebuilder:armsr-armv7-latest \
  /bin/bash -c '
    set -euxo pipefail
    echo "[Container] 安装 qemu-utils..."
    apt-get update -qq && apt-get install -y -qq qemu-utils > /dev/null 2>&1 || true
    echo "[Container] 开始执行 build.sh..."
    cd /home/build/immortalwrt
    ./build.sh
    echo "[Container] build.sh 执行完成。"
  '

sudo chmod -R 777 bin || true
echo "=== Bin 目录内容 ==="
ls -R bin || true
