# NVIDIA CUDA Dev Container Feature

A dev container feature that installs NVIDIA CUDA libraries with automatic OS detection. Supports multiple Debian and Ubuntu versions.

## Usage

Add the feature to your `devcontainer.json`:

```json
{
    "features": {
        "ghcr.io/zbirge/devcontainer-feature-cuda/nvidia-cuda:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `cudaVersion` | string | `12.6` | CUDA version to install (12.6, 12.5, 12.4, ... 11.2) |
| `installCudnn` | boolean | `false` | Install cuDNN shared library |
| `installCudnnDev` | boolean | `false` | Install cuDNN development libraries |
| `cudnnVersion` | string | `automatic` | cuDNN version (or `automatic`) |
| `installNvtx` | boolean | `false` | Install NVIDIA Tools Extension |
| `installToolkit` | boolean | `false` | Install NVIDIA CUDA Toolkit |

## Supported Platforms

| Distribution | Versions | Minimum CUDA |
|-------------|----------|--------------|
| Ubuntu | 20.04, 22.04, 24.04 | 11.2 / 11.7 / 12.4 |
| Debian | 11, 12 | 11.2 / 11.7 |

## GPU Access

To enable GPU passthrough, add to your `devcontainer.json`:

```json
{
    "hostRequirements": {
        "gpu": "optional"
    }
}
```

The host machine requires:
- NVIDIA GPU drivers
- NVIDIA Container Toolkit

Verify GPU access inside the container with `nvidia-smi`.

## Development

```bash
# Install devcontainer CLI
npm install -g @devcontainers/cli

# Test all scenarios
devcontainer features test --features nvidia-cuda --project-folder .

# Package feature
devcontainer features package ./src --output-folder ./output
```

## Publishing

Create a git tag to trigger the release workflow:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The feature will be published to GHCR automatically.
