# Python 開発環境リファレンス

Ubuntu 24.04 における Python 開発環境の構築リファレンスです。  
用途に応じて **Docker 環境** と **venv 環境** を使い分けてください。

---

## 環境の使い分け

| 用途 | 推奨環境 |
|---|---|
| GPU を使う深層学習・PyTorch 実装 | [Docker 環境](#docker-環境) |
| GPU を使わない Python スクリプト | [venv 環境](#venv-環境) |
| データ分析・可視化・軽量なプロトタイピング | [venv 環境](#venv-環境) |

```
GPU あり → Docker (PyTorch + CUDA)
GPU なし → venv  (軽量・シンプル)
```

---

## Docker 環境

**対象**: GPU を使う PyTorch プログラミング

| 項目 | 内容 |
|---|---|
| ベースイメージ | nvcr.io/nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04 |
| PyTorch | 1.13.1+cu117 (CUDA 11.7 対応) |
| 主なライブラリ | numpy, scipy, pandas, scikit-learn, matplotlib など |
| ユーザ管理 | Dockerfile の ARG でホストと同じユーザを定義 |
| 共有ディレクトリ | `./workspace` ↔ コンテナ内 `/workspace` |

### ドキュメント

→ **[Docker 環境リファレンス](./docker-pytorch/README.md)**

### 目次

| # | セクション |
|---|---|
| 1 | Docker とは？ |
| 2 | イメージとコンテナの概念 |
| 3 | Docker のインストール確認 |
| 4 | よく使う Docker コマンド |
| 5 | イメージの取得とビルド |
| 6 | Dockerfile の書き方 |
| 7 | Docker Compose の使い方 |
| 8 | この環境のセットアップ手順 |
| 9 | Jupyter Notebook の起動 |
| 10 | GPU 動作確認 |
| 11 | インストール済みライブラリ一覧 |
| 12 | トラブルシューティング |

---

## venv 環境

**対象**: GPU を使わない簡便な Python コーディング

| 項目 | 内容 |
|---|---|
| OS | Ubuntu 24.04 |
| Python | python-is-python3 で `python` コマンドを python3 に設定 |
| 仮想環境ツール | venv (Python 標準搭載) |
| 主な用途 | データ分析・可視化・軽量スクリプト |

### ドキュメント

→ **[venv 環境リファレンス](./venv_README.md)**

### 目次

| # | セクション |
|---|---|
| 1 | venv とは？ |
| 2 | Python のインストール |
| 3 | venv の基本操作 |
| 4 | 仮想環境へのパッケージインストール |
| 5 | requirements.txt による環境の再現 |
| 6 | 複数プロジェクトの管理 |
| 7 | Jupyter Notebook の使い方 |
| 8 | よく使うコマンド早見表 |
| 9 | トラブルシューティング |

---
