# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Purpose

This project provides a dev container feature for NVIDIA CUDA that supports multiple Debian and Ubuntu versions with automatic OS detection. The upstream feature at `devcontainers/features` is hardcoded to `ubuntu2204`.

## Build and Test Commands

```bash
# Install devcontainer CLI
npm install -g @devcontainers/cli

# Test all scenarios
devcontainer features test --features nvidia-cuda --project-folder .

# Test a specific scenario
devcontainer features test --features nvidia-cuda --skip-scenarios \
  --base-image mcr.microsoft.com/devcontainers/base:ubuntu-22.04 \
  --project-folder .

# Build feature for local testing
devcontainer features package ./src --output-folder ./output
```

## Project Structure

```
src/nvidia-cuda/
  devcontainer-feature.json  # Feature metadata and options
  install.sh                 # Installation script with OS auto-detection
  NOTES.md                   # User-facing documentation

test/nvidia-cuda/
  scenarios.json             # Test scenario definitions
  test.sh                    # Test verification script

.github/workflows/
  test.yaml                  # CI testing on PRs
  release.yaml               # Publish to GHCR on tags
```

## Key Implementation Details

**OS Auto-Detection**: The `install.sh` script reads `/etc/os-release` to determine the distribution and version, then constructs the appropriate NVIDIA repository URL.

**Supported Platforms**:
- Ubuntu: 20.04, 22.04, 24.04
- Debian: 11, 12

**NVIDIA Repository**: All supported distros are listed at `https://developer.download.nvidia.com/compute/cuda/repos/`. Use this URL to verify available versions when updating supported platforms. Additional distros available (not yet implemented): Fedora, RHEL, Amazon Linux, Azure Linux, openSUSE, SLES.

**Version Constraints**:
- Debian 12 and Ubuntu 22.04 require CUDA 11.7+
- Ubuntu 24.04 requires CUDA 12.4+

## Reference Resources

- NVIDIA CUDA repos: `https://developer.download.nvidia.com/compute/cuda/repos/`
- Dev container feature template: `https://github.com/devcontainers/feature-template`
- Original NVIDIA CUDA feature: `https://github.com/devcontainers/features/blob/main/src/nvidia-cuda/`
