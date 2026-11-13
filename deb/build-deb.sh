#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 yasoteien
# 自前カーネルの .deb を組む（build-deb.sh のある所で、out/ と work/ を作る）。
#
#   bash build-deb.sh <版> <KRNL 12MiB> <modules.tgz> <RSCE 1MiB> [tools の版] [組み直しの番号]
#   組み直しの番号: カーネルの版が同じまま中身（RSCE など）を替えた時に、パッケージの版を <版>+<番号> に上げる
#   （例 6.18.60-st6+1。dpkg では 6.18.60-st6 より新しい。/usr/lib/pomera-kernel/ と /usr/lib/modules/ の名前は <版> のまま）。
#   追従用のメタ（pomera-kernel）の版は、週 1 回の公開の日付 YYYY.MM.DD（2026-11-04 のユーザーの決定。
#   CHANGELOG の見出し `## [YYYY.MM.DD] - YYYY-MM-DD` と同じ）。既定は組む日（日本時間）。同じ週の出し直しは
#   POMERA_META_VER=2026.11.04.1 のように渡す。<版> の印は数字で始まる物（5jk）と英字の物（st6）が dpkg で
#   思った順に並ばないので、メタの版には使わない。
#   U-Boot も組にする版（tools 0.7 から）は POMERA_UBOOT=<uboot.img（4MiB）> と POMERA_UBOOT_KNOWN=<uboot-known.sha256> を渡す
#   （上書きしてよい U-Boot の一覧。行は「sha256 名前 [table]」で、table は表を読む U-Boot。uboot.img の sha は table の行で載る事）。
#   渡さない版は U-Boot に触らない（今までどおり）。
#   メタだけを組む（試験で合格した版のパッケージを組み直さずに、出し直しのメタだけを作る）:
#     POMERA_META_VER=2026.11.04.2 bash build-deb.sh --meta <版> [組み直しの番号]
#   例: bash build-deb.sh 6.18.60-st6 ../krnl-6.18.60-st6-12M.bin ../modules-6.18.60-st6.tgz \
#         ../wk-rk818/dt5f/rsce-alldma-rk818int-leds.bin 0.1
#
# 作る物（out/ に）:
#   pomera-kernel-tools_<tools の版>_all.deb   試し起動の仕掛け（pomera-kernel、systemd の単位）と hibernate の無線の仕掛け
#   pomera-kernel-<版>_<版>_armhf.deb          モジュール（/lib/modules/<版>）と組（/usr/lib/pomera-kernel/<版>/ の KRNL・RSCE・DTB）
#   pomera-kernel_<YYYY.MM.DD>_all.deb         apt upgrade で新しい版に追従するための空のパッケージ（版は公開の日付）
# 素材は試験 SD で合格した物をそのまま使う（組み直さない）。
set -euo pipefail
META_ONLY=0
if [ "${1:-}" = --meta ]; then
	META_ONLY=1; V=${2:?版}; REV=${3:-}; KRNL=; TGZ=; RSCE=; TV=
else
	V=${1:?版}; KRNL=${2:?KRNL}; TGZ=${3:?modules.tgz}; RSCE=${4:?RSCE}; TV=${5:-0.1}; REV=${6:-}
