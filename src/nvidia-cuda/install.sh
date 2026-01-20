#!/usr/bin/env bash
#-------------------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------------------
#
# Installs NVIDIA CUDA libraries with automatic OS detection.
# Supports: Ubuntu 18.04, 20.04, 22.04, 24.04 and Debian 10, 11, 12, 13
#
set -e

# Feature options (exported as environment variables by devcontainer)
CUDA_VERSION="${CUDAVERSION:-"12.6"}"
CUDNN_VERSION="${CUDNNVERSION:-"automatic"}"
INSTALL_CUDNN="${INSTALLCUDNN:-"false"}"
INSTALL_CUDNN_DEV="${INSTALLCUDNNDEV:-"false"}"
INSTALL_NVTX="${INSTALLNVTX:-"false"}"
INSTALL_TOOLKIT="${INSTALLTOOLKIT:-"false"}"

# Ensure script is run as root
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Source OS release information
. /etc/os-release

# Determine architecture
architecture="$(dpkg --print-architecture)"
case "${architecture}" in
    amd64) architecture="x86_64" ;;
    arm64) architecture="sbsa" ;;
    *)
        echo "Unsupported architecture: ${architecture}"
        exit 1
        ;;
esac

# Determine OS distribution string for NVIDIA repository
get_distro_string() {
    local distro_id="${ID}"
    local version_id="${VERSION_ID}"

    case "${distro_id}" in
        ubuntu)
            case "${version_id}" in
                18.04) echo "ubuntu1804" ;;
                20.04) echo "ubuntu2004" ;;
                22.04) echo "ubuntu2204" ;;
                24.04) echo "ubuntu2404" ;;
                *)
                    echo "Unsupported Ubuntu version: ${version_id}. Supported versions: 18.04, 20.04, 22.04, 24.04" >&2
                    exit 1
                    ;;
            esac
            ;;
        debian)
            case "${version_id}" in
                10) echo "debian10" ;;
                11) echo "debian11" ;;
                12) echo "debian12" ;;
                13) echo "debian13" ;;
                *)
                    echo "Unsupported Debian version: ${version_id}. Supported versions: 10, 11, 12, 13" >&2
                    exit 1
                    ;;
            esac
            ;;
        *)
            echo "Unsupported distribution: ${distro_id}. Supported distributions: ubuntu, debian" >&2
            exit 1
            ;;
    esac
}

DISTRO_STRING="$(get_distro_string)"
echo "Detected OS: ${ID} ${VERSION_ID} (${DISTRO_STRING})"

# Track if apt-get update has been run
apt_get_update_done=false

apt_get_update() {
    if [ "${apt_get_update_done}" = "false" ]; then
        echo "Running apt-get update..."
        apt-get update -y
        apt_get_update_done=true
    fi
}

# Check and install packages if missing
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# Validate CUDA version compatibility with distribution
validate_cuda_version() {
    local cuda_major="${CUDA_VERSION%%.*}"
    local cuda_minor="${CUDA_VERSION#*.}"
    cuda_minor="${cuda_minor%%.*}"

    # Debian 12 (bookworm) and Ubuntu 22.04+ require CUDA 11.7+
    if [ "${DISTRO_STRING}" = "debian12" ] || [ "${DISTRO_STRING}" = "ubuntu2204" ] || [ "${DISTRO_STRING}" = "ubuntu2404" ]; then
        if [ "${cuda_major}" -lt 11 ] || ([ "${cuda_major}" -eq 11 ] && [ "${cuda_minor}" -lt 7 ]); then
            echo "Error: ${ID} ${VERSION_ID} requires CUDA 11.7 or later. Requested: ${CUDA_VERSION}"
            exit 1
        fi
    fi

    # Ubuntu 24.04 and Debian 13 (trixie) require CUDA 12.4+
    if [ "${DISTRO_STRING}" = "ubuntu2404" ] || [ "${DISTRO_STRING}" = "debian13" ]; then
        if [ "${cuda_major}" -lt 12 ] || ([ "${cuda_major}" -eq 12 ] && [ "${cuda_minor}" -lt 4 ]); then
            echo "Error: ${ID} ${VERSION_ID} requires CUDA 12.4 or later. Requested: ${CUDA_VERSION}"
            exit 1
        fi
    fi
}

validate_cuda_version

# Install prerequisites
check_packages ca-certificates curl gnupg

# Set up NVIDIA repository
NVIDIA_REPO_URL="https://developer.download.nvidia.com/compute/cuda/repos/${DISTRO_STRING}/${architecture}"
KEYRING_PATH="/usr/share/keyrings/nvidia-cuda-keyring.gpg"

echo "Setting up NVIDIA CUDA repository: ${NVIDIA_REPO_URL}"

# Download and install NVIDIA keyring
curl -fsSL "${NVIDIA_REPO_URL}/cuda-keyring_1.1-1_all.deb" -o /tmp/cuda-keyring.deb
dpkg -i /tmp/cuda-keyring.deb
rm /tmp/cuda-keyring.deb

# Force apt-get update after adding new repository
apt_get_update_done=false
apt_get_update

