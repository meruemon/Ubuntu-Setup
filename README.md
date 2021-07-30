# Ubuntu-Setup

[Ubuntu 20.04.1 LTS 日本語Remix](https://www.ubuntulinux.jp/products/JA-Localized/download)のセットアップ方法を以下に記載する.
OSはインストール時点で最新のLTS (Long Term Support：長期サポート)版を使用する.

実験環境は，[Docker](https://ja.wikipedia.org/wiki/Docker)を前提としているため，インストールするパッケージは必要最低限としている.
OSインストール時にも，『最小インストール』を選択し，適宜パッケージをインストールする.

以降，記載順に設定を行い，管理者権限が必要な操作には，コマンドの先頭に`sudo`を付ける点に注意する.

## Proxy設定

大学からのインターネット接続は全て，Proxyサーバを経由して管理されている.
内部LAN（研究室）からインターネットに接続するために，その宛先であるProxyサーバ情報を登録する.

### 個別ユーザごとに行う全般の設定

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

### apt-getの設定

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
## 初期設定

### ホームディレクトリの英語化

ファイル名やディレクトリ（フォルダ）名が日本語であると不都合な場面が多いため，英語に変換する.

```
$ LANG=C xdg-user-dirs-gtk-update
```

### 時刻設定

```
$ sudo vim /etc/systemd/timesyncd.conf

NTP=ntp.kansai-u.ac.jp

$ sudo systemctl restart systemd-timesyncd.service
$ sudo systemctl -l status systemd-timesyncd
```

## システム更新

```
$ sudo apt update && sudo apt upgrade
```

[apt-getコマンド](https://webkaru.net/linux/apt-get-command/)は，Debian系のディストリビューション（DebianやUbuntu）のパッケージ管理システムであるAPT（Advanced Package Tool）ライブラリを利用してパッケージを操作・管理するコマンドです.

以下に，`apt-get`コマンドの概要を示す.`apt-get`は`apt`と省略可能．

| コマンド|  内容  |
| ---- | ---- |
| `apt-get install [package]` |  パッケージのインストール/更新  |
| `apt-get update`  | パッケージリストの更新  |
| `apt-get upgrade` | インストールされてるパッケージの更新 |
| `apt-get dist-upgrade` | インストールされてるカーネルの更新 |

`update`はパッケージリストが更新されるだけであり，最新のリストを参照して`upgrade`を用いてパッケージの更新を行う.

## NVIDIA Driver のインストール

### PPA の追加

```
$ sudo add-apt-repository ppa:graphics-drivers/ppa
$ sudo apt update
```

### 推奨ドライバの確認

```
$ ubuntu-drivers devices
```

### ドライバのインストール

上記操作で`recommended`と表示されたバージョンのドライバをインストールする.

```
$ sudo apt install nvidia-driver-440
```

※`autoinstall`を使用しても良いが，インストールしたバージョンを意識するために指定する.

`nvidia-smi`コマンドを実行してGPUの情報が表示されれば完了.

## Dockerのインストール

(公式マニュアル)[https://docs.docker.com/engine/install/ubuntu/]を参考にインストールする.

### 依存パッケージのインストール

```
$ sudo apt-get update
$ sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
```

### GPG keyの登録とパッケージリストへの追加

Dockerをパッケージリストに追加し，インストールできるようにする．まずは，GPG keyを追加する.

```
$  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

次に，パッケージリストにDockerを追加する.

```
$ echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

追加したパッケージリストを基に，Dockerをインストールする.

```
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io
```

最後に，Dockerの動作検証を行う.

```
$ sudo docker run hello-world
```
