#!/usr/bin/env bash
set -e

echo "[INFO] === 启动 ImmortalWrt Docker 构建环境 ==="

WORKDIR=$(pwd)
IMAGE="ghcr.io/adjlevis/immortalwrt-imagebuilder:armsr-armv7-24.10-SNAPSHOT"

echo "[INFO] 当前工作目录: $WORKDIR"
echo "[INFO] 使用镜像: $IMAGE"

# 检查必要目录
if [ ! -d "$WORKDIR/immortalwrt" ]; then
    echo "[ERROR] 未找到 immortalwrt 目录: $WORKDIR/immortalwrt"
    exit 1
fi

mkdir -p "$WORKDIR/release"

echo "[INFO] 启动 Docker 容器进行编译..."
docker run --rm --privileged -i \
    -v "$WORKDIR/immortalwrt:/home/build/openwrt" \
    -v "$WORKDIR/tool:/home/build/tool" \
    -v "$WORKDIR/release:/home/build/release" \
    -e ROOTFS_PARTSIZE=512 \
    -e TZ=Asia/Shanghai \
    "$IMAGE" bash -c "
        set -eux

        echo '[Build] 🚀 开始构建 ImmortalWrt 固件...'

        rm -rf bin/ || true
        mkdir -p bin/

        PACKAGES='curl luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn luci-i18n-opkg-zh-cn luci-i18n-upnp-zh-cn luci-app-upnp luci-app-firewall'
        echo '[Build] 📦 软件包列表: ' \$PACKAGES

        make image PROFILE=generic PACKAGES=\"\$PACKAGES\" \
            EXTRA_IMAGE_NAME=emmc-burn \
            EXTRA_IMAGE_FORMATS='ext4.gz img.gz' \
            ROOTFS_PARTSIZE=512

        echo '[Build] ✅ 构建完成！'
        ls -lh bin/targets/armsr/armv7/ || true

        cp -rf bin/targets/armsr/armv7/* /home/build/release/ || true
    "

echo "[INFO] === Docker 构建完成 ==="
