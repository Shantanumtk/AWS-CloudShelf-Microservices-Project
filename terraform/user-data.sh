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

echo "Installing Docker"
sudo apt update
sudo apt install -y docker.io
sudo systemctl enable --now docker
sudo usermod -aG docker $USER

echo "Installing Kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client

echo "Installing Minikube"
curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
minikube version

echo "Starting Minikube Cluster with Docker driver"
# Run as current user, not root
if [ "$EUID" -eq 0 ]; then
    # If running as root, switch to ubuntu user
    su - ubuntu -c "minikube start --driver=docker --cpus=4 --memory=14000"
else
    # If already non-root user
    minikube start --driver=docker --cpus=4 --memory=14000
fi

echo "Sanity Check"
kubectl get nodes
kubectl cluster-info
minikube status

echo "Installation Complete!"

# Run deployment
cd spring-microservices-bookstore-demo
chmod 755 deploy.sh
bash deploy.sh

echo "[$(date)] Setup complete!"