#!/bin/bash

# 定位到 Device/xiaomi_mi-router-4a-gigabit 这一行开始，到第一个 endef 结束的区间
# 在这个区间内，将 IMAGE_SIZE := 14384k 替换为 16064k
sed -i '/Device\/xiaomi_mi-router-4a-gigabit/,/endef/ { s/IMAGE_SIZE := 14848k/IMAGE_SIZE := 16064k/ }' target/linux/ramips/image/mt7621.mk

# 2. 修改 DTS 文件 (使用单引号 EOF 确保内容不被环境变量解析)
cat > target/linux/ramips/dts/mt7621_xiaomi_mi-router-4a-common.dtsi <<'EOF'
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

		partitions: partitions {
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
			};

			firmware: partition@50000 {
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
	mtd-mac-address = <&factory 0xe000>;
};

&state_default {
	gpio {
		groups = "jtag", "uart2", "uart3", "wdt";
		function = "gpio";
	};
};
EOF
