FROM nvcr.io/nvidia/pytorch:19.10-py3 

ENV https_proxy http://proxy.itc.kansai-u.ac.jp:8080
ENV http_proxy http://proxy.itc.kansai-u.ac.jp:8080

ARG NUM_CPUS_FOR_BUILD=4

# Proxy settings
RUN echo 'Acquire::http::proxy "http://proxy.itc.kansai-u.ac.jp:8080/";\nAcquire::https::proxy "https://proxy.itc.kansai-u.ac.jp:8080/";\nAcquire::ftp::proxy "ftp://proxy.itc.kansai-u.ac.jp:8080/";\nAcquire::socks::proxy "socks://proxy.itc.kansai-u.ac.jp:8080/";' >> /etc/apt/apt.conf
RUN echo 'http_proxy="http://proxy.itc.kansai-u.ac.jp:8080/"\nhttps_proxy="https://proxy.itc.kansai-u.ac.jp:8080/"\nftp_proxy="http://proxy.itc.kansai-u.ac.jp:8080/"\nsocks_proxy="http://proxy.itc.kansai-u.ac.jp:8080/"' >> /etc/environment
RUN echo 'https_proxy = http://proxy.itc.kansai-u.ac.jp:8080/\nhttp_proxy = http://proxy.itc.kansai-u.ac.jp:8080/\nftp_proxy = http://proxy.itc.kansai-u.ac.jp:8080/' >>/etc/wgetrc

# Time zone settings
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

RUN apt-get update && apt-get install -y --no-install-recommends \
    imagemagick && \
    rm -rf /var/lib/apt/lists/*

# RUN conda install [packages]

ENV WORKSPACE_PATH /workspace
WORKDIR $WORKSPACE_PATH

##
# Set User
##
ENV USER student
ENV USER_ID 1001
ENV HOME /home/${USER}
ENV SHELL /bin/bash

RUN groupadd -g ${USER_ID} ${USER}
RUN useradd -g ${USER_ID} -u ${USER_ID} -m -s /bin/bash ${USER}
RUN gpasswd -a ${USER} sudo
RUN echo "${USER}:${USER}" | chpasswd

USER ${USER}
WORKDIR /home/${USER}/





