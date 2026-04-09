#!/bin/bash
# =============================================================================
# crontab-setup.sh — Installs cron jobs on the App EC2 instance
# Run once: sudo bash scripts/crontab-setup.sh
# =============================================================================

SCRIPTS_DIR="/opt/capstone/scripts"
LOG_DIR="/var/log/capstone"

mkdir -p "${SCRIPTS_DIR}" "${LOG_DIR}"

# Copy scripts to /opt/capstone/scripts
cp "$(dirname "$0")/backup.sh"      "${SCRIPTS_DIR}/backup.sh"
cp "$(dirname "$0")/cleanup-logs.sh" "${SCRIPTS_DIR}/cleanup-logs.sh"

chmod +x "${SCRIPTS_DIR}/backup.sh" "${SCRIPTS_DIR}/cleanup-logs.sh"

echo "Scripts installed to ${SCRIPTS_DIR}"

# Write crontab
crontab - <<EOF
# DevOps Capstone — Cron Jobs
# Format: min hour day month weekday command

# Backup app logs every day at 2:00 AM
0 2 * * * /opt/capstone/scripts/backup.sh >> /var/log/capstone/cron.log 2>&1

# Clean up old logs and Docker resources every day at 3:00 AM
0 3 * * * /opt/capstone/scripts/cleanup-logs.sh >> /var/log/capstone/cron.log 2>&1

# Health check every 5 minutes — restarts container if unhealthy
*/5 * * * * curl -sf http://localhost:3000/health || (docker restart capstone-app && echo "[$(date)] Container restarted by healthcheck cron" >> /var/log/capstone/cron.log)
EOF

echo "Crontab installed. Current crontab:"
crontab -l
