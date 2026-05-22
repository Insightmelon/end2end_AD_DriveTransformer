#!/bin/bash
set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
  shift
fi

WORKSPACE_ROOT="/workspace"
PROJECT_ROOT="${WORKSPACE_ROOT}/end2end_AD_DriveTransformer"
REPO_URL="${REPO_URL:-https://github.com/Insightmelon/end2end_AD_DriveTransformer.git}"
REPO_REF="${REPO_REF:-main}"

CARLA_ARCHIVE_URL="${CARLA_ARCHIVE_URL:-https://carla-releases.s3.us-east-005.backblazeb2.com/Linux/CARLA_0.9.15.tar.gz}"
CARLA_ARCHIVE_PATH="${CARLA_ARCHIVE_PATH:-}"
CARLA_DIR="${PROJECT_ROOT}/carla"

DT_LARGE_CKPT_URL="${DT_LARGE_CKPT_URL:-https://drive.google.com/file/d/1wAXFWfjJm0cmP_pmgTkwxTUEs6Zu5j6i/view}"
DT_LARGE_CKPT_PATH="${DT_LARGE_CKPT_PATH:-}"
RESNET50_CKPT_URL="${RESNET50_CKPT_URL:-https://huggingface.co/rethinklab/Bench2DriveZoo/resolve/main/resnet50-19c8e357.pth}"
RESNET50_CKPT_PATH="${RESNET50_CKPT_PATH:-}"
GDOWN_VERSION="${GDOWN_VERSION:-5.2.1}"

if [ "$(id -u)" -eq 0 ]; then
  SUDO=""
else
  SUDO="sudo"
fi

download_to_file() {
  local url="$1"
  local output_path="$2"

  if [[ "$url" == *"drive.google.com"* ]]; then
    if ! python3 -m gdown --help 2>/dev/null | grep -q -- "--fuzzy"; then
      python3 -m pip install --upgrade "gdown==${GDOWN_VERSION}"
    fi
    python3 -m gdown --fuzzy "$url" -O "$output_path"
  else
    wget -O "$output_path" "$url"
  fi
}

check_url() {
  local url="$1"
  if [[ "$url" == *"drive.google.com"* ]]; then
    echo "SKIP remote HEAD check for Google Drive URL: $url"
    return 0
  fi
  curl -I -L --max-time 20 "$url" >/dev/null
}

run_or_echo() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] $*"
  else
    "$@"
  fi
}

echo "[1/6] Installing bootstrap tools"
if [ "$DRY_RUN" -eq 1 ]; then
  echo "[dry-run] Would run: $SUDO apt update"
  echo "[dry-run] Would run: $SUDO apt install -y git wget curl unzip tar python3 python3-pip"
else
  $SUDO apt update
  $SUDO apt install -y git wget curl unzip tar python3 python3-pip
fi

echo "[2/6] Preparing workspace"
run_or_echo mkdir -p "$WORKSPACE_ROOT"
cd "$WORKSPACE_ROOT"

if [ ! -d "$PROJECT_ROOT/.git" ]; then
  echo "Cloning repository from ${REPO_URL}"
  if [ "$DRY_RUN" -eq 1 ]; then
    check_url "$REPO_URL"
    echo "[dry-run] Would clone repository into $PROJECT_ROOT"
  else
    git clone "$REPO_URL" "$PROJECT_ROOT"
  fi
fi

if [ -d "$PROJECT_ROOT" ]; then
  cd "$PROJECT_ROOT"
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[dry-run] Repository directory exists: $PROJECT_ROOT"
    echo "[dry-run] Would fetch refs and checkout $REPO_REF"
  else
    git fetch --all --tags || true
    git checkout "$REPO_REF" || true
  fi
fi

