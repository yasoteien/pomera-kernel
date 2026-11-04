# pomera-kernel-tools

ポメラ DM250（日本版）の pomera-kernel のカーネルを、安全に入れ替えるための道具です。カーネルのパッケージ（`pomera-kernel-<版>`）と一緒に使います。

## 免責

試験版です。無保証で、使うのは自己責任です。ポメラの本体・SD カード・データに不具合や損失が起きても、私たち（yasoteien）は責任を負いません。キングジム、および DM250 用 Debian イメージの配布元とは関係のない、非公式の物です。入れる前に SD カードの写しを取ってください。戻すには `sudo pomera-kernel rollback`。起動しなくなった時は、SD カードを抜けば本体の純正のソフトで起動します。

## 流れ

1. `apt install` でカーネルのパッケージを入れると、次の起動で試す版として登録されます（SD カードにはまだ書きません）。
2. 次の起動で、その版を kexec で 1 回だけ試します。watchdog を動かしたまま移るので、起きなければ約 5 分で今までの組に戻ります。
3. 試しの起動で systemd が running になれば、その場で確定します。カーネル（KRNL）・デバイスツリー（RSCE）・U-Boot を組で書きます。
   - KRNL と RSCE は、SD カードの 2 つの置き場（組 A・組 B）のうち、今使っていない方に書きます。どちらを起動するかは、小さな表（26MiB・27MiB）で U-Boot に伝えます。
   - 書いている途中で電源が落ちても、次の起動は前の組か新しい組のどちらかになります。
   - DM250 用 Debian イメージの 12MiB・24MiB のカーネルは書き換えません。
   - U-Boot（8〜12MiB）は、版が持つ物と今の物が違う時だけ書きます。初めて書く時は、元の U-Boot の写しと戻し方を、SD の最初の区画（FAT）の `pomera-kernel/` に置きます。
4. 前の組は `/var/lib/pomera-kernel/prev` に記録し、`sudo pomera-kernel rollback` で戻せます。

U-Boot は試しの起動で試せないため、新しい U-Boot は確定の後の次の起動で初めて動きます。そこで起きなくなった時は、SD カードを抜けば本体の純正のソフトで起動します。SD カードを直すには、PC で `pomera-kernel/RESTORE.txt` の手順を使います。

## コマンド

| コマンド | すること |
|---|---|
| `sudo pomera-kernel status` | U-Boot・表・組 0/A/B・次の起動の組・待っている版・前回の結果・戻せる組 |
| `pomera-kernel list` | 入っている版 |
| `sudo pomera-kernel stage <版>` | 次の起動で試す版にする（apt が呼ぶ） |
| `sudo pomera-kernel unstage` | 試す予定を取り消す |
| `sudo pomera-kernel rollback` | 1 つ前の組（U-Boot も含む）に戻す（次の起動から。もう一度流すと戻る） |
| `sudo pomera-kernel keep` | `apt autoremove` が消さない版（今の組・1 つ前の組・動いている版・待っている版）を書き直す |

## hibernate

hibernate の前に Wi-Fi・Bluetooth のモジュールを外し、戻った後に入れ直します（`/usr/libexec/pomera-kernel/hibernate-wireless`、systemd-hibernate.service の drop-in から呼ばれます）。`/etc/systemd/system/systemd-hibernate.service.d/` に同じ名前の物があれば、そちらが使われます。

## 対象

DM250 の日本版だけです。ほかの機種では、パッケージを入れる時に断ります。
