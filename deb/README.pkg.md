# pomera-kernel-tools

ポメラ DM250（日本版）の自前カーネルを、安全に入れ替えるための道具です。カーネルのパッケージ（`pomera-kernel-<版>`）と一緒に使います。

## 流れ

1. `apt install` でカーネルのパッケージを入れると、次の起動で試す版として登録されます（SD カードにはまだ書きません）。
2. 次の起動で、その版を kexec で 1 回だけ試します。watchdog を動かしたまま移るので、起きなければ約 5 分で今までのカーネルに戻ります。
3. 試しの起動で systemd が running になれば、その場で SD カードのカーネルの場所（KRNL）とデバイスツリーの場所（RSCE）に組で書いて確定します。前の組は `/var/lib/pomera-kernel/prev` に残します。

## コマンド

| コマンド | すること |
|---|---|
| `pomera-kernel status` | 今の組・待っている版・前回の結果・戻せる組 |
| `pomera-kernel list` | 入っている版 |
| `sudo pomera-kernel stage <版>` | 次の起動で試す版にする（apt が呼ぶ） |
| `sudo pomera-kernel unstage` | 試す予定を取り消す |
| `sudo pomera-kernel rollback` | 1 つ前の組に戻す（次の起動から。もう一度流すと戻る） |
| `sudo pomera-kernel keep` | `apt autoremove` が消さない版（今の組・1 つ前の組・動いている版・待っている版）を書き直す |

## hibernate

hibernate の前に Wi-Fi・Bluetooth のモジュールを外し、戻った後に入れ直します（`/usr/libexec/pomera-kernel/hibernate-wireless`、systemd-hibernate.service の drop-in から呼ばれます）。`/etc/systemd/system/systemd-hibernate.service.d/` に同じ名前の物があれば、そちらが使われます。

## 対象

DM250 の日本版だけです。ほかの機種では、パッケージを入れる時に断ります。
