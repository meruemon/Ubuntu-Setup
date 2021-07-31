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

[サンプル](docker/Dockerfile)には，NGCからpullしてきた基礎となるイメージを拡張する例を示してます．
OSをセットアップするイメージですので，[ここで](ubuntu_install.md)で説明したことを記述します．
環境変数`USER`と`USER_ID`はそれぞれの環境に合わせて変更します．
`id`コマンドを入力すると自分のユーザ名とIDを確認できます．

```
$ id
uid=1001(student) gid=1001(student) ...
```

## Docker Compose

Docker Composeは，Dockerイメージのビルドや各コンテナの起動・停止などをより簡単に行えるようにするツールです．

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
