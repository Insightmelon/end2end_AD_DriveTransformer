#!/bin/bash
set -e

# Single-GPU closed-loop evaluation for the mini Bench2Drive setup.

export CARLA_ROOT="/workspace/end2end_AD_DriveTransformer/carla"
export CARLA_SERVER="/workspace/end2end_AD_DriveTransformer/carla/CarlaUE4.sh"
export SCENARIO_RUNNER_ROOT="/workspace/end2end_AD_DriveTransformer/Bench2Drive/scenario_runner"
export PYTHONPATH="/workspace/end2end_AD_DriveTransformer/carla/PythonAPI:/workspace/end2end_AD_DriveTransformer/carla/PythonAPI/carla:/workspace/end2end_AD_DriveTransformer/carla/PythonAPI/carla/dist/carla-0.9.15-py3.7-linux-x86_64.egg:/workspace/end2end_AD_DriveTransformer/Bench2Drive:/workspace/end2end_AD_DriveTransformer/Bench2Drive/leaderboard:/workspace/end2end_AD_DriveTransformer/Bench2Drive/leaderboard/team_code:/workspace/end2end_AD_DriveTransformer/Bench2Drive/scenario_runner"
export XDG_RUNTIME_DIR="/tmp/runtime-carlauser"
export VK_ICD_FILENAMES="/etc/vulkan/icd.d/my_nvidia_icd.json"
mkdir -p "$XDG_RUNTIME_DIR"

PYTHON="${PYTHON:-/workspace/miniconda3/envs/dt38/bin/python}"
PROGRAM="leaderboard/leaderboard/leaderboard_evaluator.py"

CONFIG="${CONFIG:-/workspace/end2end_AD_DriveTransformer/DriveTransformer/adzoo/drivetransformer/configs/drivetransformer/drivetransformer_large_single_gpu_24g_30epoch.py}"
DEFAULT_CKPT="/workspace/end2end_AD_DriveTransformer/DriveTransformer/adzoo/drivetransformer/work_dirs/drivetransformer/drivetransformer_large_single_gpu_24g_30epoch/latest.pth"
CKPT="${CKPT:-$DEFAULT_CKPT}"

ROUTES="${ROUTES:-/workspace/end2end_AD_DriveTransformer/Bench2Drive/leaderboard/data/drivetransformer_bench2drive_dev10.xml}"
RESULT_DIR="${RESULT_DIR:-/workspace/end2end_AD_DriveTransformer/Bench2Drive/DriveTransformer_b2d_large_single_gpu_24g_30epoch_dev10}"
RESULT_JSON="${RESULT_JSON:-$RESULT_DIR/eval_large_single_gpu_24g_30epoch_dev10.json}"

cd /workspace/end2end_AD_DriveTransformer/Bench2Drive
mkdir -p "$RESULT_DIR"

if [ ! -f "$CKPT" ]; then
    echo "Checkpoint not found: $CKPT"
    echo "Set CKPT=/path/to/checkpoint.pth if you want to evaluate a specific checkpoint."
    exit 1
fi

$PYTHON $PROGRAM \
    --routes="$ROUTES" \
    --repetitions=1 \
    --track=SENSORS \
    --checkpoint="$RESULT_JSON" \
    --agent=/workspace/end2end_AD_DriveTransformer/Bench2Drive/leaderboard/team_code/drivetransformer_vis_agent.py \
    --agent-config="$CONFIG+$CKPT" \
    --debug=0 \
    --record="" \
    --port=30001 \
    --traffic-manager-port=50000 \
    --gpu-rank=0
