# Ubuntu-Setup

Ubuntu 20.04.1 LTS 日本語Remixのセットアップ方法を以下に記載する.
管理権限が必要な操作は，`sudo`を付けコマンドを付ける点に注意する.

## Proxy設定

大学からのインターネット接続は全て，Proxyサーバを経由して管理されている.
内部LAN（研究室）からインターネットに接続するために，その宛先であるProxyサーバ情報を登録する.

### 個別ユーザごとの環境設定

`vi`コマンドで`.bashrc`を開き，末尾に以下を追記する.

```
$ vi ~/.bashrc
export https_proxy="http://proxy.kansai-u.ac.jp:8080/"
export http_proxy="http://proxy.kansai-u.ac.jp:8080"
export ftp_proxy="http://proxy.kansai-u.ac.jp:8080"
```

`wget`コマンドで動作確認を行う.

```
$ wget https://yahoo.co.jp | more
```

### apt-get

`sudo`を付けて，`vi`コマンドで`/etc/apt/apt.conf.d/30proxy`を開き以下を追記する.

```
$ sudo vi /etc/apt/apt.conf.d/30proxy
Acquire::http { Proxy "http://proxy.kansai-u.ac.jp:8080/"; };
Acquire::https { Proxy "http://proxy.kansai-u.ac.jp:8080/"; };
```

`apt-get`コマンドで動作確認を行う.

```
$ sudo apt-get update
```

## システム更新

```
$ sudo apt update && sudo apt upgrade
```

以下に，`apt-get`コマンドの概要を示す.`apt-get`は`apt`と省略可能．

| コマンド|  内容  |
| ---- | ---- |
| `apt-get install [package]` |  パッケージのインストール/更新  |
| `apt-get update`  | パッケージリストの更新  |
| `apt-get upgrade` | インストールされてるパッケージの更新 |
| `apt-get dist-upgrade` | インストールされてるカーネルの更新(Ubuntu)/ディストリビューションの更新(Debian) |

`update`はパッケージリストが更新されるだけであり，最新のリストを参照して`upgrade`を用いてパッケージの更新を行う.

## NVIDIA Driver のインストール


