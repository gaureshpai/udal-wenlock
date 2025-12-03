const express = require("express");
const path = require("path");
const http = require("http");

const app = express();
const PORT = process.env.PORT || 3002;

let otData = [];

let lastFetchedAt = null;
const SECRET_KEY = "lasdfaldf234232wqa122fsvsdlfjsdvnsasifjweiojsadlflkasdjflkasjflk32234234edswdsjfflas2 3rsd";
const baseUrl = "https://script.google.com/macros/s/AKfycbxPx3ir07CcJGv4cahv7YXkGiXP7zrk3IuNmIAgwKJ9f1imf5L3nDfDIM6mdsCF7_L4tA/exec";

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

    // const fieldsToTranslate = ["Name", "Surgery site", "Surgery", "Surgeon Name", "Department", "Time"];

    // const processedData = await Promise.all(
    //   data.map(async (item) => {
    //     const result = { ...item };
    const processedData = await Promise.all(
      data.map(async (item) => {
        const result = { ...item };

        // Loop through all keys in the item
        for (const key of Object.keys(item)) {
          const value = item[key];

          // Convert only if value exists and is text-like
          if (value && typeof value === "string" && key !='Age' ) {
            const knValue = await getKannadaTransliteration(value);
            result[`kn_${key}`] = knValue;
          } else {
            result[`kn_${key}`] = "";
          }
        }
        return result;
      })
    );

    //     for (const key of fieldsToTranslate) {
    //       const value = item[key];
    //       if (value && typeof value === "string") {
    //         const knValue = await getKannadaTransliteration(value);
    //         result[`kn_${key}`] = knValue;
    //       } else {
    //         result[`kn_${key}`] = "";
    //       }
    //     }
    //     return result;
    //   })
    // );

    const existingMap = new Map(otData.map(d => [d.Sl, d]));
    for (const newItem of processedData) {
      existingMap.set(newItem.Sl, newItem);
    }
    console.log("Total records before sorting:", existingMap);
    otData = Array.from(existingMap.values()).filter(d => d["Patient Name"] && d.Sl);
    const priority = {
      'surgery in progress': 1,
      'scheduled': 2,
      'pre-operative ward': 3,
      'ot cancelled - not fit': 4,
      'post-operative ward': 5,
      'surgery successfully': 6
    };


    otData.sort((a, b) => {
      const aPriority = priority[a.Status?.toLowerCase()] || 99;
      const bPriority = priority[b.Status?.toLowerCase()] || 99;

      return aPriority - bPriority;
    });
    console.log("Total records after update:", otData);
  } catch (err) {
    console.error("Error fetching or processing updates:", err);
  }
}

app.get("/", (req, res) => {
  res.redirect("/display.html");
});

app.use(express.static(path.join(__dirname, 'public')));

app.get("/data", (req, res) => {
  console.log("Serving data with", otData.length, "rows");
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
