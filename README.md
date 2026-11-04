# pomera-kernel（ポメラ DM250 の Linux カーネル）

キングジムのポメラ DM250（日本版）で Debian を動かすための Linux カーネルです。本家 Linux 6.18 longterm に DM250 用のパッチを当てて組み、Debian のパッケージ（.deb）と apt の置き場で配ります。毎週 1 回、本家の更新を取り込んで出し直します。

- 対象は DM250 の日本版だけです。US 版（DM250US）とほかの機種では入りません（パッケージが機種を調べて断ります）。
- SD カードから起動する Debian の上で使います。本体の eMMC には書きません。
- 試験版です。下の「免責」を読んでから入れてください。

## 免責

- これは試験版です。動くこと・品質・目的に合うことは保証しません（GPL の第 11・12 項のとおり無保証です）。使うのは自己責任でお願いします。
- これを使って、ポメラの本体・SD カード・データに不具合や損失が起きても、私たち（yasoteien）は責任を負いません。
- キングジム、および ichinomoto 氏が ekesete.net（https://www.ekesete.net/log/?p=9565）で公開している DM250 用 Debian 13 イメージ（以下「イメージ」）とは関係のない、非公式の物です。両者に問い合わせないでください。
- 入れる前に、SD カードの写し（イメージ）を取ってください。
- 戻し方: `sudo pomera-kernel rollback`（1 つ前の組に戻す。U-Boot も一緒に戻ります）。起動しなくなった時は、SD カードを抜けば本体の純正のソフトで起動します。SD カードは、取っておいた写しで戻してください。

## 入れ方

**FDTP（https://github.com/yasoteien/fdtp）を使うと、もっと簡単です。** FDTP の `./configure`（`.deb` 版なら `sudo fdtp-pomera-setup`）からも pomera-kernel を入れられ、Wi-Fi・内蔵メモリ（ポメラの文書を Linux から読み書き）・PD ハブでの充電・時計のずれの直し・HEIC の写真の表示などの設定も一緒にできます。カーネルを替えた後に要らなくなった設定の片付けもしてくれます。

FDTP を使わない時は、次のコマンドで入れられます（Debian の SD カードの上で）。

1. 公開鍵を取り、指紋が `E9B3 07FA F435 923A 22E2 A710 9110 B311 6ECA 5467` である事を確かめます。

   ```sh
   wget -O pomera-kernel.asc https://yasoteien.github.io/pomera-kernel-apt/pomera-kernel.asc
   gpg --show-keys pomera-kernel.asc
   ```

2. 鍵と apt の置き場を置きます。

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

3. 入れて、再起動します。

   ```sh
   sudo apt update && sudo apt install pomera-kernel
   sudo reboot
   ```

同じ事を 1 本でする台本 `pomera-kernel-setup.sh` もあります（この木の頭と、apt の置き場の https://yasoteien.github.io/pomera-kernel-apt/pomera-kernel-setup.sh）。鍵の指紋も台本の中で確かめます。取ったら、**中身を読んでから**流してください（`curl … | sh` のように、読まずに流すのは勧めません）。

```sh
wget https://yasoteien.github.io/pomera-kernel-apt/pomera-kernel-setup.sh
less pomera-kernel-setup.sh
sudo sh pomera-kernel-setup.sh          # 始めに FDTP の案内を出して聞きます（--yes で聞かずに進む）。外す時は remove
```

FDTP を使っている人は、FDTP の `./configure`（`.deb` 版なら `sudo fdtp-pomera-setup`）からも入れられます。

再起動すると、次の順で進みます。

1. まず、今のカーネル（初めて入れる時は、イメージのカーネル）で起動します。
2. 起動の途中で pomera-kernel に移ります（kexec）。画面が一度消えて、また出ます。
3. 正常に起動すれば（systemd が running）、約 2 分後に自動で確定し、カーネル・デバイスツリー・U-Boot を組で SD カードに書きます。以後は新しい組（カーネルと U-Boot）で起動します。
   - カーネルとデバイスツリーは、SD カードの 2 つの置き場（組 A・組 B）のうち、今使っていない方に書きます。どちらで起動するかは小さな表で U-Boot に伝えるので、書いている途中で電源が落ちても、次の起動は前の組か新しい組のどちらかです。
   - イメージのカーネル（SD カードの 12MiB・24MiB）は書き換えません。
   - 初めて U-Boot を書く時は、元の U-Boot の写しと戻し方（`RESTORE.txt`）を、SD カードの最初の区画（FAT）の `pomera-kernel/` に置きます。