fi
PV=$V${REV:++$REV}   # パッケージの版
MV=${POMERA_META_VER:-$(TZ=Asia/Tokyo date +%Y.%m.%d)}   # メタの版
[[ "$MV" =~ ^20[0-9]{2}\.[01][0-9]\.[0-3][0-9](\.[0-9]+)?$ ]] || { echo "メタの版は YYYY.MM.DD[.N]: $MV" >&2; exit 1; }
[[ -z "$REV" || "$REV" =~ ^[0-9]+$ ]] || { echo "組み直しの番号は数字: $REV" >&2; exit 1; }
cd "$(dirname "$0")"
TOP=$PWD
[[ "$V" =~ ^6\.18\.[0-9]+-[a-z0-9]+$ ]] || { echo "版の名前が違う: $V" >&2; exit 1; }
[ $META_ONLY = 1 ] || {
[ "$(stat -c %s "$KRNL")" = 12582912 ] && [ "$(head -c 4 "$KRNL")" = KRNL ] || { echo "$KRNL が 12MiB の KRNL でない" >&2; exit 1; }
[ "$(stat -c %s "$RSCE")" = 1048576 ] && [ "$(head -c 4 "$RSCE")" = RSCE ] || { echo "$RSCE が 1MiB の RSCE でない" >&2; exit 1; }
UB=${POMERA_UBOOT:-}; UBK=${POMERA_UBOOT_KNOWN:-}
if [ -n "$UB" ]; then
	[ -n "$UBK" ] || { echo "POMERA_UBOOT には POMERA_UBOOT_KNOWN も要る" >&2; exit 1; }
	[ "$(stat -c %s "$UB")" = 4194304 ] || { echo "$UB が 4MiB でない" >&2; exit 1; }
	for i in 0 1 2 3; do
		[ "$(dd if="$UB" bs=8 count=1 iflag=skip_bytes skip=$(( i << 20 )) status=none)" = "LOADER  " ] ||
			{ echo "$UB の $(( i + 1 )) 番目の写しが LOADER でない" >&2; exit 1; }
	done
	[ "$(for i in 0 1 2 3; do dd if="$UB" bs=1M skip=$i count=1 status=none | sha256sum; done | sort -u | wc -l)" = 1 ] ||
		{ echo "$UB の 4 つの写しが同じでない" >&2; exit 1; }
	awk -v h="$(sha256sum "$UB" | cut -d' ' -f1)" '$1 == h && $3 == "table" { f = 1 } END { exit !f }' "$UBK" ||
		{ echo "$UB の sha256 が $UBK に table の行で無い" >&2; exit 1; }
	# 公開ソースの組み立ての結果（uboot/public/uboot.img.sha256）と同じ物だけを入れる
	# 公開の木では POMERA_UBOOT_SHA=<木>/uboot/uboot.img.sha256 を渡す
	UBS=${POMERA_UBOOT_SHA:-$TOP/uboot/public/uboot.img.sha256}
	[ "$(sha256sum < "$UB" | cut -d' ' -f1)" = "$(cut -d' ' -f1 "$UBS")" ] ||
		{ echo "$UB が $UBS と違う（公開ソースから組んだ物でない）" >&2; exit 1; }
fi
tar -tzf "$TGZ" | grep -qv "^lib/modules/$V/\|^lib/modules/$V\$" && { echo "$TGZ に lib/modules/$V の外の物がある" >&2; exit 1; }
true
}
# Maintainer: GitHub の noreply のアドレス（2026-11-04 のユーザーの決定。個人のアドレスは公開の物に書かない）。POMERA_MAINT で替えられる
MAINT=${POMERA_MAINT:-yasoteien <263659156+yasoteien@users.noreply.github.com>}
DATE=$(date -R)
rm -rf work; mkdir -p work out

docs() {  # $1 = パッケージの根, $2 = 名前
	install -d "$1/usr/share/doc/$2"
	cp "$TOP/copyright" "$1/usr/share/doc/$2/copyright"
	printf '%s (%s) unstable; urgency=medium\n\n  * 試作（%s）。\n\n -- %s  %s\n' "$2" "$3" "$4" "$MAINT" "$DATE" |
		gzip -9n > "$1/usr/share/doc/$2/$5"
	chmod 0644 "$1/usr/share/doc/$2/$5" "$1/usr/share/doc/$2/copyright"
}
md5() { (cd "$1" && find . -path ./DEBIAN -prune -o -type f -print0 | sort -z | xargs -0 md5sum | sed 's#  \./#  #') > "$1/DEBIAN/md5sums"; }
size() { du -sk --exclude=DEBIAN "$1" | cut -f1; }

# 受け入れる機種の表と preinst は machine.sh が正本（pomera-uboot と共通）。pomera-kernel の中の表も同じかを見る
# shellcheck source=machine.sh
. "$TOP/machine.sh"
check_machine_table "$TOP/tools/sbin/pomera-kernel" || exit 1

