#!/bin/bash

# Proxy設定スクリプト for Ubuntu 22.04
# 関西大学のプロキシ設定

PROXY="http://proxy.itc.kansai-u.ac.jp:8080/"

echo "###################################################"
echo "# Ubuntu 22.04 プロキシ設定スクリプト"
echo "# プロキシ: $PROXY"
echo "###################################################"
echo ""

# .bashrcにプロキシ設定を追加
echo ">> .bashrcにプロキシ設定を追加中..."
cat <<EOT >> ~/.bashrc
# Proxy settings
export https_proxy="$PROXY"
export http_proxy="$PROXY"
export ftp_proxy="$PROXY"
EOT

# .curlrcにプロキシ設定を追加
echo ">> .curlrcにプロキシ設定を追加中..."
echo "proxy=$PROXY" > ~/.curlrc

# sudoersにプロキシ環境変数を保持する設定を追加
echo ">> sudoersにプロキシ環境変数の保持設定を追加中..."
sudo cp /etc/sudoers /etc/sudoers.bak
sudo bash -c "cat > /etc/sudoers.d/proxy" << EOT
Defaults env_keep="no_proxy NO_PROXY"
Defaults env_keep+="http_proxy https_proxy ftp_proxy"
Defaults env_keep+="HTTP_PROXY HTTPS_PROXY FTP_PROXY"
EOT

# aptにプロキシ設定を追加
echo ">> aptにプロキシ設定を追加中..."
sudo bash -c "cat > /etc/apt/apt.conf.d/30proxy" << EOT
Acquire::http { Proxy "$PROXY"; };
Acquire::https { Proxy "$PROXY"; };
EOT

# リポジトリをrikenへ変更
echo ">> aptリポジトリをrikenに変更中..."
sudo sed -i "s-$(cat /etc/apt/sources.list | grep -v "#" | cut -d " " -f 2 | grep -v "security" | sed "/^$/d" | sed -n 1p)-http://ftp.riken.go.jp/Linux/ubuntu/-g" /etc/apt/sources.list

# 設定の反映とパッケージ更新
echo ">> パッケージリストを更新中..."
sudo apt update

echo ">> Proxy設定が完了しました"
echo ">> 新しいプロキシ設定を有効にするには、シェルを再起動するか以下のコマンドを実行してください:"
echo "source ~/.bashrc"
