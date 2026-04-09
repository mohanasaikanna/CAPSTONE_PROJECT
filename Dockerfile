# ── Stage 1: Build & test ────────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first (cache layer)
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY . .

# ── Stage 2: Production image ─────────────────────────────────────────────────
FROM node:20-alpine AS production

# Security: run as non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

# Copy only production node_modules + source from builder
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app .

# Change ownership
RUN chown -R appuser:appgroup /app

USER appuser

# Expose app port
EXPOSE 3000

# Healthcheck (Docker will poll /health every 30s)
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

# Start the app
CMD ["node", "server.js"]
