# Ubuntu 24.04 インストールと初期設定ガイド

> Ubuntu 24.04 LTS（開発コードネーム: Noble Numbat）のインストール手順と初期設定を解説する。  
> 本バージョンは **2029年5月まで標準サポート**、Ubuntu Pro により **2034年4月まで拡張セキュリティ保守**、Legacy add-on により **2039年4月まで延長可能（最大15年間）** である。
>
> 実験環境は [Docker](https://ja.wikipedia.org/wiki/Docker) を前提としているため、ホストにインストールするソフトウェアは必要最小限とする。Python や PyTorch などの開発環境はホストに直接入れず、[Python 環境構築](python_env/INDEX.md) に従ってコンテナまたは仮想環境の中に作る。

---

## 目次

1. [Ubuntu 24.04 の基本情報](#1-ubuntu-2404-の基本情報)
2. [インストール前の準備](#2-インストール前の準備)
3. [ISOダウンロードとインストールメディアの作成](#3-isoダウンロードとインストールメディアの作成)
4. [インストール手順](#4-インストール手順)
5. [初期設定](#5-初期設定)
   - [5-1. プロキシ設定](#5-1-プロキシ設定)
   - [5-2. システムの更新](#5-2-システムの更新)
   - [5-3. 個人ユーザーの追加](#5-3-個人ユーザーの追加)
   - [5-4. sudo（管理者権限）について](#5-4-sudo管理者権限について)
   - [5-5. ホームディレクトリの英語化](#5-5-ホームディレクトリの英語化)
   - [5-6. ネットワーク設定の確認（DHCP）](#5-6-ネットワーク設定の確認dhcp)
   - [5-7. ファイアウォールの設定（ufw）](#5-7-ファイアウォールの設定ufw)
   - [5-8. 日時設定（NTP）](#5-8-日時設定ntp)
   - [5-9. 日本語入力の設定](#5-9-日本語入力の設定)
   - [5-10. NVIDIAグラフィックドライバの設定](#5-10-nvidiaグラフィックドライバの設定)
   - [5-11. Docker のインストール](#5-11-docker-のインストール)
   - [5-12. SSD向け推奨設定](#5-12-ssd向け推奨設定)
   - [5-13. ソフトウェアのインストール](#5-13-ソフトウェアのインストール)
   - [5-14. OpenSSH サーバの設定](#5-14-openssh-サーバの設定)
6. [トラブルシューティング](#6-トラブルシューティング)
7. [次のステップ](#7-次のステップ)
8. [付録](#8-付録)
   - [8-1. よく使う Linux コマンド](#8-1-よく使う-linux-コマンド)
   - [8-2. vi の基本操作](#8-2-vi-の基本操作)

---

## 1. Ubuntu 24.04 の基本情報

| 項目 | 内容 |
|------|------|
| バージョン | Ubuntu 24.04 LTS（Noble Numbat） |
| リリース | 2024年4月 |
| 標準サポート | 2029年5月まで（5年間） |
| 拡張サポート（Ubuntu Pro） | 2034年4月まで（10年間） |
| 最大延長（Legacy add-on） | 2039年4月まで（15年間） |
| イメージサイズ | 約5.7GB（デスクトップ版） |
| 公式サイト | https://jp.ubuntu.com/download |
| 公式リリースページ | https://releases.ubuntu.com/noble/ |

### LTS版と通常リリースの比較

| 種別 | リリース頻度 | サポート期間 | 用途 |
|------|------------|------------|------|
| **LTS版** | 2年ごと（4月） | 標準5年（Ubuntu Pro利用で最大15年） | 本番環境・企業・長期プロジェクト |
| **通常リリース** | 6か月ごと | 9か月 | 最新機能を求める開発者向け |

### 本リポジトリの補助スクリプト

初期設定の一部は、本リポジトリのシェルスクリプトで自動化している。いずれも管理アカウント `hpc` で実行する。

| スクリプト | 内容 | 使用する節 |
|-----------|------|-----------|
| [proxy_setup.sh](proxy_setup.sh) | 学内プロキシの設定（シェル・curl・sudo・apt） | [5-1](#5-1-プロキシ設定) |
| [docker_install.sh](docker_install.sh) | Docker Engine・Docker Compose・NVIDIA Container Toolkit のインストール | [5-11](#5-11-docker-のインストール) |
| [software_install.sh](software_install.sh) | Google Chrome・VS Code・LibreOffice・htop・TeamViewer・Slack のインストール | [5-13](#5-13-ソフトウェアのインストール) |

---

## 2. インストール前の準備

### 推奨する事前準備

- インストールメディア（USBメモリ）の作成
- ノートPCの場合はACアダプタを接続
- インターネット接続環境の確保

### ネットワーク設定

ネットワーク接続には **DHCP**（自動取得）を使用する。ルーターが IPアドレス・ネットマスク・デフォルトゲートウェイ・DNS サーバーを自動的に割り当てるため、追加設定は不要である。

> 大学からのインターネット接続はすべて **プロキシサーバ** を経由する。インストール直後は外部に接続できないため、初期設定の最初にプロキシを設定する（→ [5-1. プロキシ設定](#5-1-プロキシ設定)）。大学以外の環境、およびプロキシを経由しない一部の部屋ではこの設定は不要である。

---

## 3. ISOダウンロードとインストールメディアの作成

### ISOイメージのダウンロード

1. 以下のいずれかからダウンロードする
   - **公式リリースページ**: https://releases.ubuntu.com/noble/
   - **ミラーサイトポータル**: https://launchpad.net/ubuntu/+cdmirrors
2. 日本国内の HTTPS 対応ミラーサイトを選択すると速度が向上することがある
3. デスクトップ版の ISO（`ubuntu-24.04.x-desktop-amd64.iso`）を選択してダウンロード

> ダウンロードが途中で失敗した場合は、別のミラーサイトを試す。

### インストールメディアの作成

#### Windows（Rufus を使用）

1. [Rufus](https://rufus.ie/) をダウンロードして起動する
2. 以下の設定を行う

| 設定項目 | 推奨値 |
|---------|--------|
| デバイス | 使用するUSBメモリを選択 |
| ブートの種類 | ダウンロードしたUbuntu ISOファイル |
| パーティション構成 | GPT（UEFI対応PC）/ MBR（旧BIOS専用PC） |
| ファイルシステム | FAT32 |

3. 「スタート」をクリック  
   ⚠️ **USBメモリ内のデータはすべて消去される。**

#### macOS / Linux（balenaEtcher を使用）

1. [balenaEtcher](https://www.balena.io/etcher/) をダウンロードして起動する
2. ISOファイルを選択し、対象のUSBメモリに書き込む

---

## 4. インストール手順

### 4-1. USBメモリから起動する

1. 作成した起動可能なUSBメモリをPCに挿入し、起動または再起動する
2. 起動時に特定のキー（**F2 / F10 / F12 / Del / Esc** など。PCメーカーにより異なる）を押してブートメニューまたはBIOS/UEFI設定画面を開く。当研究室の計算機はF11でブートメニューが開く
3. USBデバイスを起動順序の最優先（一番上）に設定して再起動する
4. 起動メニューで **「Ubuntu（safe graphics）」** を選択する

### 4-2. 言語・キーボード・アクセシビリティの設定

1. システム言語として **「日本語」** を選択し、「Next」をクリック
2. （不要）アクセシビリティ設定画面で必要な支援機能を選択し、「Next」をクリック
3. 使用するキーボードレイアウト（例: 日本語）を選択し、「Next」をクリック

### 4-3. インターネット接続の設定

- 有線LANまたはWi-Fiで接続すると、インストール中に最新の更新プログラムやドライバをダウンロードできる
- 学内ネットワークではプロキシ設定が済むまで外部に接続できない。更新はインストール後に行うため、そのまま進めてよい（→ [5-2. システムの更新](#5-2-システムの更新)）

### 4-4. インストール方式の選択

1. **「Ubuntuをインストール」** を選択し、「Next」をクリック
2. **「対話式インストール」** を選択し、「Next」をクリック
3. システム設定は通常 **「既定の設定」** で十分
4. プロプライエタリドライバ（NVIDIAグラフィックドライバなど）のインストールは選択しない

### 4-5. ディスクパーティションの設定

「**ディスクを削除してUbuntuをインストール**」を選択し、「Next」をクリックする。

### 4-6. ユーザーアカウントの設定（管理アカウント）

インストール時には、システム全体を管理する**管理アカウント**を作成する。個人ユーザーの追加はインストール完了後に管理アカウントでログインしてから行う（→ [5-3. 個人ユーザーの追加](#5-3-個人ユーザーの追加)）。

以下を入力し、「Next」をクリックする。

| 入力項目 | 設定値 | 備考 |
|---------|--------|------|
| あなたの名前（フルネーム） | `HPC Admin`（任意） | 表示名 |
| コンピュータの名前 | 指示された名前（例: `R81`） | ネットワーク上の識別名 |
| ユーザー名 | **`hpc`** | 管理アカウントのログイン名 |
| パスワード | （指示された文字列） | 確認のため2回入力。推測されにくいものを設定 |

> **管理アカウント（hpc）の役割と運用方針**
> - インストール直後から `sudo` コマンドで管理者権限を行使できる
> - **`sudo` を伴うすべての管理作業（システム更新・パッケージ導入・設定変更・ユーザー管理など）は `hpc` で行う**
> - 個人ユーザーには `sudo` 権限を付与しない。日常作業は個人ユーザーアカウントで行い、管理アカウントは管理作業専用とする

### 4-7. タイムゾーンの設定

地図をクリックするか、入力欄に都市名（例: `Tokyo`）を入力して **Asia/Tokyo** を選択する。

### 4-8. インストールの実行と再起動

1. 設定内容を確認し、「**インストール**」をクリックする
2. インストール完了まで待機する（通常10〜30分）。**この間、電源を切らないこと。**
3. 完了後、「**今すぐ再起動する**」をクリックする
4. 「Please remove the installation medium, then press ENTER」が表示されたらUSBメモリを取り外し、Enterキーを押す

### 4-9. 初回ログイン

- 管理アカウント **`hpc`** のパスワードでログインする
- 初回ログイン時にセットアップウィザードが表示される場合がある（スキップも可能）
- ログイン後、学内ネットワークではまずプロキシを設定し（→ [5-1](#5-1-プロキシ設定)）、続けてシステムの更新（→ [5-2](#5-2-システムの更新)）と個人ユーザーの追加（→ [5-3](#5-3-個人ユーザーの追加)）を行う

---

## 5. 初期設定

以降は『端末』を開いて、記載順に設定を行う。端末はショートカットキー `Ctrl+Alt+T` で開くことができる。端末の操作に慣れていない場合は、先に [8. 付録](#8-付録) を参照する。

特に断りがない限り、本章の作業は管理アカウント **`hpc`** で行う。

### 5-1. プロキシ設定

大学からのインターネット接続はすべてプロキシサーバを経由して管理されている。内部LAN（研究室）からインターネットに接続するために、その宛先であるプロキシサーバ情報を登録する。**大学以外の環境（あるいはプロキシサーバを経由しない一部の部屋）では、本節の設定は不要である。**

| 項目 | 値 |
|------|-----|
| プロキシサーバ | `proxy.itc.kansai-u.ac.jp` |
| ポート番号 | `8080` |

#### 管理アカウントでの設定（proxy_setup.sh）

[proxy_setup.sh](proxy_setup.sh) をダウンロードして実行する。

```bash
# スクリプトをダウンロード（この時点ではプロキシ未設定のため -e オプションで直接指定する）
wget -e https_proxy=http://proxy.itc.kansai-u.ac.jp:8080/ \
    https://raw.githubusercontent.com/meruemon/Ubuntu-Setup/main/proxy_setup.sh

# 実行（途中で sudo のパスワードを求められる）
bash proxy_setup.sh

# 設定を現在の端末に反映
source ~/.bashrc
```

スクリプトが行う設定は以下のとおりである。

| 設定先 | 内容 |
|--------|------|
| `~/.bashrc` | 環境変数 `http_proxy` / `https_proxy` / `ftp_proxy` を追記 |
| `~/.curlrc` | `curl` コマンドのプロキシ設定 |
| `/etc/sudoers.d/proxy` | `sudo` 実行時にプロキシの環境変数を引き継ぐ設定 |
| `/etc/apt/apt.conf.d/30proxy` | `apt` コマンドのプロキシ設定 |

> - スクリプトは `~/.bashrc` に追記するため、**実行は1回だけ**とする
> - スクリプト内の「aptリポジトリをrikenに変更」の処理は、リポジトリ定義の場所が `/etc/apt/sources.list.d/ubuntu.sources` に移った Ubuntu 24.04 では反映されず、`sed` のエラーが表示される。他の設定には影響しないため、そのまま進めてよい

動作確認を行う。

```bash
# トップページの HTML が index.html として保存されれば成功
wget https://www.ubuntu.com/
rm index.html

# パッケージリストを取得できれば成功
sudo apt update
```

#### snap の設定

App Center や `snap` コマンドでソフトウェアをインストールするために、snap にもプロキシを設定する。

```bash
sudo snap set system proxy.http="http://proxy.itc.kansai-u.ac.jp:8080/"
sudo snap set system proxy.https="http://proxy.itc.kansai-u.ac.jp:8080/"
```

#### ウェブブラウザの設定

ウェブブラウザからインターネットに接続するために、「設定」→「ネットワーク」→「プロキシ」を開いて「手動」を選択し、`HTTP プロキシ` と `HTTPS プロキシ` に URL `proxy.itc.kansai-u.ac.jp` とポート番号 `8080` をそれぞれ入力する。

#### 個人ユーザーでの設定

`~/.bashrc`・`~/.curlrc`・ウェブブラウザの設定はユーザーごとに必要である。個人ユーザーは `sudo` を使えず `proxy_setup.sh` を実行できないため、**個人ユーザーでログインした状態で**以下を実行する。

```bash
# ~/.bashrc の末尾にプロキシ設定を追記（実行は1回だけ）
cat >> ~/.bashrc << 'EOF'
# Proxy settings
export https_proxy="http://proxy.itc.kansai-u.ac.jp:8080/"
export http_proxy="http://proxy.itc.kansai-u.ac.jp:8080/"
export ftp_proxy="http://proxy.itc.kansai-u.ac.jp:8080/"
EOF

# curl のプロキシ設定
echo 'proxy=http://proxy.itc.kansai-u.ac.jp:8080/' > ~/.curlrc

# 設定を現在の端末に反映
source ~/.bashrc
```

あわせて、上記「ウェブブラウザの設定」も個人ユーザーで行う。

---

### 5-2. システムの更新

管理アカウント **`hpc`** でログインした後、システムを最新の状態にする。

```bash
# パッケージリストを更新
sudo apt update

# インストール済みパッケージを更新
sudo apt full-upgrade

# 不要なパッケージの削除
sudo apt autoremove

# 古いキャッシュの削除
sudo apt autoclean
```

> カーネルが更新された場合は再起動が必要:
> ```bash
> sudo shutdown -r now
> ```

`apt` は、Debian 系のディストリビューション（Debian や Ubuntu）のパッケージ管理システム APT（Advanced Package Tool）を操作するコマンドである。`update` はパッケージリストを更新するだけであり、更新されたリストを参照して `full-upgrade` がパッケージ本体を更新する。

---

### 5-3. 個人ユーザーの追加

**管理アカウント（`hpc`）でログインした状態**で、以下の手順で個人ユーザーを追加する。プログラミングや実験は、管理アカウントではなく個人ユーザーで行う。

> **権限ポリシー**
> - 個人ユーザーには **`sudo` 権限を付与しない**
> - `sudo` を伴う管理作業はすべて管理アカウント `hpc` で行う
> - 個人ユーザーは自身のホームディレクトリ配下での作業のみ行う

#### コマンドラインでの追加（推奨）

```bash
# 新しい個人ユーザーを作成する（例: ユーザー名 yoshida）
# ※ sudo グループには追加しない
sudo adduser yoshida
```

実行すると対話形式で以下の入力が求められる:

| 入力項目 | 内容 |
|---------|------|
| New password | 新しいパスワード（2回入力） |
| Full Name | フルネーム（任意） |
| その他（Room Number 等） | 任意。空欄のままEnterで進む |

#### ユーザーの確認・管理

以下の作業はすべて管理アカウント（`hpc`）で行う。

```bash
# 登録済みユーザーの一覧を確認
cat /etc/passwd | grep -v "nologin\|false" | cut -d: -f1

# 特定ユーザーの情報（グループ所属など）を確認（例: yoshida）
id yoshida

# ユーザーを削除する場合（ホームディレクトリも同時削除）
sudo deluser --remove-home yoshida
```

`id yoshida` の出力例（正常な個人ユーザー）:
```
uid=1001(yoshida) gid=1001(yoshida) groups=1001(yoshida)
```
`sudo` グループが含まれていないことを確認する。

> Docker を使用する個人ユーザーは、Docker のインストール後に `docker` グループへ追加する（→ [5-11. Docker のインストール](#5-11-docker-のインストール)）。

#### 個人ユーザーへの切り替え

```bash
# 管理アカウントから個人ユーザーへ切り替え（例: yoshida）
su - yoshida

# 作業終了後、管理アカウントに戻る
exit
```

または、一度ログアウトして個人ユーザーアカウントで直接ログインする。

#### 個人ユーザーが初回ログイン時に行う設定

以下の設定はユーザーごとに保存されるため、個人ユーザーでログインしてから各自で行う。いずれも `sudo` は不要である。

| 設定 | 参照先 |
|------|--------|
| プロキシ設定（学内ネットワークのみ） | [5-1. プロキシ設定 — 個人ユーザーでの設定](#個人ユーザーでの設定) |
| ホームディレクトリの英語化 | [5-5. ホームディレクトリの英語化](#5-5-ホームディレクトリの英語化) |
| 日本語入力ソースの追加 | [5-9. 日本語入力の設定](#5-9-日本語入力の設定) |

---

### 5-4. sudo（管理者権限）について

`sudo` を伴う管理作業は**すべて管理アカウント `hpc` で行う**。個人ユーザーは `sudo` 権限を持たないため、システム設定の変更やパッケージのインストールは行えない。

```bash
# 管理アカウント hpc でのコマンド例
sudo apt update
sudo systemctl restart ssh
```

- デフォルトでは root アカウントへの直接ログインは無効。管理作業は `sudo` 経由で行う
- `sudo` 実行時はパスワードが求められる（入力中は文字が表示されない）
- `sudo` を実行できるのは `sudo` グループに属するユーザーのみ。`hpc` のみがこのグループに属する

### 5-5. ホームディレクトリの英語化

日本語でインストールすると、ホームディレクトリ直下のフォルダ名（デスクトップ、ダウンロードなど）が日本語になる。ファイル名やディレクトリ名が日本語であると端末での操作に不都合な場面が多いため、英語に変換する。**この設定はユーザーごとに必要である**（管理アカウント・個人ユーザーのそれぞれで実行する）。

```bash
LANG=C xdg-user-dirs-gtk-update
```

確認ダイアログが表示されるので、`Don't ask me this again` にチェックを入れ、`Update Names` をクリックする。

```bash
# Desktop, Documents, Downloads などに変わっていることを確認
ls ~
```

### 5-6. ネットワーク設定の確認（DHCP）

ネットワーク接続には DHCP を使用する。インストール時に自動設定されているため、通常は追加設定不要である。以下の手順で設定を確認する。

1. デスクトップ右上のシステムメニュー →「設定」→「ネットワーク」を開く
2. 設定対象の接続の歯車アイコンをクリックする
3. 「IPv4設定」タブを開き、「IPv4メソッド」が **「自動(DHCP)」** になっていることを確認する

```bash
# 現在取得しているIPアドレスをコマンドで確認する
ip a
```

### 5-7. ファイアウォールの設定（ufw）

```bash
# SSH接続を許可（リモート接続している場合は先に実行）
sudo ufw allow ssh
```

> ⚠️ SSHでリモート接続中の場合、`sudo ufw allow ssh` を**先に**実行してからファイアウォールを有効化すること。順序を守らないと接続が切断される。ファイアウォールの有効化は [5-14. OpenSSH サーバの設定](#5-14-openssh-サーバの設定) で行う。

### 5-8. 日時設定（NTP）

```bash
# 現在の日時確認
date
timedatectl

# NTPによる自動同期を有効化
sudo timedatectl set-ntp true

# NICTのNTPサーバーを指定（日本国内推奨）
echo -e "[Time]\nNTP=ntp.nict.jp" | sudo tee /etc/systemd/timesyncd.conf

# 設定を反映
sudo systemctl restart systemd-timesyncd

# 同期状態を確認
timedatectl timesync-status
```

> 学内ネットワークで NICT のサーバーと同期できない場合は、`ntp.nict.jp` の代わりに大学の NTP サーバー `ntp.kansai-u.ac.jp` を指定する。

### 5-9. 日本語入力の設定

iBus と Mozc を使用する。パッケージのインストールは管理アカウント `hpc` で行う。

```bash
# iBusとMozcをインストール
sudo apt update
sudo apt install ibus-mozc

# iBusを再起動
ibus restart
```

入力ソースの追加はユーザーごとに行う:

1. 「設定」→「キーボード」を開く
2. 「入力ソース」の「+」ボタンをクリック
3. 「日本語」→「日本語(Mozc)」を追加する
4. **Super+スペース** キーで入力ソースを切り替える

> 設定後は一度ログアウト・ログインすると確実に反映される。

### 5-10. NVIDIAグラフィックドライバの設定

nouveau（オープンソース版ドライバ）を無効化する。

```bash
sudo bash -c "echo 'blacklist nouveau' > /etc/modprobe.d/blacklist-nouveau.conf"
sudo bash -c "echo 'options nouveau modeset=0' >> /etc/modprobe.d/blacklist-nouveau.conf"
sudo update-initramfs -u
sudo reboot
```

再起動後、NVIDIA ドライバをインストールする。

```bash
# 利用可能なNVIDIAドライバを確認
sudo ubuntu-drivers list

# 推奨ドライバを自動インストール
sudo ubuntu-drivers install

# または特定バージョンを指定
# sudo ubuntu-drivers install nvidia:535

# 再起動
sudo reboot

# インストール確認
nvidia-smi
```

`nvidia-smi` コマンドを実行して、ドライバのバージョンと GPU の情報が表示されれば完了である。

### 5-11. Docker のインストール

[docker_install.sh](docker_install.sh) をダウンロードして実行する。NVIDIA Container Toolkit を含むため、[5-10. NVIDIAグラフィックドライバの設定](#5-10-nvidiaグラフィックドライバの設定) を済ませてから行う。

```bash
wget https://raw.githubusercontent.com/meruemon/Ubuntu-Setup/main/docker_install.sh
bash docker_install.sh
```

スクリプトが行う内容は以下のとおりである。

| 内容 | 説明 |
|------|------|
| Docker Engine のインストール | [公式手順](https://docs.docker.com/engine/install/ubuntu/)に従い、Docker 公式リポジトリから `docker-ce` などをインストール |
| Docker Compose のインストール | `docker-compose-plugin`（V2）。コマンドは `docker compose`（スペース区切り）で、旧来の `docker-compose` は使用しない |
| プロキシ設定 | Docker デーモンがイメージを取得する際に学内プロキシを経由する設定（`/etc/systemd/system/docker.service.d/http-proxy.conf`） |
| DNS 設定 | コンテナが使用する DNS サーバーの設定（`/etc/systemd/system/docker.service.d/dns.conf`） |
| NVIDIA Container Toolkit のインストール | コンテナから GPU を使用可能にする |

> - スクリプト冒頭の `DNS3`（既定値 `192.168.100.1`）は研究室ルータの IP アドレスである。ネットワーク環境が異なる場合は実行前に書き換える
> - スクリプトは学内プロキシの使用を前提としている。プロキシを経由しない環境では、実行前にプロキシ設定と DNS 設定の部分を削除する

#### 動作確認

```bash
# バージョン確認
docker --version
docker compose version

# Hello World コンテナで動作確認（"Hello from Docker!" と表示されれば成功）
sudo docker run --rm hello-world

# コンテナから GPU が見えるか確認（nvidia-smi の結果が表示されれば成功）
sudo docker run --rm --gpus all nvcr.io/nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04 nvidia-smi
```

#### 個人ユーザーを docker グループに追加する

個人ユーザーは `sudo` を使えないため、`docker` グループに追加して `sudo` なしで `docker` コマンドを実行できるようにする。

```bash
# 管理アカウント hpc で実行（例: yoshida）
sudo gpasswd -a yoshida docker

# docker グループが含まれていることを確認
id yoshida
# uid=1001(yoshida) gid=1001(yoshida) groups=1001(yoshida),988(docker)
```

グループの変更は、対象ユーザーが**次回ログインした時点**から有効になる。個人ユーザーでログインし直し、`sudo` なしで実行できることを確認する。

```bash
# 個人ユーザーで実行
docker run --rm hello-world
```

Docker の使い方と PyTorch 開発環境の構築は [Docker 環境リファレンス](python_env/docker-pytorch/README.md) を参照する。

### 5-12. SSD向け推奨設定

#### TRIM の有効化

```bash
# 現在の状態を確認
sudo systemctl status fstrim.timer

# 有効化
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer

# 手動実行
sudo fstrim -av
```

#### noatime オプションの追加

```bash
sudo nano /etc/fstab
```

変更前:
```
UUID=xxxx  /  ext4  errors=remount-ro  0  1
```

変更後:
```
UUID=xxxx  /  ext4  noatime,errors=remount-ro  0  1
```

> ⚠️ 変更後は再起動が必要。設定を誤るとシステムが起動しなくなる可能性があるため、編集前にバックアップを取ること。

#### スワップ使用頻度の調整

```bash
# 現在値の確認（デフォルトは60）
cat /proc/sys/vm/swappiness

# 値を10に設定（SSDへの書き込みを削減）
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

### 5-13. ソフトウェアのインストール

> ソフトウェアのインストールは管理アカウント **`hpc`** で行う。個人ユーザーは `sudo` 権限を持たないため、`apt install` 等の操作は実行できない。

#### よく使うソフトウェアの一括インストール（software_install.sh）

研究室でよく使うソフトウェアは [software_install.sh](software_install.sh) でまとめてインストールできる。

```bash
wget https://raw.githubusercontent.com/meruemon/Ubuntu-Setup/main/software_install.sh
bash software_install.sh
```

| ソフトウェア | 説明 | インストール方法 |
|-------------|------|-----------------|
| Google Chrome | ウェブブラウザ | Google 公式 apt リポジトリ |
| Visual Studio Code | Microsoft 製の高機能テキストエディタ（Visual Studio とは別物） | Microsoft 公式 apt リポジトリ |
| LibreOffice | Word・Excel などに代わるオープンソースのオフィスソフト | apt |
| htop | CPU・メモリ使用率、プロセスなどを端末に表示する（`q` で終了） | apt |
| TeamViewer | リモートデスクトップ | 公式 deb パッケージ |
| Slack | チャットツール | snap |

#### GUI（App Center）

1. デスクトップ左下のアプリアイコン →「App Center」を起動
2. 検索バーでアプリケーションを検索し、「インストール」をクリック

#### CUI（apt コマンド）

```bash
# パッケージリストを更新
sudo apt update

# パッケージをインストール
sudo apt install <パッケージ名>

# 例: GIMPをインストール
sudo apt install gimp

# パッケージ名を検索
apt search <キーワード>
```

### 5-14. OpenSSH サーバの設定

```bash
# インストール
sudo apt update
sudo apt install openssh-server

# サービスの起動と自動起動設定
sudo systemctl start ssh
sudo systemctl enable ssh

# 状態確認
sudo systemctl status ssh

# ファイアウォール設定
sudo ufw allow ssh
sudo ufw enable
sudo ufw status
```

接続テスト:

```bash
# サーバー側でIPアドレスを確認
ip a

# クライアントから接続
ssh ユーザー名@サーバーのIPアドレス
```

主なセキュリティ設定（`/etc/ssh/sshd_config`）:

| 項目 | 推奨値 | 説明 |
|------|--------|------|
| `PermitRootLogin` | `no` | rootの直接ログインを禁止 |
| `PasswordAuthentication` | `yes` | パスワード認証（鍵認証のみにする場合は `no`） |
| `Port` | `22`（任意） | SSHポート番号 |

```bash
# 設定変更後はSSHサービスを再起動
sudo systemctl restart ssh
```

---

## 6. トラブルシューティング

### インストール用USBが起動しない

1. 起動時にメーカーロゴ画面で **F2 / F10 / F12 / Del / Esc** を連打してブートメニューを表示
2. USBデバイスを選択してEnterキーを押す
3. 解決しない場合:
   - 別のUSBポート（USB 2.0）を試す
   - USBメモリを作成し直す
   - BIOS/UEFI設定でセキュアブートを一時的に無効化する

### インストールが途中で止まる

- 数分待っても進まない場合は、USBメモリの不良やハードウェア問題が考えられる
- USBメモリを作成し直すか、別のUSBポートを試す

### `apt update` や `wget` がタイムアウトする

学内ネットワークではプロキシ設定が必要である。

```bash
# プロキシの環境変数が設定されているか確認（何も表示されなければ未設定）
env | grep -i proxy

# apt のプロキシ設定を確認
cat /etc/apt/apt.conf.d/30proxy
```

未設定の場合は [5-1. プロキシ設定](#5-1-プロキシ設定) を行う。逆に、プロキシを設定した計算機を学外に持ち出した場合は、設定を無効化しないと接続できない。

### `docker` コマンドで `permission denied` と表示される

```
permission denied while trying to connect to the Docker daemon socket
```

ユーザーが `docker` グループに属していない。管理アカウント `hpc` で [docker グループへの追加](#個人ユーザーを-docker-グループに追加する) を行い、対象ユーザーでログインし直す。

### トラブルを防ぐためのポイント

- インストール・アップデート中に**強制電源オフをしない**

---

## 7. 次のステップ

OS の初期設定が完了したら、個人ユーザーでログインして開発環境を構築する。

| 目的 | ドキュメント |
|------|-------------|
| 開発環境の選び方（Docker / venv） | [Python 環境構築](python_env/INDEX.md) |
| GPU を使う PyTorch 開発（Jupyter Notebook を含む） | [Docker 環境リファレンス](python_env/docker-pytorch/README.md) |
| GPU を使わない Python コーディング | [venv 環境リファレンス](python_env/venv_README.md) |
| 卒業論文の執筆 | [Overleaf を用いた卒論執筆](latex_guide.md) |

---

## 8. 付録

### 8-1. よく使う Linux コマンド

コマンドの表記について、`sudo` が先頭に付けられたコマンドは管理者権限が必要な操作を表す。

| コマンド | 説明 | 例 |
| ---- | ---- | ---- |
| `cd` | ディレクトリを移動 | `cd ~/Documents` |
| `ls` | ファイルやディレクトリの情報を表示 | `ls -a` |
| `pwd` | カレントディレクトリのフルパスを出力 | `pwd` |
| `cp` | ファイル・ディレクトリのコピー | `cp -r コピー元 コピー先` |
| `mv` | ファイル・ディレクトリの移動 | `mv 移動元 移動先` |
| `mkdir` | ディレクトリの作成 | `mkdir tmp` |
| `touch` | タイムスタンプの変更・ファイルの新規作成 | `touch test.txt` |
| `sudo` | スーパーユーザの権限でコマンドを実行 | `sudo visudo` |
| `chmod` | ファイルの権限を変更（r:読込，w:書込，x:実行） | `chmod +x test.py` |
| `chown` | ファイルの所有者・グループを変更 | `chown user:user test` |

`apt` コマンドの概要:

| コマンド | 内容 |
| ---- | ---- |
| `apt install [package]` | パッケージのインストール/更新 |
| `apt update` | パッケージリストの更新 |
| `apt upgrade` | インストールされているパッケージの更新 |
| `apt full-upgrade` | 依存関係の変更（パッケージの追加・削除）を伴う更新も含めて更新 |
| `apt autoremove` | 不要になったパッケージの削除 |

### 8-2. vi の基本操作

端末から設定ファイルを編集する際は `vi`（または `nano`）を使用する。必要最低限の `vi` の[操作方法](https://eng-entrance.com/linux-command-vi)を以下に示す。

| コマンド | 説明 |
| ---- | ---- |
| `i, a, o` | 入力（インサート）モードに切り替え（順に、カーソルの左側，カーソルの右側，次の行から文字入力） |
| `Esc` | コマンドモードに切り替え |
| `h, l, j, k` | コマンドモード中に左右下上にカーソル移動（矢印キーも使用可） |
| `x` | コマンドモード時に1文字を削除 |
| `dd` | コマンドモード時に1行を削除 |
| `Esc`+`:w` | 保存 |
| `Esc`+`:q` | 閉じる |
| `Esc`+`:wq` | 保存して閉じる |
| `G` | 最終行へカーソルを移動 |
| `1+G` | 先頭行へカーソルを移動 |
| `v` | ビジュアルモードへ切り替え |
| `y` | ビジュアルモードで選択した範囲をコピー |
| `p` | コピーした文字列をペースト |
| `u` | 一つ前に戻る |

---

## コミュニティとサポート

- Ubuntu 日本語フォーラム: https://forums.ubuntulinux.jp/
- Ask Ubuntu（英語）: https://askubuntu.com/
- Ubuntu Discourse（英語）: https://discourse.ubuntu.com/

### 参考リンク

| リソース | URL |
|---------|-----|
| Ubuntu 公式（日本語） | https://jp.ubuntu.com/ |
| Ubuntu 24.04 公式リリースページ | https://releases.ubuntu.com/noble/ |
| Ubuntu 認定ハードウェア | https://ubuntu.com/certified |
| Unix/Linux コマンドリファレンス | https://files.fosswire.com/2007/08/fwunixref.pdf |

---
