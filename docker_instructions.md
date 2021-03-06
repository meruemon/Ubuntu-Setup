# Dockerの使い方

Dockerとはアプリケーションを開発・移動・実行するためのプラットフォームです．1台のパソコンの上に，複数の仮想環境を作成することができます． 他の仮想化技術と比較し，仮想マシンを建てる必要がないので軽量である特徴を持ちます． Dockerで作成された仮想環境を『コンテナ』と呼び，コンテナを作成する際に必要となるファイルが『イメージ』です．イメージは読み込み専用であり，OSやソフトウェアの設定をひとまとめに保存しています．コンテナはイメージから作られ，実行されます．

## よく使うコマンド

|  コマンド  |  内容  |
| ---- | ---- |
|  docker images  |  イメージ一覧を表示  |
|  docker ps |  起動中のコンテナ一覧を表示 |
|  docker ps -a |  停止中のコンテナを含めた一覧を表示 |
|  docker rmi [image name/image id] |  イメージの削除 |
|  docker rm [container name/container id] |  コンテナの削除 |

### イメージをダウンロード

Dockerのレジストリ（NGC）などからイメージをダウンロードする．

```
$ docker pull [image_name]:[tag]
```

### イメージをビルド

`[image_name]`には，任意のイメージ名を指定可能．`[tag]`はバージョンを指定することが多く，未指定の場合は自動的に`latest`となる．

```
$ docker build -t [image_name]:[tag] [path_to_Dockerfile]
# キャッシュを使わずにビルド
# $ docker build --no-cache -t [image_name]:[tag] [path_to_Dockerfile]
```

### イメージからコンテナを作成

```
$ docker run -it --name [container_name] [image_name]:[tag] bash
```

|  オプション  |  説明  |　例 |
| ---- | ---- | ---- |
| --name | コンテナ名を指定 | docker run --name "test" ubuntu | 
| -d	| バッググラウンド実行 | docker run -d ubuntu |
| -it	| 標準入出力モード	| docker run -it --name "test" ubuntu /bin/bash |
| -p host:cont | ポートフォワーディング | docker run -d -p 8080:80 httpd |
| -v | ディレクトリの共有 | docker run -v /c/Users/src:/var/www/html httpd |
| -e | 環境変数を設定 | docker run -it -e foo=bar ubuntu /bin/bash |
| -w | 作業ディレクトリを指定 | docker run -it -w=/tmp/work ubuntu /bin/bash |
| --rm | 停止後コンテナ削除 | docker run --rm -it ubuntu /bin/bash |

ただし，本研究室ではコンテナの作成のほとんどは`docker-compose`を使用する．

### コンテナ操作

|  説明  |  コマンド  | 例（CID=container_id）|
| ---- | ---- | ---- |
| コンテナ一覧 | docker ps [オプション] | docker ps |
| コンテナ確認 | docker stats コンテナID | docker stats CID |
| コンテナ起動 | docker start [オプション] コンテナID | docker start CID |
| コンテナ停止 | docker stop [オプション] コンテナID | docker stop CID |
| コンテナ再起動 | docker restart [オプション] コンテナID | docker restart CID |
| コンテナ削除 | docker rm [オプション] コンテナID | docker rm CID |
| コンテナ中断 | docker pause コンテナID | docker pause CID |
| コンテナ再開 | docker unpause コンテナID | docker unpause CID |

- コンテナを一括削除

```
$ docker rm `docker ps -a -q`
```
- REPOSITORYがnoneのイメージを削除
  
```
$ docker image prune
```

ただし，対象のイメージを使用したコンテナが起動中は削除できない．

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

|  説明  |  コマンド  | 例 |
| ---- | ---- | ---- |
| 元となるイメージ | FROM | FROM ubuntu:latest |
| 作成者 | MAINTAINER | MAINTAINER name |
| 環境変数 | ENV | ENV KEY=VALUE |
| 指定のコマンドの実行 | RUN | RUN apt -y install imagemagick |
| イメージにファイル追加 | ADD | ADD index.html /var/www/html/index.html |
| ポート番号を指定 | EXPOSE |	EXPOSE 8888 |
| コンテナ起動時に実行するコマンド | CMD | CMD jupyter notebook |
| カレントディレクトリを指定 | WORKDIR | WORKDIR /app |

[サンプル](docker/Dockerfile)には，NGCからpullしてきた基礎となるイメージを拡張する例を示してます．
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

`docker_compose.yml`が保存されたディレクトリで，次の`docker-compose up`コマンドを入力するとコンテナが立ちあがります．

```
$ docker-compose up -d
```

