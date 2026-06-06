#!/usr/bin/env bash
# shellcheck disable=SC2016

set -e

trap 'rm -rf "$TMPDIR"' EXIT
TMPDIR="$(mktemp -d)" || exit 1

[ -d "./package" ] || {
    echo "./package not found"
    exit 1
}

kernel_versions="$(find "./include" 2>/dev/null | sed -n '/kernel-[0-9]/p' | sed -e 's@./include/kernel-@@' | sed ':a;N;$!ba;s/\n/ /g')"

if [ -z "$kernel_versions" ]; then
    kernel_versions="$(find "./target/linux/generic" 2>/dev/null | sed -n '/kernel-[0-9]/p' | sed -e 's@./target/linux/generic/kernel-@@' | sed ':a;N;$!ba;s/\n/ /g')"
fi

[ -n "$kernel_versions" ] || {
    echo "Error: Unable to get kernel version"
    exit 1
}

echo "kernel version: $kernel_versions"

git clone --depth=1 --single-branch https://github.com/dotywrt/turboacc-n "$TMPDIR/turboacc"

echo "Cleaning old SFE / TurboACC files..."

rm -rf ./package/turboacc/shortcut-fe
rm -rf ./package/kernel/shortcut-fe
rm -rf ./package/shortcut-fe

find ./target/linux/generic -type f \( \
    -name "*shortcut-fe*.patch" -o \
    -name "*sfe*.patch" -o \
    -name "*fast-classifier*.patch" \
\) -delete 2>/dev/null || true

find ./target/linux/generic -type f -name "953-net-patch-linux-kernel-to-support-shortcut-fe.patch" -delete 2>/dev/null || true

for kv in $kernel_versions; do
    cfg="./target/linux/generic/config-$kv"
    if [ -f "$cfg" ]; then
        sed -i '/CONFIG_SHORTCUT_FE/d' "$cfg"
        sed -i '/CONFIG_FAST_CLASSIFIER/d' "$cfg"
        sed -i '/CONFIG_NF_FLOW_TABLE_HW/d' "$cfg"
    fi
done

mkdir -p ./package/turboacc
mkdir -p ./package/network/config/firewall/patches
mkdir -p ./package/network/config/firewall4/patches
mkdir -p ./package/network/utils/iptables/patches
mkdir -p ./package/network/utils/nftables/patches
mkdir -p ./package/libs/libnftnl/patches

echo "Copying TurboACC without SFE..."

cp -rf "$TMPDIR/turboacc/lede/luci-app-turboacc" ./package/turboacc/
cp -rf "$TMPDIR/turboacc/lede/fullconenat" ./package/turboacc/
cp -rf "$TMPDIR/turboacc/lede/fullconenat-nft" ./package/turboacc/

# Do NOT copy shortcut-fe
# cp -rf "$TMPDIR/turboacc/lede/shortcut-fe" ./package/turboacc/

echo "Copying safe patches..."

cp -rf "$TMPDIR/turboacc/lede/patches/firewall/patches/"* ./package/network/config/firewall/patches/ 2>/dev/null || true
cp -rf "$TMPDIR/turboacc/lede/patches/firewall4/patches/"* ./package/network/config/firewall4/patches/ 2>/dev/null || true
cp -rf "$TMPDIR/turboacc/lede/patches/iptables/patches/"* ./package/network/utils/iptables/patches/ 2>/dev/null || true
cp -rf "$TMPDIR/turboacc/lede/patches/nftables/patches/"* ./package/network/utils/nftables/patches/ 2>/dev/null || true
cp -rf "$TMPDIR/turboacc/lede/patches/libnftnl/patches/"* ./package/libs/libnftnl/patches/ 2>/dev/null || true

echo "Copying kernel fullcone patches only..."

