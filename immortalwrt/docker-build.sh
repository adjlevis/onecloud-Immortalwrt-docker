#!/bin/bash
#=================================================
# ImmortalWrt Docker 构建脚本 (支持 OneCloud / N1 等设备)
# 适配镜像: ghcr.io/adjlevis/immortalwrt-imagebuilder:armsr-armv7-latest
#=================================================
set -euo pipefail

echo "[INFO] === 启动 ImmortalWrt Docker 构建环境 ==="

#-----------------------------------------------
# 路径定义
#-----------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/tool"
BUILD_DIR="$ROOT_DIR/immortalwrt"
OUTPUT_DIR="$BUILD_DIR/output"

#-----------------------------------------------
# 检查工具
#-----------------------------------------------
AMLIMG="$TOOLS_DIR/AmlImg_v0.3.1_linux_amd64"
EMMC_IMG="$TOOLS_DIR/eMMC.burn.img"

echo "[INFO] 检查必要文件..."
[[ -x "$AMLIMG" ]] || { echo "[ERROR] 未找到或不可执行: $AMLIMG"; exit 1; }
[[ -f "$EMMC_IMG" ]] || { echo "[ERROR] 未找到: $EMMC_IMG"; exit 1; }

echo "[OK] AmlImg 工具与 eMMC.burn.img 均已找到"

#-----------------------------------------------
# Docker 镜像定义
#-----------------------------------------------
IMAGE_BUILDER="ghcr.io/adjlevis/immortalwrt-imagebuilder:armsr-armv7-latest"

echo "[INFO] 拉取构建镜像: $IMAGE_BUILDER"
docker pull "$IMAGE_BUILDER"

#-----------------------------------------------
# 构建前准备
#-----------------------------------------------
echo "[INFO] 修正 build.sh 格式并赋权..."
sed -i 's/\r$//' "$BUILD_DIR/build.sh" || true
chmod +x "$BUILD_DIR/build.sh" || true

mkdir -p "$OUTPUT_DIR"

#-----------------------------------------------
# 执行 Docker 构建
#-----------------------------------------------
echo "[INFO] 启动固件构建..."

docker run --rm \
  -v "$BUILD_DIR":/home/build/immortalwrt \
  -e BUILD_TARGET="armsr" \
  -e BUILD_SUBTARGET="armv7" \
  "$IMAGE_BUILDER" \
  bash -c "
    set -euxo pipefail
    cd /home/build/immortalwrt
    echo '[INFO] 开始执行 build.sh ...'
    ./build.sh
  "

#-----------------------------------------------
# 拷贝输出文件
#-----------------------------------------------
if [[ -d "$BUILD_DIR/bin" ]]; then
    echo "[INFO] 复制构建产物到 $OUTPUT_DIR"
    cp -rf "$BUILD_DIR/bin/"* "$OUTPUT_DIR/" || true
else
    echo "[WARN] 未找到 bin 目录，构建可能失败"
fi

#-----------------------------------------------
# 自动打包 OneCloud eMMC 直刷镜像
#-----------------------------------------------
cd "$OUTPUT_DIR" || exit 1

ROOTFS_IMG=$(find . -type f -name "*rootfs*.img.gz" | head -n 1 || true)
if [[ -z "$ROOTFS_IMG" ]]; then
    echo "[WARN] 未找到 rootfs 镜像 (*.rootfs.img.gz)，跳过线刷包封装"
else
    echo "[INFO] 找到 rootfs 镜像: $ROOTFS_IMG"
    gunzip -f "$ROOTFS_IMG"
    ROOTFS_IMG="${ROOTFS_IMG%.gz}"

    FINAL_IMG="Onecloud-immortalwrt-ext4-emmc-burn.img"

    echo "[INFO] 使用 AmlImg 打包直刷固件..."
    "$AMLIMG" -i "$ROOTFS_IMG" -b "$EMMC_IMG" -o "$FINAL_IMG"

    echo "[INFO] 压缩生成的线刷包..."
    gzip -f "$FINAL_IMG"

    echo "[OK] 已生成线刷包: ${FINAL_IMG}.gz"
fi

#-----------------------------------------------
# 完成
#-----------------------------------------------
echo "[SUCCESS] 🎉 ImmortalWrt 构建与打包完成"
ls -lh "$OUTPUT_DIR"
