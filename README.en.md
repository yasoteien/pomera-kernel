# pomera-kernel (Linux kernel for the Pomera DM250)

> **This branch (`linux-7.3`) is under development. General users should not use it.** If you can build kernels yourself, you can try it at your own risk (no warranty; see the disclaimer below): as of Linux 7.3.5 (7.3.5-v73d) it passes the same tests as the 6.18 line (trial boot, confirm, hibernate, rollback, SD and Wi-Fi load together, suspend, poweroff, keys, low-battery shutdown). No built .deb is published; build it yourself with `scripts/stable.sh` and the rest.
> It carries the move to Linux 7.3, the next main line. The patches are `v73-00xx` (moved from 6.18, same numbers) and `v73-1xxx` (added for 7.3). `configs/dm250.config` is the 7.3 configuration and enables MGLRU (`CONFIG_LRU_GEN`).
> - Linux 7.3 is expected to be the 2026 LTS (not designated yet), and Debian 14 (forky) is expected to use it. When Debian 14 is released, this branch will be merged into main and apt `stable` will ship 7.3. 7.3 also runs on Debian 13.
> - The 6.18 line will no longer be maintained from that day (its last state stays as a tag).
> - Until then the released line is 6.18 on main, and apt keeps installing 6.18.

A Linux kernel for running Debian on the King Jim Pomera DM250 (Japanese model). It is Linux 6.18 LTS (kernel.org longterm) with patches for the DM250, shipped as Debian packages (.deb) from an apt repository and rebuilt once a week with the latest Linux 6.18 LTS release.

- It follows kernel.org Linux 6.18 LTS. It does not follow the kernel updates of ichinomoto's image (it is built independently of the image's kernel).
- It is also separate from the kernel Debian 13 ships (the 6.12 series). The rest of Debian 13 keeps being updated by Debian's apt as before. The Japanese README is the authoritative one.

- Only the Japanese DM250. The US model (DM250US) and other models are refused by the package.
- For Debian booted from the SD card. The internal eMMC is not written.
- It is a test release: read the Disclaimer below before installing.

## Disclaimer

