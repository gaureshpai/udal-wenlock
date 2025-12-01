# Operation Theatre (OT) Service Documentation

## Overview

The Operation Theatre (OT) Service displays real-time status of all operation theatres, showing surgery schedules, patient information, and current status in both English and Kannada.

## Service Information

- **Port**: 3002
- **Technology**: Node.js, Express
- **Data Source**: Google Apps Script endpoint
- **Update Frequency**: 30 seconds
- **Display**: Single scrolling status board

## Features

### Core Features
- Real-time OT status tracking
- Patient information display (bilingual)
- Surgery details and surgeon information
- Priority-based sorting by status
- Automatic Kannada transliteration
- Incremental data updates

### Status Tracking
The system tracks these surgery statuses:
1. **In Progress** - Surgery currently ongoing
2. **Scheduled** - Confirmed for today
3. **Waiting at Pre-op** - Patient ready in pre-op
4. **Waiting** - Patient waiting
5. **Post-op** - Surgery completed, in recovery
6. **Completed** - Fully finished

## Architecture

### Data Flow

```
Google Sheets
    ↓
Google Apps Script (API)
    ↓
Node.js Backend (Port 3002)
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
   - Translates ALL text fields to Kannada
   - Excludes Age field (numeric)
   - Handles API failures gracefully

3. **Priority Sorting**
   - Automatically sorts by surgery status
   - Ensures critical surgeries appear first

**API Endpoints**:

- `GET /` - Redirects to display.html
- `GET /data` - Returns sorted OT data (JSON)

#### Frontend

**Files**:
- `display.html` - OT status display
- `style.css` - Display styles
- `script.js` - Display logic

## Data Structure

### OT Record Object

```javascript
{
  "Sl": 1,                              // Serial Number (unique ID)
  "Patient Name": "Jane Smith",         // Patient name
  "kn_Patient Name": "ಜೇನ್ ಸ್ಮಿತ್",      // Kannada name
  "Age": "45",                          // Patient age
  "kn_Age": "",                         // Not translated
  "Surgery site": "Abdomen",            // Surgery location
  "kn_Surgery site": "ಹೊಟ್ಟೆ",          // Kannada translation
  "Surgery": "Appendectomy",            // Surgery type
  "kn_Surgery": "ಅಪೆಂಡೆಕ್ಟಮಿ",           // Kannada translation
  "Surgeon Name": "Dr. Kumar",          // Operating surgeon
  "kn_Surgeon Name": "ಡಾ. ಕುಮಾರ್",       // Kannada translation
  "Department": "General Surgery",      // Hospital department
  "kn_Department": "ಜನರಲ್ ಸರ್ಜರಿ",      // Kannada translation
  "Status": "In Progress",              // Current status
  "kn_Status": "ಇನ್ ಪ್ರೋಗ್ರೆಸ್",         // Kannada translation
  "Time": "10:00 AM",                   // Surgery time
  "kn_Time": "10:00 AM"                 // Kannada translation
}
```

### Status Priority System

```javascript
const priority = {
  'in progress': 1,        // Highest priority
  'scheduled': 2,
  'waiting at pre-op': 3,
  'waiting': 4,
  'post-op': 5,
  'completed': 6          // Lowest priority
};
```

Records are sorted by this priority, ensuring the most critical surgeries appear first.

## Google Sheets Setup

### Sheet Structure

**Sheet Name**: "OT"

**Required Columns**:
- `Sl` - Serial Number (auto-increment)
- `Patient Name` - Patient's full name
- `Age` - Patient's age
- `Surgery site` - Body part/location
- `Surgery` - Type of surgery/procedure
- `Surgeon Name` - Operating surgeon
- `Department` - Hospital department
- `Status` - Current status (see status list)
- `Time` - Surgery time

### Google Apps Script

The backend expects a Google Apps Script deployed as a web app.

**Endpoint**: `GET ?key=SECRET_KEY&sheet=OT`

**Optional Parameters**:
- `since` - ISO timestamp for incremental updates

**Response Format**:
```json
[
  {
    "Sl": 1,
    "Patient Name": "Jane Smith",
    "Age": "45",
    "Surgery site": "Abdomen",
    "Surgery": "Appendectomy",
    "Surgeon Name": "Dr. Kumar",
    "Department": "General Surgery",
    "Status": "In Progress",
    "Time": "10:00 AM"
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
      const rowDate = new Date(row.Timestamp || row.Time);
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
   cd prod/OT
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

5. **Access display**:
   - Display: `http://localhost:3002/display.html`
   - API: `http://localhost:3002/data`

## Configuration

### Environment Variables

Create `.env` file (optional):
```env
PORT=3002
SECRET_KEY=your_secret_key_here
BASE_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

Update `server.js`:
```javascript
require('dotenv').config();
const PORT = process.env.PORT || 3002;
const SECRET_KEY = process.env.SECRET_KEY;
const baseUrl = process.env.BASE_URL;
```

### Customization

**Change update frequency**:
```javascript
// In server.js, line 133
setInterval(pollUpdates, 30000); // Change 30000 to desired milliseconds
```

**Modify status priority**:
```javascript
// In server.js, lines 96-103
const priority = {
  'in progress': 1,
  'scheduled': 2,
  'waiting at pre-op': 3,
  'waiting': 4,
  'post-op': 5,
  'completed': 6,
  'custom-status': 7  // Add custom statuses
};
```

**Exclude fields from translation**:
```javascript
// In server.js, line 66
if (value && typeof value === "string" && key != 'Age' && key != 'Time') {
  // Add more exclusions as needed
}
```

## API Reference

### GET `/data`

Returns all OT records sorted by priority.

**Request**:
```bash
curl http://localhost:3002/data
```

**Response**:
```json
[
  {
    "Sl": 1,
    "Patient Name": "Jane Smith",
    "kn_Patient Name": "ಜೇನ್ ಸ್ಮಿತ್",
    "Age": "45",
    "Surgery site": "Abdomen",
    "kn_Surgery site": "ಹೊಟ್ಟೆ",
    "Surgery": "Appendectomy",
    "kn_Surgery": "ಅಪೆಂಡೆಕ್ಟಮಿ",
    "Surgeon Name": "Dr. Kumar",
    "kn_Surgeon Name": "ಡಾ. ಕುಮಾರ್",
    "Department": "General Surgery",
    "kn_Department": "ಜನರಲ್ ಸರ್ಜರಿ",
    "Status": "In Progress",
    "Time": "10:00 AM"
  }
]
```

**Filtering**:
- Records without Patient Name are excluded
- Records without Sl (serial number) are excluded
- Sorted by status priority

**Status Codes**:
- `200 OK` - Success
- `500 Internal Server Error` - Server error

## Transliteration Logic

### Automatic Translation

The service automatically transliterates ALL text fields except:
- `Age` - Numeric field
- Any field you explicitly exclude

**Code**:
```javascript
for (const key of Object.keys(item)) {
  const value = item[key];
  
  // Convert only if value exists and is text-like
  if (value && typeof value === "string" && key != 'Age') {
    const knValue = await getKannadaTransliteration(value);
    result[`kn_${key}`] = knValue;
  } else {
    result[`kn_${key}`] = "";
  }
}
```

### Translation Caching

Currently, translations are NOT cached. Each update re-translates.

**To add caching**:
```javascript
const translationCache = new Map();

async function getKannadaTransliteration(text) {
  if (translationCache.has(text)) {
    return translationCache.get(text);
  }
  
  // Perform translation
  const translated = await performTranslation(text);
  translationCache.set(text, translated);
  return translated;
}
```

## Troubleshooting

### Common Issues

**1. Service won't start**
```
Error: listen EADDRINUSE: address already in use :::3002
```
**Solution**: Port 3002 is in use. Kill existing process or change port.

**2. No data showing**
```
Console: "No new rows."
```
**Solution**:
- Check Google Apps Script URL
- Verify SECRET_KEY matches
- Ensure Google Sheet has data
- Check network connectivity

**3. Sorting not working**
```
Surgeries appearing in wrong order
```
**Solution**:
- Ensure Status values match priority list exactly
- Check for typos in status names
- Status comparison is case-insensitive

**4. Kannada text not appearing**
```
Console: "Transliteration error: fetch failed"
```
**Solution**:
- Check internet connection
- Verify transliteration API is accessible
- Check for rate limiting

**5. Records disappearing**
```
Some records not showing on display
```
**Solution**:
- Check if Patient Name is filled
- Check if Sl (serial number) is present
- Review filter logic in server.js line 95

### Debug Mode

Add verbose logging:
```javascript
// In pollUpdates()
console.log("Fetched rows:", data.length);
console.log("Processed data:", processedData);
console.log("After filtering:", otData.length);
console.log("Final sorted data:", otData);
```

## Performance

### Optimization Tips

1. **Cache translations**:
   ```javascript
   const cache = new Map();
   // Store translations to avoid re-translating same text
   ```

2. **Reduce API calls**:
   - Use `since` parameter effectively
   - Only fetch changed records

3. **Frontend optimization**:
   - Implement virtual scrolling for many records
   - Debounce data updates

### Monitoring

**Check service status**:
```bash
pm2 status ot
```

**View logs**:
```bash
pm2 logs ot --lines 100
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
- Sanitize patient data if needed

## Deployment

### Production with PM2

```bash
cd prod/OT
pm2 start server.js --name ot
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
EXPOSE 3002
CMD ["node", "server.js"]
```

Build and run:
```bash
docker build -t ot-service .
docker run -d -p 3002:3002 --name ot-service ot-service
```

## Maintenance

### Regular Tasks

**Daily**:
- Check service is running
- Verify display is updating
- Review surgery statuses

**Weekly**:
- Review logs for errors
- Clean up completed surgeries in Google Sheet
- Verify all statuses are valid

**Monthly**:
- Update dependencies: `npm update`
- Review and optimize performance
- Backup Google Sheet data

### Data Cleanup

**Remove old records**:
- Manually delete completed surgeries from Google Sheet
- Or implement auto-cleanup in Apps Script

**Apps Script cleanup example**:
```javascript
function cleanupOldRecords() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('OT');
  const data = sheet.getDataRange().getValues();
  
  // Keep header, remove completed surgeries older than 7 days
  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - 7);
  
  for (let i = data.length - 1; i > 0; i--) {
    const status = data[i][7]; // Status column
    const timestamp = new Date(data[i][9]); // Timestamp column
    
    if (status === 'Completed' && timestamp < cutoffDate) {
      sheet.deleteRow(i + 1);
    }
  }
}
```

## Advanced Features

### Adding Filters

```javascript
app.get('/data/status/:status', (req, res) => {
  const status = req.params.status.toLowerCase();
  const filtered = otData.filter(d => 
    d.Status?.toLowerCase() === status
  );
  res.json(filtered);
});

// Usage: GET /data/status/in-progress
```

### Adding Statistics

```javascript
app.get('/stats', (req, res) => {
  const stats = {
    total: otData.length,
    inProgress: otData.filter(d => d.Status?.toLowerCase() === 'in progress').length,
    scheduled: otData.filter(d => d.Status?.toLowerCase() === 'scheduled').length,
    waiting: otData.filter(d => d.Status?.toLowerCase() === 'waiting').length,
    completed: otData.filter(d => d.Status?.toLowerCase() === 'completed').length
  };
  res.json(stats);
});
```

### Adding Department Filter

```javascript
app.get('/data/department/:dept', (req, res) => {
  const dept = req.params.dept.toLowerCase();
  const filtered = otData.filter(d => 
    d.Department?.toLowerCase().includes(dept)
  );
  res.json(filtered);
});
```

## Integration with Other Services

### Notify Blood Bank

When surgery requires blood:
```javascript
async function notifyBloodBank(otRecord) {
  if (otRecord.BloodRequired) {
    await fetch('http://localhost:3001/api/blood-request', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        name: otRecord['Patient Name'],
        bloodGroup: otRecord['Blood Group'],
        status: 'Emergency'
      })
    });
  }
}
```

## Support

For issues or questions:
- Check logs: `pm2 logs ot`
- Review this documentation
- Verify Google Apps Script accessibility
- Contact IT department

---

*Last Updated: December 2025*
*Version: 1.0*
