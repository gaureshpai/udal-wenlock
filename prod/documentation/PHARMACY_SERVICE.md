# Pharmacy Service Documentation

## Overview

The Pharmacy Service displays a scrolling list of available medicines at the hospital pharmacy in both English and Kannada.

## Service Information

- **Port**: 3000
- **Technology**: Node.js, Express, PapaParse
- **Data Source**: Google Sheets CSV export
- **Update Frequency**: 60 seconds
- **Offline Capability**: Yes (local CSV cache)

## Features

### Core Features
- Real-time medicine availability display
- Automatic Kannada transliteration
- Offline mode with local CSV caching
- Smart data merging (preserves translations)
- Change detection (only writes when needed)
- Pagination support for API
- Vertical scrolling display

### Resilience
- **Offline Mode**: Continues working without internet
- **Local Cache**: Stores data in CSV file
- **Smart Sync**: Only updates when data changes
- **Translation Preservation**: Keeps existing Kannada translations

## Architecture

### Data Flow

```
Google Sheets
    ↓ (CSV Export)
Node.js Backend (Port 3000)
    ↓ (Parse CSV)
PapaParse
    ↓ (Compare with local)
Local CSV Cache
    ↓ (Transliterate new items)
Devnagri API
    ↓ (Merge & Update)
In-Memory Cache
    ↓ (Serve API)
Frontend Display
```

### Key Components

#### Server (`server.js`)

**Main Functions**:

1. **`syncSheetToCsv()`**
   - Fetches CSV from Google Sheets
   - Parses with PapaParse
   - Loads existing local CSV
   - Merges data intelligently
   - Detects changes
   - Writes to local CSV only if changed
   - Updates in-memory cache
   - Runs every 60 seconds

2. **`getKannadaTransliteration(text)`**
   - Translates medicine names to Kannada
   - Splits into words for accuracy
   - Handles errors gracefully

3. **`parseAvailability(value)`**
   - Parses various availability formats
   - Accepts: ✔, ✓, 1, yes, true
   - Returns boolean

**API Endpoints**:

- `GET /` - Redirects to display.html
- `GET /medicines` - Returns all medicines
- `GET /medicines/available` - Returns available medicines (paginated)

#### Frontend

**Files**:
- `display.html` - Scrolling medicine display
- `style.css` - Display styles
- `script.js` - Display logic

## Data Structure

### Medicine Object

```javascript
{
  "name": "Paracetamol",           // Medicine name
  "available": true,                // Availability status
  "kn_name": "ಪ್ಯಾರಸಿಟಮಾಲ್"          // Kannada name
}
```

### CSV File Structure

**Location**: `data/medicines.csv`

**Format**:
```csv
name,available,kn_name
Paracetamol,true,ಪ್ಯಾರಸಿಟಮಾಲ್
Aspirin,false,ಆಸ್ಪಿರಿನ್
Amoxicillin,true,ಅಮೋಕ್ಸಿಸಿಲಿನ್
```

## Google Sheets Setup

### Sheet Structure

**Required Columns** (flexible naming):
- `Medicine Name` or `Name` or `medicine` - Medicine name
- `Available` or `Availability` - Availability status

**Supported Availability Values**:
- Checkmarks: ✔, ✓
- Text: TRUE, YES, 1
- Empty or FALSE for unavailable

### Sheet Configuration

1. **Create Google Sheet** with medicine data
2. **Get Sheet ID** from URL:
   ```
   https://docs.google.com/spreadsheets/d/SHEET_ID/edit
   ```
3. **Get GID** (sheet tab ID, usually 0 for first tab)
4. **Set sharing** to "Anyone with the link can view"

### CSV Export URL Format

```
https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:csv&gid={GID}
```

**Example**:
```
https://docs.google.com/spreadsheets/d/1nRk_AzFRq4k5v8441nL4XPNXNCNwLVVg_5-wO2bHS6g/gviz/tq?tqx=out:csv&gid=0
```

## Installation

### Prerequisites
- Node.js v14+
- npm

### Steps

1. **Navigate to service directory**:
   ```bash
   cd prod/pharmacy
   ```

2. **Install dependencies**:
   ```bash
   npm install
   ```

3. **Configure Google Sheet** in `server.js`:
   ```javascript
   const SHEET_ID = "your_sheet_id_here";
   const GID = "0";  // Your sheet tab ID
   ```

