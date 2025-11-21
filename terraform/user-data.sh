#!/bin/bash
set -e

exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "[$(date)] Starting setup as root..."

# Install Docker, kubectl, minikube as root
echo "Installing Docker"
apt update
apt install -y docker.io
systemctl enable --now docker
usermod -aG docker ubuntu

echo "Installing Kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
mv kubectl /usr/local/bin/
kubectl version --client

echo "Installing Minikube"
curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
minikube version

echo "[$(date)] Switching to ubuntu user for deployment..."

# Run everything else as ubuntu user
su - ubuntu << 'UBUNTU_SCRIPT'
set -e

echo "[$(date)] Starting as ubuntu user..."

# Clone repo
cd /home/ubuntu
git clone ${github_repo}
cd AWS-CloudShelf-Microservices-Project
git checkout ${github_branch}

echo "Starting Minikube Cluster with Docker driver"
minikube start --driver=docker --cpus=4 --memory=14000

echo "Sanity Check"
kubectl get nodes
kubectl cluster-info
minikube status

echo "Installation Complete!"

# Run deployment
cd /home/ubuntu/AWS-CloudShelf-Microservices-Project/spring-microservices-bookstore-demo
chmod 755 deploy.sh
bash deploy.sh

echo "[$(date)] Setup complete!"
UBUNTU_SCRIPT

echo "[$(date)] All setup complete!"