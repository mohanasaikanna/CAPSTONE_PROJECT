#!/bin/bash
# =============================================================================
# ec2-setup-jenkins.sh — Bootstrap Jenkins on EC2 (Ubuntu 22.04)
# Run once as ubuntu user: bash scripts/ec2-setup-jenkins.sh
# =============================================================================

set -euo pipefail

log() { echo "[SETUP] $1"; }

log "Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

# ── Install Java (Jenkins requires Java 17+) ──────────────────────────────────
log "Installing Java 17..."
sudo apt-get install -y openjdk-17-jdk
java -version

# ── Install Jenkins ───────────────────────────────────────────────────────────
log "Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | \
    sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
    https://pkg.jenkins.io/debian-stable binary/" | \
    sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

sudo systemctl enable jenkins
sudo systemctl start jenkins

log "Jenkins installed and running on port 8080"

# ── Install Docker (Jenkins will build images) ────────────────────────────────
log "Installing Docker..."
sudo apt-get install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Allow jenkins user to run docker
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu
sudo systemctl restart jenkins

log "Docker installed: $(docker --version)"

# ── Install Node.js (for npm test in pipeline) ────────────────────────────────
log "Installing Node.js 20..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

log "Node.js: $(node --version), npm: $(npm --version)"

log ""
log "========================================"
log " Jenkins EC2 setup complete!"
log ""
log " Initial admin password:"
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
log ""
log " Access Jenkins at: http://$(curl -s ifconfig.me):8080"
log ""
log " Next steps:"
log "   1. Open port 8080 in EC2 Security Group"
log "   2. Complete Jenkins setup wizard in browser"
log "   3. Install plugins: Git, Docker Pipeline, SSH Agent, Pipeline"
log "   4. Add credentials: DockerHub, EC2 SSH key"
log "   5. Create pipeline job pointing to your GitHub repo"
log "========================================"
