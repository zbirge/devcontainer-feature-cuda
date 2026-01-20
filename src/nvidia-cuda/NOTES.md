## GPU Access Requirements

This Feature installs the shared CUDA libraries required for NVIDIA GPU support. For the GPU to be accessible inside the container:

1. **NVIDIA Container Toolkit** must be installed on the host machine
2. **NVIDIA GPU drivers** must be installed on the host

To verify GPU access inside the container, run:
```bash
nvidia-smi
```

## Supported Operating Systems

This feature automatically detects the OS and uses the appropriate NVIDIA repository:

| Distribution | Versions | Minimum CUDA |
|-------------|----------|--------------|
| Ubuntu | 18.04, 20.04, 22.04, 24.04 | 11.2 (18.04/20.04), 11.7 (22.04), 12.4 (24.04) |
| Debian | 10, 11, 12, 13 | 11.2 (10/11), 11.7 (12), 12.4 (13) |

## GPU Configuration in devcontainer.json

To enable GPU passthrough, add the following to your `devcontainer.json`:

```json
{
    "hostRequirements": {
        "gpu": "optional"
    }
}
```

Using `"gpu": "optional"` instead of `"gpu": true` allows the container to work on both GPU and non-GPU systems.

## Troubleshooting

If `nvidia-smi` is not available:

1. Verify the NVIDIA Container Toolkit is installed on the host
2. Ensure Docker/Podman is configured for GPU support
3. Check that the host has working NVIDIA drivers (`nvidia-smi` on host)
