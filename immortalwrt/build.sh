#!/bin/bash
set -euxo pipefail

echo "[Build] 开始构建 OneCloud ImmortalWrt 固件..."

PACKAGES="curl luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn luci-i18n-opkg-zh-cn luci-i18n-upnp-zh-cn"

make image \
  PROFILE="generic" \
  PACKAGES="$PACKAGES" \
  EXTRA_IMAGE_NAME="ext4-emmc-burn" \
  EXTRA_IMAGE_FORMATS="ext4.gz" \
  ROOTFS_PARTSIZE=512

echo "[Build] 固件构建完成。输出文件："
find bin/targets -type f -name "*.img*" -or -name "*.ext4*" || true
