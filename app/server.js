const express = require("express");
const path = require("path");
const os = require("os");

const app = express();
const PORT = 3000;

/* =========================
   MAIN DASHBOARD ROUTE
========================= */
app.get("/", (req, res) => {
  res.send(`
  <!DOCTYPE html>
  <html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>DevOps Dashboard</title>

    <style>
      body {
        margin: 0;
        font-family: Arial, sans-serif;
        background: #0f172a;
        color: #e2e8f0;
      }

      header {
        background: #020617;
        padding: 20px;
        text-align: center;
        border-bottom: 1px solid #334155;
      }

      header h1 {
        margin: 0;
        color: #38bdf8;
      }

      .container {
        padding: 20px;
      }

      .section {
        margin-bottom: 30px;
      }

      .card {
        background: #1e293b;
        border-radius: 10px;
        padding: 20px;
        border: 1px solid #334155;
        margin-bottom: 20px;
      }

      .grid {
        display: grid;
        grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
        gap: 15px;
      }

      .status {
        color: #4ade80;
        font-weight: bold;
      }

      .links a {
        display: block;
        margin: 8px 0;
        color: #38bdf8;
        text-decoration: none;
      }

      .links a:hover {
        text-decoration: underline;
      }

      .scroll-box {
        max-height: 200px;
        overflow-y: auto;
        background: #020617;
        padding: 10px;
        border-radius: 6px;
        font-size: 14px;
      }

      footer {
        text-align: center;
        padding: 15px;
        font-size: 12px;
        color: #64748b;
      }
    </style>
  </head>

  <body>

    <header>
      <h1>DevOps Monitoring Dashboard</h1>
      <p>Node.js, Docker, Jenkins, AWS, Prometheus, Grafana</p>
    </header>

    <div class="container">

      <div class="section">
        <div class="card">
          <h2>System Status</h2>
          <p class="status">Application running successfully</p>
          <p>Hostname: ${os.hostname()}</p>
          <p>Uptime: ${Math.floor(process.uptime())} seconds</p>
        </div>
      </div>

      <div class="section">
        <h2>Services</h2>
        <div class="grid">
          <div class="card">GitHub</div>
          <div class="card">Jenkins</div>
          <div class="card">Docker</div>
          <div class="card">AWS EC2</div>
          <div class="card">Prometheus</div>
          <div class="card">Grafana</div>
        </div>
      </div>

      <div class="section">
        <div class="card">
          <h2>Monitoring Links</h2>
          <div class="links">
            <a href="/metrics" target="_blank">Prometheus Metrics</a>
            <a href="/health" target="_blank">Health Check</a>
            <a href="/api/info" target="_blank">API Information</a>
          </div>
        </div>
      </div>

      <div class="section">
        <div class="card">
          <h2>System Logs</h2>
          <div class="scroll-box">
            ${Array.from({length: 30})
              .map((_, i) => `<p>Log Entry ${i+1}: System running normally</p>`)
              .join('')}
          </div>
        </div>
      </div>

    </div>

    <footer>
      DevOps Capstone Project Dashboard
    </footer>

  </body>
  </html>
  `);
});
app.get("/health", (req, res) => {
  res.json({
    status: "UP",
    uptime: process.uptime(),
    timestamp: new Date()
  });
});
app.get("/api/info", (req, res) => {
  res.json({
    app: "DevOps Dashboard",
    node: process.version,
    platform: os.platform(),
    hostname: os.hostname()
  });
});
app.get("/metrics", (req, res) => {
  res.send(`
# HELP uptime_seconds Application uptime
# TYPE uptime_seconds counter
uptime_seconds ${process.uptime()}
  `);
});
app.listen(PORT, "0.0.0.0", () => {
  console.log(`Server running on port ${PORT}`);
});
