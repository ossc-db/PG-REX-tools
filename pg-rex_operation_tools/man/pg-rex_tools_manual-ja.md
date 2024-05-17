# PG-REX運用補助ツール 15 利用マニュアル

## 目次

- [運用補助ツールとは?](#運用補助ツールとは)
- [導入方法](#導入方法)
- [コマンドリファレンス](#コマンドリファレンス)
- [設定ファイル](#設定ファイル)
- [使用上の注意と制約](#使用上の注意と制約)
- [よくあるQ&A](#よくあるQA)
- [PG-REX運用補助ツール 14からの変更点](#PG-REX運用補助ツール14からの変更点)

## 運用補助ツールとは? {#運用補助ツールとは}

PG-REX運用補助ツールとは、PG-REXの運用手順の簡易化を目的とした以下のコマンド群です。

### 機能概要

各コマンドの概要を以下に示します。

1. pg-rex_primary_start

   本コマンドを実行したノードで、PG-REXをPrimaryとして起動する。

2. pg-rex_standby_start

   本コマンドを実行したノードで、PG-REXをStandbyとして起動する。

3. pg-rex_stop

   PG-REXのPrimaryまたはStandbyを停止する。

4. pg-rex_archivefile_delete

   データベースの復旧に必要のないアーカイブログを移動または削除する。

5. pg-rex_switchover

   PG-REXのノード切り替えを実施する。



## 導入方法

### インストール

#### 動作確認済み環境

- OS : Red Hat Enterprise Linux 8.8
- PG-REX : 15
  - DBMS : PostgreSQL 15.4
  - HA : Pacemaker 2.1.5-8



#### パッケージのインストール

PG-REX運用補助ツールを使用するためにインストール必須のRPMパッケージを以下に示します。

1. pg-rex_operation_tools_script-15.1-1.el8.noarch.rpm
2. IO_Tty-1.11-1.el8.x86_64.rpm
3. Net_OpenSSH-0.62-1.el8.x86_64.rpm

※バージョンは適宜読み替えてください。



PG-REX運用補助ツールのRPMをインストールします。インストールは以下の順序で行います。

```
# dnf install pg-rex_operation_tools_script-15.1-1.el8.noarch.rpm IO_Tty-1.11-1.el8.x86_64.rpm Net_OpenSSH-0.62-1.el8.x86_64.rpm
```



PG-REX運用補助ツールのRPMパッケージをインストールすると、コマンドと設定ファイルは以下のように配置されます。

```
/usr
   └-local
      └-bin
         └-pg-rex_primary_start
         └-pg-rex_standby_start
         └-pg-rex_stop
         └-pg-rex_archivefile_delete
         └-pg-rex_switchover

/etc
   └- pg-rex_tools.conf
```



#### 設定ファイルの編集

環境にあわせて、`/etc/pg-rex_tools.conf`の設定を行います。各項目の詳細は[設定ファイル](#設定ファイル)を参照してください。設定例を以下に示します。

```
$ cat /etc/pg-rex_tools.conf
D_LAN_IPAddress = 192.168.2.1 , 192.168.2.2
IC_LAN_IPAddress = (192.168.1.1, 192.168.1.2) , (192.168.3.1, 192.168.3.2)
Archive_dir = /dbfp/pgarch/arc1
IPADDR_STANDBY = enable
PGPATH = /usr/pgsql-15/bin
PEER_NODE_SSH_PASS_MODE = passfile
PEER_NODE_SSH_PASS_FILE = /root/.pgrex/peer_passwd
BACKUP_NODE_SSH_PASS_MODE = passfile
BACKUP_NODE_SSH_PASS_FILE = /root/.pgrex/bkup_passwd
PG_REX_Primary_ResourceID = pgsql-clone
PG_REX_Primitive_ResourceID = pgsql
IPADDR_PRIMARY_ResourceID = ipaddr-primary
IPADDR_REPLICATION_ResourceID = ipaddr-replication
IPADDR_STANDBY_ResourceID = ipaddr-standby
PING_ResourceID = ping-clone
STONITH_ResourceID = fence1-ipmilan , fence2-ipmilan
HACLUSTER_NAME = pgrex_hacluster
```



#### ネットワーク接続の登録

PG-REX運用補助ツールが相手ノードの操作や確認をD-LANを使用して行うため、事前に両ノードのrootユーザの`.ssh/known_hosts`に相手先のD-LANのIPアドレスに対する接続登録をする必要があります。

```
# ssh 192.168.2.2	←相手先のD-LANのIPアドレスを指定
The authenticity of host '192.168.2.2 (192.168.2.2)' can't be established.
ECDSA key fingerprint is *******
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
↑[yes]を入力し[Enter]キーを押下
Warning: Permanently added '192.168.2.2' (ECDSA) to the list of known hosts.
root@192.168.2.2's password:	←[Ctrl]キーと[C]キーを同時に押下
```



### アンインストール

RPMパッケージのアンインストールを行います。

```
# dnf remove pg-rex_operation_tools_script-15.1-1.el8.noarch IO_Tty-1.11-1.el8.x86_64 Net_OpenSSH-0.62-1.el8.x86_64
```



## コマンドリファレンス

1. [pg-rex_primary_start](#pg-rex_primary_start)
2. [pg-rex_standby_start](#pg-rex_standby_start)
3. [pg-rex_stop](#pg-rex_stop)
4. [pg-rex_archivefile_delete](#pg-rex_archivefile_delete)
5. [pg-rex_switchover](#pg-rex_switchover)

### pg-rex_primary_start

##### 概要

本コマンドを実行したノードで、PG-REXをPrimaryとして起動します。

##### 形式

```
pg-rex_primary_start [-h][-v][XmlFilePath]
```

##### 引数

- -h, --help

  Usageを表示して終了します

- -v, --version

  バージョン情報を表示して終了します

- *XmlFilePath*

  リソース定義xmlファイルのファイルパスを指定します(初回起動時に使用する)

##### 実行例

- 引数なしの実行例

```
# pg-rex_primary_start
root@192.168.2.2's password:
パスワードが入力されました
1. Pacemaker および Corosync が停止していることを確認
...[OK]
2. 稼働中の Primary が存在していないことを確認
...[OK]
3. Primary として稼働することが出来るかを確認
...[OK]
4. 起動禁止フラグの存在を確認
...[OK]
5. Pacemaker 起動
...[OK]
6. Primary の起動確認
...[OK]
ノード(pgrex01)が Primary として起動しました
```

- 引数ありの実行例

```
# pg-rex_primary_start pm_pcsgen_env.xml
root@192.168.2.2's password:
パスワードが入力されました
1. Pacemaker および Corosync が停止していることを確認
...[OK]
2. 稼働中の Primary が存在していないことを確認
...[OK]
3. 起動禁止フラグの存在を確認
...[OK]
既に HAクラスタ があります
再作成しても宜しいでしょうか？ (y/N) y
4. HAクラスタ の破棄
...[OK]
5. HAクラスタ の作成
...[OK]
6. Pacemaker 起動
...[OK]
7. リソース定義 xml ファイルの反映
...[OK]
8. Primary の起動確認
...[OK]
ノード(pgrex01)が Primary として起動しました
```



### pg-rex_standby_start

##### 概要

本コマンドを実行したノードで、PG-REXをStandbyとして起動します。

##### 形式

```
pg-rex_standby_start [[-n] [-r] [-b] | -c] [-d] [-s] [-h] [-v]
```

##### 引数

- -n, --normal

  現在のDBクラスタを使用してStandby を起動します

- -r, --rewind

  現在のDBクラスタに相手 (Primary) ノードと同期したうえでレプリケーションを行えるように、巻き戻し後、Standbyを起動します

- -b, --basebackup

  相手ノードをPrimaryとしてベースバックアップを取得後、Standbyとして起動します

- -d, --dry-run

  データの変更とノードの起動の実行を伴わず、表示のみを行います

- -c, --check-only

  DBクラスタの状態確認までを実施します

- -s, --shared-archive-directory

  Primary と Standby でアーカイブディレクトリを共有しているものとして動作します

- -h, --help

  Usageを表示して終了します

- -v, --version

  バージョン情報を表示して終了します

##### 実行例

```
# pg-rex_standby_start
root@192.168.2.1's password:
パスワードが入力されました
1. Pacemaker および Corosync が停止していることを確認
...[OK]
2. 稼働中の Primary が存在していることを確認
...[OK]
3. 起動禁止フラグが存在しないことを確認
...[OK]
4. DB クラスタの状態を確認
4.1 現在のDBクラスタのまま起動が可能か確認
DB クラスタが存在していません
...[NG]
4.2 巻き戻しを実行することで起動が可能か確認
DB クラスタが存在していません
...[NG]
4.3 ベースバックアップを取得することが可能か確認
...[OK]

以下の方法で起動が可能です
b) ベースバックアップを取得してStandbyを起動
q) Standbyの起動を中止する
起動方法を選択してください(b/q) b
5. IC-LAN が接続されていることを確認
...[OK]
6. Primary からベースバックアップ取得
22631/22631 kB (100%), 1/1 tablespace
NOTICE:  pg_stop_backup complete, all required WAL segments have been archived
...[OK]
7. Primary のアーカイブディレクトリと同期
000000010000000000000002.partial
00000002.history
000000020000000000000003.00000028.backup
000000010000000000000001
000000020000000000000002
000000020000000000000003
...[OK]
8. Standby の起動 (アーカイブリカバリ対象 WAL セグメント数: 1)
...[OK]
9. Standby の起動確認
...[OK]
ノード(pgrex02)が Standby として起動しました
```



### pg-rex_stop

##### 概要

本コマンドを実行したノードで、PG-REXのPrimaryまたはStandbyを停止します。

##### 形式

```
pg-rex_stop [-f][-h][-v]
```

##### 引数

- -f, --fast

  停止前にCHECKPOINTとsyncコマンドを実行しません

- -h, --help

  Usageを表示して終了します

- -v, --version

  バージョン情報を表示して終了します

##### 実行例

```
# pg-rex_stop
Primary を停止します
1. Pacemaker 停止
...[OK]
2. Pacemaker 停止確認
...[OK]
PG-REX の Primary (pgrex01)を停止しました
```



### pg-rex_archivefile_delete

##### 概要

本コマンドを実行したノードで不要なアーカイブログを削除します。不要なアーカイブログとは、PG-REXのPrimaryとStandbyのDBクラスタ、およびコマンド実行時に指定したベースバックアップのリカバリに不要なアーカイブログです。指定したベースバックアップの取得時点よりも過去に取得したベースバックアップは使用できなくなることに注意してください。PrimaryとStandbyの両方がSSH接続可能である必要があります。

コマンド実行時にベースバックアップの場所の指定を省略した場合は、対話形式での指定となります。対話形式でも省略した場合は、PrimaryとStandbyのみを対象にして不要なアーカイブログを削除します。ベースバックアップの場所がリモートサーバの場合は、環境設定ファイルのBACKUP_NODE_SSH_PASS_MODEに設定した認証方式でリモートサーバにアクセスします。

本コマンドには、不要なアーカイブログを削除するモード(削除モード)と移動するモード(移動モード)があります。移動モードを指定した場合は、アーカイブログ格納ディレクトリ直下に現在日時のディレクトリを作成し、当該ディレクトリに不要なアーカイブログが移動されます。

##### 形式

```
pg-rex_archivefile_delete {-m|-r}[-f][-D DBclusterFilepath][-h][-v] [[Hostname:]BasebackupPath]

```

##### 引数

- -m, --move

  移動モードで実行します

- -r, --remove

  削除モードで実行します

  ※ 移動モードまたは削除モードはどちらか片方を必ず指定してください


- -f, --force

  アーカイブログの削除を問い合わせ無しで実行します

- -h, --help

  Usageを表示して終了します

- -v, --version

  バージョン情報を表示して終了します

- -D, --dbcluster=*DBclusterFilepath*

  両ノードで使用しているDBクラスタの場所の絶対パスを指定します

  指定を省略した場合は、以下の優先度で値が適用されます

  1. rootユーザでの実行の場合、リソース定義xmlの「pgdata」
  2. 環境変数の「PGDATA」

- *Hostname*

  ベースバックアップが存在するリモートサーバを指定します

  Hostnameを省略した場合は"localhost"が適用されます

- *BasebackupPath*

  ベースバックアップの場所を絶対パスで指定します

##### 実行例

- 移動モードでベースバックアップの指定をしない場合

```
# pg-rex_archivefile_delete -m

**** 1. 実行準備 ****
移動モードで実行します
ベースバックアップが存在するリモートサーバを入力してください
(入力しなければ "localhost" を設定します)
>
ベースバックアップの場所の絶対パスを入力してください
(入力しなければバックアップ指定無しとして実行されアーカイブが削除されるため、
以前に取得したベースバックアップが使用できなくなります)
>
環境設定ファイル (pgrex_tools.conf) を読み込みます
root@192.168.2.2's password:
パスワードが入力されました
両ノードの名前を取得します
cib.xml ファイルを読み込みます
ベースバックアップの場所を指定せずに実行すると、
自身のノード "pgrex01" と相手のノード "pgrex02" の
現時点の PGDATA "/dbfp/pgdata/data" を基準にしてアーカイブログを削除することになります
アーカイブログを削除しますか (y/N) : y

**** 2. WAL ファイル名の取得 ****
自身のノード "pgrex01" の現時点の PGDATA "/dbfp/pgdata/data" からリカバリに必要な最初の WAL ファイル名を取得します
"00000002000000000000000C"
相手のノード "pgrex02" の現時点の PGDATA "/dbfp/pgdata/data" からリカバリに必要な最初の WAL ファイル名を取得します
"000000020000000000000003"

**** 3. 削除基準の算出 ****
削除基準を "000000020000000000000003" としました

**** 4. アーカイブログの移動 ****
削除対象のリストに "000000010000000000000002" を追加します
削除対象のリストに "000000020000000000000002" を追加します
削除対象のリストに "000000010000000000000001" を追加します
移動先ディレクトリ "/dbfp/pgarch/arc1/20130826_163510" を作成しました
-- 移動 -- 000000010000000000000002
-- 移動 -- 000000020000000000000002
-- 移動 -- 000000010000000000000001
アーカイブログの移動に成功しました
移動モード実行のため、移動したファイルは"/dbfp/pgarch/arc1/20130826_163510" に格納されています
```

- 削除モードで、ベースバックアップを指定した場合

```
# pg-rex_archivefile_delete -r pgrex03:/pgdata/backup_data

**** 1. 実行準備 ****
削除モードで実行します
環境設定ファイル (pg-rex_tools.conf) を読み込みます
root@192.168.2.2's password:
パスワードが入力されました
両ノードの名前を取得します
cib.xml ファイルを読み込みます

**** 2. WAL ファイル名の取得 ****
指定されたバックアップからリカバリを行うために必要な最初の WAL ファイル名を取得します
root@pgrex03's password:
パスワードが入力されました
"000000020000000000000004"
自身のノード "pgrex01" の現時点の PGDATA "/dbfp/pgdata/data" からリカバリに必要な最初の WAL ファイル名を取得します
"000000020000000000000003"
相手のノード "pgrex02" の現時点の PGDATA "/dbfp/pgdata/data" からリカバリに必要な最初の WAL ファイル名を取得します
"00000002000000000000000C"

**** 3. 削除基準の算出 ****
削除基準を "000000020000000000000003" としました

**** 4. アーカイブログの削除 ****
削除対象のリストに "000000010000000000000001" を追加します
削除対象のリストに "000000010000000000000002" を追加します
削除対象のリストに "000000020000000000000002" を追加します
-- 削除 -- 000000010000000000000001
-- 削除 -- 000000010000000000000002
-- 削除 -- 000000020000000000000002
アーカイブログの削除に成功しました
```



### pg-rex_switchover

##### 概要

Standbyの再組み込み時にベースバックアップを取得せずにPG-REXのノード切り替えを実行します。ベースバックアップを取得しないことで、ノード切り替え時間の短縮を実現します。

本コマンドは、PG-REXのPrimaryとStandbyのどちらのノードでも実行することができます。

##### 形式

```
pg-rex_switchover [-h][-v]
```

##### 引数

- -h, --help

  Usageを表示して終了します

- -v, --version

  バージョン情報を表示して終了します

##### 実行例

```
# pg-rex_switchover
root@192.168.2.2's password:
パスワードが入力されました
**** 実行準備 ****
1. 環境設定ファイル (pg-rex_tools.conf) の読み込みと両ノードの名前を取得
...[OK]
2. 現在およびノード切り替え後のHAクラスタ状態を確認

[ 現在 / ノード切り替え後のHAクラスタ状態 ]
 Primary : pgrex01 -> pgrex02
 Standby : pgrex02 -> pgrex01

ノード切り替え中は可用性が保証されません。
ノード切り替えを実行してもよろしいでしょうか？ (y/N) y

**** ノード切り替えを実行 ****
3. Pacemaker の監視を停止
...[OK]
4. Primary (pgrex01) の PostgreSQL を停止
...[OK]
5. Pacemaker の監視を再開しノード切り替えを実行
...[OK]
6. pgrex02 が新 Primary になったことを確認

**** pgrex02 が Primary として起動しました ****

7. pgrex01 の Pacemaker を停止
...[OK]
8. pgrex01 で Standby を起動
00000011000000000000000C
00000012000000000000000E
00000013.history

**** pgrex01 が Standby として起動しました ****

****************************************
**** ノード切り替えが正常に完了しました ****
****************************************

[ 現在のHAクラスタ状態 ]
 Primary : pgrex02
 Standby : pgrex01
```



## 設定ファイル

PG-REX運用補助ツールで利用する設定ファイルについて以下に示します。

1. 格納場所 : /etc
2. ファイル名 : pg-rex_tools.conf


### 設定項目一覧


- D_LAN_IPAddress
  - **両ノードのD-LANのIPアドレス**を指定します。IPアドレスはカンマで区切って指定します。**指定必須**の項目です。
- IC_LAN_IPAddress
  - **IC-LAN系統ごとに括弧で囲ったIPアドレスの組**を記述します。**指定必須**の項目です。
    - (IC-LAN1 アドレス1,IC-LAN1 アドレス2)[,(IC-LAN2 アドレス1 ,IC-LAN2 アドレス2)]
- Archive_dir
  - **アーカイブディレクトリの絶対パス**を指定します。**指定必須**の項目です。
- STONITH
  - STONITHの設定値は常に**enable**を指定します。
- IPADDR_STANDBY
  - Standby側接続用の仮想IPを使用する環境の場合は**enable**、それ以外の場合は**disable**を指定します。省略した場合は**enable**となります。
- PGPATH
  - **PostgreSQLコマンドへの絶対パス**を指定します。設定を省略した場合はpostgresユーザログイン時に設定される環境変数のPATHからPostgreSQLコマンドへのパスを取得します。
- PEER_NODE_SSH_PASS_MODE
  - **manual**、**passfile**、**nopass**のいずれかを指定します。運用補助ツールは実行時に相手ノードにsshで接続する場合があり、このパラメータでssh接続のパスワード取得方法を変更することができます。設定値はセキュリティの観点から**manual**を推奨します。**指定必須**の項目です。
    - manual ： パスワードを手動で入力する。
    - passfile ： PEER_NODE_SSH_PASS_FILEに指定したファイル内のパスワードを参照する。
    - nopass：公開鍵認証を使用する。
- PEER_NODE_SSH_PASS_FILE
  - **相手ノードへのssh接続に必要なパスワードのみが記述されたファイルの絶対パス**を指定します。 **PEER_NODE_SSH_PASS_MODEにpassfileを指定している場合**は、**設定が必須**となります。passfile以外を指定している場合、この設定は参照されません。
- BACKUP_NODE_SSH_PASS_MODE
  - **manual、passfile、nopass**のいずれかを設定します。pg-rex_archivefile_deleteコマンドは実行時にDBクラスタのバックアップ格納先ノードにsshで接続する場合があり、このパラメータでssh接続のパスワード取得方法を変更することができます。設定値はセキュリティの観点から**manual**を推奨します。**指定必須**の項目です。
    - manual ： パスワードを手動で入力する。
    - passfile ：BACKUP_NODE_SSH_ PASS_FILEに指定したファイル内のパスワードを参照する。
    - nopass ： 公開鍵認証を使用する。
- BACKUP_NODE_SSH_PASS_FILE
  - **DBクラスタのバックアップ格納先ノードへのssh接続に必要なパスワードのみが記述されたファイルの絶対パス**を指定します。**BACKUP_NODE_SSH_PASS_MODEにpassfileを指定している場合**は、**設定が必須**となります。passfile以外を指定している場合、この設定は参照されません。
- PG_REX_Primary_ResourceID
  - **環境定義書のPromotableのリソースID**を指定します。**指定必須**の項目です。
- PG_REX_Primitive_ResourceID
  - **環境定義書のPostgreSQL制御のリソースID**を指定します。**指定必須**の項目です。
- IPADDR_PRIMARY_ResourceID
  - Primary側接続用の仮想IPの起動確認を行う場合、**環境定義書の仮想IP定義のうちから、Primary側接続用のリソースID**を指定します。
- IPADDR_REPLICATION_ResourceID
  - レプリケーション受付用の仮想IPの起動確認を行う場合、**環境定義書の仮想IP定義のうちから、レプリケーション受付用のリソースID**を指定します。
- IPADDR_STANDBY_ResourceID
  - Standby側接続用の仮想IPの起動確認を行う場合、**環境定義書の仮想IP定義のうちから、Standby側接続用のリソースID**を指定します。
- PING_ResourceID
  - PINGリソースの起動確認を行う場合、**環境定義書のネットワーク監視のリソースID**を指定します。複数指定する場合はカンマ区切りで指定します。
- STORAGE_MON_ResourceID
  - STORAGE-MON リソースの起動確認を行う場合、**環境定義書のディスク監視のリソースID**を指定します。
- STONITH_ResourceID
  - STONITHリソースの起動確認を行う場合、**環境定義書のハードウェア制御STONITHプラグインのリソースID**をカンマ区切りで2つ指定します。
- HACLUSTER_NAME
  - **Pacemakerで管理するHAクラスタ名**を指定します。HAクラスタ名には英数字とアンダースコア, およびハイフンのみ使用可です。ただし先頭にはハイフンは使用できません。


## 使用上の注意と制約

PG-REX運用補助ツール利用時の制約を以下に示します。

1. pg-rex_switchoverによるノード切り替えでは、Primaryの停止後からPrimaryの切り替え（新Primaryの起動）が完了するまでの間は一時的にサービスが停止した状態となる。
2. pg-rex_switchoverによるノード切り替えの実施中に、pg-rex_switchoverが異常終了した場合のHAクラスタ状態は不確定であり、サービスが停止している可能性がある。この場合、元の状態への復旧は自動で実施されないため、HAクラスタ状態を確認し、手動復旧を試みること。
3. 起動確認はPostgreSQLやIPaddr2、Ping、STONITHなどの固有のリソースにしか確認を行わないため、Apacheなど新しくリソースを追加したとしてもその確認を行わない。
4. 両ノードの状態確認にネットワークの通信を用いるので、ツールが使用するLAN（デフォルトはD-LAN）切断時は、それ以外のLANが繋がっていても実行に失敗する。
5. PG-REXでインストールしたファイルのディレクトリ構成が2つのノードで同一であること。
6. アーカイブログを圧縮する場合、圧縮方式に対応した拡張子を付与しなければならない。サポートする圧縮方式はgzip (拡張子.gz)のみである。



## よくあるQ&A {#よくあるQA}

PG-REX運用補助ツール利用時における、よくある質問について以下に示します。

- Q1. 運用補助ツールコマンドのタイムアウトの時間を変更したい。
  - pg-rex_primary_start、pg-rex_standby_start、pg-rex_stop、pg-rex_switchoverコマンドの起動/停止確認時間のタイムアウト値は300秒に設定してあります。これを変更したい場合は、/usr/local/bin配下にある上記コマンドの”my $timeout = 300”と記述されている箇所の数値(秒単位)を変更して下さい。


- Q2. Standby起動時にベースバックアップを取得しなくてよいパターンとは具体的にどういう場合か。
  - 例えば、フェイルオーバ後に旧PrimaryをStandbyとして起動する場合や、Standbyを一旦停止して再び起動する場合はベースバックアップを取得する必要はありません。ただし、どちらの場合でもStandby起動時のPostgreSQLのリカバリに必要なWALファイルを消去していないことが前提となります。


- Q3. PG-REXでインストールするファイルのディレクトリ構成を2つのノードで異なる構成にしたい。
  - PG-REXではディレクトリ構成が2つのノードで同一であることを前提としています。ディレクトリ構成が両ノードで同一でない場合、運用補助ツールは正常に動作しません。


- Q4. 運用補助ツールが表示するメッセージに日本語と英語が混在する。
  - 運用補助ツールではPostgreSQLのコマンドをpostgresユーザに切り替えて実行しています。そのため、PostgreSQLのコマンドが出力するメッセージはpostgresユーザの言語設定に沿って表示されます。



## PG-REX運用補助ツール 14からの変更点 {#PG-REX運用補助ツール14からの変更点}

- 対応するPG-REXのバージョンは15です。

- PG-REX運用補助ツール 14.1と同様、PG-REX運用補助ツール 15.1からstorage-monの起動確認を追加しました。

------

Copyright (c) 2012-2023, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
