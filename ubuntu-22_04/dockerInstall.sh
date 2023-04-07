#!/bin/bash

# Install prerequisite packages
sudo apt install apt-transport-https ca-certificates curl software-properties-common

# Add Docker GPG key (verify that the packages you download are from the official Docker repository)
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
sudo apt install docker-ce docker-ce-cli containerd.io

# Verify Docker installation
docker --version

# Start and enable Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Add your user to the Docker group (optional). Rememer reconnect the session to take effects or use "su - $USER".
# sudo usermod -aG docker $USER


# Download the latest version of Docker Compose (please check the latest version on https://github.com/docker/compose/releases and please the following 2.17.2)
sudo curl -L "https://github.com/docker/compose/releases/download/2.17.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make the binary executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify the installation (Docker Compose 2.0.0 replace the command of "docker-compose")
docker compose version


