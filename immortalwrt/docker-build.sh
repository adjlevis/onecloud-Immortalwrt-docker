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

AMLIMG="$TOOLS_DIR/AmlImg_v0.3.1_linux_amd64"
EMMC_IMG="$TOOLS_DIR/eMMC.burn.img"

#-----------------------------------------------
# 检查依赖文件
#-----------------------------------------------
echo "[INFO] 检查必要文件..."
if [[ ! -f "$AMLIMG" ]]; then
  echo "[ERROR] 未找到 AmlImg 工具: $AMLIMG"
  exit 1
fi
if [[ ! -f "$EMMC_IMG" ]]; then
  echo "[ERROR] 未找到 eMMC.burn.img: $EMMC_IMG"
  exit 1
fi

chmod +x "$AMLIMG"
echo "[OK] AmlImg 工具与 eMMC.burn.img 均已找到"

#-----------------------------------------------
# Docker 镜像
#-----------------------------------------------
IMAGE_BUILDER="ghcr.io/adjlevis/immortalwrt-imagebuilder:armsr-armv7-latest"
echo "[INFO] 拉取构建镜像: $IMAGE_BUILDER"
docker pull "$IMAGE_BUILDER"

#-----------------------------------------------
# 启动 Docker 编译 ImmortalWrt
#-----------------------------------------------
echo "[INFO] 启动固件构建..."
docker run --rm \
  -v "$BUILD_DIR":/home/build/immortalwrt \
  -w /home/build/immortalwrt \
  "$IMAGE_BUILDER" \
  bash -c "
    echo '[INFO] 开始执行 build.sh ...'
    chmod +x build.sh || true
    ./build.sh
"

#-----------------------------------------------
# 输出文件检查
#-----------------------------------------------
OUTPUT_DIR="$BUILD_DIR/output"
mkdir -p "$OUTPUT_DIR"

if [[ -d "$BUILD_DIR/bin" ]]; then
  echo "[INFO] 拷贝编译输出到 $OUTPUT_DIR"
  cp -rf "$BUILD_DIR/bin/"* "$OUTPUT_DIR/" || true
else
  echo "[WARN] 未找到 bin 目录"
fi

#-----------------------------------------------
# 封装直刷镜像
#-----------------------------------------------
cd "$OUTPUT_DIR" || exit 1

ROOTFS_IMG=$(find . -type f -name '*rootfs*.img*' | head -n 1 || true)
if [[ -z "$ROOTFS_IMG" ]]; then
  echo "[WARN] 未找到 rootfs 镜像 (*.rootfs.img.gz)"
  exit 0
fi

echo "[INFO] 找到 rootfs 镜像: $ROOTFS_IMG"
if [[ "$ROOTFS_IMG" == *.gz ]]; then
  echo "[INFO] 解压 rootfs..."
  gunzip -f "$ROOTFS_IMG"
  ROOTFS_IMG="${ROOTFS_IMG%.gz}"
fi

FINAL_IMG="Onecloud-Immortalwrt-ext4-emmc-burn.img"

echo "[INFO] 开始打包线刷镜像..."
"$AMLIMG" -i "$ROOTFS_IMG" -b "$EMMC_IMG" -o "$FINAL_IMG"

gzip -f "$FINAL_IMG"
echo "[SUCCESS] 已生成线刷包: ${FINAL_IMG}.gz"

#-----------------------------------------------
# 完成
#-----------------------------------------------
echo "[✅ SUCCESS] ImmortalWrt 构建与线刷包封装完成！"
