const express = require("express");
const path = require("path");
const http = require("http");
const fs = require("fs");
const fetch = require('node-fetch');
const cron = require('node-cron');

const app = express();
const PORT = process.env.PORT || 3001;

// https://docs.google.com/spreadsheets/d/139Lp9FCeCP_-Lm8DZfrarNfYFbyTWIBbJFn3a55FrZU/edit?gid=0#gid=0

let bloodData = [];
let lastFetchedAt = null; // store last fetched time
const SECRET_KEY = "lasdfaldf234232wqa122fsvsdlfjsdvnsasifjweiojsadlflkasdjflkasjflk32234234edswdsjfflas23rsd";
const baseUrl = "https://script.google.com/macros/s/AKfycbxPx3ir07CcJGv4cahv7YXkGiXP7zrk3IuNmIAgwKJ9f1imf5L3nDfDIM6mdsCF7_L4tA/exec";

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
    console.log("Raw fetched data:", data);

    if (!Array.isArray(data) || data.length === 0) {
      console.log("No new rows.");
      return;
    }

    console.log("Fetched rows:", data.length);

    const processedData = await Promise.all(data.map(async (item) => {
      const kn_name = await getKannadaTransliteration(item.Name);
      const result = { ...item, kn_name };

      const componentKeys = ["PRBC", "FFP", "Platlet Concentrate", "Cryoprecipitate", "Cryopoor Plasma"];
      for (const key of componentKeys) {
        if (item[key]) {
          result[`kn_${key}`] = await getKannadaTransliteration(item[key]);
        }else{
          console.log('not found key:', key, 'in item:', item);
        }
      }
      return result;
    }));

    const existingMap = new Map(bloodData.map(d => [d.SN, d]));
    for (const newItem of processedData) {
      existingMap.set(newItem.SN, newItem);
    }
    bloodData = Array.from(existingMap.values());
    console.log("Total records after update:", bloodData);

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
  const filteredBloodData = bloodData.filter(item => item.Status !== "Sample Received");
  res.json(filteredBloodData);
});

const server = http.createServer(app);

server.listen(PORT, '0.0.0.0', () => {
  console.log(`HTTP Server running on http://localhost:${PORT}`);
  pollUpdates();
  setInterval(pollUpdates, 30000);
  runCron();
  cron.schedule('30 0 * * *', runCron, {
    timezone: "Asia/Kolkata"
  });

  function runCron(){
    console.log('Running cron job to send GET request');
    const cronFetchUrl = `${baseUrl}?key=${SECRET_KEY}&sheet=cron`;
    fetch(cronFetchUrl)
      .then(res => {
        if (!res.ok) {
          throw new Error(`HTTP error! status: ${res.status}`);
        }
        return res.text(); // or res.json() if the response is JSON
      })
      .then(text => console.log('GET request successful:', text))
      .catch(err => console.error('Error on GET request cron job:', err));
  }
});

process.on('SIGTERM', () => {
  console.log('SIGTERM signal received: closing HTTP server');
  server.close(() => {
    console.log('HTTP server closed');
    process.exit(0);
  });
});