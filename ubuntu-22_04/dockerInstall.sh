#!/bin/bash

# Uninstall old versions.
sudo apt-get remove docker docker-engine docker.io containerd runc

# Update the apt package index and install packages to allow apt to use a repository over HTTPS.
sudo apt-get update
sudo apt-get install ca-certificates curl gnupg

# Add Docker GPG key (verify that the packages you download are from the official Docker repository).
sudo mkdir -m 0755 -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Add Docker repository.
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Avoid a GPG error.
sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get update

# Install Docker Engine, containerd, and Docker Compose.
sudo apt install docker-ce docker-ce-cli containerd.io

# Verify Docker installation
docker --version

# Start and enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add your user to the Docker group (optional). Rememer reconnect the session to take effects or use "su - $USER".
sudo usermod -aG docker $USER

# Verify the installation (Docker Compose 2.0.0 replace the command of "docker-compose")
docker compose version


