#!/bin/bash

# Pls first use free -m to check if there is existing swap.

# Use the dd command to create a swap file on the root file system. the swap file is 2 GB (128 MB x 16). Pls check
# which size is appropriate for you device
sudo dd if=/dev/zero of=/swapfile bs=128M count=16

# Update the read and write permissions for the swap file
sudo chmod 600 /swapfile

# Set up a Linux swap area
sudo mkswap /swapfile

# Make the swap file available for immediate use by adding the swap file to swap space
sudo swapon /swapfile

# Verify that the procedure was successful
sudo swapon -s

# Start the swap file at boot time by editing the /etc/fstab file
echo "/swapfile swap swap defaults 0 0" | sudo tee -a /etc/fstab