for kv in $kernel_versions; do
    case "$kv" in
        6.6|6.12|6.18)
            mkdir -p "./target/linux/generic/hack-$kv"
            mkdir -p "./target/linux/generic/pending-$kv"

            # Keep conntrack multi registrant
            cp -f "$TMPDIR/turboacc/lede/hack-$kv/952-add-net-conntrack-events-support-multiple-registrant.patch" \
                "./target/linux/generic/hack-$kv/" 2>/dev/null || true

            # Skip SFE patch
            # 953-net-patch-linux-kernel-to-support-shortcut-fe.patch

            # Keep fullcone only
            cp -f "$TMPDIR/turboacc/lede/hack-$kv/982-add-bcm-fullconenat-support.patch" \
                "./target/linux/generic/hack-$kv/" 2>/dev/null || true

            cp -f "$TMPDIR/turboacc/lede/hack-$kv/983-add-bcm-fullconenat-to-nft.patch" \
                "./target/linux/generic/hack-$kv/" 2>/dev/null || true

            # Optional TCP window check, usually safe
            cp -f "$TMPDIR/turboacc/lede/pending-$kv/613-netfilter_optional_tcp_window_check.patch" \
                "./target/linux/generic/pending-$kv/" 2>/dev/null || true
            ;;
        *)
            echo "Unsupported kernel version: $kv"
            exit 1
            ;;
    esac
done

echo "Applying custom TurboACC files..."

mkdir -p ./package/turboacc/luci-app-turboacc/root/etc/uci-defaults
mkdir -p ./package/turboacc/luci-app-turboacc/root/usr/share/rpcd/ucode
mkdir -p ./package/turboacc/luci-app-turboacc/root/usr/share/ucitrack

cp -f "$TMPDIR/turboacc/custom/luci-app-turboacc/Makefile" \
    ./package/turboacc/luci-app-turboacc/ 2>/dev/null || true

cp -f "$TMPDIR/turboacc/custom/luci-app-turboacc/root/etc/uci-defaults/turboacc" \
    ./package/turboacc/luci-app-turboacc/root/etc/uci-defaults/ 2>/dev/null || true

cp -f "$TMPDIR/turboacc/custom/luci-app-turboacc/root/usr/share/rpcd/ucode/luci.turboacc" \
    ./package/turboacc/luci-app-turboacc/root/usr/share/rpcd/ucode/ 2>/dev/null || true

cp -f "$TMPDIR/turboacc/custom/luci-app-turboacc/root/usr/share/ucitrack/luci-app-turboacc.json" \
    ./package/turboacc/luci-app-turboacc/root/usr/share/ucitrack/ 2>/dev/null || true

cp -f "$TMPDIR/turboacc/custom/luci-app-turboacc/htdocs/luci-static/resources/view/turboacc.js" \
    ./package/turboacc/luci-app-turboacc/htdocs/luci-static/resources/view/ 2>/dev/null || true

rm -rf ./package/turboacc/luci-app-turboacc/root/usr/libexec

cp -f "$TMPDIR/turboacc/custom/fullconenat/Makefile" \
    ./package/turboacc/fullconenat/ 2>/dev/null || true

cp -f "$TMPDIR/turboacc/custom/fullconenat-nft/Makefile" \
    ./package/turboacc/fullconenat-nft/ 2>/dev/null || true

cp -f "$TMPDIR/turboacc/custom/patches/iptables/patches/900-bcm-fullconenat.patch" \
    ./package/network/utils/iptables/patches/ 2>/dev/null || true

echo "Removing any remaining SFE references..."

find ./package/turboacc -type f -exec sed -i \
    -e '/shortcut-fe/d' \
    -e '/SHORTCUT_FE/d' \
    -e '/fast-classifier/d' \
    -e '/FAST_CLASSIFIER/d' {} + 2>/dev/null || true

rm -rf ./package/turboacc/shortcut-fe

echo ""
echo "Finish: TurboACC installed without SFE / shortcut-fe."
echo "NSS should no longer be disturbed by SFE patches."
echo ""
exit 0
