# Vast.ai / New Instance Setup

This project runs most reliably with a two-phase workflow:

1. Use `root` once to provision the instance.
2. Use a non-root user such as `carlauser` to run CARLA and Bench2Drive.

This matters because CARLA refuses to run as `root`, while package installation and system configuration usually require `root`.

Project repository:

`https://github.com/Insightmelon/end2end_AD_DriveTransformer`

## Setup modes

There are now two supported setup modes:

1. Existing project assets already present on the instance
   Use:

```bash
bash setup_instance.sh
```

2. True zero-start bootstrap on a fresh instance
   Use:

```bash
bash bootstrap_instance.sh
```

To preflight a fresh instance without downloading or installing anything:

```bash
bash bootstrap_instance.sh --dry-run
```

Use `bootstrap_instance.sh` when the repository, CARLA files, or checkpoints are not already present.

Default zero-start asset sources currently assumed by `bootstrap_instance.sh`:

- CARLA 0.9.15:
  `https://carla-releases.s3.us-east-005.backblazeb2.com/Linux/CARLA_0.9.15.tar.gz`
- `drivetransformer_large.pth`:
  `https://drive.google.com/file/d/1wAXFWfjJm0cmP_pmgTkwxTUEs6Zu5j6i/view`
- `resnet50-19c8e357.pth`:
  `https://huggingface.co/rethinklab/Bench2DriveZoo/resolve/main/resnet50-19c8e357.pth`

## Quick checklist

Use this as the shortest practical checklist for a fresh instance:

1. If the repo / CARLA / checkpoints are missing, run `bash bootstrap_instance.sh` as `root`; otherwise run `bash setup_instance.sh` as `root`
2. Confirm the repository is present at `/workspace/end2end_AD_DriveTransformer`
3. Confirm the `dt38` conda environment exists
4. Confirm `carlauser` exists and can use `sudo`
5. Switch to `carlauser`
6. Activate the environment with `conda activate dt38`
7. Verify GPU visibility with `nvidia-smi`
8. Verify Vulkan with `VK_ICD_FILENAMES=/etc/vulkan/icd.d/my_nvidia_icd.json vulkaninfo --summary`
9. Run evaluation from `Bench2Drive` using one of the provided `start_eval*.sh` scripts
10. If CARLA fails early, check Vulkan, `XDG_RUNTIME_DIR`, and that you are not running as `root`

## Recommended workflow

### Option A. Existing project already copied to the instance

### 1. Provision the instance as `root`

From the repo root:

```bash
bash setup_instance.sh
```

What this script does:

- installs system packages needed for building and running the project
- installs Miniconda to `/workspace/miniconda3` if needed
- creates or updates the `dt38` conda environment
- installs Python dependencies from `requirements_frozen.txt`
- installs Vulkan runtime packages
- writes `/etc/vulkan/icd.d/my_nvidia_icd.json`
- registers the CARLA Python `.egg` into the active conda environment through `carla.pth` when the local bundle is present
- creates a non-root runtime user named `carlauser`
- grants `carlauser` passwordless `sudo`
- prepares `/tmp/runtime-carlauser`

### Option B. True zero-start bootstrap

Use this if a fresh instance does not already contain:

- the repository
- the `carla/` directory
- the required checkpoint files

Run:

```bash
bash bootstrap_instance.sh
```

Important:

`bootstrap_instance.sh` already has working default URLs for CARLA and the two required checkpoints. Override them only if you want to use your own mirror, local archive, or private storage.

Supported variables:

```bash
REPO_URL
REPO_REF
CARLA_ARCHIVE_PATH
CARLA_ARCHIVE_URL
DT_LARGE_CKPT_PATH
DT_LARGE_CKPT_URL
RESNET50_CKPT_PATH
RESNET50_CKPT_URL
```

Default repository source used by `bootstrap_instance.sh`:

