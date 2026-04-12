#!/bin/bash
# =============================================================================
# ec2-setup-app.sh — Bootstrap script for the App EC2 instance (Ubuntu 22.04)
# Run once as ubuntu user: bash scripts/ec2-setup-app.sh
# =============================================================================

set -euo pipefail

log() { echo "[SETUP] $1"; }

log "Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# ── Install Docker ────────────────────────────────────────────────────────────
log "Installing Docker..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin

# Add ubuntu user to docker group (no sudo needed for docker)
sudo usermod -aG docker ubuntu
sudo systemctl enable docker
sudo systemctl start docker

log "Docker installed: $(docker --version)"

# ── Install Node Exporter (for Prometheus monitoring) ────────────────────────
log "Installing Node Exporter..."
NODE_EXPORTER_VERSION="1.7.0"
wget -q "https://github.com/prometheus/node_exporter/releases/download/v${NODE_EXPORTER_VERSION}/node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
tar -xzf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64.tar.gz"
sudo mv "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64/node_exporter" /usr/local/bin/
rm -rf "node_exporter-${NODE_EXPORTER_VERSION}.linux-amd64"*

# Create systemd service for Node Exporter
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Prometheus Node Exporter
After=network.target

[Service]
Type=simple
User=nobody
ExecStart=/usr/local/bin/node_exporter
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

log "Node Exporter running on port 9100"

# ── Install AWS CLI (for S3 backups) ─────────────────────────────────────────
log "Installing AWS CLI..."
curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt-get install -y unzip
unzip -q awscliv2.zip
sudo ./aws/install
rm -rf aws awscliv2.zip

log "AWS CLI installed: $(aws --version)"

# ── Create directories ────────────────────────────────────────────────────────
sudo mkdir -p /var/log/capstone /var/backups/capstone /opt/capstone/scripts
sudo chown -R ubuntu:ubuntu /var/log/capstone /var/backups/capstone /opt/capstone

log ""
log "========================================"
log " App EC2 setup complete!"
log " Next steps:"
log "   1. Log out and back in (docker group takes effect)"
log "   2. Configure AWS credentials: aws configure"
log "   3. Jenkins will SSH and deploy the container automatically"
log "========================================"
