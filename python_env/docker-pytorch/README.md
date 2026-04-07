# PyTorch 1.x Docker 開発環境 (GPU対応)

> このドキュメントは環境構築の手順だけでなく、Docker の基本概念・コマンド・Dockerfile の書き方・Docker Compose の使い方を網羅したリファレンスです。

---

## 目次

1. [Docker とは？](#1-docker-とは)
2. [イメージとコンテナの概念](#2-イメージとコンテナの概念)
3. [Docker のインストール確認](#3-docker-のインストール確認)
4. [よく使う Docker コマンド](#4-よく使う-docker-コマンド)
5. [イメージの取得とビルド](#5-イメージの取得とビルド)
6. [Dockerfile の書き方](#6-dockerfile-の書き方)
7. [Docker Compose の使い方](#7-docker-compose-の使い方)
8. [この環境のセットアップ手順](#8-この環境のセットアップ手順)
9. [Jupyter Notebook の起動](#9-jupyter-notebook-の起動)
10. [GPU 動作確認](#10-gpu-動作確認)
11. [インストール済みライブラリ一覧](#11-インストール済みライブラリ一覧)
12. [トラブルシューティング](#12-トラブルシューティング)

---

## 1. Docker とは？

Docker は **アプリケーションとその実行環境をまとめてパッケージ化** し、どのマシンでも同じように動かすためのプラットフォームです。

### Docker を使うメリット

| 課題 | Docker による解決 |
|---|---|
| 「自分の PC では動くのに他では動かない」 | 環境ごとコンテナに封じ込めるため再現性が高い |
| Python や CUDA のバージョン管理が煩雑 | プロジェクトごとに独立した環境を作れる |
| 環境構築に時間がかかる | Dockerfile に手順を書けば一発で再現できる |
| 環境が壊れた | コンテナを捨てて作り直せば数分で復元できる |

### 仮想マシン (VM) との違い

```
【仮想マシン】
  ホストOS
  └─ ハイパーバイザー
       ├─ ゲストOS (数GB)
       │   └─ アプリ
       └─ ゲストOS (数GB)
           └─ アプリ

【Docker コンテナ】
  ホストOS
  └─ Docker Engine
       ├─ コンテナ (数MB〜数百MB)  ← OSカーネルを共有するため軽量・高速
       └─ コンテナ
```

VM はゲスト OS を丸ごと起動するため重いのに対し、Docker はホスト OS のカーネルを共有するため **起動が数秒** で済み、リソース消費も少ないです。

---

## 2. イメージとコンテナの概念

Docker を理解するうえで最も重要な概念が **イメージ** と **コンテナ** の区別です。

```
イメージ (Image)
  ├─ 設計図・金型のようなもの
  ├─ 読み取り専用 (変更できない)
  ├─ Dockerfile をビルドして作る、または Docker Hub から pull する
  └─ 何度でも同じコンテナを作れる

コンテナ (Container)
  ├─ イメージから起動した実行中の環境
  ├─ 読み書き可能 (ファイルを作ったりコードを実行できる)
  ├─ 停止・削除してもイメージは消えない
  └─ 同じイメージから何個でも起動できる
```

### クラスとインスタンスで例えると

```
イメージ  ≒ クラス定義 (class MyEnv: ...)
コンテナ  ≒ インスタンス (env1 = MyEnv(), env2 = MyEnv())
```

### ライフサイクル

```
Dockerfile
    │  docker build
    ▼
イメージ (Image)
    │  docker run / docker compose up
    ▼
コンテナ (Container) ─── 実行中 (running)
    │                        │
    │  docker stop           │  docker start
    ▼                        ▼
  停止 (stopped)  ──────── 再開
    │
    │  docker rm
    ▼
  削除 (gone)   ※ イメージは残る
```

---

## 3. Docker のインストール確認

```bash
# Docker のバージョン確認
docker --version
# 例: Docker version 25.0.3, build 4debf41

# Docker Compose V2 のバージョン確認
docker compose version
# 例: Docker Compose version v2.24.5

# Docker デーモンが起動しているか確認
docker info

# Hello World コンテナで動作確認
docker run --rm hello-world
```

---

## 4. よく使う Docker コマンド

### 4-1. イメージ操作

```bash
# Docker Hub からイメージを取得 (pull)
docker pull ubuntu:22.04

# ローカルにあるイメージ一覧を表示
docker images
# または
docker image ls

# イメージを削除
docker image rm ubuntu:22.04

# 使っていないイメージをまとめて削除
docker image prune

# イメージの詳細情報を確認
docker image inspect ubuntu:22.04
```

### 4-2. コンテナ操作

```bash
# コンテナを作成して起動 (イメージがなければ自動で pull)
docker run ubuntu:22.04

# よく使うオプション付きで起動
docker run \
  -it \                          # -i: 標準入力を開く, -t: 疑似TTYを割り当て (bash 操作に必要)
  --rm \                         # コンテナ終了時に自動削除
  --name mycontainer \           # コンテナに名前を付ける
  -v /home/user/work:/workspace \# ホストのディレクトリをマウント
  -p 8888:8888 \                 # ホストのポート:コンテナのポート をマッピング
  ubuntu:22.04 \                 # 使用するイメージ
  bash                           # コンテナ内で実行するコマンド

# 起動中のコンテナ一覧
docker ps

# 停止中も含めた全コンテナ一覧
docker ps -a

# 起動中のコンテナに入る
docker exec -it mycontainer bash

# コンテナを停止
docker stop mycontainer

# 停止したコンテナを再起動
docker start mycontainer

# コンテナを削除 (停止後に削除)
docker rm mycontainer

# 起動中のコンテナを強制削除
docker rm -f mycontainer

# 停止中のコンテナをまとめて削除
docker container prune

# コンテナのログを確認
docker logs mycontainer
docker logs -f mycontainer  # リアルタイムで流し続ける

# コンテナの詳細情報
docker inspect mycontainer
```

### 4-3. システム管理

```bash
# Docker が使用しているディスク容量を確認
docker system df

# 不要なイメージ・コンテナ・ネットワーク・キャッシュをまとめて削除
docker system prune

# ボリュームも含めて全削除 (注意: データが消えます)
docker system prune --volumes -a
```

### 4-4. オプション早見表

| オプション | 意味 |
|---|---|
| `-i` | 標準入力を開き続ける |
| `-t` | 疑似TTYを割り当て (ターミナル操作を可能にする) |
| `-it` | 上記2つのセット (bash 起動時に必須) |
| `--rm` | コンテナ終了時に自動削除 |
| `--name` | コンテナに名前を付ける |
| `-v ホスト:コンテナ` | ディレクトリをマウント (共有) |
| `-p ホスト:コンテナ` | ポートをマッピング |
| `-e KEY=VALUE` | 環境変数を設定 |
| `-d` | バックグラウンドで起動 (detach) |
| `--gpus all` | 全 GPU をコンテナに渡す |
| `--user uid:gid` | 実行ユーザを指定 |

---

## 5. イメージの取得とビルド
> ここからの手順説明はリファレンスですので、実行は不要です。実際の作業手順については、[この環境のセットアップ手順](#8-この環境のセットアップ手順)を参照してください。

### 5-1. Docker Hub からイメージを取得する

[Docker Hub](https://hub.docker.com) は公式・サードパーティのイメージが集まるレジストリです。

```bash
# タグ (バージョン) を指定して取得
docker pull python:3.10-slim

# タグを省略すると :latest が取得される
docker pull ubuntu

# NGC (NVIDIA GPU Cloud) レジストリから取得
docker pull nvcr.io/nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04
```

イメージ名の構造:

```
nvcr.io  /  nvidia/cuda  :  11.7.1-cudnn8-devel-ubuntu22.04
  │              │                      │
レジストリ    リポジトリ名             タグ (バージョン)
(省略時は docker.io = Docker Hub)
```

### 5-2. Dockerfile からイメージをビルドする

```bash
# カレントディレクトリの Dockerfile を使ってビルド
docker build -t myimage:1.0 .

# Dockerfile の場所を指定してビルド
docker build -t myimage:1.0 -f /path/to/Dockerfile .

# ビルドキャッシュを使わずにビルド (完全再ビルド)
docker build --no-cache -t myimage:1.0 .
```

`-t` はイメージ名とタグ (バージョン) を指定するオプション、末尾の `.` はビルドコンテキスト (Dockerfile が参照できるディレクトリ) を表します。

---

## 6. Dockerfile の書き方

Dockerfile はイメージの設計図です。上から順に命令が実行され、各命令が **レイヤー** として積み重なります。

### 6-1. 主な命令一覧

| 命令 | 役割 | 例 |
|---|---|---|
| `FROM` | ベースイメージを指定 (必ず最初に書く) | `FROM ubuntu:22.04` |
| `ARG` | ビルド時のみ有効な変数 (ビルド引数) | `ARG USERNAME=yoshida` |
| `RUN` | ビルド時にコマンドを実行 | `RUN apt-get update` |
| `COPY` | ホストのファイルをイメージにコピー | `COPY app.py /app/` |
| `ADD` | COPY の上位互換 (URL・tar も扱える) | `ADD data.tar.gz /data/` |
| `ENV` | 環境変数を設定 | `ENV PYTHONUNBUFFERED=1` |
| `WORKDIR` | 作業ディレクトリを設定 | `WORKDIR /workspace` |
| `USER` | 以降のコマンドを実行するユーザを変更 | `USER yoshida` |
| `EXPOSE` | コンテナが使用するポートを宣言 (情報提供のみ) | `EXPOSE 8888` |
| `CMD` | コンテナ起動時のデフォルトコマンド | `CMD ["bash"]` |
| `ENTRYPOINT` | コンテナの実行コマンドを固定 | `ENTRYPOINT ["python"]` |
| `VOLUME` | マウントポイントを定義 | `VOLUME /data` |

### 6-2. Dockerfile のサンプルと解説

> ⚠️ **このサンプルはあくまで学習用の例です。**  
> 実際のプロジェクトでは要件に応じて内容を変更してください。  
> 本リポジトリと同階層の `examples/` フォルダに用途別のサンプル Dockerfile を用意しています。  
> GitHub: `https://github.com/yourorg/docker-pytorch/tree/main/examples`

```dockerfile
# ① ベースイメージを指定
FROM python:3.10-slim

# ② ビルド引数 (ARG) でユーザ情報を定義
#    Dockerfile を直接編集してホストのユーザ情報に合わせる
#    ホスト側の確認: ターミナルで `id` を実行
ARG USERNAME=yoshida   # ← 自分のユーザ名に変更
ARG USER_UID=1001      # ← id コマンドで確認した uid に変更
ARG USER_GID=1001      # ← id コマンドで確認した gid に変更

# ③ 環境変数を設定
ENV PYTHONUNBUFFERED=1

# ④ システムパッケージをインストール
#    - apt-get update と install は1つの RUN にまとめる (キャッシュ問題対策)
#    - --no-install-recommends で不要パッケージを減らしイメージを軽量化
#    - 最後に apt キャッシュを削除してイメージサイズを削減
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# ⑤ ホストと同じユーザをコンテナ内に作成
RUN groupadd -g ${USER_GID} ${USERNAME} \
    && useradd -m -u ${USER_UID} -g ${USERNAME} -s /bin/bash ${USERNAME}

# ⑥ 作業ディレクトリを設定 (存在しなければ自動作成)
WORKDIR /app

# ⑦ 依存関係ファイルだけ先にコピー & インストール
#    → ソースコードが変わってもこのレイヤーはキャッシュが効く
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ⑧ アプリケーションコードをコピー
COPY . .

# ⑨ 以降の操作を作成したユーザで実行
USER ${USERNAME}

# ⑩ コンテナ起動時に実行するコマンド
CMD ["python", "app.py"]
```

### 6-3. requirements.txt とは？

`requirements.txt` は **Python パッケージの依存関係を記述するファイル** です。  
`pip install` で個別にインストールする代わりに、必要なパッケージとバージョンをまとめて管理できます。

```
# requirements.txt の例
numpy==1.24.4          # バージョン固定 (再現性が高い・推奨)
scipy>=1.10.0          # 最低バージョンを指定
pandas                 # バージョン指定なし (最新が入る)
scikit-learn
matplotlib
```

**インストール方法:**

```bash
# ローカル環境に一括インストール
pip install -r requirements.txt

# Dockerfile 内でインストール (推奨パターン)
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
```

**現在の環境の requirements.txt を生成する:**

```bash
# インストール済みの全パッケージをファイルに書き出す
pip freeze > requirements.txt
```

### 6-4. レイヤーとキャッシュの仕組み

```
FROM python:3.10-slim          ← Layer 1 (ベースイメージ)
RUN apt-get install ...        ← Layer 2
COPY requirements.txt .        ← Layer 3
RUN pip install ...            ← Layer 4
COPY . .                       ← Layer 5 ← ここが変わっても Layer 1〜4 はキャッシュ再利用
CMD [...]                      ← Layer 6
```

**変更が多いものは後ろに書く** のがキャッシュを活かすコツです。  
`requirements.txt` だけ先にコピーしてインストールしておくことで、ソースコード変更時のビルド時間を大幅に短縮できます。

---

## 7. Docker Compose の使い方

### 7-1. Docker Compose とは？

複数のコンテナをまとめて定義・管理するためのツールです。`docker run` の長いオプションを YAML ファイルに書いておくことで、コマンド一発で環境を立ち上げられます。

```
docker run -it --rm --name pytorch \
  -v ./workspace:/workspace \
  -p 8888:8888 \
  --gpus all \
  pytorch1x-gpu-env bash

          ↓ docker-compose.yml に書けば

docker compose up -d
```

### 7-2. docker-compose.yml の構造

```yaml
# サービス (コンテナ) の定義
services:

  # サービス名 (任意)
  サービス名:

    # 使用するイメージ、またはビルド設定
    image: ubuntu:22.04           # 既存イメージを使う場合
    build:                        # Dockerfile からビルドする場合
      context: .                  # Dockerfile があるディレクトリ
      dockerfile: Dockerfile      # Dockerfile のファイル名

    container_name: mycontainer   # コンテナ名

    volumes:
      - ./host/path:/container/path  # ホスト:コンテナ のマウント

    ports:
      - "8888:8888"               # ホスト:コンテナ のポートマッピング

    environment:
      - MY_VAR=hello              # 環境変数

    stdin_open: true              # docker run -i 相当
    tty: true                     # docker run -t 相当

    restart: "no"                 # 再起動ポリシー (no/always/on-failure)

    working_dir: /workspace       # 作業ディレクトリ

    # GPU サポート
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
```

### 7-3. Docker Compose V2 コマンド一覧

> **注意**: 旧来の `docker-compose` (ハイフンあり) は V1 で非推奨です。  
> 現在は `docker compose` (スペース区切り) の V2 を使用します。

```bash
# ─── ビルド ───────────────────────────────────────
# イメージをビルド
docker compose build

# キャッシュを使わずビルド
docker compose build --no-cache

# ─── 起動 ─────────────────────────────────────────
# フォアグラウンドで起動 (ログがターミナルに流れる)
docker compose up

# バックグラウンドで起動
docker compose up -d

# ビルドしてから起動
docker compose up -d --build

# ─── コンテナに入る ────────────────────────────────
# サービス名を指定してコンテナ内で bash を起動
docker compose exec pytorch bash

# ─── 状態確認 ─────────────────────────────────────
# サービスの一覧と状態を確認
docker compose ps

# リアルタイムでログを確認
docker compose logs -f

# 特定サービスのログのみ確認
docker compose logs -f pytorch

# ─── 停止・削除 ────────────────────────────────────
# コンテナを停止 (削除はしない)
docker compose stop

# 停止したコンテナを再起動
docker compose start

# コンテナを停止して削除 (イメージ・ボリュームは残る)
docker compose down

# コンテナ・イメージを削除
docker compose down --rmi local

# コンテナ・イメージ・ボリュームを全削除
docker compose down --rmi local -v
```

### 7-4. 複数サービスの例

```yaml
services:

  # Web アプリ
  web:
    build: ./web
    ports:
      - "5000:5000"
    depends_on:
      - db          # db が起動してから web を起動

  # データベース
  db:
    image: postgres:15
    environment:
      - POSTGRES_PASSWORD=secret
    volumes:
      - db_data:/var/lib/postgresql/data  # 名前付きボリュームでデータ永続化

# 名前付きボリュームの定義
volumes:
  db_data:
```

---

## 8. この環境のセットアップ手順

### 8-1. 環境仕様

| 項目 | 内容 |
|---|---|
| ベースイメージ | nvcr.io/nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04 |
| Python | 3.10 |
| PyTorch | 1.13.1+cu117 (CUDA 11.7) |
| ユーザ | Dockerfile の ARG に定義 (ホストと同じ値を設定) |
| 共有ディレクトリ | `./workspace` ↔ `/workspace` |
| Jupyter ポート | 8888 |

### 8-2. 完成後のディレクトリ構成

```
~/Programs/
└── docker-pytorch/
    ├── Dockerfile            ← GitHub からダウンロード
    ├── docker-compose.yml    ← GitHub からダウンロード
    └── workspace/            ← 手動で作成 (ホストとコンテナの共有領域)
```

### 8-3. ディレクトリの作成

まず作業フォルダを手動で作成します。

```bash
# ① Programs フォルダを Home 直下に作成
mkdir -p ~/Programs

# ② docker-pytorch フォルダを作成して移動
mkdir ~/Programs/docker-pytorch
cd ~/Programs/docker-pytorch

# ③ コンテナとホストの共有ディレクトリを作成
mkdir workspace
```

作成後の確認:

```bash
ls ~/Programs/docker-pytorch/
# workspace/
```

### 8-4. GitHub からファイルをダウンロード

このリポジトリから、`Dockerfile` と `docker-compose.yml` を個別にダウンロードします。  
ダウンロードしたファイルは、`docker-pytorch`の中に保存してください。

ダウンロード後の確認:

```bash
ls -l
# -rw-r--r-- 1 yourname yourname  XXXX  Dockerfile
# -rw-r--r-- 1 yourname yourname  XXXX  docker-compose.yml
# drwxr-xr-x 2 yourname yourname  4096  workspace/
```

### 8-5. ユーザ情報の設定

コンテナ内にホストと同じユーザを作成することで、`workspace/` のファイル権限問題を防ぎます。  
**ビルド前に Dockerfile の先頭部分を自分の情報に書き換えてください。**

```bash
# ① ホスト側のユーザ情報を確認する
id
# 例) uid=1001(yoshida) gid=1001(yoshida)

# ② Dockerfile を開く
# vimは専門性が高いため、ファイルをダブルクリックして直接標準エディタで編集してください。
vim Dockerfile
```

```dockerfile
# Dockerfile の先頭付近にある ARG を自分の情報に書き換える
ARG USERNAME=yoshida   # ← 自分のユーザ名
ARG USER_UID=1001      # ← id コマンドで確認した uid
ARG USER_GID=1001      # ← id コマンドで確認した gid
```

> **なぜ UID を合わせるのか？**  
> ホストとコンテナの UID が一致していないと、`workspace/` 内のファイルが  
> `root` 所有になり、ホスト側から編集できなくなることがあります。

### 8-6. ビルドと起動

```bash
# 作業ディレクトリにいることを確認
cd ~/Programs/docker-pytorch

# ① イメージをビルド (初回のみ。5〜15分かかります)
docker compose build

# ② コンテナをバックグラウンドで起動
docker compose up -d

# ③ 起動状態を確認
docker compose ps
# NAME            IMAGE               STATUS          PORTS
# pytorch1x-gpu   pytorch1x-gpu-env   Up              0.0.0.0:8888->8888/tcp

# ④ コンテナに入る
docker compose exec pytorch bash

# コンテナ内のプロンプトが表示されれば成功
# yourname@<コンテナID>:/workspace$
```

---

## 9. Jupyter Notebook の起動

Jupyter はコンテナ起動時に自動では起動しません。コンテナ内で手動で実行します。

```bash
# ① コンテナに入る
docker compose exec pytorch bash

# ② Jupyter Notebook を起動 (トークンあり・推奨)
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser

# ③ ターミナルに表示される URL をブラウザで開く
#    例: http://127.0.0.1:8888/?token=xxxxxxxxxxxxxxxx
```

トークンなしで起動したい場合 (ローカル開発限定):

```bash
jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token=''
# ブラウザで http://localhost:8888 にアクセス
```

Jupyter を終了するには `Ctrl + C` を2回押します。

---

## 10. GPU 動作確認

コンテナ内で以下の Python コードを実行して GPU が使えるか確認します。

```python
import torch

print("PyTorch バージョン :", torch.__version__)        # 1.13.1+cu117
print("CUDA 使用可能     :", torch.cuda.is_available()) # True
print("GPU 枚数          :", torch.cuda.device_count())
print("GPU 名            :", torch.cuda.get_device_name(0))

# テンソルを GPU に乗せて計算
x = torch.rand(3, 3).cuda()
y = torch.rand(3, 3).cuda()
z = x @ y  # 行列積
print("計算結果デバイス  :", z.device)  # cuda:0
```

---

## 11. インストール済みライブラリ一覧

| カテゴリ | ライブラリ |
|---|---|
| ディープラーニング | torch 1.13.1+cu117, torchvision, torchaudio |
| 数値計算 | numpy, scipy |
| データ処理 | pandas |
| 機械学習 | scikit-learn, optuna |
| 可視化 | matplotlib, seaborn, tensorboard |
| 画像処理 | Pillow, opencv-python-headless |
| ユーティリティ | tqdm, joblib |
| Jupyter | notebook, jupyterlab, ipywidgets |

---

## 12. トラブルシューティング

### `docker compose up` でエラーが出る

```bash
# イメージを再ビルドしてから起動
docker compose up -d --build

# キャッシュをクリアして完全再ビルド
docker compose build --no-cache
docker compose up -d
```

### GPU が認識されない

```bash
# ホスト側で nvidia-smi が動くか確認
nvidia-smi

# Docker から GPU が見えるか確認
docker run --rm --gpus all \
    nvcr.io/nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04 nvidia-smi
```

### ポート 8888 が使用中と言われる

```bash
# 使用中のプロセスを確認
sudo lsof -i :8888

# docker-compose.yml のポート番号を変更する
ports:
  - "8889:8888"   # ホスト側を 8889 に変更
```

### ファイルの権限エラー (workspace 内で書き込めない)

```bash
# Dockerfile の ARG がホスト側の id と一致しているか確認
id

# 一致していればイメージを再ビルド
docker compose build --no-cache
docker compose up -d
```

### コンテナを削除して最初からやり直したい

```bash
# コンテナとイメージをすべて削除
docker compose down --rmi local

# Dockerfile を編集したうえでイメージを再ビルドして起動
docker compose up -d --build
```
