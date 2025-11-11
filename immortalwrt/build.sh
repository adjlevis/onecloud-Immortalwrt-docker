#!/bin/bash
set -euxo pipefail

echo "🚀 开始准备构建环境..."

# 更新 feeds
./scripts/feeds update -a
./scripts/feeds install -a

# 清理旧缓存
make clean || true
rm -rf tmp/ || true

# ===============================
# 自定义安装包（无 PPP 组件）
# ===============================
PACKAGES=""
PACKAGES="$PACKAGES curl wget ca-certificates"
PACKAGES="$PACKAGES luci luci-base luci-compat luci-app-firewall"
PACKAGES="$PACKAGES luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn luci-i18n-package-manager-zh-cn"
PACKAGES="$PACKAGES luci-app-docker luci-app-ttyd luci-app-filebrowser"
PACKAGES="$PACKAGES luci-app-opkg openssh-sftp-server"
PACKAGES="$PACKAGES kmod-usb-storage block-mount e2fsprogs fdisk"

# ===============================
# 写入自动扩容脚本
# ===============================
mkdir -p files/etc/init.d
cat > files/etc/init.d/expand_rootfs <<'EOF'
#!/bin/sh /etc/rc.common
START=99
DESCRIPTION="Auto expand root filesystem on first boot"

start() {
    if [ ! -f /etc/expand_done ]; then
        echo "🔧 自动扩展 eMMC 分区..."
        parted /dev/mmcblk1 resizepart 2 100%
        losetup /dev/loop0 /dev/mmcblk1p2
        e2fsck -f -y /dev/loop0
        resize2fs -f /dev/loop0
        sync
        echo "✅ 扩展完成，重启生效..."
        touch /etc/expand_done
        reboot
    fi
}
EOF
chmod +x files/etc/init.d/expand_rootfs

# ===============================
# 构建镜像（调大分区空间）
# ===============================
echo "🧱 开始构建镜像..."
make image \
  PACKAGES="$PACKAGES" \
  FILES="files" \
  ROOTFS_PARTSIZE="1024" \
  V=s

# ===============================
# 压缩并发布
# ===============================
OUTPUT_IMG=$(find bin/targets/ -name "*emmc-burn.img" | head -n 1)
if [ -f "$OUTPUT_IMG" ]; then
  echo "📦 压缩线刷包..."
  xz -T0 -z -9 "$OUTPUT_IMG"
fi

# ===============================
# 生成更新说明
# ===============================
mkdir -p ../release_note
cat > ../release_note/update.txt <<EOF
🆕 本次更新内容：
- 移除 PPPoE 相关模块（ppp-mod-pppoe、kmod-pppoe、ppp）
- 适配旁路由模式（DHCP 自动获取上级 IP）
- 新增插件：
  - luci-app-docker
  - luci-app-ttyd
  - luci-app-filebrowser
- 自动扩展 eMMC 剩余空间
- 默认密码为空
EOF

echo "✅ 构建完成！"
echo "📁 线刷包文件: onecloud-immortalwrt-ext4-emmc-burn.img.xz"
echo "📝 更新说明: release_note/update.txt"
