#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-or-later
# Copyright (C) 2026 yasoteien
#
# 本家 stable の版に DM250 のパッチを当てて組む台本（組み立て用の Linux 機の wk-stable で使う）。
# 週 1 点検（kernel-stable-weekly）と、試験の版の両方から呼ぶ。
# 2026-11-04、木とビルド先を SSD の git の木へ移した（前の形は stable-tar.sh）。
#
# 使い方:
#   bash stable.sh <版> [LOCALVERSION] [--upto <パッチ名の一部>] [--extra <パッチ>]... [--keep <名前>]
#                  [--clean] [--pack] [--no-build]
#   例: bash stable.sh 6.18.61 -wk20261108 --upto clk-disable-unused-after-hibernation
#       bash stable.sh 6.18.60 -5jd --upto clk-disable --extra 0022-draft.patch --pack
#   --extra   UPTO の後に、series に無いパッチを積む（wk-stable からの相対か、patches/ の名前）。何度でも書ける。
#   --keep    組んだ O= を obj-keep/<名前> へ写して残す（obj-a・obj-b は次の版で使い回されるため）。
#   --clean   O= を空にしてから組む。
#   --pack    組めたら kernel_pack.sh で krnl・modules を作る（~/work/dm250-kernel に置く）。
#
# 置き場:
#   SSD /var/tmp/kbuild/stable/
#       linux/       本家 stable の git。タグは --depth 1 で取る。branch dm250/<版><LV> を版ごとに作る
#       obj-a・obj-b O=。同じ branch を前に組んだ方を、無ければ古い方を使う（今と 1 つ前の 2 つ）
#       obj-keep/    --keep の写し
#   SSD /var/tmp/kbuild/ccache/  ccache（~/.config/ccache/ccache.conf で指定、上限 5G。下の「ccache」）。入っていなければ無しで組む
#   HDD ~/work/dm250-kernel/wk-stable/
#       gnupg/・patches/（正本）・configs/
#       apply-<版><LV>.log・build-<版><LV>.log・config-new-<版><LV>.txt（記録）
#
# 行う事:
#   1. タグ v<版> を取り、git verify-tag で Greg Kroah-Hartman の署名（指紋を下に固定）を確かめる。
#   2. branch dm250/<版><LV> をタグから作り直し、patches/series を UPTO まで、続けて --extra を、
#      1 パッチ 1 commit で積む（commit の文にパッチの名前と sha256）。当たらなければ止める。
#      fuzz・offset で当たった所は記録に残す。
#   3. configs/dm250.config を元に olddefconfig（CONFIG_LOCALVERSION は空、LV は make の LOCALVERSION=）。
#      新しく現れた設定を config-new に書く。
#   4. zImage と modules を組み、build-<版><LV>.log の最後に EXIT= を書く。
set -euo pipefail

GREG_FPR=647F28654894E3BD457199BE38DBBDC86092693E
REMOTE=https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git
KB=/var/tmp/kbuild/stable
GIT=$KB/linux

cd "$(dirname "$0")"
TOP=$PWD
VER=${1:?版を指定（例 6.18.60）}
shift
LV=-dm250
UPTO=
EXTRA=()
KEEP=
CLEAN=0
PACK=0
BUILD=1
while [ $# -gt 0 ]; do
	case $1 in
	--upto) UPTO=$2; shift 2 ;;
	--extra) EXTRA+=("$2"); shift 2 ;;
	--keep) KEEP=$2; shift 2 ;;
	--clean) CLEAN=1; shift ;;
	--pack) PACK=1; shift ;;
	--no-build) BUILD=0; shift ;;
	-*) LV=$1; shift ;;
	*) echo "不明な引数: $1" >&2; exit 2 ;;
	esac
done

NAME=$VER$LV
BR=dm250/$NAME
APPLY=$TOP/apply-$NAME.log
LOG=$TOP/build-$NAME.log
export GNUPGHOME=$TOP/gnupg

