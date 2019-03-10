#!/bin/bash

# Install same version dependencies with x86_64 Dockerfile.

set -ev

if [ "${INSTALL_DEPS}" != 1 ]; then
  echo "Skip installing dependencies."
  exit 0
fi

# TODO: Separate the logic as another container image if it takes a time.

# Retry ca-certificates-java in advance to prevent SIGSEGV when installing jre.
# https://travis-ci.org/junaruga/ubuntu-arm-java-sigsegv/builds/501915248
apt-get update -qq
retry.sh apt-get install -y ca-certificates-java

# base repository
# software-properties-common: for add-apt-repository.
# python and python-*: to install qiime.
apt-get update -qq
apt-get install -yq --no-install-suggests --no-install-recommends \
  ca-certificates \
  gcc \
  git \
  g++ \
  default-jre \
  make \
  patch \
  python \
  python3 \
  software-properties-common \
  sudo \
  unzip \
  vim \
  wget \
  zlib1g-dev

add-apt-repository universe
# universe repository
# ant: to build fastqc
# mercurial: to download metaphlan2.
# metaphlan2: can not be installed
#   because the dependency bowtie2 is not installable on aarch64.
# fastqc: can not be installed
#   because the dependency libhtsjdk-java is not going to be installed on aarch64.
apt-get update -qq
apt-get install -yq --no-install-suggests --no-install-recommends \
  ant \
  libtbb-dev \
  mercurial \
  python-dev \
  python-pip \
  python-setuptools \
  python-wheel \
  python3-dev \
  python3-pip \
  python3-setuptools \
  python3-wheel \
  qiime

java --version
python3 --version

pushd /usr/local/src

# Nextflow
# https://github.com/nextflow-io/nextflow/releases
wget -q https://github.com/nextflow-io/nextflow/archive/v19.01.0.tar.gz -O nextflow.tar.gz
tar tzvf nextflow.tar.gz | head -1
tar xzf nextflow.tar.gz
pushd nextflow-*
ln -s $(pwd)/nextflow /usr/local/bin/nextflow
popd
nextflow -version

# bbmap: 37.10
# https://sourceforge.net/projects/bbmap/
wget -q https://sourceforge.net/projects/bbmap/files/BBMap_37.10.tar.gz/download -O bbmap.tar.gz
tar tzvf bbmap.tar.gz | head -1
tar xzf bbmap.tar.gz
pushd bbmap
ln -s $(pwd)/bbmap.sh /usr/local/bin/bbmap.sh
popd
bbmap.sh --version

# fastqc: 0.11.5 used for x86_64 Dockerfile.
# But the tagged archive is from 0.11.6 on GitHub.
# http://www.bioinformatics.babraham.ac.uk/projects/fastqc/
wget -q https://github.com/s-andrews/FastQC/archive/v0.11.6.tar.gz -O fastqc.tar.gz
tar tzvf fastqc.tar.gz | head -1
tar xzf fastqc.tar.gz
pushd FastQC-*
# To fix an build error on JDK 10.
# https://github.com/s-andrews/FastQC/pull/30
cat /build/patches/fastqc-0.11.6-build-on-jdk-10.patch | patch -p1
ant
chmod +x bin/fastqc
ln -s $(pwd)/bin/fastqc /usr/local/bin/fastqc
popd
fastqc --version

# humann2: 0.9.9
# https://pypi.org/project/humann2/
pip3 install humann2==0.9.9

# qiime: 1.9.1
# http://qiime.org/
# https://pypi.org/project/qiime/
# qiime does not work on Python3.
# https://github.com/alesssia/YAMP/issues/11
pip install qiime==1.9.1

# awscli
# https://pypi.org/project/awscli/
pip3 install awscli==1.16.106

# bowtie2: 2.3.4.1
BOWTIE2_VERSION="2.3.4.1"

# Comment out the normal install process.
# wget -q https://sourceforge.net/projects/bowtie-bio/files/bowtie2/${BOWTIE2_VERSION}/bowtie2-${BOWTIE2_VERSION}-source.zip/download -O bowtie2-${BOWTIE2_VERSION}.zip
# unzip bowtie2-${BOWTIE2_VERSION}.zip
# pushd bowtie2-${BOWTIE2_VERSION}

# Download by git to do "git submodule" in below process.
git clone https://github.com/BenLangmead/bowtie2.git
pushd bowtie2
git checkout "v${BOWTIE2_VERSION}"

# To build on ARM.
# https://github.com/BenLangmead/bowtie2/pull/216
# https://gitlab.com/arm-hpc/packages/wikis/packages/bowtie2
git clone https://github.com/nemequ/simde.git third_party/simde
sed -i 's/__m/simde__m/g' aligner_*
sed -i 's/__m/simde__m/g' sse_util*
sed -i 's/_mm_/simde_mm_/g' aligner_*
sed -i 's/_mm_/simde_mm_/g' sse_util*
cat /build/patches/bowtie2-2.3.4.1-build-on-arm.patch | patch -p1

uname -m
export CXXFLAGS="-Wno-deprecated-declarations -Wno-misleading-indentation -Wno-narrowing -Wno-unused-function -Wno-unused-result"

# A ping to prevent a timeout for the long command.
while sleep 9m; do
  echo "====[ $SECONDS seconds still running ]===="
done &

make install -j 4 \
  POPCNT_CAPABILITY=0 \
  NO_TBB=1

# Stop the ping.
kill %1

popd
bowtie2 --version

# metaphlan2: 2.6.0
# https://bitbucket.org/biobakery/metaphlan2
# Asking an installation by pip command.
# https://bitbucket.org/biobakery/metaphlan2/issues/32
hg clone https://bitbucket.org/biobakery/metaphlan2
pushd metaphlan2
ln -s $(pwd)/metaphlan2.py /usr/local/bin/metaphlan2.py
popd

popd