if [ $META_ONLY = 0 ]; then
# 1. pomera-kernel-tools
T=work/tools; P=pomera-kernel-tools
install -D -m 0755 tools/sbin/pomera-kernel "$T/usr/sbin/pomera-kernel"
install -D -m 0644 tools/share/RESTORE.txt "$T/usr/lib/pomera-kernel/RESTORE.txt"
install -D -m 0644 uboot/known.sha256 "$T/usr/lib/pomera-kernel/uboot-known.sha256"   # 一覧の正本は uboot/known.sha256
install -D -m 0755 tools/libexec/hibernate-wireless "$T/usr/libexec/pomera-kernel/hibernate-wireless"
install -D -m 0644 tools/systemd/pomera-kernel-trial.service "$T/usr/lib/systemd/system/pomera-kernel-trial.service"
install -D -m 0644 tools/systemd/pomera-kernel-confirm.service "$T/usr/lib/systemd/system/pomera-kernel-confirm.service"
install -D -m 0644 tools/systemd/pomera-kernel-confirm.timer "$T/usr/lib/systemd/system/pomera-kernel-confirm.timer"
install -D -m 0644 tools/systemd/systemd-hibernate.service.d/60-pomera-wireless.conf \
	"$T/usr/lib/systemd/system/systemd-hibernate.service.d/60-pomera-wireless.conf"
install -D -m 0644 tools/udev/60-pomera-usb-hub.rules "$T/usr/lib/udev/rules.d/60-pomera-usb-hub.rules"   # 0.8 から。ハブを寝かせない
docs "$T" $P "$TV" "試し起動の仕掛け、hibernate の無線の仕掛け、USB のハブを寝かせない udev の規則" changelog.gz
install -m 0644 README.pkg.md "$T/usr/share/doc/$P/README.md"   # 利用者向け（README.md は作業の記録で、パッケージには入れない）
install -d "$T/DEBIAN"
cat > "$T/DEBIAN/control" <<EOF
Package: $P
Version: $TV
Architecture: all
Maintainer: $MAINT
Installed-Size: $(size "$T")
Depends: kexec-tools, python3, systemd, kmod
Section: kernel
Priority: optional
Homepage: https://github.com/yasoteien
Description: Pomera DM250 kernel trial-boot tools
 Boots a newly installed kernel once with kexec and a hardware watchdog.
 If the trial boot reaches a healthy state, the kernel (KRNL), the device
 tree (RSCE) and the U-Boot of that version are written to the SD card as a
 set: KRNL and RSCE go to the unused one of two slots (A/B), a small table
 tells U-Boot which slot to boot, so a power cut while writing leaves either
 the previous or the new set. Otherwise the watchdog resets the board and the
 previous set boots again.
 Also unloads the Wi-Fi and Bluetooth modules around hibernation, and keeps
 USB hubs from autosuspending (the DM250's USB controller misses the remote
 wakeup of a suspended hub, so devices plugged in later were not detected).
 .
 Unofficial test release with no warranty; use at your own risk and copy
 the SD card first. It has nothing to do with King Jim or the distributor
 of the Debian image for the DM250. To go back: pomera-kernel rollback.
EOF
write_preinst "$T/DEBIAN" pomera-kernel
cat > "$T/DEBIAN/postinst" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = configure ]; then
	deb-systemd-helper enable pomera-kernel-trial.service pomera-kernel-confirm.timer >/dev/null || true
	pomera-kernel keep || true
	if [ -d /run/systemd/system ]; then
		deb-systemd-invoke daemon-reload >/dev/null 2>&1 || true
	fi
	# 0.8: 今つながっているハブにも、USB のハブを寝かせない規則を当てる（次に挿すまで待たない）
	if command -v udevadm >/dev/null 2>&1; then
		udevadm control --reload-rules >/dev/null 2>&1 || true
		udevadm trigger --action=add --subsystem-match=usb --attr-match=bDeviceClass=09 >/dev/null 2>&1 || true
	fi
fi
exit 0
EOF
cat > "$T/DEBIAN/prerm" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = remove ]; then
	if [ -f /var/lib/pomera-kernel/trying ]; then
		echo "pomera-kernel-tools: 試しの途中（/var/lib/pomera-kernel/trying）。終わってから外す" >&2
		exit 1
	fi
	deb-systemd-helper disable pomera-kernel-trial.service pomera-kernel-confirm.timer >/dev/null || true