`exec`オプションを付けた`docker`コマンドを入力するとコンテナに入ることができます．

```
$ docker exec -it [container_name] bash
```

`docker-compose rm`コマンドを入力するとコンテナが削除されます．`rm`の代わりに`start`や`stop`を入力すると，コンテナの再開・停止を行えます．

```
$ docker-compose rm [stop/start]
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
$ docker build -t example:19.12-py3 ./
...
 ---> 111dc2e23541
Successfully built 111dc2e23541
Successfully tagged example:19.12-py3
```

`Successfully built`まで表示されたら成功．

```
$ docker images
REPOSITORY               TAG         IMAGE ID       CREATED          SIZE
example                  19.12-py3   111dc2e23541   46 seconds ago   9.33GB <-- オリジナルイメージ
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

続いて，コンテナと共有するディレクトリをホームディレクトリに作成する．ここでは，`Programs`を共有ディレクトリに設定する．

```
$ cd ~
$ mkdir Programs
```

よって，`docker-compose.yml`は以下のように書き換える．

```
services:
  dev:
    container_name: example_env <-- 任意の名前
    image: example:19.12-py3 <-- buildしたイメージ名：タグ名を指定
    runtime: nvidia
    command: /bin/bash 
    working_dir: /home/student/Programs <-- 作業ディレクトリをProgramsに指定
    volumes:
        - /tmp/.X11-unix:/tmp/.X11-unix
        - /home/student/Programs:/home/student/Programs <-- ホストとコンテナの共有ディレクトリを指定
```

`docker-compose.yml`があるディレクトリで`docker-compose up`コマンドを使用して，イメージからコンテナを作成する．

```
$ docker-compose up
Creating example_env ... done
Attaching to example_env
example_env | 
example_env | =============
example_env | == PyTorch ==
example_env | =============
example_env | 
example_env | NVIDIA Release 19.12 (build 9142930)
example_env | PyTorch Version 1.4.0a0+a5b4d78
example_env | 
example_env | Container image Copyright (c) 2019, NVIDIA CORPORATION.  All rights reserved.
example_env | 
example_env | Copyright (c) 2014-2019 Facebook Inc.
example_env | Copyright (c) 2011-2014 Idiap Research Institute (Ronan Collobert)
example_env | Copyright (c) 2012-2014 Deepmind Technologies    (Koray Kavukcuoglu)
example_env | Copyright (c) 2011-2012 NEC Laboratories America (Koray Kavukcuoglu)
example_env | Copyright (c) 2011-2013 NYU                      (Clement Farabet)
example_env | Copyright (c) 2006-2010 NEC Laboratories America (Ronan Collobert, Leon Bottou, Iain Melvin, Jason Weston)
example_env | Copyright (c) 2006      Idiap Research Institute (Samy Bengio)
example_env | Copyright (c) 2001-2004 Idiap Research Institute (Ronan Collobert, Samy Bengio, Johnny Mariethoz)
example_env | Copyright (c) 2015      Google Inc.
example_env | Copyright (c) 2015      Yangqing Jia
example_env | Copyright (c) 2013-2016 The Caffe contributors
example_env | All rights reserved.
example_env | 
example_env | Various files include modifications (c) NVIDIA CORPORATION.  All rights reserved.
example_env | NVIDIA modifications are covered by the license terms that apply to the underlying project or file.
example_env | 
example_env | NOTE: MOFED driver for multi-node communication was not detected.
example_env |       Multi-node communication performance may be reduced.
example_env | 
example_env | NOTE: The SHMEM allocation limit is set to the default of 64MB.  This may be
example_env |    insufficient for PyTorch.  NVIDIA recommends the use of the following flags:
example_env |    nvidia-docker run --ipc=host ...
example_env | 
```

`-d`オプションをつけるとバックグラウンドで実行されます．

```
$ docker-compose up -d
Starting example_env ... done
$
```

`-d`オプション無しの場合は端末が占有されるため，ショートカットキー`Ctrl+Shift+t`で端末に新規タブを作成し，`docker`コマンド（`exec`オプション）でコンテナの中に入る．

```
$ docker exec -it example_env bash
student@11720b59b742:~/Programs$
```

ただし，`example_env`は`docker-compose.yml`で設定した`container_name`である．
コンテナの中に入ると端末の表示が，`student@11720b59b742`のように変化する．

Pythonに実行環境は，コンテナの中に作られている．

```
student@11720b59b742:~/Programs$ touch main.py
student@11720b59b742:~/Programs$ vi main.py
print('hello world')
student@11720b59b742:~/Programs$ python main.py
hello world
```

また，自分の計算機でJupyter notebookを起動する場合は，`jupyter notebook`コマンドを入力し，表示されたURL（`http://127.0.0.1:8888/?token=b8852485bf3dede2cf94c57bd8d5bcadf915fb999926b5bd`）のリンクをコピーし，ブラウザにペーストする．

