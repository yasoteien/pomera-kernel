# shellcheck shell=bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 yasoteien
# 受け入れる機種の表の正本（build-deb.sh と pomera-uboot の組み立ての台本が source する）。
# 保証できるのは DM250 の日本版だけ。動いている DT の model と compatible が、ここの物と完全に一致した時だけ入れる・書く。
# tools/sbin/pomera-kernel の OK_MODELS・OK_COMPATS も同じ物にする（build-deb.sh が照らして、違えば止まる）。
POMERA_OK_MODEL="King Jim Pomera DM250"
POMERA_OK_COMPAT="kingjim,pomera-dm250 rockchip,rk3128"

# write_preinst <DEBIAN の置き場> <名前>: 機種を調べて、合わなければ入れない preinst を書く。<名前> は誤りの文の頭
write_preinst() {
	cat > "$1/preinst" <<EOF
#!/bin/sh
set -e
# 保証できるのは DM250 の日本版だけ。動いている DT の model と compatible が、並べた物と完全に一致した時だけ入れる
case "\$1" in install|upgrade)
	model=\$( { tr -d '\\000' < /proc/device-tree/model; } 2>/dev/null || true)
	compat=\$( { tr '\\000' ' ' < /proc/device-tree/compatible; } 2>/dev/null | sed 's/ \$//' || true)
	if [ "\$model" = "$POMERA_OK_MODEL" ] && [ "\$compat" = "$POMERA_OK_COMPAT" ]; then
		exit 0
	fi
	echo "$2: この機械には入れられない（保証できるのは King Jim Pomera DM250 の日本版だけ）" >&2
	echo "  model:      \${model:-（読めない）}" >&2
	echo "  compatible: \${compat:-（読めない）}" >&2
	exit 1
	;;
esac
exit 0
EOF
	chmod 0755 "$1/preinst"
}

# check_machine_table <台本>: 台本の OK_MODELS・OK_COMPATS が、ここの表と同じかを見る
check_machine_table() {
	grep -qxF "OK_MODELS=(\"$POMERA_OK_MODEL\")" "$1" && grep -qxF "OK_COMPATS=(\"$POMERA_OK_COMPAT\")" "$1" ||
		{ echo "$1 の機種の表が machine.sh と違う" >&2; return 1; }
}
