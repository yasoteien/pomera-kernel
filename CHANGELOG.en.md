# Changelog

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions are those of the meta package `pomera-kernel` (the release date `YYYY.MM.DD`, with `.1` for a second release in the same week). The Japanese CHANGELOG.md is the authoritative one.

**Test release: no warranty, use at your own risk.** Unofficial, with nothing to do with King Jim or with the DM250 Debian 13 image published by ichinomoto at ekesete.net (https://www.ekesete.net/log/?p=9565) ("the image" below). Make a copy of the SD card before installing (see Disclaimer in the README).

## [2026.11.04.3] - 2026-11-04

First release.

Upgrade with `sudo apt update && sudo apt upgrade` (with `apt-get`, use `dist-upgrade` or `full-upgrade`; `apt-get upgrade` does not install the new kernel).

### Added

- Kernel built from mainline Linux 6.18.60 (longterm) with the DM250 patches 0001 to 0024 (`pomera-kernel-6.18.60-5jm`).
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
