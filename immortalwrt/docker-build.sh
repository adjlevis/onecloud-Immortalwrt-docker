#!/bin/bash
#=================================================
# ImmortalWrt Docker 构建脚本 (支持 OneCloud / N1 等设备)
# 适配镜像: ghcr.io/adjlevis/immortalwrt-imagebuilder:armsr-armv7-latest
#=================================================
set -euo pipefail

echo "[INFO] === 启动 ImmortalWrt Docker 构建环境 ==="

#-----------------------------------------------
# 环境路径定义
#-----------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/tool"
BUILD_DIR="$ROOT_DIR/immortalwrt"

#-----------------------------------------------
# 工具检测
#-----------------------------------------------
AMLIMG="$TOOLS_DIR/AmlImg_v0.3.1_linux_amd64"
EMMC_IMG="$TOOLS_DIR/eMMC.burn.img"

echo "[INFO] 检查必要文件..."
[[ -x "$AMLIMG" ]] || { echo "[ERROR] 未找到或不可执行: $AMLIMG"; exit 1; }
[[ -f "$EMMC_IMG" ]] || { echo "[ERROR] 未找到: $EMMC_IMG"; exit 1; }

echo "[OK] AmlImg 工具与 eMMC.burn.img 均已找到"

#-----------------------------------------------
# Docker 镜像设置
#-----------------------------------------------
IMAGE_BUILDER="ghcr.io/adjlevis/immortalwrt-imagebuilder:armsr-armv7-latest"

echo "[INFO] 拉取构建镜像: $IMAGE_BUILDER"
docker pull "$IMAGE_BUILDER"

#-----------------------------------------------
# 启动 Docker 构建
#-----------------------------------------------
echo "[INFO] 启动固件构建..."

docker run --rm -it \
  -v "$BUILD_DIR":/home/build/immortalwrt \
  -e BUILD_TARGET="armsr" \
  -e BUILD_SUBTARGET="armv7" \
  "$IMAGE_BUILDER" \
  bash -c "
    cd /home/build/immortalwrt
    echo '[INFO] 开始执行 build.sh ...'
    chmod +x build.sh || true
    ./build.sh
"

#-----------------------------------------------
# 打包镜像（可选）
#-----------------------------------------------
OUTPUT_DIR="$BUILD_DIR/output"
mkdir -p "$OUTPUT_DIR"

if [[ -d "$BUILD_DIR/bin" ]]; then
    echo "[INFO] 复制构建产物到 $OUTPUT_DIR"
    cp -rf "$BUILD_DIR/bin/"* "$OUTPUT_DIR/"
fi

#-----------------------------------------------
# 使用 AmlImg 打包 eMMC 镜像（可选）
#-----------------------------------------------
FINAL_IMG="$OUTPUT_DIR/immortalwrt-emmc.img"

echo "[INFO] 使用 AmlImg 打包直刷固件..."
"$AMLIMG" pack "$EMMC_IMG" "$FINAL_IMG"

echo "[OK] 固件打包完成：$FINAL_IMG"

#-----------------------------------------------
# 结束
#-----------------------------------------------
echo "[SUCCESS] ImmortalWrt 构建与打包已完成 ✅"