echo "[3/6] Preparing CARLA directory"
if [ ! -d "$CARLA_DIR" ]; then
  if [ -n "$CARLA_ARCHIVE_PATH" ] && [ -f "$CARLA_ARCHIVE_PATH" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "[dry-run] Found local CARLA archive: $CARLA_ARCHIVE_PATH"
      echo "[dry-run] Would extract into $CARLA_DIR"
    else
      mkdir -p "$CARLA_DIR"
      tar -xf "$CARLA_ARCHIVE_PATH" -C "$CARLA_DIR" --strip-components=1
    fi
  elif [ -n "$CARLA_ARCHIVE_URL" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      check_url "$CARLA_ARCHIVE_URL"
      echo "[dry-run] Would download CARLA from $CARLA_ARCHIVE_URL"
      echo "[dry-run] Would extract into $CARLA_DIR"
    else
      mkdir -p "$WORKSPACE_ROOT/carla_download"
      download_to_file "$CARLA_ARCHIVE_URL" "$WORKSPACE_ROOT/carla_download/carla.tar.gz"
      mkdir -p "$CARLA_DIR"
      tar -xf "$WORKSPACE_ROOT/carla_download/carla.tar.gz" -C "$CARLA_DIR" --strip-components=1
    fi
  else
    cat <<EOF
CARLA is missing at:
  $CARLA_DIR

Set one of these before rerunning:
  CARLA_ARCHIVE_PATH=/path/to/carla.tar.gz
  CARLA_ARCHIVE_URL=https://...
EOF
    exit 1
  fi
fi

echo "[4/6] Preparing checkpoints"
run_or_echo mkdir -p "$PROJECT_ROOT/DriveTransformer/ckpts"

if [ ! -f "$PROJECT_ROOT/DriveTransformer/ckpts/drivetransformer_large.pth" ]; then
  if [ -n "$DT_LARGE_CKPT_PATH" ] && [ -f "$DT_LARGE_CKPT_PATH" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "[dry-run] Found local DriveTransformer checkpoint: $DT_LARGE_CKPT_PATH"
      echo "[dry-run] Would copy to $PROJECT_ROOT/DriveTransformer/ckpts/drivetransformer_large.pth"
    else
      cp "$DT_LARGE_CKPT_PATH" "$PROJECT_ROOT/DriveTransformer/ckpts/drivetransformer_large.pth"
    fi
  elif [ -n "$DT_LARGE_CKPT_URL" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "[dry-run] Will use DriveTransformer checkpoint URL: $DT_LARGE_CKPT_URL"
    else
      download_to_file "$DT_LARGE_CKPT_URL" "$PROJECT_ROOT/DriveTransformer/ckpts/drivetransformer_large.pth"
    fi
  else
    echo "Missing drivetransformer_large.pth. Set DT_LARGE_CKPT_PATH or DT_LARGE_CKPT_URL." >&2
    exit 1
  fi
fi

if [ ! -f "$PROJECT_ROOT/DriveTransformer/ckpts/resnet50-19c8e357.pth" ]; then
  if [ -n "$RESNET50_CKPT_PATH" ] && [ -f "$RESNET50_CKPT_PATH" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "[dry-run] Found local ResNet checkpoint: $RESNET50_CKPT_PATH"
      echo "[dry-run] Would copy to $PROJECT_ROOT/DriveTransformer/ckpts/resnet50-19c8e357.pth"
    else
      cp "$RESNET50_CKPT_PATH" "$PROJECT_ROOT/DriveTransformer/ckpts/resnet50-19c8e357.pth"
    fi
  elif [ -n "$RESNET50_CKPT_URL" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      check_url "$RESNET50_CKPT_URL"
      echo "[dry-run] Would download ResNet checkpoint from $RESNET50_CKPT_URL"
    else
      download_to_file "$RESNET50_CKPT_URL" "$PROJECT_ROOT/DriveTransformer/ckpts/resnet50-19c8e357.pth"
    fi
  else
    echo "Missing resnet50-19c8e357.pth. Set RESNET50_CKPT_PATH or RESNET50_CKPT_URL." >&2
    exit 1
  fi
fi

echo "[5/6] Running environment setup"
if [ "$DRY_RUN" -eq 1 ]; then
  if [ -f "$PROJECT_ROOT/setup_instance.sh" ]; then
    echo "[dry-run] Found setup script: $PROJECT_ROOT/setup_instance.sh"
    bash -n "$PROJECT_ROOT/setup_instance.sh"
  else
    echo "Missing setup_instance.sh at $PROJECT_ROOT/setup_instance.sh" >&2
    exit 1
  fi
else
  bash "$PROJECT_ROOT/setup_instance.sh"
fi

echo "[6/6] Bootstrap completed"
cat <<EOF

Bootstrap finished.

Repository:
  $PROJECT_ROOT

CARLA:
  $CARLA_DIR

Checkpoints:
  $PROJECT_ROOT/DriveTransformer/ckpts/drivetransformer_large.pth
  $PROJECT_ROOT/DriveTransformer/ckpts/resnet50-19c8e357.pth

Next:
  su - carlauser
  source /workspace/miniconda3/etc/profile.d/conda.sh
  conda activate dt38
  cd /workspace/end2end_AD_DriveTransformer/Bench2Drive
  bash start_eval_open_loop_wocontrol.sh
EOF

if [ "$DRY_RUN" -eq 1 ]; then
  cat <<EOF

Dry-run finished.

No packages were installed, no files were downloaded, and no archives were extracted.
This mode only checked the expected inputs, URLs, and local script availability.
EOF
fi
