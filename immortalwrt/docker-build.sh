#!/bin/bash
#=================================================
# ImmortalWrt Docker 构建脚本 (GitHub Actions 版)
#=================================================
set -euo pipefail

echo "[INFO] === 启动 ImmortalWrt Docker 构建环境 ==="

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/tool"
BUILD_DIR="$ROOT_DIR/immortalwrt"

AMLIMG="$TOOLS_DIR/AmlImg_v0.3.1_linux_amd64"
EMMC_IMG="$TOOLS_DIR/eMMC.burn.img"

#-----------------------------------------------
# 检查工具
#-----------------------------------------------
echo "[INFO] 检查必要文件..."
if [[ ! -f "$AMLIMG" ]]; then
  echo "Error: 未找到 $AMLIMG"
  exit 1
fi
chmod +x "$AMLIMG" || true

if [[ ! -f "$EMMC_IMG" ]]; then
  echo "Error: 未找到 $EMMC_IMG"
  exit 1
fi

echo "[OK] AmlImg 工具与 eMMC.burn.img 均已找到"

#-----------------------------------------------
# 拉取构建镜像
#-----------------------------------------------
IMAGE_BUILDER="ghcr.io/adjlevis/immortalwrt-imagebuilder:armsr-armv7-latest"
echo "[INFO] 拉取构建镜像: $IMAGE_BUILDER"
docker pull "$IMAGE_BUILDER"

#-----------------------------------------------
# 检查 build.sh 状态
#-----------------------------------------------
BUILD_SCRIPT="$BUILD_DIR/build.sh"

echo "[INFO] 修正 build.sh 格式并赋权..."
if [[ -f "$BUILD_SCRIPT" ]]; then
  # 修正 Windows CRLF 换行符
  sed -i 's/\r$//' "$BUILD_SCRIPT"
  chmod +x "$BUILD_SCRIPT" || true
  echo "[INFO] build.sh 文件类型:"
  file "$BUILD_SCRIPT" || true
else
  echo "[ERROR] 未找到 $BUILD_SCRIPT"
  exit 1
fi

#-----------------------------------------------
# 启动 Docker 构建
#-----------------------------------------------
echo "[INFO] 启动固件构建..."
docker run --rm \
  -v "$BUILD_DIR":/home/build/immortalwrt \
  -w /home/build/immortalwrt \
  "$IMAGE_BUILDER" \
  bash -c "chmod +x build.sh && bash build.sh"

#-----------------------------------------------
# 打包 eMMC 镜像
#-----------------------------------------------
OUTPUT_DIR="$BUILD_DIR/output"
mkdir -p "$OUTPUT_DIR"
cp -rf "$BUILD_DIR/bin/"* "$OUTPUT_DIR/" || true

echo "[INFO] 使用 AmlImg 打包直刷镜像..."
"$AMLIMG" pack "$EMMC_IMG" "$OUTPUT_DIR/immortalwrt-emmc.img"

echo "[SUCCESS] ✅ 构建与打包完成"
