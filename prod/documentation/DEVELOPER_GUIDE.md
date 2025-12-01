# UDAL Wenlock Hospital Display System - Developer Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Service Details](#service-details)
3. [Setup and Installation](#setup-and-installation)
4. [Development Workflow](#development-workflow)
5. [API Documentation](#api-documentation)
6. [Deployment](#deployment)
7. [Troubleshooting](#troubleshooting)

---

## Architecture Overview

### System Design Principles

The UDAL Wenlock Hospital Display System follows a **microservices architecture** with these core principles:

1. **Decoupled Services**: Each service is independent and runs on its own port
2. **Google Sheets as Database**: Non-technical staff can update data easily
3. **Web-Based Displays**: Compatible with any modern browser
4. **Resilience**: Offline capabilities and error handling
5. **Automation**: Self-updating displays without manual intervention

### Technology Stack

- **Runtime**: Node.js (v14+)
- **Framework**: Express.js
- **Data Parsing**: PapaParse (CSV), node-fetch (HTTP)
- **Translation**: Devnagri Transliteration API
- **Scheduling**: node-cron
- **Process Management**: PM2 (production)

### Service Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Google Sheets                         │
│  (Data Source - Editable by Non-Technical Staff)        │
└────────────┬────────────────────────────────────────────┘
             │
             │ HTTP/CSV Export
             │
┌────────────▼────────────────────────────────────────────┐
│              Node.js Backend Services                    │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │
│  │  Blood Bank  │ │   Pharmacy   │ │      OT      │   │
│  │  Port 3001   │ │  Port 3000   │ │  Port 3002   │   │
│  └──────────────┘ └──────────────┘ └──────────────┘   │
│         │                │                │             │
│         │ Transliteration API (Kannada)   │             │
│         │                │                │             │
└─────────┼────────────────┼────────────────┼─────────────┘
          │                │                │
          │ JSON API       │                │
          │                │                │
┌─────────▼────────────────▼────────────────▼─────────────┐
│              Frontend HTML/CSS/JS Displays               │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐   │
│  │   Requests   │ │   Medicine   │ │  OT Status   │   │
│  │  Inventory   │ │   Scrolling  │ │   Display    │   │
│  └──────────────┘ └──────────────┘ └──────────────┘   │
└──────────────────────────────────────────────────────────┘
```

---

## Service Details

### 1. Blood Bank Service (`prod/blood-bank`)

**Port**: 3001  
**Data Source**: Google Apps Script endpoint  
**Update Frequency**: 30 seconds

#### Key Features
- Dual display system (Requests + Inventory)
- Emergency request prioritization
- Incremental data fetching with `since` parameter
- Automatic Kannada transliteration
- Daily cron job for cleanup

#### Server Architecture

```javascript
// Main components
- pollUpdates()          // Fetches data every 30s
- getKannadaTransliteration()  // Translates to Kannada
- /data endpoint         // Serves filtered blood requests
- Cron job (12:30 AM)    // Daily maintenance
```

#### Data Flow
1. Poll Google Apps Script endpoint with `since` timestamp
2. Receive new/updated blood requests
3. Transliterate patient names and component names to Kannada
4. Merge with existing data (using SN as key)
5. Sort by priority (Emergency first)
6. Filter out "Sample Received" status
7. Serve via `/data` endpoint

#### Google Apps Script Integration
```
Base URL: https://script.google.com/macros/s/[SCRIPT_ID]/exec
Parameters:
  - key: SECRET_KEY (authentication)
  - sheet: "Blood Requests" or "cron"
  - since: ISO timestamp (for incremental updates)
```

### 2. Pharmacy Service (`prod/pharmacy`)

**Port**: 3000  
**Data Source**: Google Sheets CSV export  
**Update Frequency**: 60 seconds

#### Key Features
- Offline capability with local CSV cache
- Smart data merging (preserves existing translations)
- Change detection (only writes when data changes)
- Pagination support
- Automatic Kannada transliteration

#### Server Architecture

```javascript
// Main components
- syncSheetToCsv()       // Syncs every 60s
- getKannadaTransliteration()  // Translates to Kannada
- /medicines             // All medicines
- /medicines/available   // Only available medicines (paginated)
```

#### Data Flow
1. Fetch CSV from Google Sheets public export URL
2. Parse CSV with PapaParse
3. Load existing local CSV (if exists)
4. For each medicine:
   - If exists locally, preserve Kannada translation
   - If new, transliterate to Kannada
5. Detect changes (size, availability, translations)
6. Write to local CSV only if changed
7. Update in-memory cache
8. Serve via API endpoints

#### Offline Resilience
```javascript
// Fallback mechanism
try {
  // Fetch from Google Sheets
} catch (error) {
  // Load from local CSV cache
  if (fs.existsSync(CSV_FILE_PATH)) {
    // Serve cached data
  }
}
```

### 3. Operation Theatre (OT) Service (`prod/OT`)

**Port**: 3002  
**Data Source**: Google Apps Script endpoint  
**Update Frequency**: 30 seconds

#### Key Features
- Real-time OT status tracking
- Priority-based sorting
- Complete field transliteration
- Incremental updates

#### Server Architecture

```javascript
// Main components
- pollUpdates()          // Fetches data every 30s
- getKannadaTransliteration()  // Translates all text fields
- /data endpoint         // Serves OT data
```

#### Status Priority System
```javascript
const priority = {
  'in progress': 1,
  'scheduled': 2,
  'waiting at pre-op': 3,
  'waiting': 4,
  'post-op': 5,
  'completed': 6
};
```

#### Data Flow
1. Poll Google Apps Script endpoint with `since` timestamp
2. Receive new/updated OT records
3. Transliterate ALL text fields to Kannada (except Age)
4. Merge with existing data (using Sl as key)
5. Filter out records without Patient Name
6. Sort by status priority
7. Serve via `/data` endpoint

### 4. OT Submission Service (`prod/OT-submission`)

**Type**: Static HTML form  
**Purpose**: Data entry interface for OT staff

This is a standalone HTML page for submitting OT data. It doesn't require a server and can be opened directly in a browser.

### 5. Release Service (`prod/Release`)

**Type**: Flutter desktop application  
**Purpose**: Service management dashboard

A Windows desktop application for managing all display services:
- Start/stop services
- Monitor service status
- View service logs
- Configure service settings

---

## Setup and Installation

### Prerequisites

1. **Node.js** (v14 or higher)
   ```bash
   node --version  # Should be v14+
   ```

2. **npm** (comes with Node.js)
   ```bash
   npm --version
   ```

3. **Git** (for cloning repository)
   ```bash
   git --version
   ```

### Installation Steps

#### 1. Clone the Repository
```bash
git clone https://github.com/gaureshpai/udal-wenlock.git
cd udal-wenlock
```

#### 2. Install Dependencies for Each Service

**Blood Bank Service**
```bash
cd prod/blood-bank
npm install
```

**Pharmacy Service**
```bash
cd prod/pharmacy
npm install
```

**OT Service**
```bash
cd prod/OT
npm install
```

#### 3. Configure Environment Variables

Create `.env` files if needed (currently using hardcoded values):

**Blood Bank** (`prod/blood-bank/.env`)
```env
PORT=3001
SECRET_KEY=your_secret_key_here
BASE_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

**Pharmacy** (`prod/pharmacy/.env`)
```env
PORT=3000
SHEET_ID=your_google_sheet_id
GID=0
```

**OT** (`prod/OT/.env`)
```env
PORT=3002
SECRET_KEY=your_secret_key_here
BASE_URL=https://script.google.com/macros/s/YOUR_SCRIPT_ID/exec
```

#### 4. Test Each Service

**Blood Bank**
```bash
cd prod/blood-bank
npm start
# Visit http://localhost:3001
```

**Pharmacy**
```bash
cd prod/pharmacy
npm start
# Visit http://localhost:3000
```

**OT**
```bash
cd prod/OT
npm start
# Visit http://localhost:3002
```

---

## Development Workflow

### Project Structure

```
udal-wenlock/
├── prod/
│   ├── blood-bank/
│   │   ├── server.js           # Main server
│   │   ├── package.json        # Dependencies
│   │   ├── service.vbs         # Windows service script
│   │   └── public/
│   │       ├── display.html    # Requests display
│   │       ├── inventory.html  # Inventory display
│   │       └── *.css, *.js     # Frontend assets
│   ├── pharmacy/
│   │   ├── server.js           # Main server
│   │   ├── package.json        # Dependencies
│   │   ├── service.vbs         # Windows service script
│   │   ├── data/
│   │   │   └── medicines.csv   # Local cache
│   │   └── public/
│   │       ├── display.html    # Medicine display
│   │       └── *.css, *.js     # Frontend assets
│   ├── OT/
│   │   ├── server.js           # Main server
│   │   ├── package.json        # Dependencies
│   │   ├── service.vbs         # Windows service script
│   │   └── public/
│   │       ├── display.html    # OT status display
│   │       └── *.css, *.js     # Frontend assets
│   ├── OT-submission/
│   │   └── index.html          # OT data entry form
│   └── Release/
│       ├── wenlock_display_server.exe  # Service manager
│       └── services.json       # Service configuration
├── docs/                       # Documentation
├── unused/                     # Archived code
└── README.md                   # Main readme
```

### Making Changes

#### 1. Backend Changes (server.js)

**Example: Change update frequency**
```javascript
// In server.js
// Change from 30 seconds to 60 seconds
setInterval(pollUpdates, 60000);  // Was 30000
```

**Example: Add new API endpoint**
```javascript
app.get("/api/stats", (req, res) => {
  const stats = {
    totalRecords: bloodData.length,
    emergencyCount: bloodData.filter(d => d.Status === 'Emergency').length
  };
  res.json(stats);
});
```

#### 2. Frontend Changes (HTML/CSS/JS)

**Example: Change display styling**
```css
/* In public/style.css */
.medicine-item {
  font-size: 24px;  /* Increase font size */
  padding: 20px;    /* Add more padding */
}
```

**Example: Modify display logic**
```javascript
// In public/display.js
async function fetchData() {
  const response = await fetch('/data');
  const data = await response.json();
  // Add filtering or processing
  const filtered = data.filter(item => item.someCondition);
  renderData(filtered);
}
```

#### 3. Testing Changes

**Local Testing**
```bash
# Start the service
npm start

# In another terminal, test the API
curl http://localhost:3000/medicines

# Or visit in browser
# http://localhost:3000/display.html
```

**Check Logs**
```bash
# View console output for errors
# Logs show:
# - Data fetch status
# - Translation progress
# - Error messages
```

### Common Development Tasks

#### Add New Field to Display

1. **Update Google Sheet** - Add new column
2. **Backend** - Field is automatically fetched
3. **Translation** - Add to transliteration if needed
4. **Frontend** - Update display.html to show new field

#### Change Data Source

1. **Update URL** in server.js
2. **Update column mappings** if structure changed
3. **Test data parsing**
4. **Verify display**

#### Add New Service

1. **Copy existing service** folder
2. **Update port number** in server.js
3. **Update data source** URLs
4. **Modify display** logic as needed
5. **Add to Release** service manager

---

## API Documentation

### Blood Bank Service (Port 3001)

#### GET `/data`
Returns filtered blood requests (excludes "Sample Received" status)

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
    "FFP": "",
    "Status": "Emergency",
    "Timestamp": "2024-12-01T10:30:00Z"
  }
]
```

**Status Codes**:
- `200 OK` - Success
- `500 Internal Server Error` - Server error

### Pharmacy Service (Port 3000)

#### GET `/medicines`
Returns all medicines with availability status

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

#### GET `/medicines/available`
Returns only available medicines with pagination

**Query Parameters**:
- `page` (optional, default: 1) - Page number
- `limit` (optional, default: 100, max: 200) - Items per page

**Response**:
```json
{
  "page": 1,
  "totalPages": 5,
  "count": 100,
  "total": 450,
  "data": [
    {
      "name": "Paracetamol",
      "kn_name": "ಪ್ಯಾರಸಿಟಮಾಲ್"
    }
  ]
}
```

**Status Codes**:
- `200 OK` - Success
- `500 Internal Server Error` - Server error

### OT Service (Port 3002)

#### GET `/data`
Returns all OT records sorted by priority

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

**Status Codes**:
- `200 OK` - Success
- `500 Internal Server Error` - Server error

---

## Deployment

### Production Deployment with PM2

#### 1. Install PM2
```bash
npm install -g pm2
```

#### 2. Create PM2 Ecosystem File

Create `ecosystem.config.js` in the root:

```javascript
module.exports = {
  apps: [
    {
      name: 'blood-bank',
      cwd: './prod/blood-bank',
      script: 'server.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3001
      }
    },
    {
      name: 'pharmacy',
      cwd: './prod/pharmacy',
      script: 'server.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3000
      }
    },
    {
      name: 'ot',
      cwd: './prod/OT',
      script: 'server.js',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '500M',
      env: {
        NODE_ENV: 'production',
        PORT: 3002
      }
    }
  ]
};
```

#### 3. Start All Services
```bash
pm2 start ecosystem.config.js
```

#### 4. Manage Services
```bash
# View status
pm2 status

# View logs
pm2 logs

# Restart a service
pm2 restart blood-bank

# Stop a service
pm2 stop pharmacy

# Restart all
pm2 restart all

# Save configuration
pm2 save

# Setup startup script
pm2 startup
```

### Windows Deployment (VBS Scripts)

Each service includes a `service.vbs` file for running as a background process on Windows.

**To start a service**:
1. Double-click `service.vbs` in the service folder
2. Or run: `wscript service.vbs`

**To stop a service**:
1. Open Task Manager
2. Find `node.exe` process
3. End the process

### Docker Deployment (Optional)

Create `Dockerfile` for each service:

```dockerfile
FROM node:14-alpine

WORKDIR /app

COPY package*.json ./
RUN npm install --production

COPY . .

EXPOSE 3000

CMD ["node", "server.js"]
```

Create `docker-compose.yml`:

```yaml
version: '3.8'

services:
  blood-bank:
    build: ./prod/blood-bank
    ports:
      - "3001:3001"
    restart: always

  pharmacy:
    build: ./prod/pharmacy
    ports:
      - "3000:3000"
    volumes:
      - ./prod/pharmacy/data:/app/data
    restart: always

  ot:
    build: ./prod/OT
    ports:
      - "3002:3002"
    restart: always
```

**Deploy with Docker**:
```bash
docker-compose up -d
```

### Nginx Reverse Proxy (Optional)

```nginx
server {
    listen 80;
    server_name hospital-display.local;

    location /blood-bank/ {
        proxy_pass http://localhost:3001/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /pharmacy/ {
        proxy_pass http://localhost:3000/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    location /ot/ {
        proxy_pass http://localhost:3002/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

---

## Troubleshooting

### Common Issues

#### 1. Service Won't Start

**Error**: `EADDRINUSE: address already in use`

**Solution**:
```bash
# Find process using the port
netstat -ano | findstr :3000

# Kill the process (Windows)
taskkill /PID <process_id> /F

# Kill the process (Linux/Mac)
kill -9 <process_id>
```

#### 2. Google Sheets Not Accessible

**Error**: `Failed to fetch sheet: 403 Forbidden`

**Solution**:
- Ensure Google Sheet is publicly accessible
- Check sharing settings: "Anyone with the link can view"
- Verify SHEET_ID is correct

#### 3. Transliteration Not Working

**Error**: `Transliteration error: fetch failed`

**Solution**:
- Check internet connection
- Verify transliteration API is accessible
- Add retry logic or fallback to original text

#### 4. CSV File Not Updating (Pharmacy)

**Issue**: Changes in Google Sheet not reflected

**Solution**:
```bash
# Check logs for sync errors
pm2 logs pharmacy

# Manually delete CSV cache
rm prod/pharmacy/data/medicines.csv

# Restart service
pm2 restart pharmacy
```

#### 5. Display Shows Blank Page

**Issue**: Frontend not loading

**Solution**:
- Check browser console for errors (F12)
- Verify API endpoint is accessible
- Check CORS settings if accessing from different domain
- Ensure static files are being served correctly

### Debugging Tips

#### Enable Verbose Logging

Add to server.js:
```javascript
// Log all requests
app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
  next();
});
```

#### Test API Endpoints

```bash
# Test blood bank
curl http://localhost:3001/data

# Test pharmacy
curl http://localhost:3000/medicines

# Test OT
curl http://localhost:3002/data
```

#### Monitor Memory Usage

```bash
# With PM2
pm2 monit

# Or check process
ps aux | grep node
```

#### Check Network Connectivity

```bash
# Test Google Sheets access
curl "https://docs.google.com/spreadsheets/d/SHEET_ID/gviz/tq?tqx=out:csv"

# Test transliteration API
curl "https://transliteration.devnagri.com/api/tl/kn/test"
```

---

## Performance Optimization

### 1. Caching Strategies

**In-Memory Cache**:
```javascript
let cache = {
  data: [],
  lastUpdated: null,
  ttl: 30000  // 30 seconds
};

function getCachedData() {
  if (Date.now() - cache.lastUpdated < cache.ttl) {
    return cache.data;
  }
  return null;
}
```

**File-Based Cache** (Pharmacy already implements this):
```javascript
// Write to CSV for offline access
fs.writeFileSync(CSV_FILE_PATH, csvData);
```

### 2. Reduce Transliteration Calls

**Preserve existing translations**:
```javascript
// Only transliterate new items
if (!existingTranslation) {
  kn_name = await getKannadaTransliteration(name);
}
```

### 3. Optimize Frontend

**Lazy loading**:
```javascript
// Load data in chunks
const CHUNK_SIZE = 50;
let currentIndex = 0;

function loadNextChunk() {
  const chunk = allData.slice(currentIndex, currentIndex + CHUNK_SIZE);
  renderChunk(chunk);
  currentIndex += CHUNK_SIZE;
}
```

**Debounce updates**:
```javascript
let updateTimeout;
function scheduleUpdate() {
  clearTimeout(updateTimeout);
  updateTimeout = setTimeout(fetchData, 1000);
}
```

---

## Security Considerations

### 1. API Authentication

Currently using a SECRET_KEY. Consider implementing:

```javascript
// JWT-based authentication
const jwt = require('jsonwebtoken');

function authenticateToken(req, res, next) {
  const token = req.headers['authorization'];
  if (!token) return res.sendStatus(401);
  
  jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
}

app.get('/data', authenticateToken, (req, res) => {
  // Protected route
});
```

### 2. Input Validation

```javascript
// Validate and sanitize input
const { body, validationResult } = require('express-validator');

app.post('/api/update', [
  body('name').trim().escape(),
  body('status').isIn(['Emergency', 'Normal'])
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }
  // Process request
});
```

### 3. Rate Limiting

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

### 4. HTTPS

For production, use HTTPS:

```javascript
const https = require('https');
const fs = require('fs');

const options = {
  key: fs.readFileSync('private-key.pem'),
  cert: fs.readFileSync('certificate.pem')
};

https.createServer(options, app).listen(443);
```

---

## Contributing

### Code Style

- Use 2 spaces for indentation
- Use semicolons
- Use async/await instead of callbacks
- Add comments for complex logic
- Follow existing naming conventions

### Pull Request Process

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit pull request with description

### Testing Checklist

- [ ] Service starts without errors
- [ ] API endpoints return correct data
- [ ] Frontend displays data correctly
- [ ] Kannada translation works
- [ ] Offline mode works (Pharmacy)
- [ ] Error handling works
- [ ] No console errors

---

## Additional Resources

### External APIs

**Devnagri Transliteration API**:
- URL: `https://transliteration.devnagri.com/api/tl/kn/{word}`
- No authentication required
- Returns JSON with transliterated text

### Google Sheets Integration

**CSV Export URL Format**:
```
https://docs.google.com/spreadsheets/d/{SHEET_ID}/gviz/tq?tqx=out:csv&gid={GID}
```

**Google Apps Script**:
- Create script in Tools > Script Editor
- Deploy as Web App
- Set permissions to "Anyone, even anonymous"

### Useful Libraries

- **Express**: Web framework
- **PapaParse**: CSV parsing
- **node-fetch**: HTTP requests
- **node-cron**: Scheduled tasks
- **PM2**: Process management

---

*Last Updated: December 2025*
*Version: 1.0*
