# Blood Bank Service Documentation

## Overview

The Blood Bank Service provides a dual-screen display system for managing and displaying blood requests and inventory at Wenlock Hospital.

## Service Information

- **Port**: 3001
- **Technology**: Node.js, Express
- **Data Source**: Google Apps Script endpoint
- **Update Frequency**: 30 seconds
- **Displays**: 2 screens (Requests + Inventory)

## Features

### 1. Blood Requests Display
- Shows urgent blood requirements for patients
- Displays patient names in English and Kannada
- Shows required blood components (PRBC, FFP, Platelets, etc.)
- Prioritizes emergency requests at the top
- Auto-scrolling list

### 2. Inventory Display
- Shows current blood bank stock
- Displays availability for all blood groups
- Rotates through different blood components
- Real-time updates

## Architecture

### Data Flow

```
Google Sheets
    ↓
Google Apps Script (API)
    ↓
Node.js Backend (Port 3001)
    ↓ (Transliteration)
Devnagri API
    ↓
Frontend Display (HTML/CSS/JS)
```

### Key Components

#### Server (`server.js`)

**Main Functions**:

1. **`pollUpdates()`**
   - Fetches data from Google Apps Script endpoint
   - Uses incremental updates with `since` parameter
   - Runs every 30 seconds
   - Merges new data with existing records

2. **`getKannadaTransliteration(text)`**
   - Translates English text to Kannada
   - Splits text into words for better accuracy
   - Handles API failures gracefully

3. **Cron Job**
   - Runs daily at 12:30 AM IST
   - Sends cleanup request to Google Apps Script
   - Maintains data hygiene

**API Endpoints**:

- `GET /` - Redirects to display.html
- `GET /data` - Returns filtered blood requests (JSON)

#### Frontend

**Files**:
- `display.html` - Blood requests display
- `inventory.html` - Blood inventory display
- `style.css` - Shared styles
- `display.js` - Display logic

## Data Structure

### Blood Request Object

```javascript
{
  "SN": 1,                          // Serial Number (unique ID)
  "Name": "John Doe",               // Patient name
  "kn_name": "ಜಾನ್ ಡೋ",              // Kannada name
  "Blood Group": "O+",              // Blood group
  "PRBC": "2 units",                // Packed Red Blood Cells
  "kn_PRBC": "2 ಯುನಿಟ್ಸ್",           // Kannada translation
  "FFP": "",                        // Fresh Frozen Plasma
  "kn_FFP": "",
  "Platlet Concentrate": "1 unit",  // Platelets
  "kn_Platlet Concentrate": "1 ಯುನಿಟ್",
  "Cryoprecipitate": "",            // Cryo
  "kn_Cryoprecipitate": "",
  "Cryopoor Plasma": "",            // Cryopoor
  "kn_Cryopoor Plasma": "",
  "Status": "Emergency",            // Emergency or Normal
  "Timestamp": "2024-12-01T10:30:00Z"
}
```

### Component Types

The system tracks these blood components:
- **PRBC** - Packed Red Blood Cells
- **FFP** - Fresh Frozen Plasma
- **Platlet Concentrate** - Platelets
- **Cryoprecipitate** - Cryoprecipitate
- **Cryopoor Plasma** - Cryopoor Plasma

## Google Sheets Setup

### Sheet Structure

**Sheet Name**: "Blood Requests"

**Required Columns**:
- `SN` - Serial Number (auto-increment)
- `Name` - Patient Name
- `Blood Group` - A+, B+, O+, AB+, A-, B-, O-, AB-
- `PRBC` - Units needed (or empty)
- `FFP` - Units needed (or empty)
- `Platlet Concentrate` - Units needed (or empty)
- `Cryoprecipitate` - Units needed (or empty)
- `Cryopoor Plasma` - Units needed (or empty)
- `Status` - "Emergency" or "Normal"
- `Timestamp` - Auto-generated timestamp

### Google Apps Script

The backend expects a Google Apps Script deployed as a web app with these endpoints:

**Endpoint**: `GET ?key=SECRET_KEY&sheet=Blood%20Requests`

**Optional Parameters**:
- `since` - ISO timestamp for incremental updates

**Response Format**:
```json
[
  {
    "SN": 1,
    "Name": "Patient Name",
    "Blood Group": "O+",
    "PRBC": "2 units",
    "Status": "Emergency",
    "Timestamp": "2024-12-01T10:30:00Z"
  }
]
```

### Sample Apps Script Code

```javascript
function doGet(e) {
  const key = e.parameter.key;
  const sheet = e.parameter.sheet;
  const since = e.parameter.since;
  
  // Verify secret key
  if (key !== "YOUR_SECRET_KEY") {
    return ContentService.createTextOutput(JSON.stringify({error: "Unauthorized"}))
      .setMimeType(ContentService.MimeType.JSON);
  }
  
  // Get sheet data
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheetObj = ss.getSheetByName(sheet);
  const data = sheetObj.getDataRange().getValues();
  
  // Convert to JSON
  const headers = data[0];
  const rows = data.slice(1);
  
  let result = rows.map(row => {
    let obj = {};
    headers.forEach((header, i) => {
      obj[header] = row[i];
    });
    return obj;
  });
  
  // Filter by timestamp if 'since' provided
  if (since) {
    const sinceDate = new Date(since);
    result = result.filter(row => {
      const rowDate = new Date(row.Timestamp);
      return rowDate > sinceDate;
    });
  }
  
  return ContentService.createTextOutput(JSON.stringify(result))
    .setMimeType(ContentService.MimeType.JSON);
}
```

