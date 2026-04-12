#!/bin/bash
# =============================================================================
# backup.sh — Backs up app logs and container data to /var/backups/capstone
# Schedule: Run via cron (see crontab-setup.sh)
# =============================================================================

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
CONTAINER_NAME="capstone-app"
BACKUP_DIR="/var/backups/capstone"
LOG_DIR="/var/log/capstone"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_DIR}/backup_${TIMESTAMP}.tar.gz"
RETENTION_DAYS=7                   # Keep backups for 7 days
S3_BUCKET="s3://your-bucket-name/backups"    # Optional: set your S3 bucket

# ── Helpers ───────────────────────────────────────────────────────────────────
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_DIR}/backup.log"; }

# ── Setup directories ─────────────────────────────────────────────────────────
mkdir -p "${BACKUP_DIR}" "${LOG_DIR}"

log "======== Backup started ========"
log "Backup target: ${BACKUP_FILE}"

# ── Step 1: Dump Docker container logs ───────────────────────────────────────
TEMP_DIR=$(mktemp -d)
log "Collecting Docker logs for container: ${CONTAINER_NAME}"

if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    docker logs "${CONTAINER_NAME}" > "${TEMP_DIR}/app-container.log" 2>&1
    log "Container logs collected ($(wc -l < "${TEMP_DIR}/app-container.log") lines)"
else
    log "WARNING: Container '${CONTAINER_NAME}' not running. Skipping container logs."
    echo "Container not running at ${TIMESTAMP}" > "${TEMP_DIR}/app-container.log"
fi

# ── Step 2: Copy existing app logs ───────────────────────────────────────────
if [ -d "${LOG_DIR}" ]; then
    cp -r "${LOG_DIR}" "${TEMP_DIR}/app-logs" 2>/dev/null || true
fi

# ── Step 3: Save Docker inspect info ─────────────────────────────────────────
docker inspect "${CONTAINER_NAME}" > "${TEMP_DIR}/container-inspect.json" 2>/dev/null || \
    echo '{"error":"container not running"}' > "${TEMP_DIR}/container-inspect.json"

# ── Step 4: Create compressed archive ────────────────────────────────────────
tar -czf "${BACKUP_FILE}" -C "${TEMP_DIR}" .
rm -rf "${TEMP_DIR}"

BACKUP_SIZE=$(du -sh "${BACKUP_FILE}" | cut -f1)
log "Backup created: ${BACKUP_FILE} (${BACKUP_SIZE})"

# ── Step 5: Upload to S3 (optional — comment out if not using AWS) ───────────
if command -v aws &>/dev/null && [ -n "${S3_BUCKET}" ]; then
    log "Uploading backup to S3: ${S3_BUCKET}"
    aws s3 cp "${BACKUP_FILE}" "${S3_BUCKET}/" && log "S3 upload successful" || \
        log "WARNING: S3 upload failed"
fi

# ── Step 6: Remove backups older than RETENTION_DAYS ─────────────────────────
log "Removing backups older than ${RETENTION_DAYS} days..."
find "${BACKUP_DIR}" -name "backup_*.tar.gz" -mtime "+${RETENTION_DAYS}" -delete
REMAINING=$(find "${BACKUP_DIR}" -name "backup_*.tar.gz" | wc -l)
log "Retained ${REMAINING} backup(s) in ${BACKUP_DIR}"

log "======== Backup completed ========"
