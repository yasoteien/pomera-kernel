# 変更の記録

この記録は [Keep a Changelog](https://keepachangelog.com/ja/1.1.0/) の形で書きます。版はメタパッケージ `pomera-kernel` の版（公開の日付 `YYYY.MM.DD`、同じ週の出し直しは `.1`）です。

## [2026.11.04.1] - 2026-11-04

最初の公開です（下書き）。

### 追加

- 本家 Linux 6.18.60（longterm）に、DM250 用のパッチ 0001〜0023 を当てたカーネル（`pomera-kernel-6.18.60-5jl`）。
- 画面（RK3128 の LVDS）、キーボード、充電（RK818）、USB の充電器の検出、suspend、hibernate。
- 試し起動の道具（`pomera-kernel`）: 入れた後の次の起動で 1 回だけ試し、正常なら確定する。起きなければ watchdog で前のカーネルに戻る。`rollback` で 1 つ前の組に戻せる。
- hibernate の時に Wi-Fi・Bluetooth のモジュールを外して入れ直す台本。
- 古い版を `apt autoremove` で消す時に、今の版と 1 つ前の版を残す設定。
- パネルの寸法を 7.0 型（154×86mm）に直したデバイスツリー。

### 直した不具合

- hibernate から戻った後に Bluetooth が使えなくなる。
- hibernate から戻った後に、一部のクロックの設定が戻らない。
- USB の充電で、決めた上限を超える電流を受け付ける事がある。
