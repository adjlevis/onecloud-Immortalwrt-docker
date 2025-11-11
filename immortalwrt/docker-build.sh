#!/bin/bash
#=================================================
# OneCloud ImmortalWrt Docker 构建脚本（增强版）
#=================================================
set -euxo pipefail

# 当前工作目录
WORKDIR=$(pwd)

# 默认镜像名称（可通过环境变量覆盖）
IMAGE_NAME="${IMAGE_NAME:-ghcr.io/adjlevis/immortalwrt-imagebuilder:armsr-armv7-latest}"

echo "================================================="
echo "[Docker] 使用镜像: $IMAGE_NAME"
echo "================================================="

# 拉取最新镜像，确保环境最新
docker pull "$IMAGE_NAME"

echo "[Docker] 启动容器并构建固件..."
docker run --rm \
  --user root \
  -v "$WORKDIR/bin:/home/build/immortalwrt/bin" \
  -v "$WORKDIR/files:/home/build/immortalwrt/files" \
  -v "$WORKDIR/build.sh:/home/build/immortalwrt/build.sh" \
  "$IMAGE_NAME" /bin/bash -c "
    set -euxo pipefail
    echo '[Container] 安装 qemu-utils...'
    apt update -qq && apt install -y -qq qemu-utils > /dev/null 2>&1 || true
    echo '[Container] 开始执行 build.sh...'
    cd /home/build/immortalwrt
    ./build.sh
    echo '[Container] build.sh 执行完成。'
  "

echo "================================================="
echo "[Host] 修复 bin 目录权限..."
sudo chmod -R 777 bin || true

echo "================================================="
echo "[Host] Bin 目录内容如下："
ls -lhR bin || true
echo "================================================="

echo "[Docker] 构建流程全部完成 ✅"
