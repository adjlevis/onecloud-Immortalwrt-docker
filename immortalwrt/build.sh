#!/bin/bash
#=================================================
# ImmortalWrt 镜像构建逻辑
#=================================================
set -euxo pipefail

echo "[Build] 🚀 开始构建 ImmortalWrt 固件..."

rm -rf bin/ || true
mkdir -p bin/

PACKAGES="curl \
luci-i18n-base-zh-cn \
luci-i18n-firewall-zh-cn \
luci-i18n-opkg-zh-cn \
luci-i18n-upnp-zh-cn \
luci-app-upnp \
luci-app-firewall"

make image PROFILE="generic" \
  PACKAGES="$PACKAGES" \
  EXTRA_IMAGE_NAME="emmc-burn" \
  EXTRA_IMAGE_FORMATS="ext4.gz img.gz" \
  ROOTFS_PARTSIZE=512

echo "[Build] ✅ 固件构建完成"
find bin/targets -type f \( -name '*.img*' -o -name '*.ext4*' \)
