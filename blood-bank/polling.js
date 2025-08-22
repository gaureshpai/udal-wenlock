let lastFetched = null;
const SECRET_KEY = "lasdfaldf234232wqa122fsvsdlfjsdvnsasifjweiojsadlflkasdjflkasjflk32234234edswdsjfflas2 3rsd"; 
const baseUrl = "https://script.google.com/macros/s/AKfycbzEckJH-sjV_vz299x0TSEAq3HjbQRTpUZ6FzXtz-tV3GCyVJYQX89zlPHocbRslVyv/exec";

async function pollUpdates() {
  let url = `${baseUrl}?key=${SECRET_KEY}`;
  if (lastFetched) {
    url += `&since=${encodeURIComponent(lastFetched)}`;
  }

  try {
    lastFetched = new Date().toISOString(); // update lastFetched
    const res = await fetch(url);
    const data = await res.json();
    console.log("New/updated rows:", data);

    if (data.length > 0) {
      // Update your UI here
    
    }

  } catch (err) {
    console.error("Error fetching updates:", err);
  }
}

setInterval(pollUpdates, 10000);
