#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 yasoteien
# DM250 用 Debian 13 イメージの DTB に、RK818 の INT の結線の直しと充電 LED の節（gpio-leds）を当てる。
#
#   bash mk_leds.sh 入力.dtb 出力.dtb
#
# 1. RK818 の INT: イメージの DT は gpio1 の 9 番（GPIO1_B1）にしているが、実機の結線は
#    gpio0 の 6 番（GPIO0_A6）、レベル Low。同じ長さの 2 か所の直しなので DTB の長さは変わらない。
# 2. 充電 LED: 赤 GPIO1_B0、緑 GPIO1_B4（どちらも active high）。トリガーは自前の
#    rk818 の充電ドライバが出す rk818-led-red / rk818-led-green。
# fdtput の順を変えると、文字列表の並びが変わって DTB のバイト列が変わる（中身は同じ）。
set -euo pipefail
IN=$1; OUT=$2
PMIC=/i2c@20072000/pmic@1c
GPIO0=0x4f	# /pinctrl/gpio@2007c000
GPIO1=0x52	# /pinctrl/gpio@20080000

cp "$IN" "$OUT"
fdtput -t x "$OUT" $PMIC interrupt-parent $GPIO0
fdtput -t x "$OUT" $PMIC interrupts 6 8
[ "$(stat -c %s "$OUT")" = "$(stat -c %s "$IN")" ] || { echo "INT の直しで長さが変わった" >&2; exit 1; }

fdtput -c "$OUT" /leds /leds/led-charge-red /leds/led-charge-green
fdtput -t s "$OUT" /leds compatible gpio-leds
fdtput -t s "$OUT" /leds/led-charge-red label red:charging
fdtput -t x "$OUT" /leds/led-charge-red gpios $GPIO1 0x8 0	# GPIO1_B0（8）
fdtput -t s "$OUT" /leds/led-charge-red linux,default-trigger rk818-led-red
fdtput -t s "$OUT" /leds/led-charge-red default-state off
fdtput -t s "$OUT" /leds/led-charge-green label green:charging
fdtput -t x "$OUT" /leds/led-charge-green gpios $GPIO1 0xc 0	# GPIO1_B4（12）。-t x は 16 進
fdtput -t s "$OUT" /leds/led-charge-green linux,default-trigger rk818-led-green
fdtput -t s "$OUT" /leds/led-charge-green default-state off
