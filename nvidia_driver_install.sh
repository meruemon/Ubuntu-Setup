#!/bin/bash

# NVIDIA Driver インストールスクリプト for Ubuntu 22.04

echo "###################################################"
echo "# Ubuntu 22.04 NVIDIAドライバーインストールスクリプト"
echo "###################################################"
echo ""

echo ">> 基本パッケージをインストール中..."
sudo apt install -y build-essential vim

# GCCの最新バージョンをインストール
echo ">> gcc-12をインストール中..."
sudo apt install --reinstall -y gcc-12
sudo ln -s -f /usr/bin/gcc-12 /usr/bin/gcc

# GCCのバージョンを確認
echo ">> インストールされたGCCバージョン:"
gcc --version

# Nouveauドライバの無効化
echo ">> Nouveauドライバを無効化中..."
sudo bash -c "cat > /etc/modprobe.d/blacklist-nouveau.conf" << EOT
blacklist nouveau
options nouveau modeset=0
EOT

# initramfsを再生成
echo ">> initramfsを再生成中..."
sudo update-initramfs -u

# NVIDIAドライバーをダウンロード
echo ">> 最新のNVIDIAドライバーをダウンロード中..."
sudo apt install -y wget
DRIVER_VERSION="570.124.04"
wget -O /tmp/nvidia-driver.run https://us.download.nvidia.com/XFree86/Linux-x86_64/${DRIVER_VERSION}/NVIDIA-Linux-x86_64-${DRIVER_VERSION}.run
chmod +x /tmp/nvidia-driver.run

echo ">> システムをマルチユーザーモードに切り替え中..."
sudo systemctl set-default multi-user.target

echo ">> NVIDIAドライバーの準備が完了しました"
echo ">> インストールを続行するには、以下の手順に従ってください:"
echo ""
echo "1. システムを再起動してください:"
echo "   sudo reboot"
echo ""
echo "2. 再起動後、CLIモードでログインしてください"
echo ""
echo "3. 以下のコマンドでNVIDIAドライバーをインストールしてください:"
echo "   export LANG=C"
echo "   sudo /tmp/nvidia-driver.run -s --dkms --no-x-check --run-nvidia-xconfig --no-nouveau-check --disable-nouveau"
echo ""
echo "4. インストールが完了したら、以下のコマンドでドライバーを確認できます:"
echo "   nvidia-smi"
echo ""
echo "5. GUIモードに戻すには、以下のコマンドを実行して再起動してください:"
echo "   sudo systemctl set-default graphical.target"
echo "   sudo reboot"