## Installation

### Prerequisites
- Node.js v14+
- npm

### Steps

1. **Navigate to service directory**:
   ```bash
   cd prod/blood-bank
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Configure settings** in `server.js`:
   ```javascript
   const SECRET_KEY = "your_secret_key";
   const baseUrl = "your_google_apps_script_url";
   ```

4. **Start the service**:
   ```bash
   npm start
   ```

5. **Access displays**:
   - Requests: `http://localhost:3001/display.html`
   - Inventory: `http://localhost:3001/inventory.html`

## Configuration

### Environment Variables

Create `.env` file (optional):
```env
PORT=3001
SECRET_KEY=your_secret_key_here
BASE_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

Update `server.js` to use environment variables:
```javascript
require('dotenv').config();
const PORT = process.env.PORT || 3001;
const SECRET_KEY = process.env.SECRET_KEY;
const baseUrl = process.env.BASE_URL;
```

### Customization

**Change update frequency**:
```javascript
// In server.js, line 105
setInterval(pollUpdates, 30000); // Change 30000 to desired milliseconds
```

**Change cron schedule**:
```javascript
// In server.js, line 107
cron.schedule('30 0 * * *', runCron, { // Change cron expression
  timezone: "Asia/Kolkata"
});
```

**Modify emergency priority**:
```javascript
// In server.js, lines 83-87
bloodData.sort((a, b) => {
  if (a.Status && a.Status.toLowerCase() === 'emergency') return -1;
  if (b.Status && b.Status.toLowerCase() === 'emergency') return 1;
  return 0;
});
```

## API Reference

### GET `/data`

Returns filtered blood requests (excludes "Sample Received" status).

**Request**:
```bash
curl http://localhost:3001/data
```

**Response**:
```json
[
  {
    "SN": 1,
    "Name": "John Doe",
    "kn_name": "ಜಾನ್ ಡೋ",
    "Blood Group": "O+",
    "PRBC": "2 units",
    "kn_PRBC": "2 ಯುನಿಟ್ಸ್",
    "Status": "Emergency",
    "Timestamp": "2024-12-01T10:30:00Z"
  }
]
```

**Status Codes**:
- `200 OK` - Success
- `500 Internal Server Error` - Server error

## Troubleshooting

### Common Issues

**1. Service won't start**
```
Error: listen EADDRINUSE: address already in use :::3001
```
**Solution**: Port 3001 is already in use. Kill the existing process or change the port.

**2. No data showing**
```
Console: "No new rows."
```
**Solution**: 
- Check Google Apps Script URL is correct
- Verify SECRET_KEY matches
- Ensure Google Sheet has data
- Check network connectivity

**3. Kannada text not appearing**
```
Console: "Transliteration error: fetch failed"
```
**Solution**:
- Check internet connection
- Verify transliteration API is accessible
- Check for rate limiting

**4. Emergency requests not at top**
```
Emergency items appearing in wrong order
```
**Solution**:
- Ensure Status column says exactly "Emergency" (case-insensitive)
- Check sorting logic in server.js

### Debug Mode

Add verbose logging:
```javascript
// In pollUpdates()
console.log("Fetched data:", JSON.stringify(data, null, 2));
console.log("Processed data:", JSON.stringify(processedData, null, 2));
console.log("Final bloodData:", JSON.stringify(bloodData, null, 2));
```

## Performance

### Optimization Tips

1. **Reduce transliteration calls**:
   - Cache translations in database
   - Only transliterate new/changed items

2. **Optimize data fetching**:
   - Use `since` parameter effectively
   - Implement exponential backoff on errors

3. **Frontend optimization**:
   - Implement virtual scrolling for large lists
   - Debounce data updates

### Monitoring

**Check service status**:
```bash
pm2 status blood-bank
```

**View logs**:
```bash
pm2 logs blood-bank --lines 100
```

**Monitor memory**:
```bash
pm2 monit
```

## Security

### Current Implementation
- Uses SECRET_KEY for API authentication
- No user authentication on frontend
- Public display (intentional)

### Recommendations
- Rotate SECRET_KEY periodically
- Use HTTPS in production
- Implement rate limiting
- Add request logging

## Deployment

### Production with PM2

```bash
pm2 start server.js --name blood-bank
pm2 save
pm2 startup
```

### Windows Service (VBS)

Double-click `service.vbs` to start as background process.

### Docker

```dockerfile
FROM node:14-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
EXPOSE 3001
CMD ["node", "server.js"]
```

Build and run:
```bash
docker build -t blood-bank .
docker run -d -p 3001:3001 --name blood-bank blood-bank
```

## Maintenance

### Regular Tasks

**Daily**:
- Check service is running
- Verify displays are updating

**Weekly**:
- Review logs for errors
- Clean up old data in Google Sheets

**Monthly**:
- Update dependencies: `npm update`
- Review and optimize performance

### Backup

**Backup Google Sheet**:
- File > Make a copy
- Download as CSV

**Backup code**:
```bash
git commit -am "Backup before changes"
git push
```

## Support

For issues or questions:
- Check logs: `pm2 logs blood-bank`
- Review this documentation
- Contact IT department

---

*Last Updated: December 2025*
*Version: 1.0*
