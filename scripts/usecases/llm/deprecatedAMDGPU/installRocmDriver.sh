#!/bin/bash

# Install AMD ROCm 5.7.1 driver on AWS Ubuntu 20.04
# - Target: AWS G4ad instances (Radeon Pro V520)

set -e

# 1. Clean up previous installations
echo "Removing previous driver installations..."
# Remove any existing No-DKMS driver or broken packages
sudo apt-get remove --purge -y amdgpu-install amdgpu-dkms amdgpu rocm-dev rocm-libs || true
sudo apt-get autoremove -y

# 2. Install AWS Kernel Headers & Dependencies
echo "Installing dependencies and kernel headers for DKMS build..."
# Kernel headers are required for compiling the DKMS module
sudo DEBIAN_FRONTEND=noninteractive apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
    wget gnupg build-essential \
    linux-headers-$(uname -r) \
    linux-modules-extra-$(uname -r) \
    linux-firmware

# 3. Download ROCm 5.7.1 Installer
echo "Downloading installer for Ubuntu 20.04..."
cd /tmp
wget -q https://repo.radeon.com/amdgpu-install/5.7.1/ubuntu/focal/amdgpu-install_5.7.50701-1_all.deb
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y ./amdgpu-install_5.7.50701-1_all.deb

# 4. Install Driver & ROCm
echo "Installing AMDGPU Driver & ROCm (This takes 10-20 mins)..."
sudo amdgpu-install -y --usecase=dkms,rocm --no-32 --accept-eula

# 5. Final Configuration
echo "Finalizing configuration..."
echo "/opt/rocm/lib" | sudo tee /etc/ld.so.conf.d/rocm.conf
sudo ldconfig
sudo usermod -aG render,video $USER

echo "Installation complete!"
echo "System will reboot in 5 seconds. Please check 'rocm-smi' after reboot."
sleep 5
sudo reboot