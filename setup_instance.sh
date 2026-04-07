#!/bin/bash
set -euo pipefail

PROJECT_ROOT="/workspace/end2end_AD_DriveTransformer"
CONDA_ROOT="/workspace/miniconda3"
ENV_NAME="dt38"
CARLA_USER="${CARLA_USER:-carlauser}"
VULKAN_ICD_PATH="/etc/vulkan/icd.d/my_nvidia_icd.json"

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

echo "[1/7] Installing system packages"
$SUDO apt update
$SUDO apt install -y \
  sudo \
  wget \
  git \
  curl \
  tmux \
  vim \
  build-essential \
  gcc-9 \
  g++-9 \
  cmake \
  ninja-build \
  pkg-config \
  libvulkan1 \
  vulkan-tools \
  libegl1 \
  libsm6

echo "[2/7] Installing Miniconda if needed"
cd /workspace
if [ ! -d "$CONDA_ROOT" ]; then
  wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O miniconda.sh
  bash miniconda.sh -b -p "$CONDA_ROOT"
fi

source "$CONDA_ROOT/etc/profile.d/conda.sh"

echo "[3/7] Creating or updating conda environment"
cd "$PROJECT_ROOT"
if ! conda env list | awk '{print $1}' | grep -qx "$ENV_NAME"; then
  conda env create -f environment_dt38.yml
else
  conda activate "$ENV_NAME"
  pip install --upgrade pip setuptools wheel
  pip install -r requirements_frozen.txt
fi

conda activate "$ENV_NAME"

echo "[4/7] Exporting build environment"
export CC=gcc-9
export CXX=g++-9
if command -v nvcc >/dev/null 2>&1; then
  export CUDA_HOME
  CUDA_HOME="$(dirname "$(dirname "$(which nvcc)")")"
  export PATH="$CUDA_HOME/bin:$PATH"
  export LD_LIBRARY_PATH="$CUDA_HOME/lib64:${LD_LIBRARY_PATH:-}"
fi
export PATH="/usr/bin/x86_64-linux-gnu-gcc-9/bin:$PATH"
export CARLA_ROOT="$PROJECT_ROOT/carla"

echo "Registering CARLA Python egg if present"
CARLA_EGG_PATH="$CARLA_ROOT/PythonAPI/carla/dist/carla-0.9.15-py3.7-linux-x86_64.egg"
if [ -f "$CARLA_EGG_PATH" ]; then
  SITE_PACKAGES_DIR="$(python -c 'import site; print(site.getsitepackages()[0])')"
  CARLA_PTH_PATH="${SITE_PACKAGES_DIR}/carla.pth"
  if [ -f "$CARLA_PTH_PATH" ]; then
    if ! grep -qxF "$CARLA_EGG_PATH" "$CARLA_PTH_PATH"; then
      echo "$CARLA_EGG_PATH" >> "$CARLA_PTH_PATH"
    fi
  else
    echo "$CARLA_EGG_PATH" > "$CARLA_PTH_PATH"
  fi
else
  echo "Warning: CARLA egg not found at $CARLA_EGG_PATH. Continuing because pip package carla==0.9.15 is also installed." >&2
fi

echo "[5/7] Configuring Vulkan ICD"
if [ -f /lib/x86_64-linux-gnu/libEGL_nvidia.so.0 ]; then
  EGL_NVIDIA_LIB="/lib/x86_64-linux-gnu/libEGL_nvidia.so.0"
elif [ -f /usr/lib/x86_64-linux-gnu/libEGL_nvidia.so.0 ]; then
  EGL_NVIDIA_LIB="/usr/lib/x86_64-linux-gnu/libEGL_nvidia.so.0"
else
  echo "Could not find libEGL_nvidia.so.0. Please verify NVIDIA drivers are available in this instance." >&2
  exit 1
fi

$SUDO mkdir -p /etc/vulkan/icd.d
cat <<EOF | $SUDO tee "$VULKAN_ICD_PATH" >/dev/null
{
  "file_format_version": "1.0.0",
  "ICD": {
    "library_path": "${EGL_NVIDIA_LIB}",
    "api_version": "1.3.277"
  }
}
EOF

echo "[6/7] Creating non-root CARLA runtime user"
if ! id "$CARLA_USER" >/dev/null 2>&1; then
  $SUDO useradd -m -s /bin/bash "$CARLA_USER"
fi
$SUDO usermod -aG sudo "$CARLA_USER"
echo "${CARLA_USER} ALL=(ALL) NOPASSWD:ALL" | $SUDO tee "/etc/sudoers.d/90-${CARLA_USER}" >/dev/null
$SUDO chmod 440 "/etc/sudoers.d/90-${CARLA_USER}"
$SUDO mkdir -p "/tmp/runtime-${CARLA_USER}"
$SUDO chown -R "${CARLA_USER}:${CARLA_USER}" "/tmp/runtime-${CARLA_USER}"
$SUDO chmod 700 "/tmp/runtime-${CARLA_USER}"

echo "[7/7] Quick verification"
export VK_ICD_FILENAMES="$VULKAN_ICD_PATH"
if command -v vulkaninfo >/dev/null 2>&1; then
  vulkaninfo --summary | sed -n '1,40p' || true
fi

cat <<EOF

Setup finished.

Recommended workflow on a new instance:
1. Run this script as root:
   bash setup_instance.sh
2. Switch to the runtime user:
   su - ${CARLA_USER}
3. Activate the conda environment:
   source ${CONDA_ROOT}/etc/profile.d/conda.sh
   conda activate ${ENV_NAME}
4. Run Bench2Drive scripts from:
   ${PROJECT_ROOT}/Bench2Drive

Important runtime env for CARLA:
  export XDG_RUNTIME_DIR=/tmp/runtime-${CARLA_USER}
  export VK_ICD_FILENAMES=${VULKAN_ICD_PATH}
EOF
