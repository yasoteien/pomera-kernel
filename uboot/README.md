# U-Boot for the KING JIM Pomera DM250

## 免責

- これは試験版です。動くこと・品質・目的に合うことは保証しません（GPL の第 11・12 項のとおり無保証です）。使うのは自己責任でお願いします。
- これを使って、ポメラの本体・SD カード・データに不具合や損失が起きても、私たち（yasoteien）は責任を負いません。
- キングジム、および DM250 用 Debian イメージの配布元とは関係のない、非公式の物です。両者に問い合わせないでください。
- 入れる前に、SD カードの写し（イメージ）を取ってください。
- 戻し方: `sudo pomera-kernel rollback`（1 つ前の組に戻す。U-Boot も一緒に戻ります）。起動しなくなった時は、SD カードを抜けば本体の純正のソフトで起動します。SD カードは、取っておいた写しで戻してください。

## Disclaimer

- This is a test release. There is no warranty that it works, of its quality, or that it fits any purpose (no warranty, as in sections 11 and 12 of the GPL). Use it at your own risk.
- We (yasoteien) are not responsible for any fault or loss of the Pomera, the SD card or data that comes from using it.
- It is unofficial and has nothing to do with King Jim or with the distributor of the Debian image for the DM250. Please do not contact them about it.
- Make a copy (image) of the SD card before installing.
- To go back: `sudo pomera-kernel rollback` (back to the previous set; U-Boot goes back with it). If it no longer starts, take out the SD card and the Pomera starts its own software; restore the SD card from the copy you made.

## What this is

The U-Boot that the pomera-kernel packages write to the SD card (at 8 MiB,
four Rockchip LOADER copies) together with the kernel and its device tree,
as U-Boot v2026.07 plus the patches here.

- `patches/`: `git format-patch v2026.07..` of the branch we build. Apply in order.
- `build.sh`: fetches v2026.07 (checked by its commit id), applies the
  patches, builds and packs `uboot.img`. With the same compiler the result
  is the same, byte for byte, as the `uboot.img` in the package
  (`uboot.img.sha256`).

## What it does

- `sd` (the default boot command): reads a kernel (KRNL) and a resource
  image (RSCE, the kernel device tree) from the SD card and boots it, with
  `root=/dev/mmcblk1p2`. If partition 3 is a swap with a hibernation image,
  it adds `resume=` so the kernel resumes.
- Which KRNL/RSCE pair: the pomera-kernel tools keep up to two pairs (slot A
  at 32/44 MiB, slot B at 48/60 MiB) and a small table at 26 and 27 MiB.
  U-Boot uses the valid table with the higher number; if that pair does not
  load, the other table's pair; then the pair at 12/24 MiB, where the
  Debian image for the DM250 keeps its own. So an update is switched by one
  512-byte write, and a power cut at any moment leaves the old pair or the
  new one.
- `emmc`: loads the built-in firmware's U-Boot from the eMMC, makes it look
  at the eMMC before the SD card, turns the display off and jumps to it. To
  use it, stop the 1-second countdown with a key and type `emmc`. Removing
  the SD card also starts the built-in firmware.
- The Bluetooth address of the board is read from the eMMC and put into the
  kernel device tree.
- A logo is shown during the countdown.

## Where the parts come from

| Patches | Author | License |
|---|---|---|
| 0001–0017 | Alex Bee: RK3128 support (clock, DRAM, USB PHY, ...) | GPL-2.0+ (as U-Boot) |
| 0018–0033 | joshua stein: the Pomera DM250 port (LVDS, VOP, keyboard, RK818, loaderimage), from github.com/jcs/u-boot branch `pomera-dm250`, rebased onto v2026.07 by us | GPL-2.0+ |
| 0034– | yasoteien: the DM250 board code and fixes | GPL-2.0+ |

- The board code (`board/kingjim/pomera_dm250/`) was reconstructed from the
  machine code of the U-Boot in ekesete's Debian image for the DM250
  (www.ekesete.net), so that it behaves the same; then we fixed the logo being
  cut by the countdown line, moved the countdown below the logo, and added
  the slot table.
- The device tree (`rk3128-pomera-dm250.dts`) was decompiled from the DTB in
  that U-Boot (which comes from the Linux `rk3128.dtsi`, Rockchip 2017, and
  jcs's DM250 device tree). We fixed three mistakes in it: the LVDS data
  mapping (jeida-24 to jeida-18), the backlight PWM polarity, and the panel
  size (223×125 mm to 154×86 mm). GPL-2.0+, as `rk3128.dtsi`.
- The logo (`logo-pom.bmp`, a Pomeranian) was generated with Google Gemini
  (Nano Banana) as instructed by yasoteien, and reduced to 32 colours with
  `mklogo.py`. GPL-2.0-or-later, like U-Boot.

joshua stein's patches have no Signed-off-by; they are as he published them.
Our patches carry `Signed-off-by: yasoteien <263659156+yasoteien@users.noreply.github.com>`
(a GitHub address that does not receive mail; please use the GitHub issues).
