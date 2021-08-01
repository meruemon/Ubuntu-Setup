# Dockerの使い方

Dockerとはアプリケーションを開発・移動・実行するためのプラットフォームです．1台のパソコンの上に，複数の仮想環境を作成することができます． 他の仮想化技術と比較し，仮想マシンを建てる必要がないので軽量である特徴を持ちます． Dockerで作成された仮想環境を『コンテナ』と呼び，コンテナを作成する際に必要となるファイルが『イメージ』です．イメージは読み込み専用であり，OSやソフトウェアの設定をひとまとめに保存しています．コンテナはイメージから作られ，実行されます．

## よく使うコマンド

|  コマンド  |  内容  |
| ---- | ---- |
|  docker images  |  イメージ一覧を表示  |
|  docker ps |  起動中のコンテナ一覧を表示 |
|  docker ps -a |  停止中のコンテナを含めた一覧を表示 |
|  docker rmi [image name/image id] |  イメージの削除 |
|  docker rm [container name/container id] |  イメージの削除 |

### イメージをダウンロード

Dockerのレジストリ（NGC）などからイメージをダウンロードしてくる．

```
$ docker pull [image_name]:[tag]
```

### イメージをビルド

`[image_name]`には，任意のイメージ名を指定可能．`[tag]`はバージョンを指定することが多く，未指定の場合は自動的に`latest`となる．

```
$ docker build -t [image_name]:[tag] [path_to_Dockerfile]
```

### イメージからコンテナを作成

```
$ docker run -it --name [container_name] [image_name]:[tag] bash
```

### 起動中のコンテナに入る

```
$ docker exec -it [container_name] bash
```

## Dockerfileの書き方

Dockerfileは，Dockerイメージを作成するための設計図です．

```Dockerfile
FROM [image_name]:[tag]（存在しなければレジストリからダウンロードされる）

RUN Linuxコマンドを実行
# Ex. RUN apt-get update

ENV 環境変数を設定
# Ex. ENV USER student

WORKDIR ワークディレクトリを設定
# Ex. WORKDIR /app
```

[Dockerfile](docker/Dockerfile)には，NGCからpullしてきた基礎となるイメージを拡張する例を示してます．
OSをセットアップするイメージですので，[ここで](ubuntu_install.md)で説明したことを記述します．
環境変数`USER`と`USER_ID`はそれぞれの環境に合わせて変更します．
`id`コマンドを入力すると自分のユーザ名とIDを確認できます．

```
$ id
uid=1001(student) gid=1001(student) groups=1001(student),998(docker)
```

## Docker Compose

Docker Composeは，Dockerイメージのビルドや各コンテナの起動・停止などをより簡単に行えるようにするツールです．[docker_compose.yml](docker/docker_compose.yml)には，コンテナ名やイメージ名，そして，ホストとコンテナとのディレクトリやポートの共有方法を記載します．

```Dockerfile
version: '2.3'
services:
  dev:
    container_name: [container_name] <-- 任意のコンテナ名
    image: [image_name]:[tag] <-- pullあるはbuildしたイメージとタグを指定
    runtime: nvidia
    command: /bin/bash 
    working_dir: /home/student/Programs <-- 起動時のワークディレクトリを指定
    volumes:
        - /tmp/.X11-unix:/tmp/.X11-unix
        - /home/student/Programs:/home/student/Programs　<-- ホストとコンテナのディレクトリを共有
    environment:
        - DISPLAY=$DISPLAY
        - TERM=xterm-256color
    ports:
        - "8888:8888"　<-- ホストとコンテナのポート番号を共有（8888はjupyter notebookのポート番号）
    ulimits:
        memlock: -1
        stack: 67108864
    tty: true
```

`docker_compose.yml`が保存されたディレクトリで，次の`docker-compose`コマンドを入力するとコンテナが立ちあがります．

```
$ docker-compose up
```

一度立ちあがると，その端末は占有されるので，`shift+ctrl+t`で新規タブを開き，`exec`オプションを付けた`docker`コマンドを入力するとコンテナに入ることができます．

