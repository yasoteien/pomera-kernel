# pomera-kernel (Linux kernel for the Pomera DM250)

A Linux kernel for running Debian on the King Jim Pomera DM250 (Japanese model). It is mainline Linux 6.18 longterm with patches for the DM250, shipped as Debian packages (.deb) from an apt repository and rebuilt once a week with the latest stable updates. The Japanese README is the authoritative one.

- Only the Japanese DM250. The US model (DM250US) and other models are refused by the package.
- For Debian booted from the SD card. The internal eMMC is not written.
- Use at your own risk, and make a copy of the SD card first.

## Install

1. Install the signing key (`apt/pomera-kernel.asc`, fingerprint `E9B3 07FA F435 923A 22E2 A710 9110 B311 6ECA 5467`).

   ```sh
   sudo install -m 0644 pomera-kernel.asc /usr/share/keyrings/pomera-kernel.asc
   ```

2. Add the repository.

   ```sh
   sudo tee /etc/apt/sources.list.d/pomera-kernel.sources <<'EOF'
   Types: deb
   URIs: https://yasoteien.github.io/pomera-kernel-apt/
   Suites: stable
   Components: main
   Architectures: armhf
   Signed-By: /usr/share/keyrings/pomera-kernel.asc
   EOF
   ```

3. Install.

   ```sh
   sudo apt update
   sudo apt install pomera-kernel
   ```

On the next boot the new kernel is tried once (kexec). If the boot is healthy (systemd reaches running), it is written to the kernel area of the SD card at once. If it does not come up, the watchdog brings back the previous kernel in about five minutes, with no one at the keys.

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
| `dts/` | device tree: the author's DTS (`rk3128-pomera-dm250-author.dts`), the scripts that fix it (`mk_leds.sh`, `mk_panel.sh`) and the script that builds the RSCE for the SD card (`mk_rsce.sh`) |
| `apt/` | public key of the apt signature |
| `CHANGELOG.en.md` | changes by release |

## Origin of the device tree

`dts/rk3128-pomera-dm250-author.dts` is the DTB from the RSCE area of the SD card of the Debian 11 image for the DM250 (https://www.ekesete.net/log/?p=9565), turned back into a DTS. That DTB comes from `pomera-dm250.dts` in jcs's https://github.com/jcs/linux-dm250 and mainline Linux's `rk3128.dtsi` (Rockchip). It is kept as it is; the fixes are applied by scripts.

- `mk_leds.sh`: wires the interrupt of the RK818 (power IC) as on the device and adds the charging LED.
- `mk_panel.sh`: corrects the panel size to 7.0 inches (154 × 86 mm).
- `mk_rsce.sh`: applies the two and builds the RSCE that goes into the package, checking the sha256 of each step.

## License

- Kernel and patches: GPL-2.0 (changes to mainline files keep the mainline headers; our new files are GPL-2.0-only). See `LICENSE`.
- Scripts and tools (`scripts/`, `deb/`, the scripts in `dts/`): GPL-2.0-or-later.
- Device tree (the DTS in `dts/`): GPL-2.0-or-later (as mainline `rk3128.dtsi`).

Source: https://github.com/yasoteien/pomera-kernel ; apt repository: https://yasoteien.github.io/pomera-kernel-apt/.
