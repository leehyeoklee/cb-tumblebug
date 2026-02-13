#!/bin/bash

# Downgrade Linux kernel to 5.15 for ROCm compatibility
# - Installs Linux 5.15.0-1068-aws kernel (required for ROCm 5.7.1)
# - Configures GRUB to boot into kernel 5.15 by default
# - Required first step before running installRocmDriver.sh

set -e

# 1. Install Kernel 5.15
echo "Installing Linux Kernel 5.15..."
sudo apt-get update -qq
sudo apt-get install -y linux-image-5.15.0-1068-aws linux-headers-5.15.0-1068-aws linux-modules-extra-5.15.0-1068-aws

# 2. Configure GRUB to boot 5.15
echo "Configuring GRUB..."
sudo cp /etc/default/grub /etc/default/grub.bak

# Find the 5.15 kernel entry in GRUB menu
echo "Finding 5.15 kernel in GRUB menu..."
KERNEL_ENTRY=$(grep -E "menuentry.*5\.15\.0-1068" /boot/grub/grub.cfg | head -1 | sed "s/.*'\(.*\)'.*/\1/")

if [ -z "$KERNEL_ENTRY" ]; then
    echo "ERROR: Could not find kernel 5.15.0-1068 in GRUB menu"
    echo "Available kernels:"
    grep "menuentry.*linux" /boot/grub/grub.cfg | sed "s/.*'\(.*\)'.*/\1/"
    exit 1
fi

echo "Found kernel: $KERNEL_ENTRY"
sudo sed -i "s/^GRUB_DEFAULT=.*/GRUB_DEFAULT=\"Advanced options for Ubuntu>$KERNEL_ENTRY\"/" /etc/default/grub
sudo update-grub

echo "GRUB configured to boot: $KERNEL_ENTRY"
echo "Rebooting in 5 seconds..."
sleep 5
sudo reboot