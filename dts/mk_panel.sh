#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 yasoteien
# パネルの寸法（width-mm・height-mm）を DM250 の 7.0 型に直す（154×86mm）。
#
#   bash mk_panel.sh 入力.dtb 出力.dtb
#
# 根拠:
#   - 作者の DT は 223×125mm（対角 10.1 型相当）。jcs の DT・作者の U-Boot の DT も同じ値で、
#     DM250 の仕様（7.0 型 TFT、1024×600）と合わない。
#   - パネルの型番は見つからない。DT のタイミング（DCLK 51.2MHz、Htotal 1344、Vtotal 635）が、
#     7 型 1024×600 の EJ070NA-01J・HSD070PFW1 系の標準のタイミングと一致する。
#     その表示領域が 154.21×85.92mm。DT の値は整数の mm なので 154×86 とした。
#   - 効くのは Linux の DPI の値だけ。
# 値は u32 のままなので、DTB の長さは変わらない。
set -euo pipefail
IN=$1; OUT=$2
W=154; H=86

[ "$(fdtget -t u "$IN" /panel width-mm) $(fdtget -t u "$IN" /panel height-mm)" = "223 125" ] ||
	{ echo "$IN: /panel の寸法が 223×125 でない（直し済みか、別の DTB）" >&2; exit 1; }
cp "$IN" "$OUT"
fdtput -t u "$OUT" /panel width-mm $W
fdtput -t u "$OUT" /panel height-mm $H
