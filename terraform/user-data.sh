#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "[$(date)] Starting setup..."

# Clone repo
cd /home/ubuntu
git clone ${github_repo}
cd AWS-CloudShelf-Microservices-Project
git checkout ${github_branch}

# Run deployment
cd spring-microservices-bookstore-demo
chmod 755 deploy.sh
bash deploy.sh

echo "[$(date)] Setup complete!"