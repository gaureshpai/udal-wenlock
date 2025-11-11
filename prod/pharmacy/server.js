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

const SHEET_ID = "1nRk_AzFRq4k5v8441nL4XPNXNCNwLVVg_5-wO2bHS6g";
const GID = "0";
const SHEET_CSV_URL = `https://docs.google.com/spreadsheets/d/${SHEET_ID}/gviz/tq?tqx=out:csv&gid=${GID}`;

app.use(express.static(path.join(__dirname, "public")));

app.get("/", (req, res) => {
  res.redirect("/display.html");
});

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

let isShuttingDown = false;
let activeSyncs = 0;
let medicinesCache = [];

async function syncSheetToCsv() {
  if (isShuttingDown) {
    console.log("Shutdown in progress, skipping sync.");
    return;
  }
  if (activeSyncs > 0) {
    console.log("Sync already in progress, skipping.");
    return;
  }
  activeSyncs++;
  console.log(`Starting sync. Active syncs: ${activeSyncs}`);
  try {
    // 1. Read local data
    let localMedicines = new Map();
    if (fs.existsSync(CSV_FILE_PATH)) {
      const localCsvData = fs.readFileSync(CSV_FILE_PATH, "utf8");
      if (localCsvData) {
        const localParsed = Papa.parse(localCsvData, { header: true, skipEmptyLines: true, dynamicTyping: true });
        localParsed.data.forEach(m => {
          if (m.name) {
            localMedicines.set(m.name, m);
          }
        });
        console.log(`Loaded ${localMedicines.size} medicines from local CSV`);
      }
    }

    // 2. Fetch remote data
    const response = await fetch(SHEET_CSV_URL);
    if (!response.ok) {
      throw new Error(`Failed to fetch sheet: ${response.statusText}`);
    }
    const csvText = await response.text();
    
    // Parse with header: true to automatically handle headers
    const parsedSheet = Papa.parse(csvText, { 
      header: true, 
      skipEmptyLines: true,
      transformHeader: (header) => header.trim().toLowerCase()
    });

    console.log(`Remote sheet has ${parsedSheet.data.length} data rows`);
    console.log(`Headers detected:`, parsedSheet.meta.fields);

    // 3. Merge data
    let newMedicines = [];
    for (const row of parsedSheet.data) {
      // Handle different possible column names
      const name = (row.name || row.medicine || row['medicine name'] || row['Medicine Name'] || row['Medicine'] || row['Name'] || '').trim();
      
      if (name === "") {
        // console.log("Skipping empty row");
        continue;
      }

      const availability = parseAvailability(row.available || row.availability || row.Available || row.Availability || row['']);
      let kn_name = "";

      const localMedicine = localMedicines.get(name);
      if (localMedicine && localMedicine.kn_name) {
        // Row exists in local data, preserve kn_name
        kn_name = localMedicine.kn_name;
        console.log(`Preserving translation for: "${name}" -> "${kn_name}"`);
      } else {
        // New row or missing translation, transliterate
        console.log(`Translating new/missing item: "${name}"...`);
        kn_name = await getKannadaTransliteration(name);
        console.log(`Translation result: "${kn_name}"`);
      }

      newMedicines.push({
        name: name,
        available: availability,
        kn_name: kn_name,
      });
    }

    console.log(`Processed ${newMedicines.length} medicines from sheet`);

    // Safety check: don't write empty data if we had data before
    if (newMedicines.length === 0 && localMedicines.size > 0) {
      console.error("WARNING: newMedicines array is empty but we had data before! Not writing to CSV to prevent data loss.");
      console.log("Remote rows received:", parsedSheet.data.length);
      console.log("Sample remote data:", parsedSheet.data.slice(0, 3));
      // Keep using local CSV as cache
      medicinesCache = Array.from(localMedicines.values());
      activeSyncs--;
      return;
    }

    // If we truly have no data anywhere, that's okay for first run
    if (newMedicines.length === 0) {
      console.log("No medicines found in sheet. This might be the first run or sheet is empty.");
    }

    // 4. Compare newMedicines with localMedicines to detect changes
    let hasChanged = false;
    if (newMedicines.length !== localMedicines.size) {
      hasChanged = true;
      console.log(`Size changed: ${localMedicines.size} -> ${newMedicines.length}`);
    } else {
      for (const newMed of newMedicines) {
        const oldMed = localMedicines.get(newMed.name);
        if (!oldMed) {
          hasChanged = true;
          console.log(`New medicine found: ${newMed.name}`);
          break;
        }
        if (oldMed.available !== newMed.available) {
          hasChanged = true;
          console.log(`Availability changed for ${newMed.name}: ${oldMed.available} -> ${newMed.available}`);
          break;
        }
        if (oldMed.kn_name !== newMed.kn_name) {
          hasChanged = true;
          console.log(`Translation changed for ${newMed.name}: "${oldMed.kn_name}" -> "${newMed.kn_name}"`);
          break;
        }
      }
    }

    // 5. Write back to CSV if changed OR if CSV doesn't exist
    if (hasChanged || !fs.existsSync(CSV_FILE_PATH)) {
      if (!fs.existsSync(CSV_FILE_PATH)) {
        console.log("CSV file doesn't exist. Creating new file...");
      } else {
        console.log("Changes detected. Writing to local CSV file...");
      }
      const newCsv = Papa.unparse(newMedicines, { header: true, columns: ["name", "available", "kn_name"] });
      fs.writeFileSync(CSV_FILE_PATH, newCsv);
      console.log(`Local CSV file has been updated with ${newMedicines.length} medicines.`);
      
      // Verify write
      const verifyData = fs.readFileSync(CSV_FILE_PATH, "utf8");
      const verifyParsed = Papa.parse(verifyData, { header: true });
      console.log(`Verification: CSV now contains ${verifyParsed.data.length} rows`);
    } else {
      console.log("No changes detected between sheet and local CSV.");
    }
    
    medicinesCache = newMedicines;
    console.log(`Cache updated with ${medicinesCache.length} medicines.`);
    console.log("Sync finished successfully.");

  } catch (error) {
    console.error("Failed to sync from Google Sheet:", error.message);
    console.error("Error stack:", error.stack);
    // if sync fails, load from local csv
    if (fs.existsSync(CSV_FILE_PATH)) {
      const csvData = fs.readFileSync(CSV_FILE_PATH, "utf8");
      const parsedData = Papa.parse(csvData, { header: true, dynamicTyping: true, skipEmptyLines: true });
      medicinesCache = parsedData.data.filter(m => m.name);
      console.log(`Loaded ${medicinesCache.length} medicines from local CSV as fallback.`);
    }
  } finally {
    activeSyncs--;
    console.log(`Finished sync. Active syncs: ${activeSyncs}`);
  }
}

