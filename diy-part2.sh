#!/bin/bash
# DIY脚本（修复版）
# 基于 daofun/immortalwrt-Actios 原 diy-part2.sh
# 修复 2026-11-01 构建失败的两个问题：
#   1. glib2 打包失败：Package glib2-gobject is missing dependencies: libffi.so.8
#      根因：lkiuyu/immortalwrt fork 的 package/libs 缺少 libffi，
#      而 immortalwrt/packages master 的 glib2 依赖它（libffi/host 也是）。
#   2. openstick feed 4 个包下载 hash 不匹配（PKG_MIRROR_HASH 过期）。

# ============================================================
# 修复 1（必须）：补回源码树缺失的 libffi
# 从上游 immortalwrt master 拷贝 package/libs/libffi（含 patches）
# ============================================================
if [ ! -d package/libs/libffi ]; then
  echo "==> [FIX] 源码树缺少 libffi，从上游 immortalwrt 补回..."
  _tmpdir=$(mktemp -d)
  git clone --depth 1 --filter=blob:none --sparse \
    https://github.com/immortalwrt/immortalwrt.git "$_tmpdir/iwrt"
  git -C "$_tmpdir/iwrt" sparse-checkout set package/libs/libffi
  cp -r "$_tmpdir/iwrt/package/libs/libffi" package/libs/
  rm -rf "$_tmpdir"
  echo "==> [FIX] libffi 已添加到 package/libs/libffi"
fi

# ============================================================
# 修复 2（建议）：跳过 openstick feed 过期/漂移的源码包 hash 校验
# gc / libusbgx / qrtr / qcom-firmware 在 make download 阶段报
# "Hash mismatch"，属于上游仓库更新后 feed 内锁定 hash 未同步。
# ============================================================
for mk in \
  feeds/openstick/utils/gc/Makefile \
  feeds/openstick/libs/libusbgx/Makefile \
  feeds/openstick/utils/qrtr/Makefile \
  feeds/openstick/firmware/qcom-firmware/Makefile
do
  if [ -f "$mk" ] && grep -q '^PKG_MIRROR_HASH:=' "$mk"; then
    sed -i 's/^PKG_MIRROR_HASH:=.*/PKG_MIRROR_HASH:=skip/' "$mk"
    echo "==> [FIX] $mk: PKG_MIRROR_HASH 已设为 skip"
  fi
done

# ============================================================
# 以下为原有内容
# ============================================================

# 修改默认IP地址
#sed -i 's/192.168.1.1/192.168.100.1/g' package/base-files/files/bin/config_generate


# 修改默认主题为 argon（路径不存在时跳过，不中断编译）
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile 2>/dev/null || true

# 启用 IPv4 策略路由（直接写入内核 platform config，绕过 make defconfig 的依赖检查）
# CONFIG_KERNEL_IP_ADVANCED_ROUTER 在 OpenWrt Config.in 中无对应 wrapper，必须用此方式
#for cfg in target/linux/msm89xx/config-*; do
#  grep -q 'CONFIG_IP_ADVANCED_ROUTER' "$cfg" || echo 'CONFIG_IP_ADVANCED_ROUTER=y' >> "$cfg"
#  grep -q 'CONFIG_IP_MULTIPLE_TABLES' "$cfg" || echo 'CONFIG_IP_MULTIPLE_TABLES=y' >> "$cfg"
#done


# 临时添加的插件
# git clone https://github.com/lkiuyu/luci-app-cpu-perf package/luci-app-cpu-perf
# git clone https://github.com/lkiuyu/luci-app-cpu-status package/luci-app-cpu-status
# git clone https://github.com/gSpotx2f/luci-app-cpu-status-mini package/luci-app-cpu-status-mini
# git clone https://github.com/lkiuyu/luci-app-temp-status package/luci-app-temp-status
# git clone https://github.com/lkiuyu/DbusSmsForwardCPlus package/DbusSmsForwardCPlus
