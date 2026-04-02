# ベースイメージ: CUDA 11.7 + cuDNN 8 + Ubuntu 22.04 (NGC)
FROM nvcr.io/nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04

# タイムゾーン設定 (apt-get 中の対話を防止)
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# ----- システムパッケージ -----
# Ubuntu 22.04 には Python 3.10 が標準搭載されているため deadsnakes 不要
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.10 \
        python3.10-dev \
        python3-pip \
        python3-distutils \
        build-essential \
        curl \
        git \
        vim \
        wget \
        ca-certificates \
        libgomp1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# python3.10 をデフォルトの python / pip にする
RUN update-alternatives --install /usr/bin/python  python  /usr/bin/python3.10 1 \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 \
    && update-alternatives --install /usr/bin/pip    pip    /usr/bin/pip3       1

# ----- ユーザ作成 (yoshida / uid=1001) -----
RUN groupadd -g 1001 yoshida \
    && useradd -m -u 1001 -g yoshida -s /bin/bash yoshida

# ----- Python ライブラリのインストール (root で実施) -----
# PyTorch 1.13.1 (GPU / CUDA 11.7版)
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir \
        torch==1.13.1+cu117 \
        torchvision==0.14.1+cu117 \
        torchaudio==0.13.1+cu117 \
        --extra-index-url https://download.pytorch.org/whl/cu117

RUN pip install --no-cache-dir \
        numpy==1.24.4 \
        scipy \
        pandas \
        scikit-learn \
        matplotlib \
        seaborn \
        pillow \
        opencv-python-headless \
        tqdm \
        joblib \
        optuna \
        tensorboard \
        jupyter \
        notebook \
        ipywidgets \
        jupyterlab

# ----- 作業ディレクトリ -----
RUN mkdir -p /workspace && chown yoshida:yoshida /workspace

# ----- 以降はユーザ yoshida として実行 -----
USER yoshida
WORKDIR /workspace

# Jupyter の設定ファイルを生成
RUN jupyter notebook --generate-config && \
    sed -i \
        -e "s/# c.NotebookApp.ip = 'localhost'/c.NotebookApp.ip = '0.0.0.0'/" \
        -e "s/# c.NotebookApp.open_browser = True/c.NotebookApp.open_browser = False/" \
        -e "s/# c.NotebookApp.port = 8888/c.NotebookApp.port = 8888/" \
        /home/yoshida/.jupyter/jupyter_notebook_config.py

# デフォルトは bash で待機 (Jupyter は手動起動)
CMD ["/bin/bash"]
