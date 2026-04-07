# end2end_AD_DriveTransformer
End-to-end autonomous driving with DriveTransformer and CARLA.

Project repository:

`https://github.com/Insightmelon/end2end_AD_DriveTransformer`

## Quick start on a new Vast.ai instance

See:

[VASTAI_SETUP.md](/workspace/end2end_AD_DriveTransformer/VASTAI_SETUP.md)

That document covers:

- instance provisioning
- true zero-start bootstrap
- conda environment setup
- Vulkan setup for headless CARLA
- why CARLA must run as a non-root user
- how CARLA checkpoints and the local CARLA Python egg are wired into the env
- how to launch Bench2Drive evaluation scripts
- which requirements are mandatory for reproducible new instances
- lessons learned and common pitfalls from bringing the project up on a fresh headless machine

## What to read first

If you are setting up a fresh instance, read [VASTAI_SETUP.md](/workspace/end2end_AD_DriveTransformer/VASTAI_SETUP.md) in this order:

1. `Recommended workflow`
2. `Required for a reproducible new instance`
3. `Why PYTHONPATH is still needed`
4. `Lessons learned and common pitfalls`
5. `Post-run outputs`

## Practical summary

For a new instance, the most important rules are:

- provision the machine as `root`
- run CARLA and Bench2Drive as `carlauser`
- keep Vulkan configured and verify it with `vulkaninfo --summary`
- keep `-RenderOffScreen` on headless instances
- use the provided `start_eval*.sh` scripts rather than ad-hoc commands
- prefer absolute paths for checkpoints, routes, agents, and config pretrained weights