```bash
REPO_URL=https://github.com/Insightmelon/end2end_AD_DriveTransformer.git
REPO_REF=main
```

Example:

```bash
CARLA_ARCHIVE_PATH=/workspace/assets/carla.tar.gz \
DT_LARGE_CKPT_PATH=/workspace/assets/drivetransformer_large.pth \
RESNET50_CKPT_PATH=/workspace/assets/resnet50-19c8e357.pth \
bash bootstrap_instance.sh
```

Preflight example:

```bash
bash bootstrap_instance.sh --dry-run
```

The setup flow also registers the local CARLA Python egg into the active conda environment by writing a `carla.pth` file. This mirrors the manual fix:

```bash
echo "$CARLA_ROOT/PythonAPI/carla/dist/carla-0.9.15-py3.7-linux-x86_64.egg" >> YOUR_CONDA_PATH/envs/YOUR_CONDA_ENV_NAME/lib/python3.8/site-packages/carla.pth
```

### 2. Switch to the runtime user

```bash
su - carlauser
```

### 3. Activate the conda environment

```bash
source /workspace/miniconda3/etc/profile.d/conda.sh
conda activate dt38
```

### 4. Verify Vulkan

```bash
export VK_ICD_FILENAMES=/etc/vulkan/icd.d/my_nvidia_icd.json
vulkaninfo --summary
```

You should see the NVIDIA GPU listed, for example `NVIDIA GeForce RTX 4090`.

### 5. Run Bench2Drive

```bash
cd /workspace/end2end_AD_DriveTransformer/Bench2Drive
bash start_eval_open_loop_wocontrol.sh
```

The start scripts already export:

- `XDG_RUNTIME_DIR`
- `VK_ICD_FILENAMES`
- `PYTHONPATH`

and the evaluator already launches CARLA with:

```bash
-RenderOffScreen
```

which is the correct mode for headless instances.

## Required for a reproducible new instance

These items are not optional if you want a fresh Vast.ai instance to reproduce the current working setup quickly.

### Must-have system requirements

- NVIDIA GPU visible from the instance
- working NVIDIA driver stack
- Vulkan runtime packages installed
- CARLA available at `/workspace/end2end_AD_DriveTransformer/carla`
- Miniconda available at `/workspace/miniconda3`
- required checkpoints available under `DriveTransformer/ckpts`

### Must-have runtime conditions

- use `root` for provisioning only
- run CARLA and Bench2Drive as a non-root user such as `carlauser`
- keep `-RenderOffScreen` for headless instances
- keep `VK_ICD_FILENAMES=/etc/vulkan/icd.d/my_nvidia_icd.json`
- keep `XDG_RUNTIME_DIR=/tmp/runtime-carlauser`
- run evaluation through the provided `start_eval*.sh` scripts

### Must-have path conventions

- use absolute paths for `--routes`
- use absolute paths for `--checkpoint`
- use absolute paths for `--agent`
- use absolute paths for the checkpoint part of `--agent-config`
- use absolute paths for config `pretrained=dict(img=...)` entries

This project had multiple runtime failures caused by relative paths resolving from `Bench2Drive` instead of the repo root.

### Must-have Python and CARLA import setup

- the active conda environment must be able to import `carla`
- `requirements_frozen.txt` and `environment_dt38.yml` both include `carla==0.9.15`
- `setup_instance.sh` also registers the local CARLA egg from:
  `/workspace/end2end_AD_DriveTransformer/carla/PythonAPI/carla/dist/carla-0.9.15-py3.7-linux-x86_64.egg`

Keeping both the pip package and the local `.egg` path available turned out to be the safest setup for fresh headless instances.

## Why `PYTHONPATH` is still needed

This repository is not used purely as a fully installed Python package.
Several runtime imports depend on source directories being visible directly, including:

- `leaderboard`
- `team_code`
- `srunner`
- `carla` PythonAPI and its `.egg`

