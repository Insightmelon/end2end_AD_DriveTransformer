#!/bin/bash

# 设置环境变量
export CARLA_ROOT="/workspace/end2end_AD_DriveTransformer/carla"
export CARLA_SERVER="/workspace/end2end_AD_DriveTransformer/carla/CarlaUE4.sh"
export SCENARIO_RUNNER_ROOT="/workspace/end2end_AD_DriveTransformer/Bench2Drive/scenario_runner"
export PYTHONPATH="/workspace/end2end_AD_DriveTransformer/carla/PythonAPI:/workspace/end2end_AD_DriveTransformer/carla/PythonAPI/carla:/workspace/end2end_AD_DriveTransformer/carla/PythonAPI/carla/dist/carla-0.9.15-py3.7-linux-x86_64.egg:/workspace/end2end_AD_DriveTransformer/Bench2Drive:/workspace/end2end_AD_DriveTransformer/Bench2Drive/leaderboard:/workspace/end2end_AD_DriveTransformer/Bench2Drive/leaderboard/team_code:/workspace/end2end_AD_DriveTransformer/Bench2Drive:/workspace/end2end_AD_DriveTransformer/Bench2Drive/scenario_runner"
export XDG_RUNTIME_DIR="/tmp/runtime-carlauser"
export VK_ICD_FILENAMES="/etc/vulkan/icd.d/my_nvidia_icd.json"
mkdir -p "$XDG_RUNTIME_DIR"

# Python路径
PYTHON="/workspace/miniconda3/envs/dt38/bin/python"
PROGRAM="leaderboard/leaderboard/leaderboard_evaluator.py"

cd /workspace/end2end_AD_DriveTransformer/Bench2Drive

# 创建输出目录
mkdir -p DriveTransformer_b2d_open_loop

echo "========================================"
echo "开环仿真 - 使用GT航点"
echo "Open-loop Simulation with GT Waypoints"
echo "========================================"
echo ""
echo "按 Ctrl+C 停止仿真"
echo "========================================"

# 执行命令
$PYTHON $PROGRAM \
    --routes=/workspace/end2end_AD_DriveTransformer/Bench2Drive/leaderboard/data/drivetransformer_bench2drive_dev10_open_loop.xml \
    --repetitions=1 \
    --track=SENSORS \
    --checkpoint=/workspace/end2end_AD_DriveTransformer/Bench2Drive/DriveTransformer_b2d_open_loop/eval_bench2drive_dev_10_open_loop.json \
    --agent=/workspace/end2end_AD_DriveTransformer/Bench2Drive/leaderboard/team_code/drivetransformer_vis_agent.py \
    --agent-config=/workspace/end2end_AD_DriveTransformer/DriveTransformer/adzoo/drivetransformer/configs/drivetransformer/drivetransformer_large.py+/workspace/end2end_AD_DriveTransformer/DriveTransformer/ckpts/drivetransformer_large.pth \
    --debug=0 \
    --record="" \
    --port=30002 \
    --traffic-manager-port=50001 \
    --gpu-rank=0

echo ""
echo "========================================"
echo "仿真结束"
echo "========================================"
