#!/bin/bash

# This test file will be executed against the default scenario
# (see scenarios.json for the default scenario configuration)

set -e

# Optional: Import test library
source dev-container-features-test-lib

# Verify CUDA libraries are installed
check "cuda-libraries-installed" bash -c "ldconfig -p | grep -q libcuda || ls /usr/local/cuda*/lib64/libcudart* 2>/dev/null"

# Verify CUDA version file exists (indicates successful installation)
check "cuda-version-exists" bash -c "ls /usr/local/cuda*/version.* 2>/dev/null || apt list --installed 2>/dev/null | grep -q cuda-libraries"

# If cuDNN was requested, verify it's installed
if [ "${INSTALLCUDNN:-false}" = "true" ]; then
    check "cudnn-installed" bash -c "ldconfig -p | grep -q libcudnn"
fi

# If toolkit was requested, verify nvcc is available
if [ "${INSTALLTOOLKIT:-false}" = "true" ]; then
    check "nvcc-available" bash -c "which nvcc || ls /usr/local/cuda*/bin/nvcc"
fi

# Report results
reportResults
