#!/bin/bash

# Install Ollama on AWS Ubuntu 20.04
# - Target: AWS G4ad instances (Radeon Pro V520)

# Check GPU driver
echo "Checking AMD driver with rocm-smi"
rocm-smi


# Install Ollama
echo "Installing Ollama"
curl -fsSL https://ollama.com/install.sh | sh

# Modify Ollama service file
echo "Modifying Ollama service file"

# Apply AMD specific configuration if detected
echo "Applying AMD V520 fix"
sudo sed -i '/\[Service\]/a Environment="HSA_OVERRIDE_GFX_VERSION=10.1.0"' /etc/systemd/system/ollama.service

# Common configuration
sudo sed -i '/\[Service\]/a Environment="OLLAMA_HOST=0.0.0.0:3000"' /etc/systemd/system/ollama.service
sudo sed -i 's/User=ollama/User=root/' /etc/systemd/system/ollama.service
sudo sed -i 's/Group=ollama/Group=root/' /etc/systemd/system/ollama.service

# Reload and restart Ollama service
echo "Reloading and restarting Ollama service"
sudo systemctl daemon-reload
sudo systemctl restart ollama

# Check Ollama service status
echo "Checking Ollama service status"
sudo systemctl status ollama --no-pager

# List models on Ollama
echo "Listing models on Ollama"
OLLAMA_HOST=0.0.0.0:3000 ollama list
