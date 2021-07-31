# Ubuntu-Setup

[Ubuntu 20.04.1 LTS 日本語Remix](https://www.ubuntulinux.jp/products/JA-Localized/download)のセットアップ方法を以下に記載する.
OSはインストール時点で最新のLTS (Long Term Support：長期サポート)版を使用する.

実験環境は，[Docker](https://ja.wikipedia.org/wiki/Docker)を前提としているため，インストールするパッケージは必要最低限としている.
OSインストール時にも，『最小インストール』を選択し，適宜パッケージをインストールする.

以降，『端末』を開いて，記載順に設定を行う．`$`マークに続く入力がコマンド部分を表す．管理者権限が必要な操作には，コマンドの先頭に`sudo`を付ける点に注意する．また，`vi`コマンドを使用して端末からファイル編集を行う.なお，端末はショートカットキー`Ctrl+Alt+t`を入力して開くことができる．

基本的な[操作方法](https://eng-entrance.com/linux-command-vi)を事前に確認する．

必要最低限のviの操作方法
| コマンド|  内容  |
| ---- | ---- |
| `i, a, o` |  入力（インサート）モードに切り替え |
| `Esc`  | コマンドモードに切り替え  |
| `h, l, j, k` | コマンドモード中に左右下上にカーソル移動（矢印キーも使用可） |
| `Esc`+`:w` | 保存 |
| `Esc`+`:q` | 閉じる |
| `Esc`+`:wq` | 保存して閉じる |

あわせて，ターミナル操作のための[よく使うLinuxコマンド](https://www.google.com/search?q=%E3%82%88%E3%81%8F%E4%BD%BF%E3%81%86Linux%E3%82%B3%E3%83%9E%E3%83%B3%E3%83%89&sxsrf=ALeKk01adUXnJjdo8eDpMdjWbD_nk4tVbQ%3A1627643043700&ei=o9wDYeuhKqeQr7wPsvWq4A0&oq=%E3%82%88%E3%81%8F%E4%BD%BF%E3%81%86Linux%E3%82%B3%E3%83%9E%E3%83%B3%E3%83%89&gs_lcp=Cgdnd3Mtd2l6EAMyCwgAEIAEEAQQJRAgSgQIQRgAUNMgWNMgYJsiaABwAngAgAGnAogBggOSAQUxLjAuMZgBAKABAqABAcABAQ&sclient=gws-wiz&ved=0ahUKEwir_8Lr0oryAhUnyIsBHbK6CtwQ4dUDCA8&uact=5)を調べる．

## ■ Proxy設定

大学からのインターネット接続は全て，Proxyサーバを経由して管理されている.
内部LAN（研究室）からインターネットに接続するために，その宛先であるProxyサーバ情報を登録する.

### 個別ユーザごとに行う全般の設定

`vi`コマンドで`.bashrc`を開き，末尾に以下を追記する.

```
$ vi ~/.bashrc
export https_proxy="http://proxy.itc.kansai-u.ac.jp:8080/"
export http_proxy="http://proxy.itc.kansai-u.ac.jp:8080/"
export ftp_proxy="http://proxy.itc.kansai-u.ac.jp:8080/"
```

`wget`コマンドで動作確認を行う.`index.html`にトップページのhtmlが保存される（スクレイピング）．

```
$ wget https://www.yahoo.co.jp | more
```

ウェブブラウザからインターネット接続するためには，設定->ネットワーク->ネットワークプロキシ->手動を順に開き，`HTTPプロキシ`，`HTTPSプロキシ`，`FTPプロキシ`にURL`proxy.itc.kansai-u.ac.jp`とポート番号`8080`をそれぞれ入力する．

### apt-getの設定

`sudo`を付けて，`vi`コマンドで`/etc/apt/apt.conf.d/30proxy`を開き以下を追記する.

```
$ sudo vi /etc/apt/apt.conf.d/30proxy
[sudo] user のパスワード: <- パスワードを入力

Acquire::http { Proxy "http://proxy.itc.kansai-u.ac.jp:8080/"; };
Acquire::https { Proxy "http://proxy.itc.kansai-u.ac.jp:8080/"; };
```

`apt-get`コマンドで動作確認を行う.

```
$ sudo apt-get update
```

### snapの設定

[sanp](https://gihyo.jp/admin/serial/01/ubuntu-recipe/0654)コマンドは[Pycharm](https://www.jetbrains.com/ja-jp/pycharm/)をコマンドラインからインストールする際に利用する．

`sudo`を付けて，`mkdir`コマンドでディレクトリ`/etc/systemd/system/snapd.service.d`を作成する.

```
$ sudo mkdir /etc/systemd/system/snapd.service.d
```

ファイル`http-proxy.conf`を作成し，`echo`コマンドを用いてプロキシ情報を追加する．

```
$ echo '[Service]' | sudo tee -a /etc/systemd/system/snapd.service.d/http-proxy.conf
$ echo 'Environment="HTTP_PROXY=http://proxy.itc.kansai-u.ac.jp:8080/"' | sudo tee -a /etc/systemd/system/snapd.service.d/http-proxy.conf
$ echo 'Environment="HTTPS_PROXY=http://proxy.itc.kansai-u.ac.jp:8080/"' | sudo tee -a /etc/systemd/system/snapd.service.d/http-proxy.conf
```

最後に，snapの設定をリロードする.

```
$ sudo systemctl daemon-reload
$ sudo systemctl restart snapd
```

## ■ 初期設定

### ホームディレクトリの英語化

ファイル名やディレクトリ（フォルダ）名が日本語であると不都合な場面が多いため，英語に変換する.

```
$ LANG=C xdg-user-dirs-gtk-update
Moving DESKTOP directory from デスクトップ to Desktop
Moving DOWNLOAD directory from ダウンロード to Downloads
Moving TEMPLATES directory from テンプレート to Templates
Moving PUBLICSHARE directory from 公開 to Public
Moving DOCUMENTS directory from ドキュメント to Documents
Moving MUSIC directory from ミュージック to Music
Moving PICTURES directory from ピクチャ to Pictures
Moving VIDEOS directory from ビデオ to Videos
```

`Don't ask me this again`にチェックを入れ，`Update Names`をクリックする．

### (Optional) 時刻設定

大学のNTPサーバを利用して，正確な時刻を取得する．

```
$ sudo vi /etc/systemd/timesyncd.conf

NTP=ntp.kansai-u.ac.jp

$ sudo systemctl restart systemd-timesyncd.service
$ sudo systemctl -l status systemd-timesyncd
 systemd-timesyncd.service - Network Time Synchronization
     Loaded: loaded (/lib/systemd/system/systemd-timesyncd.service; enabled; vendor preset: enabled)
     Active: active (running) since Sat 2021-07-31 12:33:14 JST; 6s ago
       Docs: man:systemd-timesyncd.service(8)
   Main PID: 4441 (systemd-timesyn)
     Status: "Initial synchronization to time server 158.217.208.10:123 (ntp.kansai-u.ac.jp)."
      Tasks: 2 (limit: 38237)
     Memory: 1.3M
     CGroup: /system.slice/systemd-timesyncd.service
             └─4441 /lib/systemd/systemd-timesyncd
```

`Active: active (running)`となっていることを確認する．

## ■ システム更新

```
$ sudo apt update && sudo apt upgrade
...
続行しますか? [Y/n] y <- yを入力してエンターを押す
```

[apt-getコマンド](https://webkaru.net/linux/apt-get-command/)は，Debian系のディストリビューション（DebianやUbuntu）のパッケージ管理システムであるAPT（Advanced Package Tool）ライブラリを利用してパッケージを操作・管理するコマンドです.

以下に，`apt-get`コマンドの概要を示す.`apt-get`は`apt`と省略可能．

| コマンド|  内容  |
| ---- | ---- |
| `apt-get install [package]` |  パッケージのインストール/更新  |
| `apt-get update`  | パッケージリストの更新  |
| `apt-get upgrade` | インストールされてるパッケージの更新 |
| `apt-get dist-upgrade` | インストールされてるカーネルの更新（*原則，このコマンドは使用しない*） |

`update`はパッケージリストが更新されるだけであり，最新のリストを参照して`upgrade`を用いてパッケージの更新を行う.

## ■ NVIDIA Driver のインストール

### PPA の追加

プロキシの環境変数を引き継ぐため，`-E`オプションを付けて，`add-apt-repository`コマンドを実行する．

```
$ sudo -E add-apt-repository ppa:graphics-drivers/ppa
...
[ENTER] を押すと続行します。Ctrl-c で追加をキャンセルできます。 <- エンター押す
$ sudo apt update
```

### 推奨ドライバの確認

```
$ ubuntu-drivers devices
WARNING:root:_pkg_get_support nvidia-driver-390: package has invalid Support Legacyheader, cannot determine support level
== /sys/devices/pci0000:00/0000:00:01.0/0000:01:00.0 ==
modalias : pci:v000010DEd00001CB2sv000010DEsd000011BDbc03sc00i00
vendor   : NVIDIA Corporation
model    : GP107GL [Quadro P600] <- 計算機のGPU名が表示
driver   : nvidia-driver-450-server - distro non-free
driver   : nvidia-driver-390 - distro non-free
driver   : nvidia-driver-460-server - distro non-free
driver   : nvidia-driver-470 - distro non-free recommended <- 推薦
driver   : nvidia-driver-418-server - distro non-free
driver   : nvidia-driver-460 - distro non-free
driver   : xserver-xorg-video-nouveau - distro free builtin
```

### ドライバのインストール

上記操作で`recommended`と表示されたバージョンのドライバをインストールする.

```
$ sudo apt install nvidia-driver-470
...
続行しますか? [Y/n] y <- yを入力してエンターを押す
```

ここでは，`autoinstall`を使用しても良いが，インストールしたバージョンを意識するために指定する.

インストールした内容を反映させるため，再起動を行う．

```
sudo reboot
```

再起動後，`nvidia-smi`コマンドを実行してGPUの情報が表示されれば完了.

```
$ nvidia-smi
Sat Jul 31 12:51:47 2021       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 470.57.02    Driver Version: 470.57.02    CUDA Version: 11.4     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  Quadro P600         Off  | 00000000:01:00.0  On |                  N/A |
| 34%   43C    P5    N/A /  N/A |    184MiB /  1998MiB |      3%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
|    0   N/A  N/A       852      G   /usr/lib/xorg/Xorg                 39MiB |
|    0   N/A  N/A      1394      G   /usr/lib/xorg/Xorg                 48MiB |
|    0   N/A  N/A      1522      G   /usr/bin/gnome-shell               88MiB |
+-----------------------------------------------------------------------------+
```

## ■ Dockerのインストール

[公式マニュアル](https://docs.docker.com/engine/install/ubuntu/)に従って，インストールする.

### 依存パッケージのインストール

```
$ sudo apt-get update
$ sudo apt-get install apt-transport-https ca-certificates curl gnupg lsb-release
...
続行しますか? [Y/n] y <- yを入力してエンターを押す
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

### インストールと検証

追加したパッケージリストを基に，Dockerをインストールする.

```
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io
```

### Proxy設定 for Docker

`sudo`を付けて，`mkdir`コマンドでディレクトリ`/etc/systemd/system/docker.service.d`を作成する.

```
$ sudo mkdir /etc/systemd/system/docker.service.d
```

ファイル`http-proxy.conf`を作成し，`echo`コマンドを用いてプロキシ情報を追加する．

```
$ echo '[Service]' | sudo tee -a /etc/systemd/system/docker.service.d/http-proxy.conf
$ echo 'Environment="HTTP_PROXY=http://proxy.itc.kansai-u.ac.jp:8080/"' | sudo tee -a /etc/systemd/system/docker.service.d/http-proxy.conf
$ echo 'Environment="HTTPS_PROXY=http://proxy.itc.kansai-u.ac.jp:8080/"' | sudo tee -a /etc/systemd/system/docker.service.d/http-proxy.conf
```

ファイル`dns.conf`を作成し，`echo`コマンドを用いてDNS情報を追加する．`192.168.170.1`は研究室ルータのIPアドレスを指す．

```
$ echo '[Service]' | sudo tee -a /etc/systemd/system/docker.service.d/dns.conf
$ echo 'Environment="DOCKER_NETWORK_OPTIONS=--dns 192.168.170.1"' | sudo tee -a /etc/systemd/system/Tdocker.service.d/dns.conf
$ echo 'ExecStart=' | sudo tee -a /etc/systemd/system/docker.service.d/dns.conf
$ echo 'ExecStart=/usr/bin/dockerd -H fd:// $DOCKER_NETWORK_OPTIONS' | sudo tee -a /etc/systemd/system/docker.service.d/dns.conf
```

`sudo`を付けて，`vi`コマンドでディレクトリ`/etc/default/docker`にプロキシ情報を追加する.

```
$ sudo vi /etc/default/docker
export http_proxy=http://proxy.itc.kansai-u.ac.jp:8080/
export https_proxy=http://proxy.itc.kansai-u.ac.jp:8080/
```

```
$ sudo systemctl daemon-reload
$ sudo systemctl restart docker
```


最後に，Dockerの動作検証を行う.

```
$ sudo docker run hello-world
Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
b8dfde127a29: Pull complete 
Digest: sha256:df5f5184104426b65967e016ff2ac0bfcd44ad7899ca3bbcf8e44e4461491a9e
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```

## ■ Nvidia Docker

[NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-docker)をインストールして，Dockerの仮想環境でGPUを使用可能とする設定を行う.
ここでも，[公式マニュアル](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html#docker)に従って，インストールする.

`Setting up NVIDIA Container Toolkit`から開始する．まずは，パッケージリストに該当パッケージを追加する．

```
$ distribution=$(. /etc/os-release;echo $ID$VERSION_ID) \
   && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
   && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
```

次に，パッケージリスト更新し，`nvidia-docker2`をインストールする．

```sh
$ sudo apt-get update
$ sudo apt-get install nvidia-docker2
```

最後に，Dockerを再起動して，動作検証を行う．`nvidia-smi`コマンドの実行結果（GPU情報）が表示されたら成功．

```sh
$ sudo systemctl restart docker
$ sudo docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
Unable to find image 'nvidia/cuda:11.0-base' locally
11.0-base: Pulling from nvidia/cuda
54ee1f796a1e: Pull complete 
f7bfea53ad12: Pull complete 
46d371e02073: Pull complete 
b66c17bbf772: Pull complete 
3642f1a6dfb3: Pull complete 
e5ce55b8b4b9: Pull complete 
155bc0332b0a: Pull complete 
Digest: sha256:774ca3d612de15213102c2dbbba55df44dc5cf9870ca2be6c6e9c627fa63d67a
Status: Downloaded newer image for nvidia/cuda:11.0-base
Sat Jul 31 04:00:53 2021       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 470.57.02    Driver Version: 470.57.02    CUDA Version: 11.4     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  Quadro P600         Off  | 00000000:01:00.0  On |                  N/A |
| 34%   46C    P0    N/A /  N/A |    345MiB /  1998MiB |      0%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
+-----------------------------------------------------------------------------+
```

## ■ よく使うソフトウェアのインストール

### Pycharm

Python用の統合環境（IDE）．二つのバージョンCommunity（無料）とProffessional（有料）がある．学生は，Academicライセンスを用いるとJetBrain製品を全て無料で利用できるため，[ここから](https://www.jetbrains.com/ja-jp/community/education/#students)申請することをお勧めする．申請の際は，大学のメールアドレス`***@kansai-u.ac.jp`を使用する．

`sudo`を付け，`snap`コマンドでProffesional版`pycharm-professional`をインストールする．

```
$ sudo snap install pycharm-professional --classic
```

Community版`pycharm-community`も同様の方法でインストールできる．

```
$ sudo snap install pycharm-community --classic
```

### Vim

`vi`の改良版．エディタのデファクトスタンダードの一つ．

```
$ sudo apt install vim
```

### VScode

GUIのテキストエディタ．
[ここから](https://code.visualstudio.com/download)`.deb`をダウンロードする．ファイルは`Downloads`に保存されるため，
端末でディレクトリを移動して，インストールを行う．

```
$ cd Downloads/
$ ls
code_1.58.2-1626302803_amd64.deb
$ sudo dpkg -i code_1.58.2-1626302803_amd64.deb
```

### LibreOffice

Word，Excelなどに代わるオープンソースオフィス．

```
& sudo -E add-apt-repository -n ppa:libreoffice/ppa
& sudo apt-get update 
& sudo apt install libreoffice
```

日本語化

```
$ sudo apt install libreoffice-l10n-ja libreoffice-help-ja 
```

### Google Chrome

```
$ sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list'
$ wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
$ sudo apt update
$ sudo apt install google-chrome-stable
```

### VLC

動画再生

```
$ sudo apt install vlc 
```

## ■ ユーザの追加

以上までの作業は，OSインストール時に作成したユーザで行ってきたが，実験などは，個別のユーザで行う．

`adduser`コマンドでユーザを作成する．任意のユーザ名を入力し，指示に従ってパスワードを入力する.
それ以外は，未入力のままEnterを押してよい．

```
$ sudo adduser 【ユーザ名】
ユーザー `student' を追加しています... <- 【ユーザ名】にstudentを入力した例
新しいグループ `student' (1001) を追加しています...
新しいユーザー `student' (1001) をグループ `student' に追加しています...
ホームディレクトリ `/home/student' を作成しています...
`/etc/skel' からファイルをコピーしています...
新しいパスワード: <- 任意のパスワードを入力（表示されない．誤入力した場合は，複数回BackSpaceを押し，最初から打ち直す）
新しいパスワードを再入力してください: 
passwd: パスワードは正しく更新されました
student のユーザ情報を変更中
新しい値を入力してください。標準設定値を使うならリターンを押してください
	フルネーム []: <- 以降，何も入力しないでエンターを押す
	部屋番号 []: 
	職場電話番号 []: 
	自宅電話番号 []: 
	その他 []: 
以上で正しいですか? [Y/n] y <- yを入力してエンターを押す
```

`gpasswd`コマンドで，作成したユーザを`docker`グループに追加する．

```
$ sudo gpasswd -a 【ユーザ名】 docker
```

コマンドラインからユーザを切り替えて，動作確認を行う．

```
$ su - 【ユーザ名】
パスワード:
```

新規作成したユーザで`docker`コマンドを使用できるか確認する．

```
$ docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi
Sat Jul 31 04:06:35 2021       
+-----------------------------------------------------------------------------+
| NVIDIA-SMI 470.57.02    Driver Version: 470.57.02    CUDA Version: 11.4     |
|-------------------------------+----------------------+----------------------+
| GPU  Name        Persistence-M| Bus-Id        Disp.A | Volatile Uncorr. ECC |
| Fan  Temp  Perf  Pwr:Usage/Cap|         Memory-Usage | GPU-Util  Compute M. |
|                               |                      |               MIG M. |
|===============================+======================+======================|
|   0  Quadro P600         Off  | 00000000:01:00.0  On |                  N/A |
| 34%   40C    P0    N/A /  N/A |    316MiB /  1998MiB |      0%      Default |
|                               |                      |                  N/A |
+-------------------------------+----------------------+----------------------+
                                                                               
+-----------------------------------------------------------------------------+
| Processes:                                                                  |
|  GPU   GI   CI        PID   Type   Process name                  GPU Memory |
|        ID   ID                                                   Usage      |
|=============================================================================|
+-----------------------------------------------------------------------------+
```

再起動し，作成したユーザでログインする．そこで，新たに，『Proxy設定->個別ユーザごとに行う全般の設定』と『初期設定->ホームディレクトリの英語化』を行う．

なお，新規作成したユーザには管理者権限を与えないため，`sudo`コマンドを伴う操作はできない．