```
student@11720b59b742:~/Programs$ jupyter notebook
[I 14:39:44.834 NotebookApp] Writing notebook server cookie secret to /home/student/.local/share/jupyter/runtime/notebook_cookie_secret
[I 14:39:45.433 NotebookApp] jupyter_tensorboard extension loaded.
[I 14:39:45.460 NotebookApp] JupyterLab extension loaded from /opt/conda/lib/python3.6/site-packages/jupyterlab
[I 14:39:45.460 NotebookApp] JupyterLab application directory is /opt/conda/share/jupyter/lab
[I 14:39:45.462 NotebookApp] [Jupytext Server Extension] NotebookApp.contents_manager_class is (a subclass of) jupytext.TextFileContentsManager already - OK
[I 14:39:45.462 NotebookApp] Serving notebooks from local directory: /home/student/Programs
[I 14:39:45.462 NotebookApp] The Jupyter Notebook is running at:
[I 14:39:45.462 NotebookApp] http://hostname:8888/?token=b8852485bf3dede2cf94c57bd8d5bcadf915fb999926b5bd
[I 14:39:45.462 NotebookApp]  or http://127.0.0.1:8888/?token=b8852485bf3dede2cf94c57bd8d5bcadf915fb999926b5bd
[I 14:39:45.463 NotebookApp] Use Control-C to stop this server and shut down all kernels (twice to skip confirmation).
[C 14:39:45.466 NotebookApp] 
    
    To access the notebook, open this file in a browser:
        file:///home/student/.local/share/jupyter/runtime/nbserver-95-open.html
    Or copy and paste one of these URLs:
        http://hostname:8888/?token=b8852485bf3dede2cf94c57bd8d5bcadf915fb999926b5bd
     or http://127.0.0.1:8888/?token=b8852485bf3dede2cf94c57bd8d5bcadf915fb999926b5bd
```

`jupyter notebook`を終了する場合は，`Ctrl+c`を入力する．

コンテナを抜ける場合は，`Ctrl+d`を入力する．ただし，コンテナは起動したまま（`STATUS`が`Up`）のままである．

```
student@11720b59b742:~/Programs$ exit <-- Ctrl+dを入力
student@IMGPROC-180129:~$ docker ps -a
CONTAINER ID   IMAGE               COMMAND                  CREATED          STATUS                    PORTS                                                 NAMES
11720b59b742   example:19.21-py3   "/usr/local/bin/nvid…"   20 minutes ago   Up 12 minutes             6006/tcp, 0.0.0.0:8888->8888/tcp, :::8888->8888/tcp   example_env
793789db6d50   hello-world         "/hello"                 26 hours ago     Exited (0) 26 hours ago                                                         quirky_blackburn
student@IMGPROC-180129:~$ 
```

コンテナを停止する場合は，`docker-compose up`したタブ開き，`Ctrc+c`を入力する．

```
...
example_env |
Gracefully stopping... (press Ctrl+C again to force)
Stopping example_env ... done
```

コンテナの状態は`Exited`に変化する．

```
$ docker ps -a
CONTAINER ID   IMAGE               COMMAND                  CREATED          STATUS                      PORTS     NAMES
11720b59b742   example:19.21-py3   "/usr/local/bin/nvid…"   22 minutes ago   Exited (0) 59 seconds ago             example_env
793789db6d50   hello-world         "/hello"                 26 hours ago     Exited (0) 26 hours ago               quirky_blackburn
```

もう一度コンテナを起動する場合は，`docker-compose up`コマンドを入力する．また，コンテナを削除する場合は，`docker-compose rm`コマンドを入力する．

```
$ docker-compose rm
Going to remove example_env
Are you sure? [yN] y <-- yを入力
Removing example_env ... done
$ docker ps -a
CONTAINER ID   IMAGE         COMMAND    CREATED        STATUS                    PORTS     NAMES
793789db6d50   hello-world   "/hello"   26 hours ago   Exited (0) 26 hours ago             quirky_blackburn
```

不要なコンテナは`docker rm`コマンドでも直接削除可能．ただし，`Exited`以外の`STATUS`のコンテナは起動中であるため，停止`docker stop [container_id]`した上で削除しなければならない．

```
$ docker rm 793789db6d50
$ docker ps -a
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
```
