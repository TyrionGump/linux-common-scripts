#!/bin/bash

# Add a 2GB Swap file.
sudo fallocate -l 2G /swapfile

# Make the file only accessible to root
sudo chmod 600 /swapfile

# Verify that the correct amount of space was reserved
ls -lh /swapfile

# Mark the file as swap space
sudo mkswap /swapfile

# Enable the swap file, allowing our system to start using it
sudo swapon /swapfile

# Verify that the swap is available
sudo swapon --show
free -h

# Making the Swap File Permanent
sudo cp /etc/fstab /etc/fstab.bak
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab