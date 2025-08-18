const express = require("express");

const fs = require("fs");
const path = require("path");
const http = require("http");

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_DIR = path.join(__dirname, "data");
const DATA_FILE = path.join(DATA_DIR, "medicines.json");

app.use(express.json());
app.use(express.static(path.join(__dirname, "public")));


function ensureDataFile() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
  if (!fs.existsSync(DATA_FILE)) {
    const seed = [
      { id: 1, name: "Paracetamol 500mg", available: true },
      { id: 2, name: "Ibuprofen 200mg", available: false },
      { id: 3, name: "Cough Syrup", available: true },
      { id: 4, name: "Vitamin C", available: true }
    ];
    fs.writeFileSync(DATA_FILE, JSON.stringify(seed, null, 2));
  }
}

function loadData() {
  try {
    const raw = fs.readFileSync(DATA_FILE, "utf8");
    if (!raw.trim()) return [];
    return JSON.parse(raw);
  } catch (err) {
    console.error("Error loading JSON:", err);
    return [];
  }
}

function saveData(data) {
  fs.writeFileSync(DATA_FILE, JSON.stringify(data, null, 2));
}

app.get("/medicines", (req, res) => {
  res.json(loadData());
});

app.post("/medicines", (req, res) => {
  const { name, available = true } = req.body || {};
  if (!name || typeof name !== "string") {
    return res.status(400).json({ error: "Field 'name' is required." });
  }
  const meds = loadData();
  const nextId = meds.length ? Math.max(...meds.map(m => m.id)) + 1 : 1;
  const newMed = { id: nextId, name: name.trim(), available: !!available };
  meds.push(newMed);
  saveData(meds);
  res.status(201).json(newMed);
});

app.delete("/medicines/:id", (req, res) => {
  const id = Number(req.params.id);
  const meds = loadData();
  const idx = meds.findIndex(m => m.id === id);
  if (idx === -1) return res.status(404).json({ error: "Not found" });
  const removed = meds.splice(idx, 1)[0];
  saveData(meds);
  res.json(removed);
});

app.patch("/medicines/:id/toggle", (req, res) => {
  const id = Number(req.params.id);
  const { available } = req.body || {};
  const meds = loadData();
  const med = meds.find(m => m.id === id);
  if (!med) return res.status(404).json({ error: "Not found" });
  med.available = typeof available === "boolean" ? available : !med.available;
  saveData(meds);
  res.json(med);
});

app.patch("/medicines/batch", (req, res) => {
  const updates = req.body?.updates;
  if (!Array.isArray(updates)) {
    return res.status(400).json({ error: "Body 'updates' must be an array." });
  }
  const meds = loadData();
  const map = new Map(meds.map(m => [m.id, m]));
  let applied = 0;
  for (const u of updates) {
    const t = map.get(Number(u.id));
    if (t && typeof u.available === "boolean") {
      t.available = u.available;
      applied++;
    }
  }
  saveData(meds);
  res.json({ updated: applied });
});

app.get("/medicines/available", (req, res) => {
  const page = Math.max(1, Number(req.query.page) || 1);
  const limit = Math.max(1, Math.min(200, Number(req.query.limit) || 100));

  const meds = loadData().filter(m => m.available);
  const total = meds.length;
  const totalPages = Math.max(1, Math.ceil(total / limit));
  const start = (page - 1) * limit;
  const data = meds.slice(start, start + limit).map(({ id, name }) => ({ id, name }));

  res.json({ page, totalPages, count: data.length, total, data });
});

http.createServer(app).listen(PORT, '0.0.0.0', () => {
  console.log(`HTTP Server running on http://0.0.0.0:${PORT}`);
});