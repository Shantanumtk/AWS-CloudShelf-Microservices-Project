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

# --- minimal path helpers (new) ---
REPO_DIR="$HOME/AWS-CloudShelf-Microservices-CPSC-465"
DEMO_DIR="$REPO_DIR/spring-microservices-bookstore-demo"

echo "[*] Git Clone the Repo ..."
git clone https://github.com/Shantanumtk/AWS-CloudShelf-Microservices-CPSC-465.git "$REPO_DIR" || true

cd "$DEMO_DIR"

echo "[*] Maven Build Package ..."
mvn clean package -DskipTests | tee maven.log

echo "Run Create Env Script ..."
bash ./create-env.sh

ls -ltrh

# ensure we're back in the right folder even if create-env.sh 'cd' somewhere
cd "$DEMO_DIR"

# make sure CI/CD scripts are executable (small but important)
chmod +x ./ci-script.sh ./cd-script.sh || true

echo "Run CI Script ..."
bash ./ci-script.sh

echo "Run CD Script ..."
bash ./cd-script.sh

echo "✅ Done"