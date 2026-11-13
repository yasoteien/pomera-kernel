# 変更の記録

この記録は [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) の形で書きます。版はメタパッケージ `pomera-kernel` の版（公開の日付 `YYYY.MM.DD`、同じ週の出し直しは `.1`）です。

**試験版です。無保証で、使うのは自己責任です。** キングジム、および ichinomoto 氏が ekesete.net（https://www.ekesete.net/log/?p=9565）で公開されている DM250 用 Debian 13 イメージ（以下「イメージ」）とは関係のない、非公式の物です。入れる前に SD カードの写しを取ってください（README の「免責」）。

## [2026.11.13] - 2026-11-13

上げ方: `sudo apt update && sudo apt upgrade`（`apt-get` なら `dist-upgrade` か `full-upgrade`）。次の起動で新しい版を 1 回だけ試し、正常なら確定します。

### 変更

- Linux 6.18 LTS の 6.18.62 → 6.18.63 に追従（`pomera-kernel-6.18.63-wk20261113`）。ARM の cacheinfo、ext4・FAT、TCP・IPv6、Bluetooth L2CAP の修正を含む（例: CVE-2026-99288）。
- `pomera-kernel-tools` を 0.8 に上げた。
- README に、追従する先（kernel.org の Linux 6.18 LTS。イメージのカーネル・Debian 13 のカーネル〔6.12 系〕には追従しない）と、「USB の 5V 出力（VBUS）について」（イメージの 20261113 版の `vbus_ctl` を入れない理由）を書いた。
- DM250 用のパッチ（0001〜0024）と U-Boot（`dm250.8`）は前の版と同じ。

### 直した不具合

- USB のハブに後から挿した機器（マウス・USB-LAN・スマホ・オーディオインターフェースなど）が認識されない事があった。何もつないでいないハブが省電力で眠ると、DM250 の USB がハブを起こせないため。`pomera-kernel-tools` 0.8 で、ハブを省電力で眠らせないようにした（ハブを挿している間は、ハブの先の機器を見張る分だけ割り込みが増えます。ハブは外から給電されているので、電池への影響は小さいと見ています）。

## [2026.11.07] - 2026-11-07

上げ方: `sudo apt update && sudo apt upgrade`（`apt-get` なら `dist-upgrade` か `full-upgrade`）。次の起動で新しい版を 1 回だけ試し、正常なら確定します。

### 変更

- Linux 6.18 LTS の 6.18.60 → 6.18.62 に追従（`pomera-kernel-6.18.62-wk20261107`）。SD カード（dw_mmc）の DMA の止め方、Bluetooth、ext4・FAT、TCP・IPv6 の修正を含む（例: CVE-2026-99270、CVE-2026-99076）。
- DM250 用のパッチ（0001〜0024）、U-Boot（`dm250.8`）、`pomera-kernel-tools`（0.7）は前の版と同じ。

## [2026.11.04.3] - 2026-11-04

最初の公開です。

上げ方: `sudo apt update && sudo apt upgrade`（`apt-get` なら `dist-upgrade` か `full-upgrade`。`apt-get upgrade` では新しい版のカーネルが入らない）。

### 追加

- Linux 6.18.60（LTS）に、DM250 用のパッチ 0001〜0024 を当てたカーネル（`pomera-kernel-6.18.60-5jm`）。
- 画面（RK3128 の LVDS）、キーボード、充電（RK818）、USB の充電器の検出、suspend、hibernate。
- 試し起動の道具（`pomera-kernel`）: 入れた後の次の起動で 1 回だけ試し、正常なら確定する。起きなければ watchdog で約 5 分以内に前のカーネルに戻る。`rollback` で 1 つ前の組（カーネルと U-Boot）に戻せる。
- SD カードの U-Boot（`dm250.8`、U-Boot v2026.07（公式） ＋パッチ）を、カーネルと組で書く。確定の時に書き、`rollback` で一緒に戻る。
  - 起動の画面にポメラニアンの絵を出す。数え下げは 3 秒。
  - カーネルとデバイスツリーを 2 つの置き場（組 A・組 B）に交互に書き、小さな表（26MiB・27MiB）でどちらを起動するかを選ぶ。書いている途中で電源が落ちても、前の組か新しい組で起きる。イメージのカーネル（12MiB・24MiB）は書き換えない。
  - U-Boot は写しを 4 つ持ち、1 つ目を最後に書く。1 つ目が壊れていても、2 つ目で起きる（試験済み）。
  - `emmc` の命令（数え下げをキーで止めて打つ）で、本体（eMMC）の純正のソフトを起こす。
  - hibernate の像があれば、そこから戻る（`resume=` を足す）。
- hibernate の時に Wi-Fi・Bluetooth のモジュールを外して入れ直す台本。
- 古い版を `apt autoremove` で消す時に、今の版と 1 つ前の版を残す設定。
- パネルの寸法を 7.0 型（154×86mm）に直したデバイスツリー。

### 直した不具合

イメージのカーネルと U-Boot と比べて、次を直しました。

- SD カードと Wi-Fi に同時に負荷を掛けると固まる（DMA の PL330 の電源管理）。
- PD ハブにつなぐと「充電中」と出ながら放電する（USB の充電器の検出と、RK818 の充電の設定）。
- 充電の LED が点かない。
- RTC の alarm の割り込みが届かない（RK818 の割り込みの結線）。
- U-Boot: 起動の画面の絵が、黒い横の帯で割れる。
- U-Boot: デバイスツリーの LVDS の形式（jeida-24 → jeida-18）と、バックライトの PWM の極性。
