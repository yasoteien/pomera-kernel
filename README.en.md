# pomera-kernel (Linux kernel for the Pomera DM250)

A Linux kernel for running Debian on the King Jim Pomera DM250 (Japanese model). It is mainline Linux 6.18 longterm with patches for the DM250, shipped as Debian packages (.deb) from an apt repository and rebuilt once a week with the latest stable updates. The Japanese README is the authoritative one.

- Only the Japanese DM250. The US model (DM250US) and other models are refused by the package.
- For Debian booted from the SD card. The internal eMMC is not written.
- It is a test release: read the Disclaimer below before installing.

## Disclaimer

- This is a test release. There is no warranty that it works, of its quality, or that it fits any purpose (no warranty, as in sections 11 and 12 of the GPL). Use it at your own risk.
- We (yasoteien) are not responsible for any fault or loss of the Pomera, the SD card or data that comes from using it.
- It is unofficial and has nothing to do with King Jim or with the distributor of the Debian image for the DM250. Please do not contact them about it.
- Make a copy (image) of the SD card before installing.
- To go back: `sudo pomera-kernel rollback` (back to the previous set). If it no longer starts, take out the SD card and the Pomera starts its own software; restore the SD card from the copy you made.

## Install

**FDTP (https://github.com/yasoteien/fdtp) makes this easier.** FDTP's `./configure` (`sudo fdtp-pomera-setup` for the .deb version) can also install pomera-kernel, and sets up Wi-Fi, the internal memory (reading and writing Pomera documents from Linux), charging through a PD hub, the clock drift fix, HEIC photo viewing and more at the same time. It also cleans up settings that are no longer needed after the kernel changes.

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

1. The Pomera first starts with the current kernel.
2. During that start it switches to pomera-kernel (kexec); the screen goes dark once and comes back.
3. If it starts normally (systemd reaches running), it is confirmed by itself about 2 minutes later and written to the kernel area of the SD card; from then on it starts with the new kernel.
4. If it does not start properly, the watchdog brings back the current kernel about 5 minutes later, with no one at the keys.
5. To go back after it is confirmed: `sudo pomera-kernel rollback` (the previous kernel from the next boot).

The workarounds for the current kernel (the one that comes with the Debian image for the DM250), such as the Wi-Fi PIO, the watchdog and nftables, were put in by FDTP. Without FDTP there is nothing to remove.

## Upgrade

Each weekly release comes with:

```sh
sudo apt update && sudo apt upgrade
```

A new kernel comes as a package with a new name (`pomera-kernel-<version>`). `apt-get upgrade` does not install new packages, so the meta package `pomera-kernel` stays "kept back". With `apt-get`, use `sudo apt-get dist-upgrade` (or `full-upgrade`). The next boot after the upgrade tries the new kernel once before confirming it, as on installation.

## Roll back

```sh
sudo pomera-kernel status     # current and previous pair
sudo pomera-kernel rollback   # back to the previous pair from the next boot (run again to undo)
```

`apt autoremove` removes old versions but keeps the current and the previous one.

## Contents

| Path | What |
|---|---|
| `patches/` | patches on mainline and their order (`series`) |
| `configs/` | kernel configuration |
| `scripts/` | script that fetches the stable release, applies the patches and builds |
| `deb/` | script that builds the .deb, the tool for trying, confirming and rolling back (`pomera-kernel`), and the script that unloads and reloads the wireless modules around hibernation |
| `dts/` | device tree: the DTS of the Debian image for the DM250 (`rk3128-pomera-dm250-image.dts`), the scripts that fix it (`mk_leds.sh`, `mk_panel.sh`) and the script that builds the RSCE for the SD card (`mk_rsce.sh`) |
| `apt/` | public key of the apt signature |
| `pomera-kernel-setup.sh` | script that adds the key and the apt source and installs, without FDTP |
| `CHANGELOG.en.md` | changes by release |

## Origin of the device tree

`dts/rk3128-pomera-dm250-image.dts` is the DTB from the RSCE area of the SD card of the Debian 13 image for the DM250 (https://www.ekesete.net/log/?p=9565), turned back into a DTS. That DTB comes from `pomera-dm250.dts` in jcs's https://github.com/jcs/linux-dm250 and mainline Linux's `rk3128.dtsi` (Rockchip). It is kept as it is; the fixes are applied by scripts.

- `mk_leds.sh`: wires the interrupt of the RK818 (power IC) as on the device and adds the charging LED.
- `mk_panel.sh`: corrects the panel size to 7.0 inches (154 × 86 mm).
- `mk_rsce.sh`: applies the two and builds the RSCE that goes into the package, checking the sha256 of each step.

## License

- Kernel and patches: GPL-2.0 (changes to mainline files keep the mainline headers; our new files are GPL-2.0-only). See `LICENSE`.
- Scripts and tools (`scripts/`, `deb/`, the scripts in `dts/`): GPL-2.0-or-later.
- Device tree (the DTS in `dts/`): GPL-2.0-or-later (as mainline `rk3128.dtsi`).

Source: https://github.com/yasoteien/pomera-kernel ; apt repository: https://yasoteien.github.io/pomera-kernel-apt/.
