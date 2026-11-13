# Changelog

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions are those of the meta package `pomera-kernel` (the release date `YYYY.MM.DD`, with `.1` for a second release in the same week). The Japanese CHANGELOG.md is the authoritative one.

**Test release: no warranty, use at your own risk.** Unofficial, with nothing to do with King Jim or with the DM250 Debian 13 image published by ichinomoto at ekesete.net (https://www.ekesete.net/log/?p=9565) ("the image" below). Make a copy of the SD card before installing (see Disclaimer in the README).

## [2026.11.13] - 2026-11-13

Upgrade with `sudo apt update && sudo apt upgrade` (with `apt-get`, use `dist-upgrade` or `full-upgrade`). The next boot tries the new kernel once and confirms it if healthy.

### Changed

- Follow Linux 6.18 LTS from 6.18.62 to 6.18.63 (`pomera-kernel-6.18.63-wk20261113`), including fixes to ARM cacheinfo, ext4 and FAT, TCP and IPv6, and Bluetooth L2CAP (e.g. CVE-2026-99288).
- `pomera-kernel-tools` is now 0.8.
- The README now says what this follows (kernel.org Linux 6.18 LTS; not the image's kernel nor Debian 13's 6.12 kernel) and explains why the 5 V USB output (`vbus_ctl` in the image's 20261113 release) is not included.
- The DM250 patches (0001 to 0024) and U-Boot (`dm250.8`) are the same as in the previous release.

### Fixed

- A device plugged into a USB hub later (a mouse, USB Ethernet, a phone, an audio interface, etc.) was sometimes not recognized: when nothing is connected, the hub goes into power saving and the DM250's USB cannot wake it. `pomera-kernel-tools` 0.8 keeps hubs out of power saving (while a hub is connected, interrupts increase a little to watch the devices behind it; the hub is powered from outside, so the effect on the battery should be small).

## [2026.11.07] - 2026-11-07

Upgrade with `sudo apt update && sudo apt upgrade` (with `apt-get`, use `dist-upgrade` or `full-upgrade`). The next boot tries the new kernel once and confirms it if healthy.

### Changed

- Follow Linux 6.18 LTS from 6.18.60 to 6.18.62 (`pomera-kernel-6.18.62-wk20261107`), including fixes to SD card (dw_mmc) DMA stopping, Bluetooth, ext4 and FAT, TCP and IPv6 (e.g. CVE-2026-99270, CVE-2026-99076).
- The DM250 patches (0001 to 0024), U-Boot (`dm250.8`) and `pomera-kernel-tools` (0.7) are the same as in the previous release.

## [2026.11.04.3] - 2026-11-04

First release.

Upgrade with `sudo apt update && sudo apt upgrade` (with `apt-get`, use `dist-upgrade` or `full-upgrade`; `apt-get upgrade` does not install the new kernel).

### Added

- Kernel built from Linux 6.18.60 (LTS) with the DM250 patches 0001 to 0024 (`pomera-kernel-6.18.60-5jm`).
- Display (RK3128 LVDS), keyboard, charging (RK818), USB charger detection, suspend and hibernation.
- Trial boot tool (`pomera-kernel`): the next boot after installation tries the kernel once and confirms it if healthy; if it does not come up, the watchdog brings back the previous kernel within about 5 minutes. `rollback` returns to the previous set (kernel and U-Boot).
- U-Boot on the SD card (`dm250.8`, mainline U-Boot v2026.07 with patches), written together with the kernel: written at confirmation and taken back by `rollback`.
  - A Pomeranian on the boot screen; a 3-second countdown.
  - The kernel and device tree are written alternately to two places (slot A and B), and a small table (at 26 and 27 MiB) selects which one boots, so a power cut while writing leaves the previous set or the new one. The image's kernel (at 12 and 24 MiB) is not changed.
  - Four copies of U-Boot; the first one is written last. If the first one is broken, the Pomera starts from the second (tested).
  - The `emmc` command (stop the countdown with a key and type it) starts the built-in (eMMC) firmware.
  - Resumes from a hibernation image when there is one (adds `resume=`).
- Script that unloads and reloads the Wi-Fi and Bluetooth modules around hibernation.
- Setting that keeps the current and the previous version when `apt autoremove` removes old ones.
- Device tree with the panel size corrected to 7.0 inches (154 × 86 mm).

### Fixed

Compared with the image's kernel and U-Boot:

- The Pomera hangs under load on the SD card and Wi-Fi at the same time (power management of the PL330 DMA).
- On a PD hub it shows "charging" while the battery discharges (USB charger detection and RK818 charge settings).
- The charge LED does not light.
- The RTC alarm interrupt does not arrive (wiring of the RK818 interrupt).
- U-Boot: the boot logo is split by black horizontal bands.
- U-Boot: the LVDS format (jeida-24 to jeida-18) and the backlight PWM polarity in its device tree.