fi
exit 0
EOF
cat > "$T/DEBIAN/postrm" <<'EOF'
#!/bin/sh
set -e
if [ "$1" = purge ]; then
	deb-systemd-helper purge pomera-kernel-trial.service pomera-kernel-confirm.timer >/dev/null || true
	rm -rf /var/lib/pomera-kernel
	rm -f /etc/apt/apt.conf.d/01pomera-kernel-autoremove
fi
exit 0
EOF
chmod 0755 "$T/DEBIAN/postinst" "$T/DEBIAN/prerm" "$T/DEBIAN/postrm"
md5 "$T"
# 同じ版の tools が out/ にあれば置き換えない（作り直すと日付で sha256 が変わり、試験で合格した物と別物になる）
if [ -e "out/${P}_${TV}_all.deb" ]; then
	echo "out/${P}_${TV}_all.deb はもうある。置き換えない（中身を変えたなら tools の版を上げる）" >&2
else
	dpkg-deb --root-owner-group -Zxz --build "$T" "out/${P}_${TV}_all.deb" >/dev/null
fi

# 2. pomera-kernel-<版>
I=work/image; P=pomera-kernel-$V
install -d "$I/usr/lib/pomera-kernel/$V"
# Debian 13 は /lib が /usr/lib への symlink（/usr の統合）。モジュールは /usr/lib/modules に置く
install -d "$I/usr"
tar --no-same-owner -xzf "$TGZ" -C "$I/usr"
rm -f "$I/usr/lib/modules/$V/build" "$I/usr/lib/modules/$V/source"
find "$I/usr/lib/modules" -type d -exec chmod 0755 {} + -o -type f -exec chmod 0644 {} +
# depmod が作る物は持たない（postinst の depmod が書き換えると dpkg の記録と食い違う。Debian の linux-image と同じ）
GEN="modules.alias modules.alias.bin modules.builtin.alias.bin modules.builtin.bin modules.dep modules.dep.bin modules.devname modules.softdep modules.symbols modules.symbols.bin modules.weakdep"
(cd "$I/usr/lib/modules/$V" && rm -f $GEN)
cp "$KRNL" "$I/usr/lib/pomera-kernel/$V/krnl-12M.bin"
cp "$RSCE" "$I/usr/lib/pomera-kernel/$V/rsce.bin"
# RSCE の 0x400 から DTB（大きさは FDT の頭の totalsize、big endian）。試しの kexec に渡す
python3 - "$RSCE" "$I/usr/lib/pomera-kernel/$V/dtb" <<'PY'
import struct, sys
d = open(sys.argv[1], "rb").read()
assert d[0x400:0x404] == b"\xd0\x0d\xfe\xed", "RSCE の 0x400 に DTB が無い"
n = struct.unpack(">I", d[0x404:0x408])[0]
open(sys.argv[2], "wb").write(d[0x400:0x400 + n])
print("dtb", n, "bytes")
PY
echo "$V" > "$I/usr/lib/pomera-kernel/$V/kernel.release"
if [ -n "$UB" ]; then
	cp "$UB" "$I/usr/lib/pomera-kernel/$V/uboot.img"
	cp "$UBK" "$I/usr/lib/pomera-kernel/$V/uboot-known.sha256"
	(cd "$I/usr/lib/pomera-kernel/$V" && sha256sum krnl-12M.bin rsce.bin dtb uboot.img uboot-known.sha256 > sha256sums)
else
	(cd "$I/usr/lib/pomera-kernel/$V" && sha256sum krnl-12M.bin rsce.bin dtb > sha256sums)
