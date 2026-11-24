# Changelog

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions are those of the meta package `pomera-kernel` (the release date `YYYY.MM.DD`, with `.1` for a second release in the same week). The Japanese CHANGELOG.md is the authoritative one.

**Test release: no warranty, use at your own risk.** Unofficial, with nothing to do with King Jim or with the DM250 Debian 13 image published by ichinomoto at ekesete.net (https://www.ekesete.net/log/?p=9565) ("the image" below). Make a copy of the SD card before installing (see Disclaimer in the README).

## [2026.11.24.1] - 2026-11-24

Upgrade with `sudo apt update && sudo apt upgrade` (with `apt-get`, use `dist-upgrade` or `full-upgrade`). The next boot tries the new kernel once and confirms it if healthy.

### Changed

- Follow Linux 6.18 LTS from 6.18.64 to 6.18.65 (`pomera-kernel-6.18.65-wk20261124b`), including fixes to IPv4 fragment reassembly, mm, Bluetooth, Wi-Fi (mac80211, cfg80211), USB audio (UAC2 mixers) and ARM (e.g. CVE-2026-99709).
- Power-off: 6.18.65 moves the RK818 power-off write to the last power-off step. The kernel follows that and also keeps the write in the earlier step that has switched the DM250 off so far (DM250 patch 0037).
- `pomera-kernel-tools` 0.9: a way to install it while building an SD image (`pomera-kernel image-init`). On the device it works as 0.8.
- The user and host names of the kernel build are fixed (`/proc/version` shows `pomera@kbuild`).
- U-Boot (`dm250.8`) is the same as in the previous release.

## [2026.11.18] - 2026-11-18

Upgrade with `sudo apt update && sudo apt upgrade` (with `apt-get`, use `dist-upgrade` or `full-upgrade`). The next boot tries the new kernel once and confirms it if healthy.

### Changed

- Follow Linux 6.18 LTS from 6.18.63 to 6.18.64 (`pomera-kernel-6.18.64-wk20261118`), including fixes to 32-bit mm (truncation beyond 4 GiB, an overflow in writeback), FAT, IPv6, Bluetooth L2CAP and Wi-Fi (cfg80211, mac80211, brcmfmac) (e.g. CVE-2026-99272, CVE-2026-99275, which matter only when mounting SMB shares).
- New DM250 patches 0025 to 0036: findings of a review by Claude Mythos, a model for security work, checked on the device and fixed (see Added and Fixed below).
- The README now has "Charging a nearly empty battery" (a known issue).
- U-Boot (`dm250.8`) and `pomera-kernel-tools` (0.8) are the same as in the previous release.

### Added

- Charging pauses while the battery is hot (about 55 C or more) and goes on by itself when it cools, using the battery's temperature sensor (shown as not charging, overheat).
- With the battery nearly empty (on battery below about 3.55 V, or below 3.7 V after it once fell below 3.5 V, or while below 3.5 V), the Pomera does not sleep when the lid is closed, so that it does not run the battery flat while asleep and the normal shutdown on an empty battery can run. Hibernation still works.

### Fixed

- The system could be reset by the watchdog while writing the hibernation image, losing it (on a boot where the watchdog runs, such as the boot after trying a new kernel).
- After the battery recovered and the forced power-off was cancelled, the battery was no longer watched.
- A key held at the moment a keyboard read failed could stay pressed and repeat.
- With a debug setting (`debug_key_state`) on, typed keys went to the kernel log (off by default; the setting is removed).
- If the charger driver failed partway through starting, the USB input limit was left at 2 A, also on a PC's USB port.
- Unbinding the charger driver (root only) could use freed memory.
- A battery node with a charge voltage below 4.2 V was still charged at 4.2 V (the DM250 uses 4.2 V, so no effect). Checks for abnormal calibration and test values were added.

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
