#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 yasoteien
# DM250 用 Debian 13 イメージ（https://www.ekesete.net/log/?p=9565）の DTB を DTS に戻した物から、
# 今使っている DTB と RSCE を組む。
#
#   bash mk_rsce.sh [出力先]	（既定はこの台本のある所）
#
# 作る物:
#   rk3128-pomera-dm250-image.dtb   イメージの DTB と同じ物
#   rk3128-pomera-dm250.dtb         それに mk_leds.sh・mk_panel.sh を当てた物
#   rsce.bin                        1MiB の RSCE（項目 rk-kernel.dtb 1 つ）。SD カードの
#                                   24MiB の位置（RSCE 領域）に書く物
# どれも sha256 を確かめる。違えば止まる。要る物: dtc・fdtput・fdtget（device-tree-compiler）、python3。
set -euo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
OUT=$(mkdir -p "${1:-$HERE}" && cd "${1:-$HERE}" && pwd)
cd "$OUT"

check() {	# check ファイル sha256
	[ "$(sha256sum "$1" | cut -d' ' -f1)" = "$2" ] || { echo "$1 の sha256 が違う" >&2; exit 1; }
	echo "$1: $2"
}

dtc -q -b 0 -I dts -O dtb -o rk3128-pomera-dm250-image.dtb "$HERE/rk3128-pomera-dm250-image.dts"
check rk3128-pomera-dm250-image.dtb bd97037c2e7eddb99a9a4042e1ffc716402c5199450aafbe3a5bacf6ef8b4c48

bash "$HERE/mk_leds.sh" rk3128-pomera-dm250-image.dtb leds.dtb.tmp
bash "$HERE/mk_panel.sh" leds.dtb.tmp rk3128-pomera-dm250.dtb
rm leds.dtb.tmp
check rk3128-pomera-dm250.dtb e39acaed18786ffa5a0eb546667c026e3f52ef6c0b9cc5aec40cae0aade18a9f

# RSCE: 0x000 "RSCE" の頭、0x200 項目 "ENTR" と名前、0x304 DTB の位置（512 バイト単位で 2 = 0x400）、
# 0x308 DTB の長さ、0x400 から DTB、残りは 0 で 1MiB
python3 - rk3128-pomera-dm250.dtb rsce.bin <<'PY'
import struct, sys
d = open(sys.argv[1], "rb").read()
r = bytearray(1 << 20)
r[0:16] = b"RSCE" + bytes(4) + bytes([1, 1, 1, 0, 1, 0, 0, 0])
r[0x200:0x204] = b"ENTR"
name = b"rk-kernel.dtb"
r[0x204:0x204 + len(name)] = name
r[0x304:0x30c] = struct.pack("<II", 2, len(d))
assert 0x400 + len(d) <= len(r)
r[0x400:0x400 + len(d)] = d
open(sys.argv[2], "wb").write(r)
PY
check rsce.bin 75e3b8e9b06775e87e45848f1c88fe6f78ed22826da207bfe8d3f52fc94fa4be
