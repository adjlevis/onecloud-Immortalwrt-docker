#!/bin/bash
set -euxo pipefail

echo "[Build] 开始构建 ImmortalWrt 固件..."

# 自定义要安装的包
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-base-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"

# 构建镜像（512MB 根分区）
make image PACKAGES="$PACKAGES" ROOTFS_PARTSIZE="512" || {
  echo "❌ 构建失败"
  exit 1
}

echo "[Build] 构建完成，输出文件如下："
find bin/targets -type f -name "*.img*" -or -name "*.bin*" || true
