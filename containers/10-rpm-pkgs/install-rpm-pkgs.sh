#!/bin/bash

set -evo pipefail

dnf -y update
dnf -y \
    --allowerasing \
    --setopt=deltarpm=0 \
    --setopt=install_weak_deps=false \
    --setopt=tsflags=nodocs \
    install \
    ant \
    ca-certificates \
    gcc \
    git \
    java-11-openjdk \
    make \
    mercurial \
    patch \
    python3 \
    python3-devel \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    tbb-devel \
    unzip \
    vim \
    wget \
    zlib-devel
dnf clean all
rm -rf /tmp/* /var/tmp/*

# qiime is not available on Fedora.
# samtools v0.1.19 on Fedora 30 is older than v1.3.1 used by YAMP.

java -version
python3 --version
# samtools --version
