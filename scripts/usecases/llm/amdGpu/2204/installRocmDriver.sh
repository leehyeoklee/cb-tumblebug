#!/bin/bash

# Install AMD ROCm 5.7.1 driver on Ubuntu 22.04
# - Requires Linux Kernel 5.15 (must run kernelDowngrade.sh first)
# - Downloads and installs ROCm 5.7.1 package from AMD repository
# - Configures AMDGPU driver and ROCm runtime for GPU compute
# - Adds user to render/video groups and reboots system

set -e

# Verify Kernel 5.15
if [[ "$(uname -r)" != *"5.15"* ]]; then
    echo "ERROR: Kernel mismatch ($(uname -r)). Please reboot into 5.15 first."
    exit 1
fi

# 1. Install Dependencies
echo "Installing dependencies..."
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y wget gnupg2

# 2. Download ROCm 5.7.1 Installer
echo "Downloading installer..."
cd /tmp
wget -q https://repo.radeon.com/amdgpu-install/5.7.1/ubuntu/jammy/amdgpu-install_5.7.50701-1_all.deb
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ./amdgpu-install_5.7.50701-1_all.deb

# 3. Install Driver & ROCm
echo "Installing AMDGPU Driver & ROCm (This takes 10-20 mins)..."
sudo DEBIAN_FRONTEND=noninteractive amdgpu-install -y --usecase=dkms,rocm --no-32

# 4. Final Configuration
echo "Finalizing configuration..."
sudo ldconfig
sudo usermod -aG render,video $USER

sudo reboot