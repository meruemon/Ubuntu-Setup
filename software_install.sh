#!/bin/bash

# Ubuntu 22.04 ソフトウェアインストールスクリプト
# Google Chrome, Visual Studio Code, LibreOffice, htop, TeamViewerをインストール

echo "###################################################"
echo "# Ubuntu 22.04 ソフトウェアインストールスクリプト"
echo "# - Google Chrome"
echo "# - Visual Studio Code"
echo "# - LibreOffice"
echo "# - htop"
echo "# - TeamViewer"
echo "###################################################"
echo ""

# 必要なパッケージをインストール
echo ">> 依存パッケージをインストール中..."
sudo apt update
sudo apt install -y wget gpg apt-transport-https curl

# Google Chromeのインストール
echo ">> Google Chromeをインストール中..."
wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
sudo apt update
sudo apt install -y google-chrome-stable

# Visual Studio Codeのインストール
echo ">> Visual Studio Codeをインストール中..."
wget -q -O- https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-vscode.gpg
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

echo ""
echo ">> インストールが完了しました。"
echo ">> 各アプリケーションはアプリケーションメニューから起動できます。"
