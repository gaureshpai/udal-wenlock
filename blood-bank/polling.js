let lastFetched = null;
const SECRET_KEY = "lasdfaldf234232wqa122fsvsdlfjsdvnsasifjweiojsadlflkasdjflkasjflk32234234edswdsjfflas2 3rsd"; 
const baseUrl = "https://script.google.com/macros/s/AKfycbzWYYnT46qKH0AxD18VGvi6Yu40JpGEWZ159EieWqvITvHIprl7enxi06sF26KT043F/exec";

async function pollUpdates() {
  let url = `${baseUrl}?key=${SECRET_KEY}`;
  if (lastFetched) {
    url += `&since=${encodeURIComponent(lastFetched)}`;
  }

  try {
    const res = await fetch(url);
    const data = await res.json();
    console.log("New/updated rows:", data);

    if (data.length > 0) {
      // Update your UI here
    
    }

    lastFetched = new Date().toISOString(); // update lastFetched
  } catch (err) {
    console.error("Error fetching updates:", err);
  }
}

setInterval(pollUpdates, 10000);
