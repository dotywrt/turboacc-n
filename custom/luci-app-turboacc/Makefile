# SPDX-Identifier-License: GPL-3.0-only
#
# Copyright (C) 2024 Lean <coolsnowwolf@gmail.com>
# Copyright (C) 2019-2022 ImmortalWrt.org

include $(TOPDIR)/rules.mk

PKG_NAME:=luci-app-turboacc

PKG_CONFIG_DEPENDS:= \
	CONFIG_PACKAGE_TURBOACC_INCLUDE_NO_FASTPATH \
	CONFIG_PACKAGE_TURBOACC_INCLUDE_FLOW_OFFLOADING \
	CONFIG_PACKAGE_TURBOACC_INCLUDE_BBR_CCA \
	CONFIG_PACKAGE_TURBOACC_INCLUDE_FULLCONE

PKG_LICENSE:=GPL-3.0-only
PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

LUCI_TITLE:=LuCI support for FastPath / NSS / FullCone NAT

LUCI_DEPENDS:= \
	+PACKAGE_TURBOACC_INCLUDE_FLOW_OFFLOADING&&PACKAGE_firewall:kmod-ipt-offload \
	+PACKAGE_TURBOACC_INCLUDE_FLOW_OFFLOADING&&PACKAGE_firewall4:kmod-nft-offload \
	+PACKAGE_TURBOACC_INCLUDE_BBR_CCA:kmod-tcp-bbr \
	+PACKAGE_TURBOACC_INCLUDE_FULLCONE&&PACKAGE_firewall:iptables-mod-fullconenat \
	+PACKAGE_TURBOACC_INCLUDE_FULLCONE&&PACKAGE_firewall4:kmod-nft-fullcone

LUCI_PKGARCH:=all

define Package/luci-app-turboacc/config
  choice
    prompt "FastPath Engine"
    default PACKAGE_TURBOACC_INCLUDE_NO_FASTPATH if (TARGET_qualcommax||TARGET_ipq50xx||TARGET_ipq53xx||TARGET_ipq60xx||TARGET_ipq807x||TARGET_ipq95xx)
    default PACKAGE_TURBOACC_INCLUDE_FLOW_OFFLOADING

    config PACKAGE_TURBOACC_INCLUDE_NO_FASTPATH
      bool "Use NSS ECM"
      depends on TARGET_qualcommax||TARGET_ipq50xx||TARGET_ipq53xx||TARGET_ipq60xx||TARGET_ipq807x||TARGET_ipq95xx

    config PACKAGE_TURBOACC_INCLUDE_FLOW_OFFLOADING
      bool "Use flow offloading"
  endchoice

  config PACKAGE_TURBOACC_INCLUDE_BBR_CCA
    bool "Enable BBR CCA"
    default y

  config PACKAGE_TURBOACC_INCLUDE_FULLCONE
    bool "Include fullcone NAT"
    default y
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
