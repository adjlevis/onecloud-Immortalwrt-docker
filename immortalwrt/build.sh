#!/bin/bash
set -euxo pipefail

# ===============================
# OneCloud ImmortalWrt Build Script
# ===============================

echo "🚀 开始准备构建环境..."

# 更新 feeds 确保依赖完整
./scripts/feeds update -a
./scripts/feeds install -a

# 清理缓存避免上次残留错误
make clean || true
rm -rf tmp/ || true

# ===============================
# 自定义要安装的包
# ===============================
PACKAGES=""

# 基础功能 & 中文界面
PACKAGES="$PACKAGES curl wget ca-certificates"
PACKAGES="$PACKAGES luci luci-compat luci-base luci-app-firewall"
PACKAGES="$PACKAGES luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn luci-i18n-package-manager-zh-cn"
#PACKAGES="$PACKAGES ppp ppp-mod-pppoe luci-proto-ppp"

# 常用增强插件
PACKAGES="$PACKAGES luci-app-docker luci-app-ttyd luci-app-filebrowser"
PACKAGES="$PACKAGES kmod-usb-storage block-mount e2fsprogs fdisk"
PACKAGES="$PACKAGES luci-app-opkg openssh-sftp-server"

# ===============================
# 写入扩容脚本（系统启动自动执行）
# ===============================
echo "🧩 添加自动扩容脚本..."
mkdir -p files/etc/init.d

cat > files/etc/init.d/expand_rootfs <<'EOF'
#!/bin/sh /etc/rc.common
START=99
DESCRIPTION="Auto expand root filesystem on first boot"

start() {
    if [ ! -f /etc/expand_done ]; then
        echo "🔧 正在自动扩展 eMMC 分区..."

        parted /dev/mmcblk1 resizepart 2 100%
        losetup /dev/loop0 /dev/mmcblk1p2
        e2fsck -f -y /dev/loop0
        resize2fs -f /dev/loop0
        sync

        echo "✅ 分区扩展完成。系统将自动重启以生效..."
        touch /etc/expand_done
        reboot
    fi
}
EOF

chmod +x files/etc/init.d/expand_rootfs

# ===============================
# 构建镜像（根分区调整为 1024MB）
# ===============================
echo "🧱 开始构建镜像..."
make image \
  PACKAGES="$PACKAGES" \
  FILES="files" \
  ROOTFS_PARTSIZE="1024" \
  V=s

# ===============================
# 自动生成更新说明（供 Release 使用）
# ===============================
echo "📄 生成更新说明..."
mkdir -p ../release_note
cat > ../release_note/update.txt <<EOF
🆕 本次构建更新内容：
- 自动扩展 eMMC 分区（首次启动自动完成）
- 修复 ppp-mod-pppoe 安装失败问题
- 新增 luci-app-docker、luci-app-ttyd、luci-app-filebrowser 等插件
- 完善中文界面支持
- 默认 root 密码为空（直接登录）
- 根分区扩大为 1024MB，空间更充足
EOF

echo "✅ 构建完成！固件请查看 bin/targets/"