# 同じ木を 2 つが同時に触らないように
mkdir -p "$KB"
exec 9> "$KB/.lock"
flock -n 9 || { echo "ほかの stable.sh が動いている（$KB/.lock）" >&2; exit 1; }

# --extra の場所を先に決める（無ければ何もしないうちに止める）
EXTRA_PATH=()
for e in "${EXTRA[@]}"; do
	if [ -f "$e" ]; then EXTRA_PATH+=("$(readlink -f "$e")")
	elif [ -f "patches/$e" ]; then EXTRA_PATH+=("$TOP/patches/$e")
	else echo "--extra のパッチが無い: $e" >&2; exit 2
	fi
done

# 1. 取得と署名の確かめ
[ -d "$GIT/.git" ] || git init -q "$GIT"
git -C "$GIT" remote get-url origin > /dev/null 2>&1 || git -C "$GIT" remote add origin $REMOTE
git -C "$GIT" config remote.origin.tagOpt --no-tags
git -C "$GIT" rev-parse -q --verify "refs/tags/v$VER" > /dev/null ||
	git -C "$GIT" fetch -q --depth 1 origin tag "v$VER"
gpg -q --list-keys $GREG_FPR > /dev/null 2>&1 ||
	gpg -q --auto-key-locate clear,wkd --locate-keys gregkh@kernel.org > /dev/null
git -C "$GIT" verify-tag --raw "v$VER" 2>&1 |
	grep -q "^\[GNUPG:\] VALIDSIG .* $GREG_FPR\$" || { echo "署名が合わない: タグ v$VER" >&2; exit 1; }
echo "署名は正しい: タグ v$VER（$(git -C "$GIT" rev-parse "v$VER^{commit}")）"

# 2. branch を作り直して当てる
git -C "$GIT" checkout -q -f -B "$BR" "v$VER"
git -C "$GIT" clean -q -fdx
apply_one() {
	local p=$1 name
	name=$(basename "$p")
	echo "== $name" >> "$APPLY"
	if ! patch -d "$GIT" -p1 --forward --no-backup-if-mismatch < "$p" >> "$APPLY" 2>&1; then
		echo "当たらない: $name（$APPLY と $GIT の *.rej を見る）" >&2
		git -C "$GIT" ls-files -o --exclude-standard '*.rej' >&2
		exit 1
	fi
	git -C "$GIT" add -A
	git -C "$GIT" -c user.name=stable.sh -c user.email=stable.sh@example.invalid commit -q --allow-empty \
		-m "$name" -m "sha256 $(sha256sum < "$p" | cut -d' ' -f1)"
}
: > "$APPLY"
while read -r p; do
	case $p in ''|'#'*) continue ;; esac
	apply_one "$TOP/patches/$p"
	[ -n "$UPTO" ] && [[ $p == *"$UPTO"* ]] && break
done < patches/series
for p in "${EXTRA_PATH[@]}"; do
	apply_one "$p"
done
if grep -q -E 'fuzz|offset' "$APPLY"; then
	echo "ずれて当たった所（中身を確かめる事）:"
	grep -B1 -E 'fuzz|offset' "$APPLY" | grep -v '^--$'
fi
echo "当てた: $(grep -c '^== ' "$APPLY") 個（$APPLY、branch $BR）"
[ $BUILD = 1 ] || exit 0

# 3. O= を選ぶ（同じ branch を組んだ方、無ければ古い方）
OBJ=
for o in obj-a obj-b; do
	[ "$(cat "$KB/$o/.branch" 2>/dev/null)" = "$BR" ] && { OBJ=$KB/$o; break; }
done
if [ -z "$OBJ" ]; then
	OBJ=$KB/obj-a
	[ "$KB/obj-b/.branch" -ot "$KB/obj-a/.branch" ] && OBJ=$KB/obj-b