```
$ docker exec -it [container_name] bash
```

`rm`オプションを付けて`docker-compose`コマンドを入力するとコンテナが削除されます．

```
$ docker-compose rm
```

## 動作確認

[NGC](https://ngc.nvidia.com/signin)にログインし，`右上名前->Setup->Get API Key->Generate API Key->Confirm`を順にクリックする．

次に，『Usage』に表示されたコマンドを端末に入力する．

```
$ docker login nvcr.io
Username: $oauthtoken <-- 『$oauthtoken』をそのまま入力
Password:  <-- 英数字文字列をコピーしてペースト（何も表示されない）
WARNING! Your password will be stored unencrypted in /home/student/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```

続いて，『Catalog』から実験に必要なDockerイメージをダウンロードする．NGCには，常に最新のイメージが公開されている．CUDAやPytorch・Tensorflowのバージョンなどを[Release Note](https://docs.nvidia.com/deeplearning/frameworks/pytorch-release-notes/overview.html#overview)から確認して，今実行したいソースコードに合うイメージを探す．ここでは，
[19.12-py3](https://docs.nvidia.com/deeplearning/frameworks/pytorch-release-notes/rel_19-12.html#rel_19-12)をダウンロードする例を示す．
イメージのサイズは10GB弱であるため，ある程度時間がかかる．

```
$ docker pull nvcr.io/nvidia/pytorch:19.12-py3
19.12-py3: Pulling from nvidia/pytorch
...
883443701e4c: Pull complete 
Digest: sha256:2eda2bfdfe698a63baf1cab64003f5dcef72f79cbeba80709a53e1159ddeeaf7
Status: Downloaded newer image for nvcr.io/nvidia/pytorch:19.12-py3
nvcr.io/nvidia/pytorch:19.12-py3
```

ダウンロードされたイメージ一覧の表示．

```
$ docker images
REPOSITORY               TAG         IMAGE ID       CREATED         SIZE
hello-world              latest      d1165f221234   4 months ago    13.3kB
nvidia/cuda              11.0-base   2ec708416bb8   11 months ago   122MB
nvcr.io/nvidia/pytorch   19.12-py3   be021446e08c   20 months ago   9.28GB <-- ダウンロードされた
```

まずは，ホームディレクトリに，ディレクトリ`docker/example`を作成し，その中に`Dockerfile`を作成する．
[サンプル](docker/Dockerfile)をコピーし，テキストエディタで開いた`Dockerfile`に貼り付ける．
ここでは，`vi`コマンドでも，GUIのテキストエディタ`gedit`のどちらを用いても良い．

```
$ cd ~
$ mkdir -p docker/example
$ cd docker/example
$ touch Dockerfile
```

ただし，以下の部分は自分の環境にあわせて変更する．

```Dockerfile
##
# User Settings
##
ENV USER student
ENV USER_ID 1001
```

カレントディレクトリにDockerfileがあることを確認してbuildする．ここでは，イメージ名を`example`，タグを`19.12-py3`とした．

```
$ ls
Dockerfile
$ docker build -t example:19.21-py3 ./
...
 ---> 111dc2e23541
Successfully built 111dc2e23541
Successfully tagged example:19.21-py3
```

`Successfully built`まで表示されたら成功．

```
$ docker images
REPOSITORY               TAG         IMAGE ID       CREATED          SIZE
example                  19.21-py3   111dc2e23541   46 seconds ago   9.33GB <-- オリジナルイメージ
hello-world              latest      d1165f221234   4 months ago     13.3kB
nvidia/cuda              11.0-base   2ec708416bb8   11 months ago    122MB
nvcr.io/nvidia/pytorch   19.12-py3   be021446e08c   20 months ago    9.28GB
```

次に，コンテナの立ち上げを行う．`Dockerfile`と同じ場所`docker/example`に`docker-compose.yml`を作成し，
[サンプル](docker/docker-compose.yml)をコピーし，`docker-compose.yml`にペーストする．

```
$ touch docker-compose.yml
$ ls
Dockerfile  docker-compose.yml
```
