const express = require("express");
const fs = require("fs");
const path = require("path");
const http = require("http");
const Papa = require("papaparse");
const fetch = (...args) => import('node-fetch').then(({ default: fetch }) => fetch(...args));

const app = express();
const PORT = process.env.PORT || 3000;
const DATA_DIR = path.join(__dirname, "data");
const CSV_FILE_PATH = path.join(DATA_DIR, "medicines.csv");

if (!fs.existsSync(DATA_DIR)) {
  fs.mkdirSync(DATA_DIR);
}

//https://docs.google.com/spreadsheets/d/1nRk_AzFRq4k5v8441nL4XPNXNCNwLVVg_5-wO2bHS6g/edit?gid=0#gid=0

const SHEET_ID = "1nRk_AzFRq4k5v8441nL4XPNXNCNwLVVg_5-wO2bHS6g";
const GID = "0";
const SHEET_CSV_URL = `https://docs.google.com/spreadsheets/d/${SHEET_ID}/gviz/tq?tqx=out:csv&gid=${GID}`;

app.use(express.static(path.join(__dirname, "public")));

async function getKannadaTransliteration(text) {
  if (!text || !text.trim()) return "";
  try {
    const words = text.split(' ');
    const transliteratedWords = await Promise.all(words.map(async (word) => {
      const response = await fetch(`https://transliteration.devnagri.com/api/tl/kn/${word}`);
      const data = await response.json();
      if (data && data.success && data.result) {
        return data.result[0];
      }
      return word;
    }));
    return transliteratedWords.join(' ');
  } catch (err) {
    console.error("Transliteration error:", err);
    return text;
  }
}

function parseAvailability(value) {
  if (value === undefined || value === null || value === '') return false;
  const normalized = String(value).trim().toLowerCase();
  if (normalized === 'true') return true;
  if (normalized === 'false') return false;
  return ["✔", "✓", "1", "yes"].includes(normalized);
}

async function syncSheetToCsv() {
  console.log("Attempting to sync from public Google Sheet...");
  try {
    let localMedicines = [];
    if (fs.existsSync(CSV_FILE_PATH)) {
      const localCsvData = fs.readFileSync(CSV_FILE_PATH, "utf8");
      const localParsed = Papa.parse(localCsvData, { header: true, skipEmptyLines: true });
      localMedicines = localParsed.data;
    }
    const localDataMap = new Map(localMedicines.map(m => [m.name, m]));

    const response = await fetch(SHEET_CSV_URL);
    if (!response.ok) {
      throw new Error(`Failed to fetch sheet: ${response.statusText}`);
    }
    const csvText = await response.text();
    const parsedSheet = Papa.parse(csvText, { header: false, skipEmptyLines: true });

    let newMedicines = [];
    for (const row of parsedSheet.data) {
      const name = row[0] ? String(row[0]).trim() : "";
      if (name === "") continue;

      const existingEntry = localDataMap.get(name);
      let kn_name = existingEntry ? existingEntry.kn_name : "";

      if (!kn_name) {
        console.log(`Translating new/updated item: "${name}"...`);
        kn_name = await getKannadaTransliteration(name);
      }

      newMedicines.push({
        name: name,
        available: parseAvailability(row[1]),
        kn_name: kn_name,
      });
    }

    const hasChanged = newMedicines.length !== localMedicines.length ||
      newMedicines.some((newMed, index) => {
        const oldMed = localMedicines[index];
        return !oldMed ||
          newMed.name !== oldMed.name ||
          newMed.available !== oldMed.available ||
          newMed.kn_name !== oldMed.kn_name;
      });

    if (hasChanged) {
      console.log("Changes detected. Writing to local CSV file...");
      const newCsv = Papa.unparse(newMedicines, { header: true });
      fs.writeFileSync(CSV_FILE_PATH, newCsv);
      console.log("Local CSV file has been updated.");
    } else {
      console.log("No changes detected between sheet and local CSV.");
    }

    return newMedicines;

  } catch (error) {
    console.error("Failed to sync from Google Sheet:", error.message);
    throw error;
  }
}

app.get("/medicines", async (req, res) => {
  try {
    const medicines = await syncSheetToCsv();
    res.json(medicines);
  } catch (error) {
    console.log("Serving data from local CSV due to sync failure.");
    if (fs.existsSync(CSV_FILE_PATH)) {
      const csvData = fs.readFileSync(CSV_FILE_PATH, "utf8");
      const parsedData = Papa.parse(csvData, { header: true, dynamicTyping: true });
      res.json(parsedData.data);
    } else {
      res.status(500).json({
        error: "Could not fetch data from Google Sheets and no local data is available.",
        details: error.message
      });
    }
  }
});

app.get("/medicines/available", async (req, res) => {
  try {
    let allMedicines;
    try {
      allMedicines = await syncSheetToCsv();
    } catch (error) {
      console.log("Serving available medicines from local CSV due to sync failure.");
      if (fs.existsSync(CSV_FILE_PATH)) {
        const csvData = fs.readFileSync(CSV_FILE_PATH, "utf8");
        const parsedData = Papa.parse(csvData, { header: true, dynamicTyping: true });
        allMedicines = parsedData.data;
      } else {
        throw new Error("No online or local data available.");
      }
    }

    const availableMeds = allMedicines.filter(m => m && m.available);

    const page = Math.max(1, Number(req.query.page) || 1);
    const limit = Math.max(1, Math.min(200, Number(req.query.limit) || 100));
    const total = availableMeds.length;
    const totalPages = Math.max(1, Math.ceil(total / limit));
    const start = (page - 1) * limit;
    const data = availableMeds.slice(start, start + limit).map(({ name, kn_name }) => ({ name, kn_name }));

    res.json({ page, totalPages, count: data.length, total, data });

  } catch (error) {
    res.status(500).json({
      error: "Failed to retrieve available medicines.",
      details: error.message
    });
  }
});

http.createServer(app).listen(PORT, "0.0.0.0", () => {
  console.log(`HTTP Server running`);
  syncSheetToCsv().catch(err => {
    console.error("Initial sync failed on startup.", err.message);
  });
  setInterval(() => {
    syncSheetToCsv().catch(err => {
      console.error("Scheduled sync failed.", err.message);
    });
  }, 60 * 1000);
});