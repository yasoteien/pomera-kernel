#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 yasoteien
#
# Build the KING JIM Pomera DM250 U-Boot from the U-Boot v2026.07 release
# and the patches in patches/, and pack it the way the SD card holds it
# (uboot.img: 4 MiB, four identical Rockchip LOADER copies at 0x60200000;
# it goes at 8 MiB on the SD card).
#
#   ./build.sh [WORKDIR]      default WORKDIR: ./work
#
# Needs: git, make, gcc, bison, flex, python3, libssl-dev, device-tree-compiler
# and an ARM cross compiler (CROSS_COMPILE, default arm-linux-gnueabihf-).
# The build is reproducible: the same compiler gives the same uboot.img as
# the one in the pomera-uboot package (sha256 in uboot.img.sha256).
set -euo pipefail

UPSTREAM=https://source.denx.de/u-boot/u-boot.git
TAG=v2026.07
TAG_COMMIT=ece349ade2973e220f524ce59e59711cc919263f
LOCALVERSION=-dm250.8
SOURCE_DATE_EPOCH=1793750400     # 2026-11-04 00:00 UTC
LOAD_ADDR=0x60200000
export CROSS_COMPILE=${CROSS_COMPILE:-arm-linux-gnueabihf-}
export SOURCE_DATE_EPOCH LOCALVERSION

HERE=$(cd "$(dirname "$0")" && pwd)
W=$(mkdir -p "${1:-$PWD/work}" && cd "${1:-$PWD/work}" && pwd)
SRC=$W/u-boot-${TAG#v}
OUT=$W/out

# 1. U-Boot v2026.07, checked by its commit id
if [ ! -d "$W/upstream.git" ]; then
	git clone -q --bare --depth 1 --branch "$TAG" "$UPSTREAM" "$W/upstream.git"
fi
got=$(git -C "$W/upstream.git" rev-parse "$TAG^{commit}")
[ "$got" = "$TAG_COMMIT" ] || { echo "$TAG is $got, expected $TAG_COMMIT" >&2; exit 1; }

# 2. A plain tree (no .git, so the version string has no commit hash) with the patches
rm -rf "$SRC" "$OUT"
mkdir -p "$SRC"
git -C "$W/upstream.git" archive "$TAG_COMMIT" | tar -x -C "$SRC"
for p in "$HERE"/patches/*.patch; do
	git -C "$SRC" apply --whitespace=nowarn "$p" || { echo "failed: $p" >&2; exit 1; }
done

# 3. Build (pom.config: the Pomeranian logo)
make -C "$SRC" -s O="$OUT" pomera_dm250_defconfig pom.config </dev/null
make -C "$SRC" -s O="$OUT" -j"$(nproc)" </dev/null

# 4. Pack: four LOADER copies, 1 MiB each
"$OUT/tools/loaderimage" --pack "$OUT/u-boot.bin" "$W/uboot.img" $LOAD_ADDR >/dev/null
sha256sum "$W/uboot.img"
if [ -f "$HERE/uboot.img.sha256" ]; then
	if [ "$(cut -d' ' -f1 "$HERE/uboot.img.sha256")" = "$(sha256sum "$W/uboot.img" | cut -d' ' -f1)" ]; then
		echo "same as the released uboot.img"
	else
		echo "differs from the released uboot.img (another compiler version?)"
	fi
fi