4. うまく起動しなければ、watchdog で約 5 分以内に自動で今のカーネル（初めて入れる時は、イメージのカーネル）に戻ります（U-Boot は書き換えません）。人の手は要りません。
5. 確定した後で戻すには `sudo pomera-kernel rollback`（次の起動から、1 つ前の組。カーネルと U-Boot が組で戻ります）。

U-Boot は試しの起動で試せないため、新しい U-Boot は確定の後の次の起動で初めて動きます。そこで起動しなくなった時は、SD カードを抜けば本体の純正のソフトで起動します。SD カードは、PC で `pomera-kernel/RESTORE.txt` の手順（元の U-Boot を書き戻す）か、取っておいた写しで戻してください。

イメージのカーネル向けの回避策（Wi-Fi の PIO・watchdog・nftables など）は、FDTP が入れた物です。FDTP を使っていない人は、何も外す必要はありません。

## 上げ方

毎週の新しい版は、次で入ります。

```sh
sudo apt update && sudo apt upgrade
```

新しい版のカーネルは、別の名前のパッケージ（`pomera-kernel-<版>`）として入ります。`apt-get upgrade` は新しいパッケージを入れないので、メタパッケージ `pomera-kernel` が「保留」のまま上がりません。`apt-get` を使う時は `sudo apt-get dist-upgrade`（または `full-upgrade`）にしてください。上げた後の次の起動で、入れた時と同じく 1 回だけ試してから確定します。

## 戻し方

```sh
sudo pomera-kernel status     # U-Boot・今の組・次の起動の組・1 つ前の組
sudo pomera-kernel rollback   # 1 つ前の組（カーネルと U-Boot）に戻す（次の起動から。もう一度流すと戻る）
```

古い版は `apt autoremove` で消えます。今の版と 1 つ前の版は残ります。

## 中身

| 置き場 | 中身 |
|---|---|
| `patches/` | 本家に当てるパッチと順番（`series`） |
| `configs/` | カーネルの設定 |
| `scripts/` | 本家の版を取ってパッチを当てて組む台本 |
| `deb/` | .deb を組む台本と、試し起動・確定・戻しの道具（`pomera-kernel`）、hibernate の時に無線のモジュールを外して入れ直す台本 |
| `dts/` | デバイスツリー。イメージの DTS（`rk3128-pomera-dm250-image.dts`）と、それを直す台本（`mk_leds.sh`・`mk_panel.sh`）、SD カードの RSCE を組む台本（`mk_rsce.sh`） |
| `uboot/` | SD カードの U-Boot のソース（本家 U-Boot v2026.07 に当てるパッチ・組む台本・組んだ物の sha256） |
| `apt/` | apt の署名の公開鍵 |
| `pomera-kernel-setup.sh` | FDTP なしで、鍵と apt の置き場を足して入れる台本 |
| `CHANGELOG.md` | 版ごとの変更 |

## デバイスツリーの出どころ

`dts/rk3128-pomera-dm250-image.dts` は、イメージの SD カードの RSCE 領域にある DTB を、DTS に戻した物です。その DTB は、jcs さんの https://github.com/jcs/linux-dm250 の `pomera-dm250.dts` と、本家 Linux の `rk3128.dtsi`（Rockchip）が元です。この形のまま置き、直す所は台本で当てます。

- `mk_leds.sh`: RK818（電源 IC）の割り込みの結線を実機に合わせ、充電の LED を足す。
- `mk_panel.sh`: パネルの寸法を 7.0 型（154×86mm）に直す。
- `mk_rsce.sh`: 上の 2 つを当てて、パッケージに入れる RSCE を組む。途中の物も含めて sha256 を確かめる。

## ライセンス

- カーネルとパッチ: GPL-2.0（本家のファイルを変えた所は本家のヘッダーのまま。私たちの新しいファイルは GPL-2.0-only）。`LICENSE` を見てください。
- 台本と道具（`scripts/`・`deb/`・`dts/` の台本）: GPL-2.0-or-later。
- デバイスツリー（`dts/` の DTS）: GPL-2.0-or-later（本家の `rk3128.dtsi` に合わせた）。
- U-Boot とパッチ（`uboot/`）: GPL-2.0+（本家 U-Boot のまま）。出どころは `uboot/README.md`。

ソースは https://github.com/yasoteien/pomera-kernel 、apt の置き場は https://yasoteien.github.io/pomera-kernel-apt/ です。

英語の説明は [README.en.md](README.en.md) にあります（日本語が正です）。
