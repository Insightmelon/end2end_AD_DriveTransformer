#!/bin/bash
set -e

apt update
apt install -y wget git curl tmux vim build-essential gcc-9 g++-9 cmake ninja-build pkg-config

cd /workspace

if [ ! -d "/workspace/miniconda3" ]; then
  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
  bash miniconda.sh -b -p /workspace/miniconda3
fi

source /workspace/miniconda3/etc/profile.d/conda.sh

if ! conda env list | grep -q "^dt38 "; then
  conda create -y -n dt38 python=3.8
fi

conda activate dt38
pip install --upgrade pip setuptools wheel

cd /workspace/end2end_AD_DriveTransformer
pip install -r requirements_frozen.txt || true

export CC=gcc-9
export CXX=g++-9

export CUDA_HOME=$(dirname $(dirname $(which nvcc)))
export PATH=$CUDA_HOME/bin:$PATH
export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH
export PATH=/usr/bin/x86_64-linux-gnu-gcc-9/bin:$PATH
export CARLA_ROOT=/workspace/end2end_AD_DriveTransformer/carla

echo "setup finished"

