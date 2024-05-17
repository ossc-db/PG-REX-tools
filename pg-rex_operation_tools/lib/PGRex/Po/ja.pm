#!/usr/bin/perl
#####################################################################
# Function: ja.pm
#
#
# 概要:
# PG-REX 便利ツールから呼び出すメッセージの集まり
# JPN ロケール用
# 
# 特記事項:
# なし
#
# Copyright (c) 2012-2023, NIPPON TELEGRAPH AND TELEPHONE CORPORATION
#
#####################################################################
use warnings;
use strict;

use constant {

    PRIMARYSTART_USAGE  => <<_PRIMARYSTART_USAGE_,
PG-REX を Primary として起動するツールです
Primary として起動したいノードで実行します

Usage:
  pg-rex_primary_start [-h] [-v] [XmlFilePath] 

XmlFilePath       初回起動時のみリソース定義 xml ファイルのファイルパスを指定します

Options:
  -h, --help      Usage を表示して終了します
  -v, --version   バージョン情報を表示して終了します

_PRIMARYSTART_USAGE_

    PRIMARYSTART_MS0001  => "Ctrl+C は本プログラムでは無効です\n",
    PRIMARYSTART_MS0002  => "指定されたリソース定義 xml ファイルが存在しません\n",
    PRIMARYSTART_MS0004  => "リソース定義 xml ファイルの読み込みに失敗したためスクリプトを終了します\n",
    PRIMARYSTART_MS0007  => "[0]. Pacemaker および Corosync が停止していることを確認\n",
    PRIMARYSTART_MS0008  => "...[NG]\n",
    PRIMARYSTART_MS0009  => "自身のノードで Pacemaker または Corosync が稼働しています\n".
                           "Primary 起動処理を中止します\n",
    PRIMARYSTART_MS0010  => "...[OK]\n",
    PRIMARYSTART_MS0011  => "[0]. 稼働中の Primary が存在していないことを確認\n",
    PRIMARYSTART_MS0013  => "相手のノードで Primary が稼働中です\n".
                           "Primary 起動処理を中止します\n",
    PRIMARYSTART_MS0014  => "[0]. 起動禁止フラグの存在を確認\n",
    PRIMARYSTART_MS0015  => "起動禁止フラグ \"[0]\" が存在するため Primary の起動処理を中止します\n",
    PRIMARYSTART_MS0016  => "既に HAクラスタ があります\n".
                            "再作成しても宜しいでしょうか？ (y/N) ",
    PRIMARYSTART_MS0017  => "スクリプトを終了します\n",
    PRIMARYSTART_MS0018  => "[0]. HAクラスタ の破棄\n",
    PRIMARYSTART_MS0019  => "[0]. Pacemaker 起動\n",
    PRIMARYSTART_MS0020  => "[0]. リソース定義 xml ファイルの反映\n",
    PRIMARYSTART_MS0021  => "Pacemaker 起動確認処理のタイムアウト時間([0]秒)を経過したためスクリプトを終了します\n".
                           "[1] が起動していません\n".
                           "Pacemaker の状態の詳細は、pcs status --full コマンドで確認してください\n",
    PRIMARYSTART_MS0022  => "[0]. Primary の起動確認\n",
    PRIMARYSTART_MS0023  => "Pacemaker の起動中にリソース故障が発生しました\n".
                           "Pacemaker の状態の詳細は、pcs status --full コマンドを用いて確認してください\n",
    PRIMARYSTART_MS0026  => "ノード([0])が Primary として起動しました\n",
    PRIMARYSTART_MS0027  => "[0]. Primary として稼働することが出来るかを確認\n",
    PRIMARYSTART_MS0028  => "自身のノードの [0]-data-status の値が \"[1]\" になっています\n".
                           "[0]-data-status が初回起動などでまだ登録されていない状態か \"LATEST\" か \"STREAMING|SYNC\" の値でないと\n".
                           "DB クラスタが最新でない可能性があるため、Primary として稼働することができません\n".
                           "Primary 起動処理を中止します\n",
    PRIMARYSTART_MS0029  => "root@[0]'s password:",
    PRIMARYSTART_MS0030  => "\nパスワードが入力されました\n",
    PRIMARYSTART_MS0032  => "リソース定義 xml ファイルの Pacemaker への反映に失敗したためスクリプトを終了します\n".
                           "Pacemaker を停止し、[0] の内容を確認してください\n",
    PRIMARYSTART_MS0033  => "リソース定義 xml ファイルにリソース ID \"[0]\" の \"[1]\" のパラメータが存在していません\n",
    PRIMARYSTART_MS0034  => "pg-rex_standby_startで巻き戻しに失敗したDBクラスタのため起動できません。\n",
    PRIMARYSTART_MS0035  => "[0]. HAクラスタ の作成\n",
    PRIMARYSTART_MS0036  => "自身のノードの \"[0]\" が存在しません\n",


    STANDBYSTART_USAGE  => <<_STANDBYSTART_USAGE_,
PG-REX を Standby として起動するツールです
Standby として起動したいノードで実行します

Usage:
  pg-rex_standby_start [[-n] [-r] [-b] | -c] [-d] [-s] [-h] [-v]

Options:
  -n, --normal                    現在のDBクラスタを使用して Standby を起動します
  -r, --rewind                    現在のDBクラスタに相手 (Primary) ノードと
                                  同期したうえでレプリケーションを行えるように、
                                  巻き戻し後、Standby を起動します
  -b, --basebackup                相手ノードをPrimaryとしてベースバックアップを
                                  取得後、Standby として起動します
  -d, --dry-run                   データの変更とノードの起動の実行を伴わず、
                                  表示のみを行います
  -c, --check-only                DB クラスタの状態確認までを実施します
  -s, --shared-archive-directory  Primary と Standby でアーカイブディレクトリを
                                  共有しているものとして動作します
  -h, --help                      Usage を表示して終了します
  -v, --version                   バージョン情報を表示して終了します

_STANDBYSTART_USAGE_
    
    STANDBYSTART_MS0001   => "Ctrl+C は本プログラムでは無効です\n",
    STANDBYSTART_MS0004   => "[0]. Pacemaker および Corosync が停止していることを確認\n",
    STANDBYSTART_MS0005   => "...[NG]\n",
    STANDBYSTART_MS0006   => "自身のノードで Pacemaker または Corosync が稼働しています\n".
                           "Standby の起動処理を中止します\n",
    STANDBYSTART_MS0007   => "...[OK]\n",
    STANDBYSTART_MS0008   => "[0]. 稼働中の Primary が存在していることを確認\n",
    STANDBYSTART_MS0010   => "相手のノードで Primary が稼働していません\n".
                           "Standby の起動処理を中止します\n",
    STANDBYSTART_MS0011   => "[0]. IC-LAN が接続されていることを確認\n",
    STANDBYSTART_MS0012   => "IC-LAN の接続応答がありません\n",
    STANDBYSTART_MS0013   => "[0]. 起動禁止フラグが存在しないことを確認\n",
    STANDBYSTART_MS0014   => "起動禁止フラグ \"[0]\" が存在するため Standby の起動処理を中止します\n".
                           "前回停止時に Primary として稼働していた可能性があるので Standby として起動していいかどうかを確認してください\n",
    STANDBYSTART_MS0015   => "[0]. Primary からベースバックアップ取得\n",
    STANDBYSTART_MS0018   => "readlink コマンドの実行に失敗しました\n",
    STANDBYSTART_MS0019   => "[0]. Primary のアーカイブディレクトリと同期\n",
    STANDBYSTART_MS0021   => "[0]. Standby の起動 (アーカイブリカバリ対象 WAL セグメント数: [1])\n",
    STANDBYSTART_MS0022   => "[0]. Standby の起動確認\n",
    STANDBYSTART_MS0024   => "Pacemaker の起動中にリソース故障が発生しました\n".
                           "Pacemaker の状態の詳細は、pcs status --full コマンドで確認してください\n",
    STANDBYSTART_MS0029   => "ノード([0])が Standby として起動しました\n",
    STANDBYSTART_MS0032   => "アーカイブディレクトリにファイルが存在するため処理を継続できません: [0]\n",
    STANDBYSTART_MS0033   => "DB クラスタが存在していません\n",
    STANDBYSTART_MS0034   => "[0]. DB クラスタの状態を確認\n",
    STANDBYSTART_MS0035   => "DB クラスタのバージョンが取得できません\n",
    STANDBYSTART_MS0036   => "DB クラスタのバージョン ([0]) が PostgreSQL サーバのバージョン ([1]) と一致していません\n",
    STANDBYSTART_MS0037   => "自身のノードと相手のノードでデータベース識別子が異なっています ([0] != [1])\n",
    STANDBYSTART_MS0038   => "自身のノードの タイムラインID のほうが相手のノードの タイムラインID よりも大きくなっています ([0] > [1])\n",
    STANDBYSTART_MS0040   => "相手のノードに WAL ファイルが存在しません: [0]\n",
    STANDBYSTART_MS0041   => "自身のノードの XLOG の位置のほうが相手のノードの XLOG の位置よりも進んでいます ([0] > [1])\n",
    STANDBYSTART_MS0042   => "相手のノードにタイムライン履歴ファイルが存在しません\n",
    STANDBYSTART_MS0043   => "相手のノードのタイムラインIDに対応するタイムライン履歴ファイル \"[0]\" に自身のノードのタイムラインIDを通った履歴が残っていません\n",
    STANDBYSTART_MS0044   => "相手ノードは自身のノードのLSNより以前に昇格しています\n",
    STANDBYSTART_MS0045   => "自身のノードをベースバックアップから再構築してください\n",
    STANDBYSTART_MS0046   => "Pacemaker 起動確認処理のタイムアウト時間([0]秒)を経過したためスクリプトを終了します\n",
    STANDBYSTART_MS0047   => "[0] の同期レプリケーション状態が確立されていません\n".
                           "[0] の状態を確認してください\n",
    STANDBYSTART_MS0048   => "[0] が起動していません\n".
                           "Pacemaker の状態の詳細は、pcs status --full コマンドで確認してください\n",
    STANDBYSTART_MS0049   => "アーカイブディレクトリのタイムライン履歴ファイルが処理できません (未知の拡張子: [0])\n",
    STANDBYSTART_MS0050   => "[0].[1] 現在のDBクラスタのまま起動が可能か確認\n",
    STANDBYSTART_MS0051   => "[0].[1] 巻き戻しを実行することで起動が可能か確認\n",
    STANDBYSTART_MS0052   => "[0].[1] ベースバックアップを取得することが可能か確認\n",
    STANDBYSTART_MS0053   => "自身のノードと相手のノードのタイムラインID([0])の分岐点が異なっています\n",
    STANDBYSTART_MS0055   => "相手ノードの full_page_writes は有効である必要があります\n",
    STANDBYSTART_MS0056   => "DBクラスタが --data-checksums 付きで作成されているか、wal_log_hints が on である必要があります\n",
    STANDBYSTART_MS0057   => "pg_rewind を実行可能な状態にできません - pg_rewind 以外の方法を使ってください\n",
    STANDBYSTART_MS0058   => "\n指定された起動方法に実行可能なものがありませんでした\n",
    STANDBYSTART_MS0059   => "\n以下の方法で起動が可能です\n",
    STANDBYSTART_MS0060   => "n) 現在のDBクラスタのままStandbyを起動\n",
    STANDBYSTART_MS0061   => "r) 現在のDBクラスタを巻き戻してStandbyを起動\n",
    STANDBYSTART_MS0062   => "b) ベースバックアップを取得してStandbyを起動\n",
    STANDBYSTART_MS0063   => "q) Standbyの起動を中止する\n",
    STANDBYSTART_MS0064   => "起動方法を選択してください([0]) ",
    STANDBYSTART_MS0065   => "Standby の起動処理を中止します\n",
    STANDBYSTART_MS0066   => "選択範囲外の入力がありました\n",
    STANDBYSTART_MS0067   => "\n現在のDBクラスタのまま起動します。\n\n",
    STANDBYSTART_MS0068   => "\n巻き戻し実行後に起動します。\n\n",
    STANDBYSTART_MS0069   => "\nベースバックアップ取得後に起動します。\n\n",
    STANDBYSTART_MS0070   => "[0]. DBクラスタの巻き戻し\n",
    STANDBYSTART_MS0071   => "自身のノードを巻き戻します\n",
    STANDBYSTART_MS0072   => "相手ノードとの分岐点まで状態を戻すことができないため pg_rewind は利用できません\n",
    STANDBYSTART_MS0073   => "ssh の接続に失敗しました([0])\n - 巻き戻しを中断します\n",
    STANDBYSTART_MS0074   => "pg_rewind が相手のノードへの接続に失敗しました\n - 相手ノードの sshd_config で TCP Forwarding が無効になっている可能性があります\n",
    STANDBYSTART_MS0075   => "pg-rex_standby_startで巻き戻しに失敗したDBクラスタです。\n",
    STANDBYSTART_MS0076   => "アーカイブディレクトリに相手のノードの XLOG の位置よりも進んだ WAL ファイルが存在します\n",
    STANDBYSTART_MS0077   => "Standby のアーカイブディレクトリのほうが新しいため、同期をスキップします\n",
    STANDBYSTART_MS0078   => "アーカイブログ \"[0]\" が不完全であるため、スクリプトを終了します\n",
    STANDBYSTART_MS0079   => "アーカイブログ \"[0]\" の拡張子が未知のため、完全性が確認できませんでした (未知の拡張子: [1])\n完全性の確認をスキップします\n",
    STANDBYSTART_MS0080   => "WAL ファイルが存在するため、スクリプトを終了します\n",
    STANDBYSTART_MS0081   => "Primary のアーカイブディレクトリに Primary の現在の LSN よりも進んだ WAL ファイルが存在します\n",
    STANDBYSTART_MS0083   => "pg_wal の WAL ファイルの状態が不適切です。このまま Standby を起動するとアーカイブログが欠損するためスクリプトを終了します\n",
    STANDBYSTART_MS0084   => "-c オプションが指定されているため、非対話オプション(-n,-r,-b)を無視します\n",
    STANDBYSTART_MS0085   => "自身のノードの XLOG の位置のほうが相手のノードのタイムラインの分岐点よりも進んでいます ([0] > [1])\n",
    STANDBYSTART_MS0086   => "...[SKIP]\n",
    STANDBYSTART_MS0087   => "タイムラインID [0] に対応するタイムライン履歴ファイルが相手のノードに存在しません: [1]\n",
    STANDBYSTART_MS0089   => "自身のノードの \"[0]\" が存在しません\n",
    STANDBYSTART_MS0099   => "内部エラー\n",

    STOP_USAGE  => <<_STOP_USAGE_,
PG-REX の Primary または Standby を停止するツールです
停止したいノードで実行します

Usage:
  pg-rex_stop [-f] [-h] [-v]

Options:
  -f, --fast      停止前に CHECKPOINT と sync コマンドを実行しません
  -h, --help      Usage を表示して終了します
  -v, --version   バージョン情報を表示して終了します

_STOP_USAGE_
    
    STOP_MS0001         => "Ctrl+C は本プログラムでは無効です\n",
    STOP_MS0004         => "既に Pacemaker および Corosync は停止しているため停止処理を終了します\n",
    STOP_MS0005         => "PostgreSQL の状態を確認できませんでした\n".
                           "Pacemaker を停止します\n",
    STOP_MS0006         => "Primary を停止します\n",
    STOP_MS0007         => "Standby を停止します\n",
    STOP_MS0009         => "スクリプトを停止します\n",
    STOP_MS0010         => "1. Pacemaker 停止\n",
    STOP_MS0011         => "...[OK]\n",
    STOP_MS0012         => "2. Pacemaker 停止確認\n",
    STOP_MS0013         => "...[NG]\n",
    STOP_MS0014         => "Pacemaker の停止確認処理のタイムアウト時間([0]秒)を経過したのでスクリプトを終了します\n".
                           "Pacemaker および Corosync のプロセスが正常に停止されているかを確認してください\n",
    STOP_MS0015         => "ノード([0])で Pacemaker を停止しました\n",
    STOP_MS0016         => "PG-REX の [0] ([1])を停止しました\n",
    STOP_MS0018         => "Standby がまだ起動しています\n",
    STOP_MS0019         => "ノード切り替えが目的の場合は pg-rex_switchover コマンドの使用を推奨します\n",
    STOP_MS0020         => "今停止すると F/O しますが本当に停止しても宜しいですか？ (y/N) ",

    ARCHDELETE_USAGE  => <<_ARCDELETE_USAGE_,
PG-REX 運用中に作成された、不要なアーカイブログを削除するツールです

Usage:
  pg-rex_archivefile_delete {-m|-r} [-f] [-D DBclusterFilepath] [-h] [-v]
                            [[Hostname:]BasebackupPath]

Hostname        ベースバックアップが存在するリモートサーバを指定します

BasebackupPath  ベースバックアップの場所の絶対パスを指定します

Options:
  -m, --move                         移動モードで実行します
  -r, --remove                       削除モードで実行します
  -f, --force                        アーカイブログの削除を問い合わせ無しで
                                     実行します
  -D, --dbcluster=DBclusterFilepath  両ノードで使用している DB クラスタの場所の
                                     絶対パスを指定します
  -h, --help                         Usage を表示して終了します
  -v, --version                      バージョン情報を表示して終了します

_ARCDELETE_USAGE_
    
    ARCHDELETE_MS0001   => "Ctrl+C は本プログラムでは無効です\n",
    ARCHDELETE_MS0002   => "移動モードか 削除モードのどちらか片方を指定してください\n",
    ARCHDELETE_MS0003   => "\n**** 1. 実行準備 ****\n",
    ARCHDELETE_MS0004   => "移動モードで実行します\n",
    ARCHDELETE_MS0005   => "削除モードで実行します\n",
    ARCHDELETE_MS0006   => "バックアップパスのフォーマットが不正です : \"[0]\"\n",
    ARCHDELETE_MS0007   => "ベースバックアップが存在するリモートサーバを入力してください\n".
                           "(入力しなければ \"localhost\" を設定します)\n".
                           "> ",
    ARCHDELETE_MS0008   => "リモートサーバの入力が不正です : \"[0]\"\n",
    ARCHDELETE_MS0009   => "ベースバックアップの場所の絶対パスを入力してください\n".
                           "(入力しなければバックアップ指定無しとして実行されアーカイブが削除されるため、\n".
                           " 以前に取得したベースバックアップが使用できなくなります)\n".
                           "> ",
    ARCHDELETE_MS0010   => "ベースバックアップの場所の絶対パスの入力が不正です : \"[0]\"\n",
    ARCHDELETE_MS0011   => "リモートサーバ \"[0]\" 、ベースバックアップの場所 \"[1]\" を指定しました\n".
                           "よろしいでしょうか (y/N) : ",
    ARCHDELETE_MS0012   => "スクリプトを終了します\n",
    ARCHDELETE_MS0013   => "環境設定ファイル (pg-rex_tools.conf) を読み込みます\n",
    ARCHDELETE_MS0015   => "両ノードの名前を取得します\n",
    ARCHDELETE_MS0016   => "cib.xml ファイルを読み込みます\n",
    ARCHDELETE_MS0018   => "ベースバックアップの場所を指定せずに実行すると、\n".
                           "自身のノード \"[0]\" と相手のノード \"[1]\" の\n".
                           "現時点の PGDATA \"[2]\" を基準にしてアーカイブログを削除することになります\n".
                           "アーカイブログを削除しますか (y/N) : ",
    ARCHDELETE_MS0019   => "\n**** 2. WAL ファイル名の取得 ****\n",
    ARCHDELETE_MS0020   => "指定されたバックアップからリカバリを行うために必要な最初の WAL ファイル名を取得します\n",
    ARCHDELETE_MS0021   => "ディレクトリ \"[0]\" が存在しません\n",
    ARCHDELETE_MS0022   => "バックアップラベルファイル \"[0]\" の一行目のフォーマットが正しくありません\n",
    ARCHDELETE_MS0023   => " \"[0]\" \n",
    ARCHDELETE_MS0024   => "自身のノード \"[0]\" の現時点の PGDATA \"[1]\" からリカバリに必要な最初の WAL ファイル名を取得します\n",
    ARCHDELETE_MS0025   => "pg_controldata の結果が空のためリカバリに必要な最初の WAL ファイル名を取得できません\n",
    ARCHDELETE_MS0026   => "相手のノード \"[0]\" の現時点の PGDATA \"[1]\" からリカバリに必要な最初の WAL ファイル名を取得します\n",
    ARCHDELETE_MS0027   => "\n**** 3. 削除基準の算出 ****\n",
    ARCHDELETE_MS0028   => "削除基準がないためスクリプトを終了します\n",
    ARCHDELETE_MS0029   => "削除基準を \"[0]\" としました\n",
    ARCHDELETE_MS0030   => "\n**** 4. アーカイブログの削除 ****\n",
    ARCHDELETE_MS0031   => "アーカイブディレクトリ \"[0]\" の確認に失敗しました\n",
    ARCHDELETE_MS0032   => "削除対象のリストに \"[0]\" を追加します\n",
    ARCHDELETE_MS0033   => "削除対象のリストが空のためスクリプトを終了します\n",
    ARCHDELETE_MS0034   => "移動先ディレクトリ \"[0]\" が既に存在しています\n",
    ARCHDELETE_MS0035   => "移動先ディレクトリ \"[0]\" の作成に失敗しました\n",
    ARCHDELETE_MS0036   => "移動先ディレクトリ \"[0]\" の postgres ユーザへの変更に失敗しました\n",
    ARCHDELETE_MS0037   => "移動先ディレクトリ \"[0]\" を作成しました\n",
    ARCHDELETE_MS0038   => "ファイル \"[0]\" の移動に失敗しました\n",
    ARCHDELETE_MS0039   => " -- 移動 -- [0] \n",
    ARCHDELETE_MS0040   => "アーカイブログの移動に成功しました\n".
                           "移動モード実行のため、移動したファイルは \"[0]\" に格納されています\n",
    ARCHDELETE_MS0041   => "ファイル \"[0]\" の削除に失敗しました\n",
    ARCHDELETE_MS0042   => " -- 削除 -- [0] \n",
    ARCHDELETE_MS0043   => "アーカイブログの削除に成功しました\n",
    ARCHDELETE_MS0044   => "DB クラスタの場所の絶対パスを取得できませんでした\n".
                           "-D オプションで DB クラスタの場所の絶対パスを指定してください\n",
    ARCHDELETE_MS0045   => "\n**** 4. アーカイブログの移動 ****\n",
    ARCHDELETE_MS0046   => "ベースバックアップ格納先サーバへの ssh 接続に失敗しました\n",

    SWITCHOVER_USAGE  => <<_SWITCHOVER_USAGE_,
PG-REX のノード切り替えを実行するツールです
  
Usage:
  pg-rex_switchover [-h] [-v]
  
Options:
  -h, --help      Usage を表示して終了します
  -v, --version   バージョン情報を表示して終了します

_SWITCHOVER_USAGE_
    
    SWITCHOVER_MS0001   => "Ctrl+C は本プログラムでは無効です\n",
    SWITCHOVER_MS0002   => "**** 実行準備 ****\n",
    SWITCHOVER_MS0003   => "[0]. 環境設定ファイル (pg-rex_tools.conf) の読み込みと両ノードの名前を取得\n",
    SWITCHOVER_MS0004   => "...[OK]\n",
    SWITCHOVER_MS0005   => "...[NG]\n",
    SWITCHOVER_MS0008   => "[0]. 現在およびノード切り替え後のHAクラスタ状態を確認\n",
    SWITCHOVER_MS0009   => "HAクラスタ状態が以下の条件を満たしていないためノード切り替えを実行できません\n".
                           " (1) Pacemaker、Corosync および PostgreSQL が両ノードで稼働している\n".
                           " (2) Primary と Standby が存在している\n".
                           " (3) PostgreSQL が同期レプリケーション状態である\n",
    SWITCHOVER_MS0010   => "[ 現在のHAクラスタ状態 ]\n",
    SWITCHOVER_MS0011   => "[ 現在 / ノード切り替え後のHAクラスタ状態 ]\n",
    SWITCHOVER_MS0012   => "ノード切り替え中は可用性が保証されません\n",
    SWITCHOVER_MS0013   => "また、現在 [0] に複数の Standby が存在しています\n",
    SWITCHOVER_MS0014   => "ノード切り替えを実行してもよろしいでしょうか？ (y/N) ",
    SWITCHOVER_MS0015   => "スクリプトを終了します\n",
    SWITCHOVER_MS0017   => "[0]. CHECKPOINT の実行\n",
    SWITCHOVER_MS0018   => "**** ノード切り替えを実行 ****\n",
    SWITCHOVER_MS0019   => "[0]. Pacemaker の監視を停止\n",
    SWITCHOVER_MS0020   => "[0]. Primary ([1]) の PostgreSQL を停止\n",
    SWITCHOVER_MS0021   => "[0]. Pacemaker の監視を再開しノード切り替えを実行\n",
    SWITCHOVER_MS0022   => "[0]. [1] が新 Primary になったことを確認\n",
    SWITCHOVER_MS0023   => "リソース起動確認処理のタイムアウト時間([0]秒)を経過したためスクリプトを終了します\n".
                           "[1] が起動していません\n".
                           "Pacemaker の状態の詳細は、pcs status --full コマンドで確認してください\n",
    SWITCHOVER_MS0026   => "[0]. [1] の Pacemaker を停止\n",
    SWITCHOVER_MS0027   => "Pacemaker の停止確認処理のタイムアウト時間([0]秒)を経過したのでスクリプトを終了します\n".
                           "Pacemaker の状態の詳細は、pcs status --full コマンドで確認してください\n",
    SWITCHOVER_MS0028   => "[0]. [1] で Standby を起動\n",
    SWITCHOVER_MS0030   => "**** [0] が Standby として起動しました ****\n",
    SWITCHOVER_MS0031   => "********************************************\n".
                           "**** ノード切り替えが正常に完了しました ****\n".
                           "********************************************\n",
    SWITCHOVER_MS0032   => "\"[0]\" のコマンドの実行に失敗しました\n",
    SWITCHOVER_MS0033   => "**** [0] が Primary として起動しました ****\n",

    COMMON_MS0001       => "pcs status --full の実行に失敗しました\n",
    COMMON_MS0003       => "cib.xml ファイルにリソース ID \"[0]\" の \"[1]\" のパラメータが存在していません\n",
    COMMON_MS0004       => "環境設定ファイル (pg-rex_tools.conf) の [0] の指定がありません\n",
    COMMON_MS0005       => "環境設定ファイル (pg-rex_tools.conf) の [0] の設定は絶対パスで指定してください\n",
    COMMON_MS0006       => "環境設定ファイル (pg-rex_tools.conf) の STONITH の設定は enable 以外設定できません\n",
    COMMON_MS0007       => "環境設定ファイル (pg-rex_tools.conf) の [0] の設定は2つの IP アドレスをカンマ区切りで指定してください\n",
    COMMON_MS0008       => "自身のノードの IP アドレスの取得に失敗しました\n",
    COMMON_MS0009       => "[0] に自ノードのIPアドレスが含まれていません: [1]\n",
    COMMON_MS0010       => "[0] に相手ノードのIPアドレスが含まれていません: [1]\n",
    COMMON_MS0011       => "\"[0]\" のコマンドの実行に失敗しました\n",
    COMMON_MS0013       => "XLOG 位置の情報をパースできません\n",
    COMMON_MS0014       => "pg_controldata の値の取得に失敗しました\n",
    COMMON_MS0015       => "相手のノード名の取得に失敗しました\n",
    COMMON_MS0016       => "相手ノードへの ssh 接続に失敗しました\n",
    COMMON_MS0018       => "scp コマンドの実行に失敗しました\n",
    COMMON_MS0021       => "環境設定ファイル (pg-rex_tools.conf) の IPADDR_STANDBY の設定は enable または disable で指定してください\n",
    COMMON_MS0022       => "環境設定ファイル (pg-rex_tools.conf) の STONITH_ResourceID の設定は2つのリソース ID をカンマ区切りで指定してください\n",
    COMMON_MS0023       => "cib.xml \"[0]\" の読み込みに失敗しました\n",
    COMMON_MS0024       => "環境設定ファイル \"[0]\" の読み込みに失敗しました\n",
    COMMON_MS0026       => "[0] ユーザで実行されているためスクリプトを終了します\n".
                           "root ユーザで再度実行してください\n",
    COMMON_MS0028       => "環境設定ファイル \"[0]\" の書き込みに失敗しました\n",
    COMMON_MS0029       => "[0]@[1]'s password:",
    COMMON_MS0030       => "\nパスワードが入力されました\n",
    COMMON_MS0031       => "パスワードファイル \"[0]\" が存在しません\n",
    COMMON_MS0032       => "パスワードファイル \"[0]\" の読み込みに失敗しました\n",
    COMMON_MS0033       => "パスワードファイル \"[0]\" の内容が不正です\n",
    COMMON_MS0034       => "環境設定ファイル (pg-rex_tools.conf) の [0] の設定は、\n".
                           "manual、passfile、nopass のいずれかを指定してください\n",
    COMMON_MS0035       => "パスワードファイル \"[0]\" の権限が 600 ではありません\n",
    COMMON_MS0036       => "[0] に PostgreSQL コマンドが見つかりません。: [1]\n",
    COMMON_MS0037       => "PostgreSQL [0] には対応していません\n".
                           "PostgreSQL 15 を使用してください\n",
    COMMON_MS0038       => "Pacemaker [0] には対応していません\n".
                           "Pacemaker 2 を使用してください\n",
    COMMON_MS0039       => "[0] で bindnetaddr ([1]) に対応するネットワークインタフェースが見つかりませんでした\n",
    COMMON_MS0040       => "[0] で bindnetaddr ([1]) に属する IP アドレスの取得に失敗しました\n",
    COMMON_MS0044       => "アーカイブディレクトリの状態を確認できませんでした: [0]\n",
    COMMON_MS0045       => "バックアップラベルファイルの一行目のフォーマットが正しくありません: [0]\n",
    COMMON_MS0046       => "DBクラスタの状態確認に失敗しました。: [0]\n",
    COMMON_MS0047       => "DBクラスタにアクセス中のプロセスが存在します。\n[0]",
    COMMON_MS0048       => "ロックファイル([0])の作成に失敗しました。: [1]\n",
    COMMON_MS0049       => "自身のノードで [0] が稼働しています。起動処理を中止します。\n",
    COMMON_MS0050       => "ロックファイル([0])の作成に失敗しました。\n",
    COMMON_MS0051       => "ロックファイル([0])の削除に失敗しました。: [1]\n",
    COMMON_MS0052       => "[0] はIPv4の形式ではありません。\n",
    COMMON_MS0053       => "[0] が見つかりません: [1]\n",
    COMMON_MS0054       => "アーカイブファイル \"[0]\" のサイズが0のため、スクリプトを終了します\n",
    COMMON_MS0055       => "アーカイブログ \"[0]\" のサイズが制御ファイルの情報([1])と一致しないため、スクリプトを終了します\n",
    COMMON_MS0056       => "lsofコマンドの出力を読み取れません。[0]\n",
    COMMON_MS0057       => "設定パラメータ [0] の設定値が不正です。\n",
    COMMON_MS0058       => "ファイル [0] のパーミッションが不正です。600でなければなりません。\n",
};

1;
