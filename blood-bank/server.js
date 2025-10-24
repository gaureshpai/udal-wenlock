const express = require("express");
const path = require("path");
const http = require("http");
const fetch = require('node-fetch');

const app = express();
const PORT = process.env.PORT || 3001;

let bloodData = [];
let lastFetchedAt = null; // store last fetched time
const SECRET_KEY = "lasdfaldf234232wqa122fsvsdlfjsdvnsasifjweiojsadlflkasdjflkasjflk32234234edswdsjfflas2 3rsd";
const baseUrl = "https://script.google.com/macros/s/AKfycbx4wgFIQ1Dm0iKvH-NPnIg5YP7SuBSOT80GbbCxBQt7i3SKOuANdy_JJAyqwFtDVFJs/exec";

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
    let url = `${baseUrl}?key=${SECRET_KEY}`;
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

    // Process transliterations
    const processedData = await Promise.all(data.map(async (item) => {
      const kn_name = await getKannadaTransliteration(item.Name);
      const kn_component = await getKannadaTransliteration(item.Component);
      return { ...item, kn_name, kn_component };
    }));

    // Merge new data into local cache
    const existingMap = new Map(bloodData.map(d => [d.SN, d]));
    for (const newItem of processedData) {
      existingMap.set(newItem.SN, newItem); // overwrite or add
    }
    bloodData = Array.from(existingMap.values());

    // sort emergencies first
    bloodData.sort((a, b) => {
      if (a.Status && a.Status.toLowerCase() === 'emergency') return -1;
      if (b.Status && b.Status.toLowerCase() === 'emergency') return 1;
      return 0;
    });

    // Update last fetched time

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
  setInterval(pollUpdates, 10000);
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});

