name: Onecloud ImmortalWrt eMMC Build

on:
  workflow_dispatch:
  schedule:
    - cron: '0 19 * * *'  # 每日北京时间 03:00 自动构建

permissions:
  contents: write

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      # 1️⃣ 检出仓库
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      # 2️⃣ 安装构建依赖
      - name: Install dependencies
        run: |
          sudo apt-get update
          sudo apt-get install -y docker.io git wget curl xz-utils unzip dos2unix

      # 3️⃣ 拉取 ImmortalWrt ImageBuilder 镜像
      - name: Pull ImmortalWrt ImageBuilder
        run: docker pull immortalwrt/imagebuilder:armsr-armv7-24.10-SNAPSHOT

      # 4️⃣ 构建 rootfs.tar.gz
      - name: Build rootfs with ImageBuilder
        run: |
          mkdir -p build_output
          docker run --rm -v $(pwd)/build_output:/home/build/bin \
            immortalwrt/imagebuilder:armsr-armv7-24.10-SNAPSHOT bash -c '
              set -eux
              PACKAGES="curl luci luci-i18n-base-zh-cn luci-i18n-firewall-zh-cn luci-app-upnp luci-app-firewall"
              make image PROFILE=generic PACKAGES="$PACKAGES" FILES=files/ EXTRA_IMAGE_NAME=onecloud ROOTFS_TAR=y
              cp bin/targets/armsr/armv7/*rootfs.tar.gz /home/build/bin/
            '
          echo "✅ rootfs 构建完成："
          ls -lh build_output

      # 5️⃣ 下载 Amlogic 打包脚本（onhub）
      - name: Clone amlogic-s9xxx-openwrt
        run: |
          git clone https://github.com/onhub/amlogic-s9xxx-openwrt.git
          cd amlogic-s9xxx-openwrt
          chmod +x make.sh

      # 6️⃣ 使用 Amlogic 工具打包 eMMC 镜像
      - name: Build Amlogic eMMC image
        run: |
          set -eux
          ROOTFS=$(ls build_output/*rootfs.tar.gz | head -n 1)
          echo "🔍 使用 rootfs: $ROOTFS"
          cd amlogic-s9xxx-openwrt

          # 你可以在这里修改目标设备名称，如 onecloud / s905d / s905x3 等
          ./make.sh onecloud "$ROOTFS"

          mkdir -p ../release
          cp -v out/*img* ../release/
          cd ..
          echo "✅ 打包完成："
          ls -lh release

      # 7️⃣ 上传构建产物
      - name: Upload artifacts
        uses: actions/upload-artifact@v4
        with:
          name: onecloud-emmc-images
          path: release
          compression-level: 6

      # 8️⃣ 获取北京时间
      - name: Get Beijing Time
        id: time
        run: |
          export TZ=Asia/Shanghai
          echo "datetime=$(date '+%Y%m%d-%H%M')" >> $GITHUB_OUTPUT
          echo "datetime_readable=$(date '+%Y-%m-%d %H:%M:%S %Z')" >> $GITHUB_OUTPUT

      # 9️⃣ 发布到 Release
      - name: Publish to GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: Onecloud-eMMC-${{ steps.time.outputs.datetime }}
          name: "OneCloud eMMC Image ${{ steps.time.outputs.datetime }}"
          body: |
            ✅ **OneCloud eMMC 固件打包成功！**

            🕓 构建时间：${{ steps.time.outputs.datetime_readable }}
            💾 包含：
            - ImmortalWrt rootfs.tar.gz
            - OneCloud eMMC 可直刷镜像 (.img / .img.gz)

            👉 下载地址：
            https://github.com/${{ github.repository }}/releases/tag/Onecloud-eMMC-${{ steps.time.outputs.datetime }}
          files: release/**/*
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
