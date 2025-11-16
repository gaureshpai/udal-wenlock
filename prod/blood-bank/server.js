const express = require("express");
const path = require("path");
const http = require("http");
const fs = require("fs");
const fetch = require('node-fetch');

const app = express();
const PORT = process.env.PORT || 3001;

// https://docs.google.com/spreadsheets/d/139Lp9FCeCP_-Lm8DZfrarNfYFbyTWIBbJFn3a55FrZU/edit?gid=0#gid=0

let bloodData = [];
let lastFetchedAt = null; // store last fetched time
const SECRET_KEY = "lasdfaldf234232wqa122fsvsdlfjsdvnsasifjweiojsadlflkasdjflkasjflk32234234edswdsjfflas2 3rsd";
const baseUrl = "https://script.google.com/macros/s/AKfycbweEiZ7uE7KXrQCC4Iu5gPsSGKLBRDSwa4Wi5QQsTcszvsz37ufilRu-TcBO5thRs89/exec";

app.get("/", (req, res) => {
  res.redirect("/display.html");
});

async function getKannadaTransliteration(text) {
  if (!text || typeof text !== 'string') return text;
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

async function pollUpdates() {
  try {
    let url = `${baseUrl}?key=${SECRET_KEY}&sheet=Blood%20Requests`;
    if (lastFetchedAt) {
      url += `&since=${encodeURIComponent(lastFetchedAt)}`;
    }

    console.log("Fetching updates with since:", lastFetchedAt || "first fetch");
    lastFetchedAt = new Date().toISOString();
    const res = await fetch(url);
    const data = await res.json();

    if (!Array.isArray(data) || data.length === 0) {
      console.log("No new rows.");
      return;
    }

    console.log("Fetched rows:", data.length);

    const processedData = await Promise.all(data.map(async (item) => {
      const kn_name = await getKannadaTransliteration(item.Name);
      const result = { ...item, kn_name };

      const componentKeys = ["PRBC", "FFP", "PLATELET_CONCENTRATE", "CRYOPRECIPITATE", "CRYOPOOR_PLASMA"];
      for (const key of componentKeys) {
        if (item[key] && typeof item[key] === 'string') {
          result[`kn_${key}`] = await getKannadaTransliteration(item[key]);
        }
      }
      return result;
    }));

    const existingMap = new Map(bloodData.map(d => [d.SN, d]));
    for (const newItem of processedData) {
      existingMap.set(newItem.SN, newItem);
    }
    bloodData = Array.from(existingMap.values());

    bloodData.sort((a, b) => {
      if (a.Status && a.Status.toLowerCase() === 'emergency') return -1;
      if (b.Status && b.Status.toLowerCase() === 'emergency') return 1;
      return 0;
    });
  } catch (err) {
    console.error("Error fetching or processing updates:", err);
  }
}

app.use(express.static(path.join(__dirname, 'public')));

app.get("/data", (req, res) => {
  res.json(bloodData);
});

const server = http.createServer(app);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`HTTP Server running on http://localhost:${PORT}`);
  pollUpdates();
  setInterval(pollUpdates, 30000);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});