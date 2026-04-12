# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /app

COPY app/package*.json ./
RUN npm install --omit=dev

COPY app/ .

# Stage 2: Production
FROM node:20-alpine

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder /app ./

RUN chown -R appuser:appgroup /app

USER appuser

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD wget -qO- http://localhost:3000/health || exit 1

CMD ["node", "server.js"]
