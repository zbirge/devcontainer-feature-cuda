#!/bin/bash
set -e
source dev-container-features-test-lib
check "cuda-libraries-installed" bash -c "ldconfig -p | grep -q libcuda || ls /usr/local/cuda*/lib64/libcudart* 2>/dev/null || apt list --installed 2>/dev/null | grep -q cuda-libraries"
check "nvcc-available" bash -c "which nvcc || ls /usr/local/cuda*/bin/nvcc 2>/dev/null"
reportResults