Because of that, the `start_eval*.sh` scripts explicitly export `PYTHONPATH`.

Recommended practice:

- keep the `PYTHONPATH` export inside the start scripts
- do not rely on a manually configured global shell `PYTHONPATH`
- when possible, launch evaluations through the provided `start_eval*.sh` scripts instead of ad-hoc Python commands
- keep the `carla.pth` registration performed by `setup_instance.sh`

## Lessons learned and common pitfalls

These are not just theoretical notes. They came directly from bringing this project up on a fresh headless instance.

## Switching instances with Vast.ai storage copy

Vast.ai storage copy turned out to be a practical way to move work from one instance to another when the original machine was stopped but not destroyed.

Practical pattern:

1. keep the source instance stopped so its storage is preserved
2. provision a destination instance with enough disk capacity
3. use Vast.ai storage copy from the source instance to the destination instance
4. validate the copied environment on the destination instance before resuming work

What storage copy preserved well in practice:

- repository changes under `/workspace/end2end_AD_DriveTransformer`
- local documents and setup notes
- checkpoints under `DriveTransformer/ckpts`
- the copied Miniconda tree under `/workspace/miniconda3`
- CARLA files stored under `/workspace/end2end_AD_DriveTransformer/carla`

What still needed to be revalidated on the new instance:

- `carlauser` runtime permissions
- `sudo` behavior for `carlauser`
- GPU driver health through `nvidia-smi`
- Vulkan health through `vulkaninfo --summary`
- CARLA runtime health by launching CARLA and checking port `30002`

Two concrete issues appeared after switching with storage copy:

### `carlauser` existed but lost passwordless `sudo`

The copied workspace preserved the user-related expectations in the project, but the new instance still needed system-level sudo configuration to be restored.

Symptom:

```bash
sudo -n true
sudo: a password is required
```

Fix:

```bash
usermod -aG sudo carlauser
echo 'carlauser ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/90-carlauser
chmod 440 /etc/sudoers.d/90-carlauser
```

Then verify:

```bash
su - carlauser
sudo -n true && echo "sudo ok"
```

### `nvidia-smi` initially failed after the copy

After switching instances, `nvidia-smi` failed with a driver/library mismatch and Vulkan also failed. This turned out not to be a project problem but an instance-level GPU runtime problem.

Observed symptoms:

```bash
nvidia-smi
Failed to initialize NVML: Driver/library version mismatch
```

and:

```bash
vulkaninfo --summary
vkCreateInstance failed with ERROR_INCOMPATIBLE_DRIVER
```

What fixed it in practice:

- reboot the new instance
- rerun:

```bash
nvidia-smi
export VK_ICD_FILENAMES=/etc/vulkan/icd.d/my_nvidia_icd.json
vulkaninfo --summary
```

After reboot, both `nvidia-smi` and Vulkan returned to a healthy state and CARLA launched normally again.

Bottom line:

- storage copy is very effective for preserving `/workspace` state
- storage copy does not guarantee that system-level runtime state is still valid on the destination instance
- always recheck GPU, Vulkan, `carlauser`, and CARLA launch after an instance switch

### 1. `nvidia-smi` being healthy is not enough

The instance can see the GPU and still fail to start CARLA.

The real requirement is:

- Vulkan runtime installed
- valid NVIDIA Vulkan ICD
- `vulkaninfo --summary` working

If CARLA exits early and prints almost nothing, Vulkan is one of the first things to verify.

### 2. CARLA must not run as `root`

Provisioning as `root` is fine.
Running CARLA as `root` is not.

This is why the setup flow is split into:

- `root` for installation and system configuration
- `carlauser` for runtime

### 3. Headless instances should stay on `-RenderOffScreen`

This environment does not provide a usable desktop display session by default.

If you remove `-RenderOffScreen`, CARLA may fail to launch again unless you explicitly set up a graphical desktop or X11/Wayland forwarding.

### 4. Relative paths are fragile in this repo