4. **Start the service**:
   ```bash
   npm start
   ```

5. **Access display**:
   - Display: `http://localhost:3000/display.html`
   - API: `http://localhost:3000/medicines`

## Configuration

### Environment Variables

Create `.env` file (optional):
```env
PORT=3000
SHEET_ID=your_google_sheet_id
GID=0
SYNC_INTERVAL=60000
```

Update `server.js`:
```javascript
require('dotenv').config();
const PORT = process.env.PORT || 3000;
const SHEET_ID = process.env.SHEET_ID;
const GID = process.env.GID || "0";
const SYNC_INTERVAL = process.env.SYNC_INTERVAL || 60000;
```

### Customization

**Change sync frequency**:
```javascript
// In server.js, line 251
syncInterval = setInterval(() => {
  syncSheetToCsv();
}, 60 * 1000); // Change to desired milliseconds
```

**Change pagination limits**:
```javascript
// In server.js, line 227
const limit = Math.max(1, Math.min(200, Number(req.query.limit) || 100));
// Change 200 (max) and 100 (default)
```

**Modify CSV cache location**:
```javascript
// In server.js, line 10-11
const DATA_DIR = path.join(__dirname, "data");
const CSV_FILE_PATH = path.join(DATA_DIR, "medicines.csv");
```

## API Reference

### GET `/medicines`

Returns all medicines with availability status.

**Request**:
```bash
curl http://localhost:3000/medicines
```

**Response**:
```json
[
  {
    "name": "Paracetamol",
    "available": true,
    "kn_name": "ಪ್ಯಾರಸಿಟಮಾಲ್"
  },
  {
    "name": "Aspirin",
    "available": false,
    "kn_name": "ಆಸ್ಪಿರಿನ್"
  }
]
```

### GET `/medicines/available`

Returns only available medicines with pagination.

**Query Parameters**:
- `page` (optional, default: 1) - Page number
- `limit` (optional, default: 100, max: 200) - Items per page

**Request**:
```bash
curl "http://localhost:3000/medicines/available?page=1&limit=50"
```

**Response**:
```json
{
  "page": 1,
  "totalPages": 5,
  "count": 50,
  "total": 234,
  "data": [
    {
      "name": "Paracetamol",
      "kn_name": "ಪ್ಯಾರಸಿಟಮಾಲ್"
    },
    {
      "name": "Amoxicillin",
      "kn_name": "ಅಮೋಕ್ಸಿಸಿಲಿನ್"
    }
  ]
}
```

**Status Codes**:
- `200 OK` - Success
- `500 Internal Server Error` - Server error

## Sync Logic

### Smart Data Merging

The service implements intelligent data synchronization:

1. **Load Local Data**: Read existing CSV cache
2. **Fetch Remote Data**: Get latest from Google Sheets
3. **Merge Strategy**:
   - If medicine exists locally → preserve Kannada translation
   - If medicine is new → transliterate to Kannada
4. **Change Detection**:
   - Compare size (number of medicines)
   - Compare availability status
   - Compare translations
5. **Write Decision**:
   - Only write to CSV if changes detected
   - Prevents unnecessary disk I/O

### Offline Mode

When internet is unavailable:

1. Sync fails to fetch from Google Sheets
2. Service catches error
3. Loads data from local CSV cache
4. Continues serving cached data
5. Retries sync on next interval

**Code**:
```javascript
try {
  // Fetch from Google Sheets
  const response = await fetch(SHEET_CSV_URL);
  // Process and update
} catch (error) {
  // Fallback to local CSV
  if (fs.existsSync(CSV_FILE_PATH)) {
    const csvData = fs.readFileSync(CSV_FILE_PATH, "utf8");
    medicinesCache = Papa.parse(csvData, { header: true }).data;
  }
}
```

## Troubleshooting

### Common Issues

**1. Service won't start**
```
Error: listen EADDRINUSE: address already in use :::3000
```
**Solution**: Port 3000 is in use. Kill existing process or change port.

**2. Google Sheet not accessible**
```
Error: Failed to fetch sheet: 403 Forbidden
```
**Solution**:
- Check sheet sharing settings
- Verify SHEET_ID is correct
- Ensure sheet is public or accessible

**3. CSV file not updating**
```
Console: "No changes detected between sheet and local CSV."
```
**Solution**: This is normal if data hasn't changed. To force update:
```bash
rm data/medicines.csv
# Restart service
```