fi
[ $CLEAN = 1 ] && rm -rf "$OBJ"
mkdir -p "$OBJ"
echo "$BR" > "$OBJ/.branch"
echo "O=: $OBJ"

# 版の文字（/proc/version）に組んだ機械の名前が入らないよう、組んだ人と機械を固定する（2026-11-23、
# それまで組んだ機械のアカウントと名前が入って公開されていた）。呼ぶ側が値を渡せばそれを使う（sha の突き合わせ用）
export KBUILD_BUILD_USER=${KBUILD_BUILD_USER:-pomera} KBUILD_BUILD_HOST=${KBUILD_BUILD_HOST:-kbuild}
# 設定。版の印（LV）は CONFIG_LOCALVERSION でなく make の LOCALVERSION= で渡す（.config を版ごとに
# 変えない）。LOCALVERSION を渡すと、git の木でも版の名前に「+」は付かない（scripts/setlocalversion）
M=(make -C "$GIT" O="$OBJ" ARCH=arm CROSS_COMPILE=arm-linux-gnueabihf- LOCALVERSION="$LV")
# ccache は /usr/lib/ccache の symlink を PATH の前に置いて使う。設定は ~/.config/ccache/ccache.conf
#（cache_dir=/var/tmp/kbuild/ccache・max_size=5G・base_dir=/var/tmp/kbuild/stable・hash_dir=false）。
# DEBUG_INFO=y だと ccache は作業場所（O=）を hash に入れるので、後の 2 つが無いと obj-a と obj-b の間で効かない
if [ -x /usr/lib/ccache/arm-linux-gnueabihf-gcc ]; then
	export PATH=/usr/lib/ccache:$PATH
	echo "ccache を使う（$(ccache -k cache_dir)）"
fi
cp configs/dm250.config "$OBJ/.config"
"$GIT/scripts/config" --file "$OBJ/.config" --set-str LOCALVERSION "" --disable LOCALVERSION_AUTO
"${M[@]}" olddefconfig > /dev/null
"$GIT/scripts/diffconfig" configs/dm250.config "$OBJ/.config" > "$TOP/config-new-$NAME.txt" || true
echo "設定の差（configs/dm250.config からの）: $TOP/config-new-$NAME.txt"

# 4. 組み立て
{
	date
	echo "branch $BR $(git -C "$GIT" rev-parse HEAD)  O=$OBJ"
	"${M[@]}" -j"$(nproc)" zImage modules && echo EXIT=0 || echo "EXIT=$?"
} > "$LOG" 2>&1
tail -1 "$LOG"
grep -q '^EXIT=0$' "$LOG"
R=$(cat "$OBJ/include/config/kernel.release")
# 版の文字に組んだ機械の名前が入っていない事を確かめる（2026-11-23。それまで公開の版に組んだ機械の名前が入っていた）
CB=$(sed -n "s/^#define LINUX_COMPILE_BY[[:space:]]*\"\(.*\)\"/\1/p" "$OBJ/include/generated/compile.h")
CH=$(sed -n "s/^#define LINUX_COMPILE_HOST[[:space:]]*\"\(.*\)\"/\1/p" "$OBJ/include/generated/compile.h")
if [ "$CB@$CH" != "$KBUILD_BUILD_USER@$KBUILD_BUILD_HOST" ]; then
	echo "版の文字の組んだ人・機械が想定と違う: $CB@$CH（期待 $KBUILD_BUILD_USER@$KBUILD_BUILD_HOST）" >&2; exit 1
fi
echo "版の名前: $R"

if [ -n "$KEEP" ]; then
	mkdir -p "$KB/obj-keep"
	rm -rf "$KB/obj-keep/$KEEP"
	cp -a "$OBJ" "$KB/obj-keep/$KEEP"
	echo "残した: $KB/obj-keep/$KEEP（branch $BR）"
fi
if [ $PACK = 1 ]; then
	bash "$TOP/../kernel_pack.sh" "$R" --src "$GIT" --obj "$OBJ"
fi
