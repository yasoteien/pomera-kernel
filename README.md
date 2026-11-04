# pomera-kernel（ポメラ DM250 の Linux カーネル）

キングジムのポメラ DM250（日本版）で Debian を動かすための Linux カーネルです。本家 Linux 6.18 longterm に DM250 用のパッチを当てて組み、Debian のパッケージ（.deb）と apt の置き場で配ります。毎週 1 回、本家の更新を取り込んで出し直します。

- 対象は DM250 の日本版だけです。US 版（DM250US）とほかの機種では入りません（パッケージが機種を調べて断ります）。
- SD カードから起動する Debian の上で使います。本体の eMMC には書きません。
- 使うのは自己責任でお願いします。SD カードの写しを取ってから入れてください。

## 入れ方

1. 署名の鍵を置きます（`apt/pomera-kernel.asc`、指紋 `E9B3 07FA F435 923A 22E2 A710 9110 B311 6ECA 5467`）。

   ```sh
   sudo install -m 0644 pomera-kernel.asc /usr/share/keyrings/pomera-kernel.asc
   ```

2. apt の置き場を足します。

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

3. 入れます。

   ```sh
   sudo apt update
   sudo apt install pomera-kernel
   ```

入れた後の次の起動で、新しいカーネルを 1 回だけ試します（kexec）。起動が正常（systemd が running）なら、その場で SD カードのカーネルの場所に書いて確定します。起きなければ、watchdog で今までのカーネルに戻ります（約 5 分）。人の手は要りません。

## 戻し方

```sh
sudo pomera-kernel status     # 今の組・1 つ前の組
sudo pomera-kernel rollback   # 1 つ前の組に戻す（次の起動から。もう一度流すと戻る）
```

古い版は `apt autoremove` で消えます。今の版と 1 つ前の版は残ります。

## 中身

| 置き場 | 中身 |
|---|---|
| `patches/` | 本家に当てるパッチと順番（`series`） |
| `configs/` | カーネルの設定 |
| `scripts/` | 本家の版を取ってパッチを当てて組む台本 |
| `deb/` | .deb を組む台本と、試し起動・確定・戻しの道具（`pomera-kernel`）、hibernate の時に無線のモジュールを外して入れ直す台本 |
| `dts/` | デバイスツリー。作者の DTS（`rk3128-pomera-dm250-author.dts`）と、それを直す台本（`mk_leds.sh`・`mk_panel.sh`）、SD カードの RSCE を組む台本（`mk_rsce.sh`） |
| `apt/` | apt の署名の公開鍵 |
| `CHANGELOG.md` | 版ごとの変更 |

## デバイスツリーの出どころ

`dts/rk3128-pomera-dm250-author.dts` は、DM250 用の Debian 11 イメージ（https://www.ekesete.net/log/?p=9565）の SD カードの RSCE 領域にある DTB を、DTS に戻した物です。その DTB は、jcs さんの https://github.com/jcs/linux-dm250 の `pomera-dm250.dts` と、本家 Linux の `rk3128.dtsi`（Rockchip）が元です。この形のまま置き、直す所は台本で当てます。

- `mk_leds.sh`: RK818（電源 IC）の割り込みの結線を実機に合わせ、充電の LED を足す。
- `mk_panel.sh`: パネルの寸法を 7.0 型（154×86mm）に直す。
- `mk_rsce.sh`: 上の 2 つを当てて、パッケージに入れる RSCE を組む。途中の物も含めて sha256 を確かめる。

## ライセンス

- カーネルとパッチ: GPL-2.0（本家のファイルを変えた所は本家のヘッダーのまま。私たちの新しいファイルは GPL-2.0-only）。`LICENSE` を見てください。
- 台本と道具（`scripts/`・`deb/`・`dts/` の台本）: GPL-2.0-or-later。
- デバイスツリー（`dts/` の DTS）: GPL-2.0-or-later（本家の `rk3128.dtsi` に合わせた）。

ソースは https://github.com/yasoteien/pomera-kernel 、apt の置き場は https://yasoteien.github.io/pomera-kernel-apt/ です。

英語の説明は [README.en.md](README.en.md) にあります（日本語が正です）。
