#!/usr/bin/env bash
set -Eeuo pipefail


# 调整NSS驱动q6_region内存区域预留大小（ipq6018.dtsi默认预留85MB，ipq6018-512m.dtsi默认预留55MB，带WiFi必须至少预留54MB，以下分别是改成预留16MB、32MB、64MB和96MB）
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x01000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x02000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x04000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi
# sed -i 's/reg = <0x0 0x4ab00000 0x0 0x[0-9a-f]\+>/reg = <0x0 0x4ab00000 0x0 0x06000000>/' target/linux/qualcommax/files/arch/arm64/boot/dts/qcom/ipq6018-512m.dtsi

# 调节IPQ60XX的1.5GHz频率电压(从0.9375V提高到0.95V，过低可能导致不稳定，过高可能增加功耗和发热，具体数值需要根据实际情况调整)
# sed -i 's/opp-microvolt = <937500>;/opp-microvolt = <950000>;/' target/linux/qualcommax/patches-6.12/0038-v6.16-arm64-dts-qcom-ipq6018-add-1.5GHz-CPU-Frequency.patch

# 移除要替换的包

rm -rf feeds/luci/applications/luci-app-upnp
rm -rf feeds/luci/themes/luci-theme-argon
rm -rf feeds/packages/net/miniupnpd
rm -rf feeds/packages/net/ariang
rm -rf feeds/packages/net/aria2
rm -rf feeds/packages/net/nginx
rm -rf feeds/packages/lang/golang

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  local branch="$1"
  local repourl="$2"
  local repodir
  shift 2

  repodir="$(basename "${repourl%.git}")"
  rm -rf "$repodir"
  git clone --depth=1 -b "$branch" --single-branch --filter=blob:none --sparse "$repourl" "$repodir"
  (
    cd "$repodir"
    git sparse-checkout set "$@"
    mv -f "$@" ../package
  )
  rm -rf "$repodir"
}

# Aria2 & nginx & Go & DDNS & frp & UPnP & Wol & Argon & Aurora & OpenList & Lucky & wechatpush & OpenAppFilter & 集客无线AC控制器 & 雅典娜LED控制
git_sparse_clone aria2 https://github.com/laipeng668/packages net/aria2
mv -f package/aria2 feeds/packages/net/aria2
git_sparse_clone nginx https://github.com/laipeng668/packages net/nginx
mv -f package/nginx feeds/packages/net/nginx
git_sparse_clone ariang https://github.com/laipeng668/packages net/ariang
mv -f package/ariang feeds/packages/net/ariang
git_sparse_clone master https://github.com/laipeng668/packages lang/golang
mv -f package/golang feeds/packages/lang/golang

git_sparse_clone master https://github.com/immortalwrt/packages net/miniupnpd
mv -f package/miniupnpd feeds/packages/net/miniupnpd
git_sparse_clone master https://github.com/immortalwrt/luci applications/luci-app-upnp
mv -f package/luci-app-upnp feeds/luci/applications/luci-app-upnp

git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon feeds/luci/themes/luci-theme-argon

git clone --depth=1 https://github.com/eamonxg/luci-theme-aurora feeds/luci/themes/luci-theme-aurora
git clone --depth=1 https://github.com/makeding/luci-app-wolh package/huggy/luci-app-wolh
echo "src-git nikki https://github.com/nikkinikki-org/OpenWrt-nikki.git;main" >> "feeds.conf.default"

./scripts/feeds update -i -a
./scripts/feeds install -a
