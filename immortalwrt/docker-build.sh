#!/bin/bash
set -euxo pipefail

WORKDIR=$(pwd)
IMAGE="ghcr.io/adjlevis/immortalwrt-imagebuilder:armsr-armv7-latest"

echo "=== 拉取镜像：$IMAGE ==="
docker pull "$IMAGE"

docker run --rm --platform linux/arm/v7 \
  --user root \
  -v "$WORKDIR/bin:/home/build/immortalwrt/bin" \
  -v "$WORKDIR/files:/home/build/immortalwrt/files" \
  -v "$WORKDIR/build.sh:/home/build/immortalwrt/build.sh" \
  "$IMAGE" /bin/sh -c '
    set -eux
    echo "[容器] 安装 qemu-utils..."
    if command -v apk >/dev/null 2>&1; then
      apk add --no-cache qemu-img || true
    else
      apt-get update -qq && apt-get install -y -qq qemu-utils || true
    fi

    echo "[容器] 开始执行 build.sh..."
    cd /home/build/immortalwrt
    sh ./build.sh
    echo "[容器] build.sh 执行完成。"
  '

sudo chmod -R 777 bin || true
echo "=== Bin 目录内容 ==="
ls -R bin || true
