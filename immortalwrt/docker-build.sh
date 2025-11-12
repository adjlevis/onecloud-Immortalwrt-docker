#!/usr/bin/env bash
#=================================================
# ImmortalWrt Docker 构建脚本（支持 GitHub Actions ARM 架构构建）
#=================================================
set -euo pipefail

echo "[INFO] === 启动 ImmortalWrt Docker 构建环境 ==="

#-----------------------------------------------
# 定义路径
#-----------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
TOOLS_DIR="$ROOT_DIR/tool"
BUILD_DIR="$ROOT_DIR/immortalwrt"
OUTPUT_DIR="$BUILD_DIR/output"

#-----------------------------------------------
# 工具检测
#-----------------------------------------------
AMLIMG="$TOOLS_DIR/AmlImg_v0.3.1_linux_amd64"
EMMC_IMG="$TOOLS_DIR/eMMC.burn.img"

echo "[INFO] 检查必要文件..."
if [[ ! -x "$AMLIMG" ]]; then
  echo "[WARN] 修复 AmlImg 权限..."
  chmod +x "$AMLIMG" 2>/dev/null || true
fi
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
# 修复 build.sh
#-----------------------------------------------
echo "[INFO] 修正 build.sh 格式并赋权..."
cd "$BUILD_DIR"
dos2unix build.sh 2>/dev/null || sed -i 's/\r$//' build.sh
sed -i '1s/^\xEF\xBB\xBF//' build.sh
chmod +x build.sh
echo "[INFO] build.sh 文件类型:"
file build.sh || true

#-----------------------------------------------
# 启动 Docker（启用 QEMU 模拟 ARM）
#-----------------------------------------------
echo "[INFO] 启动 ARMv7 Docker 构建..."

docker run --rm --platform linux/arm/v7 \
  -v "$BUILD_DIR":/home/build/immortalwrt \
  -e BUILD_TARGET="armsr" \
  -e BUILD_SUBTARGET="armv7" \
  "$IMAGE_BUILDER" \
  /bin/bash -c "
    set -eux
    cd /home/build/immortalwrt
    echo '[INFO] 容器内执行 build.sh ...'
    dos2unix build.sh 2>/dev/null || sed -i 's/\r$//' build.sh
    chmod +x build.sh
    /bin/bash ./build.sh
  "

#-----------------------------------------------
# 拷贝产物
#-----------------------------------------------
mkdir -p "$OUTPUT_DIR"
if [[ -d "$BUILD_DIR/bin" ]]; then
  echo "[INFO] 复制构建产物到 $OUTPUT_DIR"
  cp -rf "$BUILD_DIR/bin/"* "$OUTPUT_DIR/" || true
fi

#-----------------------------------------------
# 打包 eMMC 镜像
#-----------------------------------------------
FINAL_IMG="$OUTPUT_DIR/immortalwrt-emmc.img"
echo "[INFO] 使用 AmlImg 打包 eMMC 镜像..."
"$AMLIMG" pack "$EMMC_IMG" "$FINAL_IMG"

echo "[OK] ✅ 固件打包完成：$FINAL_IMG"
