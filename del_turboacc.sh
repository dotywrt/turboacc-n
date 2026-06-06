#!/usr/bin/env bash

set -e

echo "Removing TurboACC packages..."

rm -rf ./package/turboacc
rm -rf ./feeds/luci/applications/luci-app-turboacc

echo "Removing Shortcut-FE packages..."

rm -rf ./package/shortcut-fe
rm -rf ./package/kernel/shortcut-fe
rm -rf ./package/network/utils/shortcut-fe

echo "Removing kernel patches..."

find ./target/linux/generic -type f \
    \( \
        -name "*shortcut-fe*.patch" \
        -o -name "*fast-classifier*.patch" \
        -o -name "*sfe*.patch" \
        -o -name "953-net-patch-linux-kernel-to-support-shortcut-fe.patch" \
    \) -delete 2>/dev/null || true

echo "Removing TurboACC patches..."

find ./package/network/config/firewall/patches \
    -type f | grep -Ei 'fullcone|shortcut|fast-classifier|turboacc' | xargs -r rm -f

find ./package/network/config/firewall4/patches \
    -type f | grep -Ei 'fullcone|shortcut|fast-classifier|turboacc' | xargs -r rm -f

find ./package/network/utils/iptables/patches \
    -type f | grep -Ei 'fullcone|shortcut|fast-classifier|turboacc' | xargs -r rm -f

find ./package/network/utils/nftables/patches \
    -type f | grep -Ei 'fullcone|shortcut|fast-classifier|turboacc' | xargs -r rm -f

find ./package/libs/libnftnl/patches \
    -type f | grep -Ei 'fullcone|shortcut|fast-classifier|turboacc' | xargs -r rm -f

echo "Cleaning kernel configs..."

for cfg in ./target/linux/generic/config-*; do
    [ -f "$cfg" ] || continue

    sed -i \
        -e '/CONFIG_SHORTCUT_FE/d' \
        -e '/CONFIG_FAST_CLASSIFIER/d' \
        -e '/CONFIG_NF_FLOW_TABLE_HW/d' \
        "$cfg"
done

echo "Cleaning .config..."

if [ -f .config ]; then
    sed -i \
        -e '/TURBOACC/d' \
        -e '/SHORTCUT_FE/d' \
        -e '/FAST_CLASSIFIER/d' \
        -e '/FULLCONENAT/d' \
        .config
fi

echo "Refreshing configuration..."

make defconfig

echo ""
echo "Done."
echo ""
echo "Removed:"
echo "  - luci-app-turboacc"
echo "  - shortcut-fe"
echo "  - fast-classifier"
echo "  - SFE kernel patches"
echo "  - TurboACC patches"
echo ""
echo "NSS packages remain untouched."
