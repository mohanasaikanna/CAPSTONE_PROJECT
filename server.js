'use strict';

const express = require('express');
const client = require('prom-client');

const app = express();
const PORT = process.env.PORT || 3000;

// ── Prometheus metrics ───────────────────────────────────────────────────────
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ timeout: 5000 });

const httpRequestCounter = new client.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status'],
});

const httpRequestDuration = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5],
});

// Middleware: track every request
app.use((req, res, next) => {
  const end = httpRequestDuration.startTimer({ method: req.method, route: req.path });
  res.on('finish', () => {
    httpRequestCounter.inc({ method: req.method, route: req.path, status: res.statusCode });
    end();
  });
  next();
});

app.use(express.json());

// ── Routes ───────────────────────────────────────────────────────────────────
app.get('/', (req, res) => {
  res.send(`
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8" />
      <meta name="viewport" content="width=device-width, initial-scale=1.0" />
      <title>DevOps Capstone App</title>
      <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: system-ui, sans-serif; background: #0f172a; color: #e2e8f0; display: flex; align-items: center; justify-content: center; min-height: 100vh; }
        .card { background: #1e293b; border: 1px solid #334155; border-radius: 16px; padding: 48px; max-width: 560px; text-align: center; }
        h1 { font-size: 2rem; color: #38bdf8; margin-bottom: 8px; }
        p { color: #94a3b8; margin: 12px 0; line-height: 1.6; }
        .badge { display: inline-block; background: #0ea5e9; color: #fff; border-radius: 999px; padding: 4px 14px; font-size: 0.75rem; font-weight: 600; margin: 4px; }
        .grid { display: flex; flex-wrap: wrap; justify-content: center; margin-top: 20px; }
        .status { margin-top: 24px; font-size: 0.85rem; color: #4ade80; }
      </style>
    </head>
    <body>
      <div class="card">
        <h1>🚀 DevOps Capstone</h1>
        <p>End-to-end CI/CD pipeline — Node.js · Docker · Jenkins · AWS</p>
        <div class="grid">
          <span class="badge">GitHub</span>
          <span class="badge">Jenkins</span>
          <span class="badge">Docker</span>
          <span class="badge">AWS EC2</span>
          <span class="badge">Prometheus</span>
          <span class="badge">Grafana</span>
        </div>
        <p class="status">✅ Application running successfully</p>
        <p style="margin-top:16px;font-size:0.8rem;color:#475569;">
          Hostname: ${require('os').hostname()} &nbsp;|&nbsp; Uptime: ${Math.floor(process.uptime())}s
        </p>
      </div>
    </body>
    </html>
  `);
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    environment: process.env.NODE_ENV || 'development',
  });
});

app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

app.get('/api/info', (req, res) => {
  res.json({
    app: 'DevOps Capstone App',
    version: '1.0.0',
    node: process.version,
    hostname: require('os').hostname(),
    platform: process.platform,
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Start server
const server = app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
  console.log(`Metrics available at http://localhost:${PORT}/metrics`);
  console.log(`Health check at http://localhost:${PORT}/health`);
});

module.exports = { app, server };