**4. Kannada translations missing**
```
kn_name shows empty or English text
```
**Solution**:
- Check internet connection
- Wait for transliteration to complete
- Check transliteration API availability

**5. Empty data showing**
```
Console: "WARNING: newMedicines array is empty"
```
**Solution**:
- Check Google Sheet has data
- Verify column names match expected format
- Check CSV parsing logs

### Debug Mode

Enable verbose logging:
```javascript
// In syncSheetToCsv()
console.log("Remote rows:", parsedSheet.data.length);
console.log("Sample data:", parsedSheet.data.slice(0, 3));
console.log("Headers:", parsedSheet.meta.fields);
console.log("Local medicines:", localMedicines.size);
console.log("New medicines:", newMedicines.length);
```

### Testing Sync

**Manual sync test**:
```bash
# Watch logs
pm2 logs pharmacy

# In another terminal, trigger sync by restarting
pm2 restart pharmacy

# Check CSV file
cat prod/pharmacy/data/medicines.csv
```

## Performance

### Optimization Tips

1. **Reduce transliteration calls**:
   - Already implemented: preserves existing translations
   - Only new medicines are transliterated

2. **Optimize CSV parsing**:
   ```javascript
   // Use streaming for very large files
   const stream = fs.createReadStream(CSV_FILE_PATH);
   Papa.parse(stream, {
     header: true,
     step: (row) => {
       // Process row by row
     }
   });
   ```

3. **Cache API responses**:
   ```javascript
   // Add cache headers
   app.get('/medicines', (req, res) => {
     res.set('Cache-Control', 'public, max-age=60');
     res.json(medicinesCache);
   });
   ```

### Memory Management

**Current implementation**:
- In-memory cache: `medicinesCache` array
- Typical size: ~500 medicines × ~100 bytes = ~50 KB
- Very lightweight

**For large datasets** (10,000+ medicines):
- Consider using SQLite database
- Implement pagination on backend
- Use streaming responses

## Security

### Current Implementation
- No authentication (public display)
- Read-only access to Google Sheets
- No user input validation needed

### Recommendations
- Use HTTPS in production
- Implement rate limiting on API
- Add request logging
- Secure CSV file permissions

## Deployment

### Production with PM2

```bash
cd prod/pharmacy
pm2 start server.js --name pharmacy
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
RUN mkdir -p data
VOLUME /app/data
EXPOSE 3000
CMD ["node", "server.js"]
```

Build and run:
```bash
docker build -t pharmacy .
docker run -d -p 3000:3000 -v pharmacy-data:/app/data --name pharmacy pharmacy
```

## Maintenance

### Regular Tasks

**Daily**:
- Verify service is running
- Check display is updating

**Weekly**:
- Review logs for errors
- Update medicine list in Google Sheet
- Clean up unavailable medicines

**Monthly**:
- Update dependencies: `npm update`
- Backup CSV file
- Review performance

### Backup

**Backup CSV cache**:
```bash
cp prod/pharmacy/data/medicines.csv backup/medicines_$(date +%Y%m%d).csv
```

**Backup Google Sheet**:
- File > Make a copy
- Download as CSV

## Advanced Features

### Adding Search Functionality

```javascript
app.get('/medicines/search', (req, res) => {
  const query = req.query.q?.toLowerCase();
  if (!query) {
    return res.status(400).json({ error: 'Query parameter required' });
  }
  
  const results = medicinesCache.filter(m => 
    m.name.toLowerCase().includes(query) ||
    m.kn_name.includes(query)
  );
  
  res.json(results);
});
```

### Adding Categories

Update Google Sheet with category column, then:
```javascript
app.get('/medicines/category/:category', (req, res) => {
  const category = req.params.category;
  const results = medicinesCache.filter(m => 
    m.category === category && m.available
  );
  res.json(results);
});
```

### Export Functionality

```javascript
app.get('/medicines/export', (req, res) => {
  const csv = Papa.unparse(medicinesCache);
  res.setHeader('Content-Type', 'text/csv');
  res.setHeader('Content-Disposition', 'attachment; filename=medicines.csv');
  res.send(csv);
});
```

## Support

For issues or questions:
- Check logs: `pm2 logs pharmacy`
- Review this documentation
- Verify Google Sheet accessibility
- Contact IT department

---

*Last Updated: December 2025*
*Version: 1.0*
