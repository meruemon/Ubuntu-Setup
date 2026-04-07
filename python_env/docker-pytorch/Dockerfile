# ベースイメージ: CUDA 11.7 + cuDNN 8 + Ubuntu 22.04 (NGC)
FROM nvcr.io/nvidia/cuda:11.7.1-cudnn8-devel-ubuntu22.04

# ----- ビルド引数 (各自の環境に合わせて変更してください) -----
ARG USERNAME=yoshida
ARG USER_UID=1001
ARG USER_GID=1001

# タイムゾーン設定 (apt-get 中の対話を防止)
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Tokyo

# ----- システムパッケージ -----
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

# ----- ユーザ作成 (ARG で指定した名前・UID・GID を使用) -----
RUN groupadd -g ${USER_GID} ${USERNAME} \
    && useradd -m -u ${USER_UID} -g ${USERNAME} -s /bin/bash ${USERNAME}

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
RUN mkdir -p /workspace && chown ${USERNAME}:${USERNAME} /workspace

# ----- 以降はビルド引数で指定したユーザとして実行 -----
USER ${USERNAME}
WORKDIR /workspace

# Jupyter の設定ファイルを生成
RUN jupyter notebook --generate-config && \
    sed -i \
        -e "s/# c.NotebookApp.ip = 'localhost'/c.NotebookApp.ip = '0.0.0.0'/" \
        -e "s/# c.NotebookApp.open_browser = True/c.NotebookApp.open_browser = False/" \
        -e "s/# c.NotebookApp.port = 8888/c.NotebookApp.port = 8888/" \
        /home/${USERNAME}/.jupyter/jupyter_notebook_config.py

# デフォルトは bash で待機 (Jupyter は手動起動)
CMD ["/bin/bash"]
