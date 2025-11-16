const express = require("express");
const path = require("path");
const http = require("http");

const app = express();
const PORT = process.env.PORT || 3002;

let otData = [];

let lastFetchedAt = null;
const SECRET_KEY = "lasdfaldf234232wqa122fsvsdlfjsdvnsasifjweiojsadlflkasdjflkasjflk32234234edswdsjfflas2 3rsd";
const baseUrl = "https://script.google.com/macros/s/AKfycbzaoIRRlwryKQ8qE_sJwuQ9L3dBwsLnRck4dkhj9nDAdQisz3SZovZl3kDoxG-BBOoa/exec";

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
    let url = `${baseUrl}?key=${SECRET_KEY}&sheet=OT`;
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

    const fieldsToTranslate = ["Name", "Surgery site", "Surgery", "Surgeon Name"];

    const processedData = await Promise.all(
      data.map(async (item) => {
        const result = { ...item };

        for (const key of fieldsToTranslate) {
          const value = item[key];
          if (value && typeof value === "string") {
            const knValue = await getKannadaTransliteration(value);
            result[`kn_${key}`] = knValue;
          } else {
            result[`kn_${key}`] = "";
          }
        }
        return result;
      })
    );

    const existingMap = new Map(otData.map(d => [d.SN, d]));
    for (const newItem of processedData) {
      existingMap.set(newItem.SN, newItem);
    }
    otData = Array.from(existingMap.values()).filter(d => d.Name && d.SN);

    const priority = {
      'in progress': 1,
      'scheduled': 2,
      'post-op': 3,
    };

    otData.sort((a, b) => {
      const aPriority = priority[a.Status?.toLowerCase()] || 99;
      const bPriority = priority[b.Status?.toLowerCase()] || 99;

      return aPriority - bPriority;
    });
  } catch (err) {
    console.error("Error fetching or processing updates:", err);
  }
}

app.get("/", (req, res) => {
  res.redirect("/display.html");
});

app.use(express.static(path.join(__dirname, 'public')));

app.get("/data", (req, res) => {
  res.json(otData);
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
