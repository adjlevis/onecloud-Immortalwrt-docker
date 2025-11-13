#!/bin/bash
set -e
set -o pipefail

# ============================================================
# 🚀 OneCloud ImmortalWrt Docker 构建 + Amlogic 线刷镜像打包脚本
# 基于：
#   1. ImmortalWrt 官方 ImageBuilder
#   2. ophub/amlogic-s9xxx-openwrt 打包工具
# ============================================================

# ======= 基本变量配置 =======
DEVICE="onecloud"
IMAGE_TAG="armsr-armv7-24.10-SNAPSHOT"
OUTPUT_DIR="$(pwd)/bin"
ROOTFS_DIR="$(pwd)/bin/rootfs"
RELEASE_DIR="$(pwd)/bin/release"
BUILD_TEMP="$(pwd)/build_temp"
PACKAGES="curl luci luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn luci-app-upnp luci-app-firewall"
FILES_DIR="$(pwd)/files"

echo "============================================================"
echo "🚀 OneCloud ImmortalWrt Docker 构建脚本启动"
echo "============================================================"
echo "设备: $DEVICE"
echo "ImageBuilder: $IMAGE_TAG"
echo "输出目录: $OUTPUT_DIR"
echo "文件目录: $FILES_DIR"
echo "============================================================"
sleep 2

# ======= 准备目录 =======
mkdir -p "$OUTPUT_DIR" "$ROOTFS_DIR" "$RELEASE_DIR" "$BUILD_TEMP"

# ======= 阶段 1：使用 ImageBuilder 构建 rootfs.tar.gz =======
echo "🔥 [阶段1] 开始使用 ImmortalWrt ImageBuilder 构建 rootfs..."
docker run --rm -v "$OUTPUT_DIR":/home/build/bin -v "$FILES_DIR":/home/build/files \
  immortalwrt/imagebuilder:$IMAGE_TAG bash -c "
    set -eux
    cd /home/build
    echo '当前镜像环境：'
    uname -a
    PACKAGES=\"$PACKAGES\"
    make image PROFILE=generic PACKAGES=\"\$PACKAGES\" FILES=files/ EXTRA_IMAGE_NAME=$DEVICE ROOTFS_TAR=y
    cp -v bin/targets/*/*/*rootfs.tar.gz /home/build/bin/
"

ROOTFS_PATH=$(ls "$OUTPUT_DIR"/*rootfs.tar.gz | head -n 1 || true)
if [ ! -f "$ROOTFS_PATH" ]; then
  echo "❌ 未找到 rootfs.tar.gz，构建失败！"
  exit 1
fi
echo "✅ RootFS 构建成功：$ROOTFS_PATH"

# ======= 阶段 2：使用 Amlogic 工具打包 img =======
echo "🔥 [阶段2] 使用 ophub/amlogic-s9xxx-openwrt 打包线刷镜像..."

cd "$BUILD_TEMP"
if [ ! -d "amlogic-s9xxx-openwrt" ]; then
  git clone https://github.com/ophub/amlogic-s9xxx-openwrt.git
fi

cd amlogic-s9xxx-openwrt
chmod +x make.sh
echo "🔧 调用 make.sh 打包 $DEVICE"
./make.sh "$DEVICE" "$ROOTFS_PATH"

# 输出镜像文件
mkdir -p "$RELEASE_DIR"
cp -v out/*img* "$RELEASE_DIR" || true
cd "$RELEASE_DIR"
ls -lh

echo "============================================================"
echo "🎉 构建完成！输出目录内容如下："
ls -lh "$RELEASE_DIR"
echo "============================================================"
