# Changelog

This file follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions are those of the meta package `pomera-kernel` (the release date `YYYY.MM.DD`, with `.1` for a second release in the same week). The Japanese CHANGELOG.md is the authoritative one.

**Test release: no warranty, use at your own risk.** Unofficial, with nothing to do with King Jim or the distributor of the Debian image for the DM250. Make a copy of the SD card before installing (see Disclaimer in the README).

## [2026.11.04.3] - 2026-11-04

First release (draft).

Upgrade with `sudo apt update && sudo apt upgrade` (with `apt-get`, use `dist-upgrade` or `full-upgrade`; `apt-get upgrade` does not install the new kernel).

### Added

- Kernel built from mainline Linux 6.18.60 (longterm) with the DM250 patches 0001 to 0024 (`pomera-kernel-6.18.60-5jm`).
- Display (RK3128 LVDS), keyboard, charging (RK818), USB charger detection, suspend and hibernation.
- Trial boot tool (`pomera-kernel`): the next boot after installation tries the kernel once and confirms it if healthy; if it does not come up, the watchdog brings back the previous kernel. `rollback` returns to the previous pair.
- Script that unloads and reloads the Wi-Fi and Bluetooth modules around hibernation.
- Setting that keeps the current and the previous version when `apt autoremove` removes old ones.
- Device tree with the panel size corrected to 7.0 inches (154 × 86 mm).

### Fixed

- Bluetooth no longer works after resuming from hibernation.
- Some clock settings are not restored after resuming from hibernation.
- USB charging may accept a current above the set limit.
- After a full charge on a powered hub, the battery is shown as discharging, the charge LEDs alternate red and green, and the capacity does not reach 100%.
