#!/bin/bash
set -euxo pipefail

echo "[Build] 开始构建 ImmortalWrt 固件..."

PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-base-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"

# 构建 ext4 镜像，不生成 qcow2/vmdk，避免 qemu-img 错误
make image PACKAGES="$PACKAGES" ROOTFS_PARTSIZE="512" \
  EXTRA_IMAGE_NAME="ext4-emmc-burn" \
  EXTRA_IMAGE_FORMATS="ext4.gz"

echo "[Build] 构建完成，输出文件如下："
find bin/targets -type f -name "*.img*" -or -name "*.ext4*" || true
