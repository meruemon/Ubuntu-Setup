#!/bin/bash

# Ubuntu 24.04 ソフトウェアインストールスクリプト
# Google Chrome, Visual Studio Code, LibreOffice, htop, TeamViewer, Slackをインストール
# 管理アカウント(sudo権限のあるユーザー)で実行する

echo "###################################################"
echo "# Ubuntu 24.04 ソフトウェアインストールスクリプト"
echo "# - Google Chrome"
echo "# - Visual Studio Code"
echo "# - LibreOffice"
echo "# - htop"
echo "# - TeamViewer"
echo "# - Slack"
echo "###################################################"
echo ""

# 必要なパッケージをインストール
echo ">> 依存パッケージをインストール中..."
sudo apt update
sudo apt install -y wget gpg curl

# Google Chromeのインストール
echo ">> Google Chromeをインストール中..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor --yes -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install -y google-chrome-stable

# Visual Studio Codeのインストール
echo ">> Visual Studio Codeをインストール中..."
wget -q -O- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor --yes -o /usr/share/keyrings/microsoft-vscode.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft-vscode.gpg] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
sudo apt update
sudo apt install -y code

# LibreOfficeのインストール
echo ">> LibreOfficeをインストール中..."
sudo apt install -y libreoffice libreoffice-help-ja libreoffice-l10n-ja

# htopのインストール
echo ">> htopをインストール中..."
sudo apt install -y htop

# TeamViewerのインストール
echo ">> TeamViewerをインストール中..."
wget -q https://download.teamviewer.com/download/linux/teamviewer_amd64.deb -O /tmp/teamviewer.deb
sudo apt install -y /tmp/teamviewer.deb
rm /tmp/teamviewer.deb

# Slackのインストール (snap版: バージョン固定のdebと異なり常に最新版が入る)
echo ">> Slackをインストール中..."
# プロキシ環境ではsnapにもプロキシを設定する
if [ -n "$http_proxy" ]; then
    sudo snap set system proxy.http="$http_proxy"
    sudo snap set system proxy.https="${https_proxy:-$http_proxy}"
fi
sudo snap install slack

# インストール確認
echo ""
echo ">> ソフトウェアのバージョン確認:"
echo ">> Google Chrome:"
google-chrome --version
echo ">> Visual Studio Code:"
code --version
echo ">> LibreOffice:"
libreoffice --version
echo ">> htop:"
htop --version
echo ">> TeamViewer:"
teamviewer --version
echo ">> Slack:"
snap list slack

echo ""
echo ">> インストールが完了しました。"
echo ">> 各アプリケーションはアプリケーションメニューから起動できます。"
