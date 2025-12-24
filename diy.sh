#!/bin/bash
#
# Copyright (c) 2019-2025 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#

# 1. 修正编译配置 (针对小米 4A 千兆版)
# 修改编译 Makefile，将固件最大限制调整为适配新分区布局的大小 (16064k)
# 这一步非常重要，否则编译最后阶段会报错：Image too big
sed -i 's/xiaomi_mi-router-4a-gigabit_max_size := .*/xiaomi_mi-router-4a-gigabit_max_size := 16064k/' target/linux/ramips/image/mt7621.mk

# 2. 修改 DTS 分区布局
# 我们直接使用 cat 重写 target/linux/ramips/dts/mt7621_xiaomi_mi-router-4a-common.dtsi
# 这样可以确保 100% 覆盖，不受源码更新干扰
cat > target/linux/ramips/dts/mt7621_xiaomi_mi-router-4a-common.dtsi <<EOF
// SPDX-License-Identifier: GPL-2.0-or-later OR MIT

#include "mt7621.dtsi"

#include <dt-bindings/gpio/gpio.h>
#include <dt-bindings/input/input.h>

/ {
	aliases {
		led-boot = &led_status_yellow;
		led-failsafe = &led_status_yellow;
		led-running = &led_status_blue;
		led-upgrade = &led_status_yellow;
	};

	chosen {
		bootargs = "console=ttyS0,115200n8";
	};

	keys {
		compatible = "gpio-keys";

		reset {
			label = "reset";
			gpios = <&gpio 18 GPIO_ACTIVE_LOW>;
			linux,code = <KEY_RESTART>;
		};
	};
};

&spi0 {
	status = "okay";

	flash@0 {
		compatible = "jedec,spi-nor";
		reg = <0>;
		spi-max-frequency = <50000000>;
		m25p,fast-read;

		partitions {
			compatible = "fixed-partitions";
			#address-cells = <1>;
			#size-cells = <1>;

			partition@0 {
				label = "u-boot";
				reg = <0x0 0x30000>;
				read-only;
			};

			partition@30000 {
				label = "u-boot-env";
				reg = <0x30000 0x10000>;
				read-only;
			};

			factory: partition@40000 {
				label = "factory";
				reg = <0x40000 0x10000>;
				read-only;

				nvmem-layout {
					compatible = "fixed-layout";
					#address-cells = <1>;
					#size-cells = <1>;

					eeprom_factory_0: eeprom@0 {
						reg = <0x0 0x400>;
					};

					eeprom_factory_8000: eeprom@8000 {
						reg = <0x8000 0x200>;
					};

					macaddr_factory_e000: macaddr@e000 {
						reg = <0xe000 0x6>;
					};

					macaddr_factory_e006: macaddr@e006 {
						reg = <0xe006 0x6>;
					};
				};
			};

			partition@50000 {
				compatible = "denx,uimage";
				label = "firmware";
				reg = <0x50000 0xfb0000>;
			};
		};
	};
};

&pcie {
	status = "okay";
};

&pcie0 {
	wifi0: wifi@0,0 {
		compatible = "mediatek,mt76";
		reg = <0x0000 0 0 0 0>;
	};
};

&pcie1 {
	wifi1: wifi@0,0 {
		compatible = "mediatek,mt76";
		reg = <0x0000 0 0 0 0>;
	};
};

&gmac0 {
	nvmem-cells = <&macaddr_factory_e000>;
	nvmem-cell-names = "mac-address";
};

&state_default {
	gpio {
		groups = "jtag", "uart2", "uart3", "wdt";
		function = "gpio";
	};
};
EOF

# 3. 基础微调 (可选)
# 修改默认 IP 为 192.168.1.1 (如果需要修改可改此处)
# sed -i 's/192.168.1.1/192.168.31.1/g' package/base-files/files/bin/config_generate

echo "DTS partition layout patch applied successfully."