# Construct CUDA package version string
# NVIDIA uses format like cuda-libraries-11-8 for CUDA 11.8
CUDA_VERSION_DASHED="${CUDA_VERSION//./-}"

# Verify requested CUDA version is available
echo "Checking availability of CUDA ${CUDA_VERSION}..."
if ! apt-cache show "cuda-libraries-${CUDA_VERSION_DASHED}" > /dev/null 2>&1; then
    echo "Error: CUDA version ${CUDA_VERSION} is not available for ${ID} ${VERSION_ID} (${architecture})"
    echo "Available CUDA library packages:"
    apt-cache search "^cuda-libraries-[0-9]" || true
    exit 1
fi

# Install CUDA libraries
echo "Installing CUDA ${CUDA_VERSION} libraries..."
apt-get -y install --no-install-recommends \
    "cuda-libraries-${CUDA_VERSION_DASHED}"

# Install cuDNN if requested
if [ "${INSTALL_CUDNN}" = "true" ] || [ "${INSTALL_CUDNN_DEV}" = "true" ]; then
    echo "Installing cuDNN..."

    # Determine cuDNN version
    if [ "${CUDNN_VERSION}" = "automatic" ]; then
        # Find the latest compatible cuDNN version
        CUDNN_PACKAGE=$(apt-cache search "^libcudnn[0-9]+-cuda-${CUDA_VERSION%%.*}$" | sort -V | tail -n1 | awk '{print $1}')
        if [ -z "${CUDNN_PACKAGE}" ]; then
            echo "Warning: Could not find compatible cuDNN package for CUDA ${CUDA_VERSION}. Trying generic search..."
            CUDNN_PACKAGE=$(apt-cache search "^libcudnn[0-9]+" | grep -v dev | sort -V | tail -n1 | awk '{print $1}')
        fi
        if [ -z "${CUDNN_PACKAGE}" ]; then
            echo "Error: Could not find any cuDNN package"
            exit 1
        fi
        echo "Auto-selected cuDNN package: ${CUDNN_PACKAGE}"
        apt-get -y install --no-install-recommends "${CUDNN_PACKAGE}"
    else
        # Install specific cuDNN version
        CUDNN_MAJOR="${CUDNN_VERSION%%.*}"
        apt-get -y install --no-install-recommends "libcudnn${CUDNN_MAJOR}=${CUDNN_VERSION}-1+cuda${CUDA_VERSION%%.*}" || \
        apt-get -y install --no-install-recommends "libcudnn${CUDNN_MAJOR}"
    fi

    # Install cuDNN dev packages if requested
    if [ "${INSTALL_CUDNN_DEV}" = "true" ]; then
        echo "Installing cuDNN development packages..."
        if [ "${CUDNN_VERSION}" = "automatic" ]; then
            CUDNN_DEV_PACKAGE=$(apt-cache search "^libcudnn[0-9]+-dev-cuda-${CUDA_VERSION%%.*}$" | sort -V | tail -n1 | awk '{print $1}')
            if [ -z "${CUDNN_DEV_PACKAGE}" ]; then
                CUDNN_DEV_PACKAGE=$(apt-cache search "^libcudnn[0-9]+-dev" | sort -V | tail -n1 | awk '{print $1}')
            fi
            if [ -n "${CUDNN_DEV_PACKAGE}" ]; then
                apt-get -y install --no-install-recommends "${CUDNN_DEV_PACKAGE}"
            fi
        else
            apt-get -y install --no-install-recommends "libcudnn${CUDNN_MAJOR}-dev=${CUDNN_VERSION}-1+cuda${CUDA_VERSION%%.*}" || \
            apt-get -y install --no-install-recommends "libcudnn${CUDNN_MAJOR}-dev" || true
        fi
    fi
fi

# Install NVTX if requested
if [ "${INSTALL_NVTX}" = "true" ]; then
    echo "Installing NVIDIA Tools Extension (NVTX)..."
    apt-get -y install --no-install-recommends "cuda-nvtx-${CUDA_VERSION_DASHED}" || \
    apt-get -y install --no-install-recommends cuda-nvtx || true
fi

# Install CUDA Toolkit if requested
if [ "${INSTALL_TOOLKIT}" = "true" ]; then
    echo "Installing CUDA Toolkit..."
    apt-get -y install --no-install-recommends "cuda-toolkit-${CUDA_VERSION_DASHED}"
fi

# Cleanup
rm -rf /var/lib/apt/lists/*

echo "NVIDIA CUDA installation complete!"
echo "  - CUDA Version: ${CUDA_VERSION}"
echo "  - Distribution: ${ID} ${VERSION_ID}"
echo "  - Architecture: ${architecture}"
[ "${INSTALL_CUDNN}" = "true" ] && echo "  - cuDNN: installed"
[ "${INSTALL_CUDNN_DEV}" = "true" ] && echo "  - cuDNN Dev: installed"
[ "${INSTALL_NVTX}" = "true" ] && echo "  - NVTX: installed"
[ "${INSTALL_TOOLKIT}" = "true" ] && echo "  - Toolkit: installed"
