#!/bin/bash

# Docker インストールスクリプト for Ubuntu 22.04
# 関西大学のプロキシ設定も含む

PROXY="http://proxy.itc.kansai-u.ac.jp:8080/"
DNS1="158.217.208.10"
DNS2="158.217.6.7"
DNS3="192.168.100.1"

echo "###################################################"
echo "# Ubuntu 22.04 Dockerインストールスクリプト"
echo "# プロキシ: $PROXY"
echo "###################################################"
echo ""

# Docker公式GPGキーの追加
echo ">> Docker公式GPGキーを追加中..."
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Dockerリポジトリの追加
echo ">> Dockerリポジトリを追加中..."
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Dockerパッケージのインストール
echo ">> Dockerパッケージをインストール中..."
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Dockerのプロキシ設定
echo ">> Dockerのプロキシ設定を構成中..."
# systemdディレクトリの作成
sudo mkdir -p /etc/systemd/system/docker.service.d

# プロキシ設定ファイルの作成
echo ">> Dockerのhttp-proxy.confを作成中..."
sudo bash -c "cat > /etc/systemd/system/docker.service.d/http-proxy.conf" << EOT
[Service]
Environment="HTTP_PROXY=$PROXY"
Environment="HTTPS_PROXY=$PROXY"
EOT

# DNS設定ファイルの作成
echo ">> Dockerのdns.confを作成中..."
sudo bash -c "cat > /etc/systemd/system/docker.service.d/dns.conf" << EOT
[Service]
Environment="DOCKER_NETWORK_OPTIONS=--dns $DNS1 --dns $DNS2 --dns $DNS3"
ExecStart=
ExecStart=/usr/bin/dockerd -H fd:// \$DOCKER_NETWORK_OPTIONS
EOT

# /etc/defaultのDockerプロキシ設定
echo ">> /etc/default/dockerにプロキシ設定を追加中..."
sudo bash -c "cat > /etc/default/docker" << EOT
export http_proxy=$PROXY
export https_proxy=$PROXY
EOT

# NVIDIA Container Toolkitのインストール
echo ">> NVIDIA Container Toolkitをインストール中..."
sudo curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo sed -i -e '/experimental/ s/^#//g' /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# NVIDIA Container Runtimeを設定
echo ">> NVIDIA Container Runtimeを設定中..."
sudo nvidia-ctk runtime configure --runtime=docker

# Dockerサービスを再起動
echo ">> Dockerサービスを再起動中..."
sudo systemctl daemon-reload
sudo systemctl restart docker

# 動作確認
echo ">> Dockerの基本動作を確認中..."
sudo docker run --rm hello-world

echo ">> NVIDIA Container Toolkitの動作確認"
echo ">> GPUを利用できるか確認するには、以下のコマンドを実行してください:"
echo "sudo docker run --rm --gpus all nvcr.io/nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04 bash -c \"nvidia-smi; nvcc -V\""

echo ">> Docker設定が完了しました"