- This is a test release. There is no warranty that it works, of its quality, or that it fits any purpose (no warranty, as in sections 11 and 12 of the GPL). Use it at your own risk.
- We (yasoteien) are not responsible for any fault or loss of the Pomera, the SD card or data that comes from using it.
- It is unofficial and has nothing to do with King Jim or with the DM250 Debian 13 image published by ichinomoto at ekesete.net (https://www.ekesete.net/log/?p=9565) ("the image" below). Please do not contact them about it.
- Make a copy (image) of the SD card before installing.
- To go back: `sudo pomera-kernel rollback` (back to the previous set; U-Boot goes back with it). If it no longer starts, take out the SD card and the Pomera starts its own software; restore the SD card from the copy you made.

## Install

**FDTP (https://github.com/yasoteien/fdtp) makes this easier.** FDTP's `./configure` (`sudo fdtp-pomera-setup` for the .deb version) can also install pomera-kernel, and sets up Wi-Fi, the internal memory (reading and writing Pomera documents from Linux), charging through a PD hub, the clock drift fix, HEIC photo viewing and more at the same time. It also cleans up settings that are no longer needed after the kernel changes.

> **About the network while installing (only if you can):** with the kernel that came with the image, fetching something large over Wi-Fi at full speed can freeze the Pomera (a bug in the DMA shared by the SD card and Wi-Fi; pomera-kernel fixes it). The kernel .deb is about 17 MB, so either of these is safer:
>
> - **Use a wired USB-LAN adapter or USB tethering from a phone.** USB traffic does not go through that DMA. The Pomera's Linux has drivers for USB-LAN chips such as Realtek RTL8152, RTL8153 and RTL8156, ASIX AX88179 and AX88179A, and Microchip LAN7800, and for iPhone (install `usbmuxd`) and Android USB tethering. The Pomera does not supply 5 V on its USB port, so connect through an externally powered USB hub (PD hubs with HDMI may not be detected). When connected, it is used in preference to Wi-Fi.
> - **Slow down apt's download.** Run step 3's `apt install` as `sudo apt -o Acquire::https::Dl-Limit=200 install pomera-kernel`; the download is limited to about 200 KB/s (it takes a minute or two longer).

Without FDTP, the following commands install it (on the Debian SD card).

1. Fetch the public key and check that its fingerprint is `E9B3 07FA F435 923A 22E2 A710 9110 B311 6ECA 5467`.

   ```sh
   wget -O pomera-kernel.asc https://yasoteien.github.io/pomera-kernel-apt/pomera-kernel.asc
   gpg --show-keys pomera-kernel.asc
   ```

2. Install the key and the apt source.

   ```sh
   sudo install -m 0644 pomera-kernel.asc /usr/share/keyrings/pomera-kernel.asc
   sudo tee /etc/apt/sources.list.d/pomera-kernel.sources <<'EOF'
   Types: deb
   URIs: https://yasoteien.github.io/pomera-kernel-apt/
   Suites: stable
   Components: main
   Architectures: armhf
   Signed-By: /usr/share/keyrings/pomera-kernel.asc
   EOF
   ```

3. Install and reboot.

   ```sh
   sudo apt update && sudo apt install pomera-kernel
   sudo reboot
   ```

The script `pomera-kernel-setup.sh` does the same in one go (at the top of this tree, and at https://yasoteien.github.io/pomera-kernel-apt/pomera-kernel-setup.sh); it also checks the key fingerprint. **Read it before running it** (running it unread, as with `curl … | sh`, is not recommended).

```sh
wget https://yasoteien.github.io/pomera-kernel-apt/pomera-kernel-setup.sh
less pomera-kernel-setup.sh
sudo sh pomera-kernel-setup.sh          # shows the FDTP note and asks first (--yes skips the question); to remove: remove
```

FDTP users can also install it from FDTP's `./configure` (`sudo fdtp-pomera-setup` for the .deb version).

After the reboot:

1. The Pomera first starts with the current kernel (on the first install, the image's kernel).
2. A login prompt appears once; do not log in, wait about a minute. The screen scrolls as pomera-kernel (test release) starts, and the login prompt appears again (a login at the first prompt is cut off by the switch).
3. If it starts normally (systemd reaches running), it is confirmed by itself about 2 minutes later: the kernel, its device tree and U-Boot are written to the SD card as a set, and from then on the Pomera starts with the new set (kernel and U-Boot).
   - The kernel and device tree go to the unused one of two places on the card (slot A or B). A small table tells U-Boot which one to boot, so a power cut while writing leaves either the previous set or the new one.
   - The image's kernel (at 12 MiB and 24 MiB on the card) is not changed.
   - The first time U-Boot is written, a copy of the original U-Boot and how to restore it (`RESTORE.txt`) are put in `pomera-kernel/` on the first (FAT) partition of the card.
4. If it does not start properly, the watchdog brings back the current kernel (on the first install, the image's kernel) within about 5 minutes (U-Boot is not rewritten), with no one at the keys.
5. To go back after it is confirmed: `sudo pomera-kernel rollback` (the previous set from the next boot; kernel and U-Boot go back together).

U-Boot cannot be tried in the trial boot, so a new U-Boot first runs at the boot after confirmation. If the Pomera then no longer starts, take out the SD card and it starts its own software; repair the card on a PC with `pomera-kernel/RESTORE.txt` (write the original U-Boot back) or from the copy you made.

The workarounds for the image's kernel, such as the Wi-Fi PIO, the watchdog and nftables, were put in by FDTP. Without FDTP there is nothing to remove.

## Upgrade

Each weekly release comes with:

```sh
sudo apt update && sudo apt upgrade
```

A new kernel comes as a package with a new name (`pomera-kernel-<version>`). `apt-get upgrade` does not install new packages, so the meta package `pomera-kernel` stays "kept back". With `apt-get`, use `sudo apt-get dist-upgrade` (or `full-upgrade`). The next boot after the upgrade tries the new kernel once before confirming it, as on installation.

## Roll back

```sh
sudo pomera-kernel status     # U-Boot, current set, set of the next boot, previous set
sudo pomera-kernel rollback   # back to the previous set (kernel and U-Boot) from the next boot (run again to undo)
```

`apt autoremove` removes old versions but keeps the current and the previous one.

## About USB 5 V output (VBUS)

The 20261113 release of ichinomoto's image added `sudo vbus_ctl on`, which supplies 5 V from the Pomera's USB-C port to the connected device (using the boost converter and OTG_SWITCH of the RK818 power IC). pomera-kernel does not include this feature for now, for these reasons:

- **It can collide with an external power source.** While the output is on, the Pomera itself drives USB 5 V (VBUS). If a charger, a PC or a powered hub is connected afterwards, the power IC cannot tell the two apart, and two 5 V sources may fight and damage the device. The image's download page gives the same warning. The software stops the output in several cases (a time-limited lease, stop on unplug), but this is not electrical protection.
- **It does not fit charging through a powered hub.** pomera-kernel is mainly tested with a powered hub (a hub with PD charging) that charges the Pomera while USB devices are in use. That setup does not need 5 V output, and plugging power into the hub while the output is on causes exactly the collision above.
- **There is no software current monitoring.** What happens when a device draws too much current is left to the power IC's own protection (we have not tested how it behaves).

Connect devices that need power (USB Ethernet, phones, etc.) through a powered hub. We will reconsider this if a reliable way to stop the output before external power is connected is confirmed.

The problem where devices plugged into a hub later are not recognized is unrelated to this 5 V output (the Pomera's USB cannot wake a hub that has gone into power saving). pomera-kernel-tools 0.8 fixes it by keeping hubs awake.

## Charging a nearly empty battery

When the battery is nearly empty (around 3.4 V), charge it with the supplied AC adapter (or a powered hub).

On a weak supply such as a PC's USB port, the Pomera can use more than the supply gives, and the battery keeps going down. When it reaches the minimum, pomera-kernel shuts the Pomera down in the normal way, but with power connected the Pomera starts again at once, and it may keep shutting down and starting again. The battery can go further down each time, until the power IC's own protection (about 2.7 V) cuts the power. There is not yet a way (in U-Boot) to wait for the battery to charge before starting.

While the battery is below about 3.5 V, the Pomera does not sleep when the lid is closed, even on power, so that it does not run the battery flat while asleep.

## Contents

| Path | What |
|---|---|
| `patches/` | patches on mainline and their order (`series`) |
| `configs/` | kernel configuration |
| `scripts/` | script that fetches the stable release, applies the patches and builds |
| `deb/` | script that builds the .deb, the tool for trying, confirming and rolling back (`pomera-kernel`), and the script that unloads and reloads the wireless modules around hibernation |
| `dts/` | device tree: the DTS of the image (`rk3128-pomera-dm250-image.dts`), the scripts that fix it (`mk_leds.sh`, `mk_panel.sh`) and the script that builds the RSCE for the SD card (`mk_rsce.sh`) |
| `uboot/` | source of the U-Boot on the SD card (patches for mainline U-Boot v2026.07, build script, sha256 of the result) |
| `apt/` | public key of the apt signature |
| `pomera-kernel-setup.sh` | script that adds the key and the apt source and installs, without FDTP |
| `CHANGELOG.en.md` | changes by release |

## Origin of the device tree

`dts/rk3128-pomera-dm250-image.dts` is the DTB from the RSCE area of the SD card of the image, turned back into a DTS. That DTB comes from `pomera-dm250.dts` in jcs's https://github.com/jcs/linux-dm250 and mainline Linux's `rk3128.dtsi` (Rockchip). It is kept as it is; the fixes are applied by scripts.

- `mk_leds.sh`: wires the interrupt of the RK818 (power IC) as on the device and adds the charging LED.
- `mk_panel.sh`: corrects the panel size to 7.0 inches (154 × 86 mm).
- `mk_rsce.sh`: applies the two and builds the RSCE that goes into the package, checking the sha256 of each step.

## License

- Kernel and patches: GPL-2.0 (changes to mainline files keep the mainline headers; our new files are GPL-2.0-only). See `LICENSE`.
- Scripts and tools (`scripts/`, `deb/`, the scripts in `dts/`): GPL-2.0-or-later.
- Device tree (the DTS in `dts/`): GPL-2.0-or-later (as mainline `rk3128.dtsi`).
- U-Boot and its patches (`uboot/`): GPL-2.0+ (as mainline U-Boot); origins in `uboot/README.md`.

Source: https://github.com/yasoteien/pomera-kernel ; apt repository: https://yasoteien.github.io/pomera-kernel-apt/.