Several failures came from paths that worked only from one working directory.

Examples:

- model checkpoints passed through `--agent-config`
- config pretrained weights under `./ckpts/...`

Absolute paths are strongly preferred for reproducibility.

### 4.5. Zero-start recovery depends on asset availability

The environment setup can be made reproducible, but CARLA binaries and checkpoints still need a reliable source.

For a true zero-start workflow, you should keep at least one of these ready:

- a private object storage URL
- a mounted volume containing CARLA and checkpoints
- a local archive bundle copied into the new instance

### 5. `meta/*.json` was originally empty in open-loop wocontrol mode

The original control flow called `save()` before populating the metadata dictionary.

It has now been updated so that `meta/*.json` can store:

- frame-level control state
- speed and pose-related values
- OD detections
- map predictions
- ego trajectory information

### 6. Evaluation outputs are worth keeping

Useful artifacts produced during evaluation include:

- `save_path/.../bev`
- `save_path/.../rgb_front` and other camera folders
- `save_path/.../meta/*.json`

These can be turned into GIFs or compressed archives after the run.

### 7. New instances may still need local extension rebuilds

Even if Python packages install successfully, custom local ops or compiled `.so` files may still be an issue on a different machine.

If runtime errors mention local MMCV ops, extension rebuilding should be considered early.

## Post-run outputs

After a successful run, look under:

```bash
/workspace/end2end_AD_DriveTransformer/Bench2Drive/save_path
```

Typical per-scenario artifacts:

- `bev/*.png`
- `rgb_front/*.png`
- `rgb_front_left/*.png`
- `rgb_front_right/*.png`
- `rgb_back/*.png`
- `rgb_back_left/*.png`
- `rgb_back_right/*.png`
- `meta/*.json`

Recommended post-processing:

- convert `bev` or `rgb_front` sequences into GIFs
- archive `meta/*.json` using `7z` if sharing or downloading results
- prefer `.7z` over `.zip` for large JSON collections

## Why not run everything as root?

CARLA refuses to run as `root`.

So the practical pattern is:

- `root` for provisioning
- `carlauser` for runtime

This is why `setup_instance.sh` creates `carlauser` and grants it `sudo`.

If you prefer, you can log in as `carlauser` after provisioning and still install packages later with:

```bash
sudo apt install ...
sudo pip ...
```

because the script grants `carlauser` passwordless `sudo`.

## Files that matter for reproducibility

- `bootstrap_instance.sh`
  Zero-start bootstrap for fresh instances without repo / CARLA / checkpoints already present.
- `environment_dt38.yml`
  Full conda environment snapshot.
- `requirements_frozen.txt`
  Frozen Python package list used by the setup script.
- `setup_instance.sh`
  Main provisioning script for new instances.

## Common validation commands

Check GPU visibility:

```bash
nvidia-smi
```

Check Vulkan:

```bash
export VK_ICD_FILENAMES=/etc/vulkan/icd.d/my_nvidia_icd.json
vulkaninfo --summary
```

Check CARLA process and port after launch:

```bash
ps -ef | grep CarlaUE4 | grep -v grep
ss -ltnp | grep 30002
```

## Common issues

### CARLA fails with root privilege error

Run as `carlauser`, not `root`.

### `XDG_RUNTIME_DIR not set`

Use:

```bash
export XDG_RUNTIME_DIR=/tmp/runtime-carlauser
```

The start scripts already do this.

### CARLA starts and exits immediately

Check:

```bash
export VK_ICD_FILENAMES=/etc/vulkan/icd.d/my_nvidia_icd.json
vulkaninfo --summary
```

If Vulkan is not working, CARLA may exit before writing useful logs.

### Git says `dubious ownership`

If you need to use Git as `root`:

```bash
git config --global --add safe.directory /workspace/end2end_AD_DriveTransformer
```

Using the repository owner or `carlauser` is usually cleaner.
