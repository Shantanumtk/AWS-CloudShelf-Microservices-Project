#!/usr/bin/env bash
# Minimal Docker install for Ubuntu 22.04/24.04 + add user to 'docker' group

set -e

# Decide which user to add to the 'docker' group:
# - If running with sudo, use the invoking user (SUDO_USER).
# - If running as root directly, fall back to $USER (or 'ubuntu' if empty).
TARGET_USER="${SUDO_USER:-$USER}"
if [ -z "$TARGET_USER" ] || [ "$TARGET_USER" = "root" ]; then
  # Reasonable default on EC2 Ubuntu
  TARGET_USER="ubuntu"
fi

# Use sudo if not root
SUDO=""
if [ "$EUID" -ne 0 ]; then
  SUDO="sudo"
fi

echo "[*] Updating apt and installing prerequisites..."
$SUDO apt-get update -y
$SUDO apt-get install -y ca-certificates curl gnupg

echo "[*] Setting up Docker's official GPG key and repo..."
$SUDO install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$SUDO chmod a+r /etc/apt/keyrings/docker.gpg

CODENAME="$(. /etc/os-release && echo "$VERSION_CODENAME")"
ARCH="$(dpkg --print-architecture)"
echo "deb [arch=${ARCH} signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${CODENAME} stable" \
  | $SUDO tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "[*] Installing Docker Engine, CLI, Buildx, and Compose..."
$SUDO apt-get update -y
$SUDO apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "[*] Enabling and starting Docker service..."
$SUDO systemctl enable --now docker

echo "[*] Adding user '${TARGET_USER}' to 'docker' group (no-sudo usage)..."
if id -u "$TARGET_USER" >/dev/null 2>&1; then
  $SUDO groupadd -f docker
  $SUDO usermod -aG docker "$TARGET_USER"
else
  echo "[WARN] User '$TARGET_USER' does not exist. Skipping group add."
fi

echo
echo "▶ Verify: docker --version && docker compose version"
echo "▶ Test:   docker run --rm hello-world"
echo
echo "ℹ If 'docker' still needs sudo, start a new shell/session or run: newgrp docker"
echo "   (User added: $TARGET_USER)"

echo "[*] Installing Java 17 ..."
sudo apt-get install -y openjdk-17-jdk

echo "[*] Installing Apache Maven ..."
sudo apt install maven -y

echo "============================== Setting Up The Code =============================="

echo "[*] Git Clone the Repo ..."
git clone https://github.com/Shantanumtk/AWS-CloudShelf-CPSC-465.git
cd spring-microservices-bookstore-demo

echo "[*] Maven Build Package ..."
mvn clean package -DskipTests | tee maven.log


echo "============================== Running The Containers =============================="

echo "[*] Building Frontend Image ..."
docker build -t microservices-bookstore/nextjs-frontend:latest ./frontend
echo "[*] Running Infra Profile Containers"
docker compose --profile infrastructure up -d
echo "[*] Running Discovery-Config Profile Containers"
docker compose --profile discovery-config up -d
echo "[*] Running Services Profile Containers"
docker compose --profile services up -d

echo "============================== Container Health Check =============================="
echo "Checking Docker Compose Containers ..."
docker compose ps 
echo "============================== Container Health Check =============================="
echo "✅ Done"