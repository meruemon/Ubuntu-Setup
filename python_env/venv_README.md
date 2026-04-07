# Python 開発環境リファレンス — venv 編 (Ubuntu 24.04)

> **位置づけ**: GPU を使わない簡便な Python コーディングに使用します。  
> GPU を使う PyTorch の実装には Docker 環境を使用してください。→ [Docker 編](./docker-pytorch/README.md)

---

## 目次

1. [venv とは？](#1-venv-とは)
2. [Python のインストール](#2-python-のインストール)
3. [venv の基本操作](#3-venv-の基本操作)
4. [仮想環境へのパッケージインストール](#4-仮想環境へのパッケージインストール)
5. [requirements.txt による環境の再現](#5-requirementstxt-による環境の再現)
6. [複数プロジェクトの管理](#6-複数プロジェクトの管理)
7. [Jupyter Notebook の使い方](#7-jupyter-notebook-の使い方)
8. [よく使うコマンド早見表](#8-よく使うコマンド早見表)
9. [トラブルシューティング](#9-トラブルシューティング)

---

## 1. venv とは？

`venv` は Python に標準搭載されている **仮想環境ツール** です。  
プロジェクトごとに独立した Python 環境を作成し、パッケージのバージョンが他のプロジェクトと衝突しないようにします。

### なぜ仮想環境が必要か？

```
仮想環境なし (システム全体に直接インストール)
  └─ システムの Python
       ├─ プロジェクトA: numpy==1.24  ← バージョンが衝突する！
       └─ プロジェクトB: numpy==1.26  ← どちらか一方しか入れられない

仮想環境あり (プロジェクトごとに独立)
  ├─ 仮想環境A (projectA/)
  │   └─ numpy==1.24  ← 共存できる
  └─ 仮想環境B (projectB/)
      └─ numpy==1.26  ← 共存できる
```

### Docker との使い分け

| 用途 | 推奨環境 |
|---|---|
| GPU を使う深層学習 (PyTorch) | **Docker** |
| GPU を使わない Python スクリプト | **venv** |
| データ分析・可視化 | **venv** |
| 軽量なプロトタイピング | **venv** |

---

## 2. Python のインストール

Ubuntu 24.04 には Python がプリインストールされていないため、まず Python をインストールします。

### 2-1. システムを最新化する

```bash
sudo apt update && sudo apt upgrade -y
```

### 2-2. Python 3 と関連ツールをインストール

```bash
sudo apt install -y \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential
```

| パッケージ | 役割 |
|---|---|
| `python3` | Python 3 本体 |
| `python3-pip` | パッケージマネージャ pip |
| `python3-venv` | 仮想環境モジュール venv |
| `python3-dev` | C拡張モジュールのビルドに必要なヘッダファイル |
| `build-essential` | gcc など C コンパイラ一式 |

### 2-3. python3 をデフォルトの `python` コマンドに設定

Ubuntu 24.04 では `python` コマンドは存在せず、`python3` と打つ必要があります。  
`python` で Python 3 が起動するように設定します。

```bash
# python-is-python3 パッケージをインストール
sudo apt install -y python-is-python3
```

これにより `python` コマンドが `python3` に紐付けられます。

```bash
# 確認
python --version
# Python 3.12.x

python3 --version
# Python 3.12.x

pip --version
# pip XX.X from ... (python 3.12)
```

### 2-4. pip を最新版に更新

```bash
pip install --upgrade pip
```

> **注意**: Ubuntu のシステム Python に直接 pip install すると  
> `error: externally-managed-environment` と表示されることがあります。  
> これはシステムの Python を保護するための Ubuntu 24.04 の仕様です。  
> **パッケージのインストールは必ず後述の仮想環境内で行ってください。**

---

## 3. venv の基本操作

### 3-1. 仮想環境の作成

```bash
# 書式: python -m venv <仮想環境名>
# 慣例として .venv または venv という名前がよく使われる

# プロジェクトディレクトリに移動
mkdir ~/myproject && cd ~/myproject

# 仮想環境を作成
python -m venv .venv
```

実行すると `.venv/` ディレクトリが作成されます。

```
myproject/
└── .venv/
    ├── bin/          ← python, pip などの実行ファイル
    ├── include/
    └── lib/
        └── python3.12/
            └── site-packages/  ← インストールしたパッケージが入る
```

### 3-2. 仮想環境の有効化 (activate)

```bash
source .venv/bin/activate
```

有効化すると、プロンプトの先頭に仮想環境名が表示されます。

```
(.venv) user@hostname:~/myproject$
```

この状態での `python` や `pip` は仮想環境内のものを指します。

```bash
# 仮想環境内の python が使われていることを確認
which python
# /home/user/myproject/.venv/bin/python

python --version
# Python 3.12.x
```

### 3-3. 仮想環境の無効化 (deactivate)

```bash
deactivate
```

プロンプトの先頭の `(.venv)` が消え、システムの Python に戻ります。

### 3-4. 仮想環境の削除

仮想環境は単なるディレクトリです。削除するだけで完全に消えます。

```bash
rm -rf .venv
```

---

## 4. 仮想環境へのパッケージインストール

**必ず仮想環境を有効化してから** `pip install` を実行してください。

```bash
# ① 仮想環境を有効化
source .venv/bin/activate

# ② パッケージをインストール
pip install numpy
pip install pandas matplotlib seaborn

# バージョンを指定してインストール
pip install numpy==1.24.4
pip install "scipy>=1.10.0"

# ③ インストール済みパッケージの一覧を確認
pip list

# ④ 特定パッケージの詳細情報を確認
pip show numpy
```

### よく使う機械学習系パッケージ (CPU版)

```bash
# 数値計算・データ処理
pip install numpy scipy pandas

# 機械学習
pip install scikit-learn

# 可視化
pip install matplotlib seaborn

# Jupyter
pip install jupyter notebook jupyterlab ipywidgets

# ユーティリティ
pip install tqdm joblib

# まとめてインストール
pip install numpy scipy pandas scikit-learn matplotlib seaborn \
            jupyter notebook jupyterlab ipywidgets tqdm joblib
```

---

## 5. requirements.txt による環境の再現

`requirements.txt` はインストールするパッケージとバージョンを記録したファイルです。  
チームメンバーや別のマシンで同じ環境を再現するために使います。

### 5-1. 現在の環境を requirements.txt に書き出す

```bash
# 仮想環境を有効化した状態で実行
pip freeze > requirements.txt

# 内容を確認
cat requirements.txt
# numpy==1.24.4
# pandas==2.1.0
# scipy==1.11.0
# ...
```

### 5-2. requirements.txt からインストールする

```bash
# 新しい仮想環境を作成・有効化してから実行
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 5-3. requirements.txt を手書きする場合

```
# requirements.txt の書き方
numpy==1.24.4       # バージョン完全一致 (再現性重視)
scipy>=1.10.0       # 最低バージョン指定
pandas              # バージョン指定なし (最新版)
matplotlib~=3.7.0   # マイナーバージョン固定 (3.7.x)
```

---

## 6. 複数プロジェクトの管理

プロジェクトごとに仮想環境を作成するのが基本です。

```
~/
├── projectA/
│   ├── .venv/          ← projectA 専用の仮想環境
│   ├── main.py
│   └── requirements.txt
│
├── projectB/
│   ├── .venv/          ← projectB 専用の仮想環境
│   ├── analysis.py
│   └── requirements.txt
│
└── projectC/
    ├── .venv/          ← projectC 専用の仮想環境
    └── ...
```

### プロジェクト開始の定型手順

```bash
# ① プロジェクトディレクトリを作成
mkdir ~/newproject && cd ~/newproject

# ② 仮想環境を作成
python -m venv .venv

# ③ 有効化
source .venv/bin/activate

# ④ 必要なパッケージをインストール
pip install numpy pandas matplotlib

# ⑤ requirements.txt に保存
pip freeze > requirements.txt

# ⑥ 作業...

# ⑦ 作業終了時に無効化
deactivate
```

### .gitignore への追記

仮想環境ディレクトリは Git 管理対象から外すのが慣例です。

```bash
echo ".venv/" >> .gitignore
echo "__pycache__/" >> .gitignore
echo "*.pyc" >> .gitignore
```

---

## 7. Jupyter Notebook の使い方

### 7-1. Jupyter のインストールと起動

```bash
# ① 仮想環境を有効化
source .venv/bin/activate

# ② Jupyter をインストール
pip install jupyter notebook

# ③ Jupyter Notebook を起動
jupyter notebook

# ブラウザが自動で開く。開かない場合は表示された URL をコピーして開く
# 例: http://localhost:8888/?token=xxxxxxxx
```

### 7-2. 仮想環境を Jupyter のカーネルとして登録する

複数の仮想環境を Jupyter から切り替えて使う場合、各環境をカーネルとして登録します。

```bash
# ① 登録したい仮想環境を有効化
source ~/projectA/.venv/bin/activate

# ② ipykernel をインストール
pip install ipykernel

# ③ カーネルとして登録 (--name と --display-name は任意の名前)
python -m ipykernel install --user --name projectA --display-name "Python (projectA)"

# ④ 登録済みカーネルの一覧を確認
jupyter kernelspec list
```

以降は Jupyter Notebook の右上「Kernel」メニューから `Python (projectA)` を選択できます。

### 7-3. カーネルの削除

```bash
jupyter kernelspec remove projectA
```

---

## 8. よく使うコマンド早見表

### venv コマンド

| 操作 | コマンド |
|---|---|
| 仮想環境を作成 | `python -m venv .venv` |
| 仮想環境を有効化 | `source .venv/bin/activate` |
| 仮想環境を無効化 | `deactivate` |
| 仮想環境を削除 | `rm -rf .venv` |

### pip コマンド

| 操作 | コマンド |
|---|---|
| パッケージをインストール | `pip install パッケージ名` |
| バージョン指定でインストール | `pip install numpy==1.24.4` |
| requirements.txt からインストール | `pip install -r requirements.txt` |
| パッケージをアンインストール | `pip uninstall パッケージ名` |
| インストール済み一覧を表示 | `pip list` |
| 現在の環境を requirements.txt に出力 | `pip freeze > requirements.txt` |
| パッケージの詳細を表示 | `pip show パッケージ名` |
| pip 自体を更新 | `pip install --upgrade pip` |
| アップデート可能なパッケージを確認 | `pip list --outdated` |

### Python バージョン確認

```bash
python --version     # python-is-python3 設定後
python3 --version    # 常に使用可能
pip --version
which python         # 使用されている python のパスを確認
```

---

## 9. トラブルシューティング

### `python` コマンドが見つからない

```bash
# python-is-python3 が未インストールの場合
sudo apt install -y python-is-python3

# または python3 を直接使う
python3 -m venv .venv
```

### `pip install` で `externally-managed-environment` エラーが出る

Ubuntu 24.04 ではシステムの Python を保護するため、直接の pip install が制限されています。  
**仮想環境内で実行するのが正しい方法です。**

```bash
# 仮想環境を有効化してから pip install する
source .venv/bin/activate
pip install numpy   # ← これは OK
```

### 仮想環境を有効化し忘れてインストールした

```bash
# 仮想環境を作り直して正しくインストールし直す
deactivate          # 念のため無効化
rm -rf .venv        # 仮想環境を削除
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### `source .venv/bin/activate` を毎回打つのが面倒

プロジェクトディレクトリに入ったとき自動で有効化する設定を `.bashrc` に追加できます。

```bash
# ~/.bashrc に追記
cat >> ~/.bashrc << 'EOF'

# カレントディレクトリに .venv があれば自動で有効化
auto_activate_venv() {
    if [ -f ".venv/bin/activate" ]; then
        source .venv/bin/activate
    fi
}
cd() { builtin cd "$@" && auto_activate_venv; }
EOF

source ~/.bashrc
```

### パッケージのインストールが遅い

PyPI ミラーを国内サーバに切り替えると速くなる場合があります。

```bash
# JAIST ミラーを使用する例
pip install numpy -i https://pypi.org/simple/
```
