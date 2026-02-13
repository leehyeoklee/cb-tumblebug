#!/bin/bash

# Fix AMD GPU firmware compatibility issues
# - Removes incompatible kernel 6.5/6.8 packages
# - Downloads and installs specific linux-firmware (20220329) for kernel 5.15
# - Replaces /lib/firmware/amdgpu with compatible version
# - Updates initramfs to apply firmware changes

set -e

# Verify Kernel 5.15
if [[ "$(uname -r)" != *"5.15"* ]]; then
    echo "ERROR: Kernel mismatch ($(uname -r)). Please reboot into 5.15 first."
    exit 1
fi

# 1. Purge incompatible kernels
echo "Purging incompatible kernels..."
sudo apt-get purge -y linux-image-6.8* linux-headers-6.8* linux-modules-6.8* linux-modules-extra-6.8* linux-image-6.5* linux-headers-6.5* || true
sudo apt-get autoremove -y
sudo update-grub

# 2. Patch Firmware
echo "Downloading specific firmware version..."
mkdir -p /tmp/fw_fix && cd /tmp/fw_fix
wget -q https://archive.ubuntu.com/ubuntu/pool/main/l/linux-firmware/linux-firmware_20220329.git681281e4.orig.tar.xz
tar -xf linux-firmware_20220329.git681281e4.orig.tar.xz

# Replace firmware files
echo "Replacing AMDGPU firmware..."
sudo rm -rf /lib/firmware/amdgpu/*
sudo mkdir -p /lib/firmware/amdgpu
sudo cp -r linux-firmware-20220329.git681281e4/amdgpu/* /lib/firmware/amdgpu/

# Update initramfs
echo "Updating initramfs..."
sudo update-initramfs -u