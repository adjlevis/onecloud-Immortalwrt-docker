#!/bin/bash
set -euxo pipefail

# 自定义要安装的包
PACKAGES=""
PACKAGES="$PACKAGES curl"
PACKAGES="$PACKAGES luci-i18n-base-zh-cn"
PACKAGES="$PACKAGES luci-i18n-firewall-zh-cn"
PACKAGES="$PACKAGES luci-i18n-package-manager-zh-cn"

# 可选：增加更多包，比如
# PACKAGES="$PACKAGES luci luci-app-opkg openssh-sftp-server"

# 构建镜像，ROOTFS_PARTSIZE 可调整大小（单位 MB）
make image PACKAGES="$PACKAGES" ROOTFS_PARTSIZE="512"


