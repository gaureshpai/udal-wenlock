const express = require("express");
const path = require("path");
const http = require("http");
const fs = require("fs");
const csv = require('csv-parser');

const app = express();
const PORT = process.env.PORT || 3002;

let otData = [];

function loadData() {
  const results = [];
  fs.createReadStream(path.join(__dirname, 'public', 'ot_data.csv'))
    .pipe(csv())
    .on('data', (data) => results.push(data))
    .on('end', () => {
      otData = results;
      console.log("OT data loaded successfully.");
    });
}

app.get("/", (req, res) => {
  res.redirect("/display.html");
});

app.use(express.static(path.join(__dirname, 'public')));

app.get("/data", (req, res) => {
  res.json(otData);
});

const server = http.createServer(app);

fs.watch(path.join(__dirname, 'public', 'ot_data.csv'), (eventType, filename) => {
  if (filename && eventType === 'change') {
    console.log('ot_data.csv changed, reloading data...');
    loadData();
  }
});

server.listen(PORT, '0.0.0.0', () => {
  console.log(`HTTP Server running on http://localhost:${PORT}`);
  loadData();
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});
