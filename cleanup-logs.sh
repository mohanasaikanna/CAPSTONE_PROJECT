#!/bin/bash
# =============================================================================
# cleanup-logs.sh — Cleans up old logs and unused Docker resources
# Schedule: Run via cron daily (see crontab-setup.sh)
# =============================================================================

set -euo pipefail

LOG_DIR="/var/log/capstone"
CLEANUP_LOG="${LOG_DIR}/cleanup.log"
LOG_RETENTION_DAYS=14
DOCKER_LOG_MAX_SIZE="100m"

mkdir -p "${LOG_DIR}"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${CLEANUP_LOG}"; }

log "======== Log cleanup started ========"

# ── Step 1: Remove old log files ─────────────────────────────────────────────
log "Removing log files older than ${LOG_RETENTION_DAYS} days from ${LOG_DIR}..."
DELETED=$(find "${LOG_DIR}" -name "*.log" -mtime "+${LOG_RETENTION_DAYS}" -print -delete | wc -l)
log "Deleted ${DELETED} old log file(s)"

# ── Step 2: Rotate large log files (>50MB) ───────────────────────────────────
log "Checking for oversized log files (>50MB)..."
find "${LOG_DIR}" -name "*.log" -size +50M | while read -r biglog; do
    log "Rotating oversized log: ${biglog} ($(du -sh "${biglog}" | cut -f1))"
    mv "${biglog}" "${biglog}.$(date +%Y%m%d).old"
    touch "${biglog}"
done

# ── Step 3: Clean up Docker ───────────────────────────────────────────────────
log "Cleaning up Docker resources..."

# Remove stopped containers
CONTAINERS=$(docker ps -a -q --filter status=exited 2>/dev/null | wc -l)
if [ "${CONTAINERS}" -gt 0 ]; then
    docker rm $(docker ps -a -q --filter status=exited) 2>/dev/null || true
    log "Removed ${CONTAINERS} stopped container(s)"
else
    log "No stopped containers to remove"
fi

# Remove dangling images (<none>:<none>)
IMAGES=$(docker images -f "dangling=true" -q 2>/dev/null | wc -l)
if [ "${IMAGES}" -gt 0 ]; then
    docker rmi $(docker images -f "dangling=true" -q) 2>/dev/null || true
    log "Removed ${IMAGES} dangling image(s)"
else
    log "No dangling images to remove"
fi

# Remove unused volumes
docker volume prune -f >> "${CLEANUP_LOG}" 2>&1
log "Docker volumes pruned"

# Remove unused networks
docker network prune -f >> "${CLEANUP_LOG}" 2>&1
log "Docker networks pruned"

# ── Step 4: Report disk usage ─────────────────────────────────────────────────
log "Current disk usage:"
df -h / | tail -1 | awk '{print "  Filesystem: " $1 ", Used: " $3 "/" $2 " (" $5 " used)"}' | tee -a "${CLEANUP_LOG}"

log "Docker disk usage:"
docker system df 2>/dev/null | tee -a "${CLEANUP_LOG}"

log "======== Log cleanup completed ========"
