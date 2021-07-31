FROM nvidia/cuda:10.2-cudnn7-devel-ubuntu18.04
LABEL maintainer="Soh Yoshida"

# Proxy Setting
ENV https_proxy "http://proxy.itc.kansai-u.ac.jp:8080"
ENV http_proxy "http://proxy.itc.kansai-u.ac.jp:8080"

ARG NUM_CPUS_FOR_BUILD=10

RUN sed -i.bak -e "s%http://archive.ubuntu.com/ubuntu/%http://ftp.jaist.ac.jp/pub/Linux/ubuntu/%g" /etc/apt/sources.list

ENV TZ Asia/Tokyo
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update \
  && apt-get install -y tzdata \
  && rm -rf /var/lib/apt/lists/* \
  && echo "${TZ}" > /etc/timezone \
  && rm /etc/localtime \
  && ln -s /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
  && dpkg-reconfigure -f noninteractive tzdata
RUN apt-get -y clean all
RUN rm -rf /var/lib/apt/lists/*

# PyTorch (Geometric) installation
RUN rm /etc/apt/sources.list.d/cuda.list && \
    rm /etc/apt/sources.list.d/nvidia-ml.list

RUN apt-get update &&  apt-get install -y \
    curl \
    ca-certificates \
    vim \
    sudo \
    git \
    bzip2 \
    libx11-6 \
 && rm -rf /var/lib/apt/lists/*

# Create a working directory.
RUN mkdir /app
WORKDIR /app

# Create a non-root user and switch to it.
RUN adduser --disabled-password --gecos '' --shell /bin/bash user \
 && chown -R user:user /app
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER user

# All users can use /home/user as their home directory.
ENV HOME=/home/user
RUN chmod 777 /home/user

# Install Miniconda.
RUN curl -so ~/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh \
 && chmod +x ~/miniconda.sh \
 && ~/miniconda.sh -b -p ~/miniconda \
 && rm ~/miniconda.sh
ENV PATH=/home/user/miniconda/bin:$PATH
ENV CONDA_AUTO_UPDATE_CONDA=false

# Create a Python 3.6 environment.
RUN /home/user/miniconda/bin/conda install conda-build \
 && /home/user/miniconda/bin/conda create -y --name py36 python=3.6.5 \
 && /home/user/miniconda/bin/conda clean -ya
ENV CONDA_DEFAULT_ENV=py36
ENV CONDA_PREFIX=/home/user/miniconda/envs/$CONDA_DEFAULT_ENV
ENV PATH=$CONDA_PREFIX/bin:$PATH

# CUDA 10.0-specific steps.
RUN conda install pytorch==1.7.0 torchvision==0.8.0 torchaudio==0.7.0 cudatoolkit=10.2 -c pytorch \
#RUN conda install -y -c pytorch \
#    cudatoolkit=10.1 \
#     "pytorch=1.7.0=py3.6_cuda10.1.243_cudnn7.6.3_0" \
#    torchvision=0.5.0=py36_cu101 \
 && conda clean -ya

# Install HDF5 Python bindings.
RUN conda install -y h5py=2.8.0 \
 && conda clean -ya
RUN pip install h5py-cache==1.0

# Install TorchNet, a high-level framework for PyTorch.
RUN pip install torchnet==0.0.4

# Install Requests, a Python library for making HTTP requests.
RUN conda install -y requests=2.19.1 \
 && conda clean -ya

# Install Graphviz.
RUN conda install -y graphviz=2.40.1 python-graphviz=0.8.4 \
 && conda clean -ya

# Install Pandas.
RUN conda install -y pandas=0.24.1 \
 && conda clean -ya

 # Install Pandas.
RUN conda install -y jupyter jupyterlab ipython \
 && conda clean -ya

# Install TorchNet, a high-level framework for PyTorch.
RUN pip install elasticsearch

# Install OpenCV3 Python bindings.
RUN sudo apt-get update && sudo apt-get install -y --no-install-recommends \
    libgtk2.0-0 \
    libcanberra-gtk-module \
 && sudo rm -rf /var/lib/apt/lists/*
RUN conda install -y -c menpo opencv3=3.1.0 \
 && conda clean -ya

# Install PyTorch Geometric.
RUN CPATH=/usr/local/cuda/include:$CPATH \
 && LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH \
 && DYLD_LIBRARY_PATH=/usr/local/cuda/lib:$DYLD_LIBRARY_PATH

# NVIDIA container runtime.
ENV NVIDIA_VISIBLE_DEVICES all
ENV NVIDIA_DRIVER_CAPABILITIES compute,utility
ENV NVIDIA_REQUIRE_CUDA "cuda>=10.0 brand=tesla,driver>=384,driver<385 brand=tesla,driver>=410,driver<411"

RUN pip install torch-scatter -f https://pytorch-geometric.com/whl/torch-1.7.0+cu102.html \
 && pip install torch-sparse -f https://pytorch-geometric.com/whl/torch-1.7.0+cu102.html \
 && pip install torch-cluster -f https://pytorch-geometric.com/whl/torch-1.7.0+cu102.html \
 && pip install torch-spline-conv -f https://pytorch-geometric.com/whl/torch-1.7.0+cu102.html \
 && pip install torch-geometric

# RUN pip install transformers==2.8.0
RUN pip install -U sentence-transformers

RUN git clone https://github.com/NVIDIA/apex
RUN cd apex && \
    python3 setup.py install && \
    pip install -v --no-cache-dir --global-option="--cpp_ext" --global-option="--cuda_ext" ./

CMD ["/bin/bash"]
