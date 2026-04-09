# DevOps Capstone Project
**End-to-End CI/CD Pipeline — Node.js · Docker · Jenkins · AWS · Prometheus · Grafana**

---

## Project Overview

A production-ready DevOps pipeline that automates the build, test, containerization, deployment, and monitoring of a Node.js web application.

```
Developer pushes code
       │
       ▼
   GitHub Repo
       │
       ▼  (webhook / poll)
  Jenkins EC2
  ┌────────────────────────────────┐
  │  1. Checkout code              │
  │  2. npm install                │
  │  3. npm test (Jest)            │
  │  4. docker build               │
  │  5. docker push → Docker Hub   │
  │  6. SSH → App EC2 → deploy     │
  │  7. Health check               │
  └────────────────────────────────┘
       │
       ▼
   App EC2 (Docker container)
       │
       ▼
  Prometheus scrapes /metrics
       │
       ▼
  Grafana dashboard
```

---

## Tech Stack

| Layer | Tool |
|---|---|
| Source Control | Git + GitHub |
| CI/CD | Jenkins on EC2 |
| Application | Node.js + Express |
| Containerization | Docker + Docker Hub |
| Infrastructure | AWS EC2 (Ubuntu 22.04) |
| Monitoring | Prometheus + Grafana + Node Exporter |
| Automation | Bash + Cron |

---

## Repository Structure

```
devops-capstone/
├── app/
│   ├── server.js            # Express app with Prometheus metrics
│   ├── package.json
│   ├── Dockerfile
│   ├── .dockerignore
│   └── __tests__/
│       └── server.test.js   # Jest unit tests
├── monitoring/
│   ├── docker-compose.yml   # Prometheus + Grafana + Node Exporter
│   └── prometheus/
│       └── prometheus.yml   # Scrape config
├── scripts/
│   ├── ec2-setup-jenkins.sh # Bootstrap Jenkins EC2
│   ├── ec2-setup-app.sh     # Bootstrap App EC2
│   ├── backup.sh            # Log/data backup script
│   ├── cleanup-logs.sh      # Docker & log cleanup
│   └── crontab-setup.sh     # Install cron jobs
├── Jenkinsfile              # Full CI/CD pipeline
└── README.md
```

---

## Quick Start — Run Locally

```bash
# 1. Clone the repo
git clone https://github.com/your-username/devops-capstone.git
cd devops-capstone

# 2. Run the Node.js app directly
cd app
npm install
npm start
# → http://localhost:3000

# 3. OR run with Docker
docker build -t capstone-app .
docker run -d -p 3000:3000 --name capstone-app capstone-app
# → http://localhost:3000

# 4. Run tests
npm test
```

---

## AWS Setup — Step by Step

### Prerequisites
- AWS account with EC2 access
- Two EC2 instances: **Jenkins EC2** and **App EC2** (Ubuntu 22.04, t2.micro or larger)
- Security groups open:
  - Jenkins EC2: ports 22, 8080
  - App EC2: ports 22, 3000, 9100
  - Monitoring EC2: ports 22, 9090, 3001

### 1. Bootstrap Jenkins EC2

```bash
# SSH into Jenkins EC2
ssh -i your-key.pem ubuntu@<jenkins-ec2-ip>

# Clone repo and run setup
git clone https://github.com/your-username/devops-capstone.git
bash devops-capstone/scripts/ec2-setup-jenkins.sh
```

Access Jenkins at `http://<jenkins-ec2-ip>:8080`. Install these plugins:
- **Git Plugin**
- **Docker Pipeline**
- **SSH Agent Plugin**
- **Pipeline**

### 2. Bootstrap App EC2

```bash
ssh -i your-key.pem ubuntu@<app-ec2-ip>
git clone https://github.com/your-username/devops-capstone.git
bash devops-capstone/scripts/ec2-setup-app.sh
```

### 3. Configure Jenkins Credentials

In Jenkins → Manage Jenkins → Credentials → (global) → Add Credential:

| ID | Type | Value |
|---|---|---|
| `dockerhub-credentials` | Username + Password | Your Docker Hub login |
| `ec2-ssh-key` | SSH Username with Private Key | Your EC2 .pem key |

### 4. Update Jenkinsfile

Edit `Jenkinsfile` — replace placeholders:
```groovy
DOCKER_HUB_REPO = "your-dockerhub-username/devops-capstone"
APP_EC2_HOST    = "your-app-ec2-public-ip"
```

### 5. Create Jenkins Pipeline Job

1. New Item → Pipeline
2. Pipeline Definition: **Pipeline script from SCM**
3. SCM: Git → your GitHub repo URL
4. Script Path: `Jenkinsfile`
5. Save → Build Now

---

## Monitoring Setup

```bash
# SSH into Monitoring EC2 (or use the Jenkins EC2)
cd devops-capstone/monitoring

# Edit prometheus/prometheus.yml — replace IP placeholders
nano prometheus/prometheus.yml

# Start the monitoring stack
docker compose up -d

# Access:
# Prometheus → http://<monitoring-ec2-ip>:9090
# Grafana    → http://<monitoring-ec2-ip>:3001  (admin / admin123)
```

**Grafana Dashboard setup:**
1. Add Prometheus data source: `http://prometheus:9090`
2. Import dashboard ID **1860** (Node Exporter Full)
3. Import dashboard ID **11159** (Node.js Application)

---

## Cron Jobs Setup (on App EC2)

```bash
# Install cron jobs
sudo bash scripts/crontab-setup.sh

# Verify
crontab -l
```

| Schedule | Job |
|---|---|
| Daily at 2:00 AM | Backup container logs to `/var/backups/capstone` + S3 |
| Daily at 3:00 AM | Clean old logs + prune Docker resources |
| Every 5 minutes | Health check — auto-restart container if unhealthy |

---

## CI/CD Flow

```
git push origin main
        │
        ▼ (poll / webhook)
   Jenkins detects change
        │
  ┌─────▼──────┐
  │  Checkout  │ ← git clone
  └─────┬──────┘
        │
  ┌─────▼──────────────┐
  │  Install + Test    │ ← npm ci && npm test
  └─────┬──────────────┘
        │
  ┌─────▼──────────────┐
  │  Docker Build      │ ← docker build -t repo:BUILD_NUMBER
  └─────┬──────────────┘
        │
  ┌─────▼──────────────┐
  │  Push to Hub       │ ← docker push
  └─────┬──────────────┘
        │
  ┌─────▼──────────────┐
  │  Deploy to EC2     │ ← SSH → docker run
  └─────┬──────────────┘
        │
  ┌─────▼──────────────┐
  │  Health Check      │ ← curl /health → 200 OK
  └─────┬──────────────┘
        │
  ┌─────▼──────────────┐
  │  Cleanup           │ ← docker image prune
  └────────────────────┘
```

---

## API Endpoints

| Route | Description |
|---|---|
| `GET /` | Web UI |
| `GET /health` | Health check (JSON) |
| `GET /metrics` | Prometheus metrics |
| `GET /api/info` | App info (JSON) |
