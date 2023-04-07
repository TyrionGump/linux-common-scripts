#!/bin/bash

# Older versions of Docker were called docker or docker-engine. If these are installed, uninstall them, along with associated dependencies.
sudo yum remove docker \
                  docker-client \
                  docker-client-latest \
                  docker-common \
                  docker-latest \
                  docker-latest-logrotate \
                  docker-logrotate \
                  docker-engine

# Install the yum-utils package (which provides the yum-config-manager utility) and set up the repository.
sudo yum install -y yum-utils
sudo yum-config-manager \
    --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo

# Install the latest version of Docker Engine, containerd, and Docker Compose or go to the next step to install a specific version
sudo yum install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Run docker and check its status
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl status docker