# shellcheck shell=bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 yasoteien
#
# U-Boot（SD の 8〜12MiB、Rockchip の LOADER の写し 1MiB × 4）を見る・書く部品。
# pomera-kernel が source する（/usr/lib/pomera-kernel/uboot.sh）。
# 呼ぶ側が UBOOT_DEV（例 /dev/mmcblk1）を決める。誤りは標準エラーに出し、0 以外で返す（止めるかは呼ぶ側）。
#
# 写しの形: 各 1MiB の 0 バイト目に "LOADER  "（8 文字）、+16 に読み込み先 0x60200000（LE）、本体は +2048 から。
# 4 つは同じ物。miniloader は写し 1 から読む（壊れた写しを飛ばすかは試験 SD で確かめる）。
# known の一覧は「sha256（4MiB 全体） 名前」の 2 列。作者の U-Boot は 825b5b19…（8〜12MiB の 4MiB 全体）。

UBOOT_OFF=8      # MiB
UBOOT_LOAD=0x60200000

# 1MiB の所（MiB の位置）からの sha256。$1 = 位置、$2 = MiB の数
uboot_sha_at() { dd if="$UBOOT_DEV" bs=1M skip="$1" count="$2" iflag=direct status=none | sha256sum | cut -d' ' -f1; }

# SD の 8〜12MiB 全体の sha256
uboot_current() { uboot_sha_at $UBOOT_OFF 4; }

# sha256 の名前（無ければ空で 1 を返す）。$1 = sha256、$2 = known の一覧
uboot_name() {
	local n
	n=$(awk -v h="$1" '$1 == h { print $2; exit }' "$2" 2>/dev/null)
	[ -n "$n" ] && echo "$n"
}

# 4MiB の物が U-Boot の形か: 大きさ・4 つとも LOADER・読み込み先・4 つが同じ。$1 = ファイル
uboot_check_image() {
	local f=$1 i addr
	[ "$(stat -c %s "$f" 2>/dev/null)" = 4194304 ] || { echo "$f が 4MiB でない" >&2; return 1; }
	for i in 0 1 2 3; do
		[ "$(dd if="$f" bs=8 count=1 iflag=skip_bytes skip=$(( i << 20 )) status=none | tr -d '\0')" = "LOADER  " ] ||
			{ echo "$f の写し $(( i + 1 )) が LOADER でない" >&2; return 1; }
		addr=$(dd if="$f" bs=4 count=1 iflag=skip_bytes skip=$(( (i << 20) + 16 )) status=none | od -An -tu4 | tr -d ' ')
		[ "$addr" = $(( UBOOT_LOAD )) ] || { echo "$f の写し $(( i + 1 )) の読み込み先が違う" >&2; return 1; }
	done
	[ "$(for i in 0 1 2 3; do dd if="$f" bs=1M skip=$i count=1 status=none | sha256sum; done | sort -u | wc -l)" = 1 ] ||
		{ echo "$f の 4 つの写しが同じでない" >&2; return 1; }
}

# 4MiB の物を 8〜12MiB に書く。写し 2・3・4 を先に、1 を最後に（途中で落ちても、写し 1 は最後まで前の物）。
# 1 つ書くごとに fsync・flushbufs して読み戻し、照合する。$1 = ファイル（先に uboot_check_image を通す）
uboot_put() {
	local f=$1 h i
	for i in 1 2 3 0; do
		h=$(dd if="$f" bs=1M skip=$i count=1 status=none | sha256sum | cut -d' ' -f1)
		dd if="$f" of="$UBOOT_DEV" bs=1M skip=$i seek=$(( UBOOT_OFF + i )) count=1 conv=fsync,notrunc status=none || return 1
		blockdev --flushbufs "$UBOOT_DEV" 2>/dev/null || true
		[ "$(uboot_sha_at $(( UBOOT_OFF + i )) 1)" = "$h" ] ||
			{ echo "U-Boot の写し $(( i + 1 )) の読み戻しが違う" >&2; return 1; }
	done
	[ "$(uboot_current)" = "$(sha256sum "$f" | cut -d' ' -f1)" ] || { echo "書いた後の 8〜12MiB が違う" >&2; return 1; }
}

# 今の 8〜12MiB を退避する。$1 = 出力。照合して、合えば 0
uboot_save() {
	local out=$1 now
	now=$(uboot_current)
	dd if="$UBOOT_DEV" of="$out.new" bs=1M skip=$UBOOT_OFF count=4 iflag=direct status=none || return 1
	[ "$(sha256sum "$out.new" | cut -d' ' -f1)" = "$now" ] || { rm -f "$out.new"; echo "U-Boot の退避の sha256 が違う" >&2; return 1; }
	mv "$out.new" "$out"
}

# p1（vfat）に uboot.env があるか。ある時 0。U-Boot（作者の物も dm250 の物も）は p1 の uboot.env を読み、
# 既定の環境（bootargs 等）を丸ごと置き換えるので、ある時は試さない。$1 = p1 の装置（例 /dev/mmcblk1p1）
uboot_env_present() {
	local p1=$1 m t r=1
	[ "$(blkid -o value -s TYPE "$p1" 2>/dev/null)" = vfat ] || return 1
	m=$(findmnt -n -o TARGET "$p1" 2>/dev/null | head -1 || true)
	if [ -n "$m" ]; then
		[ -e "$m/uboot.env" ] && r=0
	else
		t=$(mktemp -d /run/pomera-uboot-p1.XXXXXX)
		if mount -t vfat -o ro "$p1" "$t" 2>/dev/null; then
			[ -e "$t/uboot.env" ] && r=0
			umount "$t"
		fi
		rmdir "$t"
	fi
	return $r
}