fi
chmod 0644 "$I/usr/lib/pomera-kernel/$V"/*
docs "$I" "$P" "$PV" "本家 6.18 longterm ＋ DM250 のパッチ（patches/series）。素材は試験 SD で合格した物" changelog.Debian.gz
install -d "$I/DEBIAN"
cat > "$I/DEBIAN/control" <<EOF
Package: $P
Version: $PV
Architecture: armhf
Maintainer: $MAINT
Installed-Size: $(size "$I")
Depends: pomera-kernel-tools (>= $TV), kmod
Section: kernel
Priority: optional
Homepage: https://github.com/yasoteien
Description: Linux $V for the King Jim Pomera DM250
 Linux 6.18 longterm with the DM250 patches (PL330, RK3128 LVDS, TC3589x
 keypad, USB charger detection, RK818 charger and fuel gauge, hibernation
 fixes). Ships the modules, the kernel in Rockchip KRNL format and the
 matching device tree in RSCE format. Nothing is written to the SD card at
 install time: the kernel is tried once on the next boot and confirmed by
 pomera-kernel-tools.
 .
 Unofficial test release with no warranty; use at your own risk and copy
 the SD card first. It has nothing to do with King Jim or the distributor
 of the Debian image for the DM250. To go back: pomera-kernel rollback.
EOF
write_preinst "$I/DEBIAN" pomera-kernel
cat > "$I/DEBIAN/postinst" <<EOF
#!/bin/sh
set -e
if [ "\$1" = configure ]; then
	depmod -a $V
	if pomera-kernel stage $V; then
		:  # 試す予定を作ったか、もう入っているかは stage が書く
	else
		echo "pomera-kernel: $V は置きました。試すには pomera-kernel stage $V" >&2
	fi
fi
exit 0
EOF
cat > "$I/DEBIAN/prerm" <<EOF
#!/bin/sh
set -e
if [ "\$1" = remove ]; then
	if [ "\$(cat /var/lib/pomera-kernel/current 2>/dev/null)" = $V ] && [ -z "\${POMERA_KERNEL_FORCE_REMOVE:-}" ]; then
		echo "pomera-kernel: $V は今 SD の 12MiB・24MiB に入っている組。外すと次の起動でモジュールが無い。" >&2
		echo "  別の版を確定してから外す（どうしても外すなら POMERA_KERNEL_FORCE_REMOVE=1）" >&2
		exit 1
	fi
	if [ "\$(cat /var/lib/pomera-kernel/pending 2>/dev/null)" = $V ]; then
		pomera-kernel unstage || true
	fi
fi
exit 0
EOF
cat > "$I/DEBIAN/postrm" <<EOF
#!/bin/sh
set -e
if [ "\$1" = remove ] || [ "\$1" = purge ]; then
	if cd /usr/lib/modules/$V 2>/dev/null; then
		rm -f $GEN
		cd /
		rmdir /usr/lib/modules/$V 2>/dev/null || true
	fi
fi
exit 0
EOF
chmod 0755 "$I/DEBIAN/postinst" "$I/DEBIAN/prerm" "$I/DEBIAN/postrm"
md5 "$I"
dpkg-deb --root-owner-group -Zxz --build "$I" "out/${P}_${PV}_armhf.deb" >/dev/null

fi  # META_ONLY

# 3. pomera-kernel（追従用）
if [ -e "out/pomera-kernel_${MV}_all.deb" ]; then
	echo "out/pomera-kernel_${MV}_all.deb はもうある。置き換えない（出し直しは POMERA_META_VER で版を上げる）" >&2; exit 1
fi
M=work/meta; P=pomera-kernel
docs "$M" $P "$MV" "最新の pomera-kernel-<版> に追従する空のパッケージ" changelog.gz   # 版に - が無い native なので changelog.gz
install -d "$M/DEBIAN"
cat > "$M/DEBIAN/control" <<EOF
Package: $P
Version: $MV
Architecture: all
Maintainer: $MAINT
Installed-Size: $(size "$M")
Depends: pomera-kernel-$V (>= $PV)
Section: kernel
Priority: optional
Homepage: https://github.com/yasoteien
Description: Latest Linux kernel for the King Jim Pomera DM250 (metapackage)
 Depends on the newest pomera-kernel-<version> package so that
 "apt upgrade" brings in new kernels.
 .
 Unofficial test release with no warranty; use at your own risk and copy
 the SD card first. It has nothing to do with King Jim or the distributor
 of the Debian image for the DM250. To go back: pomera-kernel rollback.
EOF
md5 "$M"
dpkg-deb --root-owner-group -Zxz --build "$M" "out/${P}_${MV}_all.deb" >/dev/null

ls -la out/
(cd out && sha256sum *.deb > SHA256SUMS)