app.get("/medicines", (req, res) => {
  res.json(medicinesCache);
});

app.get("/medicines/available", (req, res) => {
  try {
    const availableMeds = medicinesCache.filter(m => m && m.available);

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

const server = http.createServer(app);
let syncInterval;

fs.watchFile(path.join(__dirname, 'public', 'close.txt'), (curr, prev) => {
  console.log('Shutdown signal received. Closing server...');
  isShuttingDown = true;
  clearInterval(syncInterval);

  const waitForSyncs = () => {
    if (activeSyncs > 0) {
      console.log(`Waiting for ${activeSyncs} sync(s) to complete...`);
      setTimeout(waitForSyncs, 500);
    } else {
      server.close(() => {
        console.log('Server closed.');
        if (fs.existsSync(path.join(__dirname, 'public', 'close.txt'))) {
          fs.unlinkSync(path.join(__dirname, 'public', 'close.txt'));
        }
        process.exit(0);
      });
    }
  };

  console.log("Waiting for active connections to close...");
  waitForSyncs();
});

server.listen(PORT, "0.0.0.0", () => {
  console.log(`HTTP Server running on port ${PORT}`);
  syncSheetToCsv().catch(err => {
    console.error("Initial sync failed on startup.", err.message);
  });
  syncInterval = setInterval(() => {
    syncSheetToCsv().catch(err => {
      console.error("Scheduled sync failed.", err.message);
    });
  }, 60 * 1000);
});