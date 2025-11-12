#!/usr/bin/env bash
set -e

echo "[INFO] === 启动 ImmortalWrt Docker 构建环境 ==="

# 当前路径
WORKDIR=$(pwd)
IMAGE="immortalwrt/imagebuilder:armsr-armv7-24.10-SNAPSHOT"

echo "[INFO] 当前工作目录: $WORKDIR"
echo "[INFO] 使用镜像: $IMAGE"

# 检查构建脚本
if [ ! -f "$WORKDIR/immortalwrt/build.sh" ]; then
    echo "[ERROR] 未找到构建脚本: $WORKDIR/immortalwrt/build.sh"
    exit 1
fi

# 修复换行符问题
echo "[INFO] 修复 build.sh 格式..."
dos2unix "$WORKDIR/immortalwrt/build.sh" || true
chmod +x "$WORKDIR/immortalwrt/build.sh"

# 创建输出目录
mkdir -p "$WORKDIR/release"

echo "[INFO] 启动 Docker 容器进行编译..."
docker run --rm -i \
    -v "$WORKDIR/immortalwrt:/home/build/immortalwrt" \
    -v "$WORKDIR/tool:/home/build/tool" \
    -v "$WORKDIR/release:/home/build/release" \
    -e ROOTFS_PARTSIZE=512 \
    -e TZ=Asia/Shanghai \
    "$IMAGE" bash -c "
        set -eux
        cd /home/build/immortalwrt

        echo '[Build] 🚀 开始构建 ImmortalWrt 固件...'

        # 修复权限
        chmod -R 777 /home/build/immortalwrt

        rm -rf bin/ || true
        mkdir -p bin/

        PACKAGES='curl luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn luci-i18n-opkg-zh-cn luci-i18n-upnp-zh-cn luci-app-upnp luci-app-firewall'
        echo '[Build] 📦 软件包列表: ' \$PACKAGES

        make -C . image PROFILE=generic PACKAGES=\"\$PACKAGES\" EXTRA_IMAGE_NAME=emmc-burn EXTRA_IMAGE_FORMATS='ext4.gz img.gz' ROOTFS_PARTSIZE=512

        echo '[Build] ✅ 构建完成！'
        ls -lh bin/targets/armsr/armv7/ || true
    "

echo "[INFO] === Docker 构建完成 ==="
