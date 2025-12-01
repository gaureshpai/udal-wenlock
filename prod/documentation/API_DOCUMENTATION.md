# UDAL Wenlock Hospital Display System - API Documentation

## Overview

This document provides comprehensive API documentation for all services in the UDAL Wenlock Hospital Display System.

## Base URLs

- **Blood Bank Service**: `http://localhost:3001`
- **Pharmacy Service**: `http://localhost:3000`
- **OT Service**: `http://localhost:3002`

> Replace `localhost` with your server IP address for remote access.

---

## Blood Bank Service API

### Base URL
```
http://localhost:3001
```

### Endpoints

#### GET `/`
Redirects to the main blood requests display page.

**Response**: HTTP 302 Redirect to `/display.html`

---

#### GET `/data`
Returns filtered blood requests (excludes "Sample Received" status).

**Request**:
```bash
curl http://localhost:3001/data
```

**Response**: `200 OK`
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
    "kn_FFP": "",
    "Platlet Concentrate": "1 unit",
    "kn_Platlet Concentrate": "1 ಯುನಿಟ್",
    "Cryoprecipitate": "",
    "kn_Cryoprecipitate": "",
    "Cryopoor Plasma": "",
    "kn_Cryopoor Plasma": "",
    "Status": "Emergency",
    "Timestamp": "2024-12-01T10:30:00Z"
  }
]
```

**Response Fields**:
- `SN` (number): Serial number (unique identifier)
- `Name` (string): Patient name in English
- `kn_name` (string): Patient name in Kannada
- `Blood Group` (string): Blood group (A+, B+, O+, AB+, A-, B-, O-, AB-)
- `PRBC` (string): Packed Red Blood Cells requirement
- `kn_PRBC` (string): PRBC in Kannada
- `FFP` (string): Fresh Frozen Plasma requirement
- `kn_FFP` (string): FFP in Kannada
- `Platlet Concentrate` (string): Platelet requirement
- `kn_Platlet Concentrate` (string): Platelets in Kannada
- `Cryoprecipitate` (string): Cryoprecipitate requirement
- `kn_Cryoprecipitate` (string): Cryo in Kannada
- `Cryopoor Plasma` (string): Cryopoor plasma requirement
- `kn_Cryopoor Plasma` (string): Cryopoor in Kannada
- `Status` (string): "Emergency" or "Normal"
- `Timestamp` (string): ISO 8601 timestamp

**Sorting**: Emergency requests appear first, followed by normal requests.

**Status Codes**:
- `200 OK`: Success
- `500 Internal Server Error`: Server error

---

## Pharmacy Service API

### Base URL
```
http://localhost:3000
```

### Endpoints

#### GET `/`
Redirects to the medicine availability display page.

**Response**: HTTP 302 Redirect to `/display.html`

---

#### GET `/medicines`
Returns all medicines with availability status.

**Request**:
```bash
curl http://localhost:3000/medicines
```

**Response**: `200 OK`
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
  },
  {
    "name": "Amoxicillin",
    "available": true,
    "kn_name": "ಅಮೋಕ್ಸಿಸಿಲಿನ್"
  }
]
```

**Response Fields**:
- `name` (string): Medicine name in English
- `available` (boolean): Availability status
- `kn_name` (string): Medicine name in Kannada

**Status Codes**:
- `200 OK`: Success
- `500 Internal Server Error`: Server error

---

#### GET `/medicines/available`
Returns only available medicines with pagination support.

**Query Parameters**:
- `page` (optional, default: 1): Page number (integer, min: 1)
- `limit` (optional, default: 100, max: 200): Items per page (integer)

**Request**:
```bash
curl "http://localhost:3000/medicines/available?page=1&limit=50"
```

**Response**: `200 OK`
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

**Response Fields**:
- `page` (number): Current page number
- `totalPages` (number): Total number of pages
- `count` (number): Number of items in current page
- `total` (number): Total number of available medicines
- `data` (array): Array of medicine objects
  - `name` (string): Medicine name in English
  - `kn_name` (string): Medicine name in Kannada

**Status Codes**:
- `200 OK`: Success
- `400 Bad Request`: Invalid query parameters
- `500 Internal Server Error`: Server error

**Examples**:
```bash
# Get first page with default limit (100)
curl http://localhost:3000/medicines/available

# Get page 2 with 25 items
curl "http://localhost:3000/medicines/available?page=2&limit=25"

# Get all available medicines (use high limit)
curl "http://localhost:3000/medicines/available?limit=200"
```

---

## OT Service API

### Base URL
```
http://localhost:3002
```

### Endpoints

#### GET `/`
Redirects to the OT status display page.

**Response**: HTTP 302 Redirect to `/display.html`

---

#### GET `/data`
Returns all OT records sorted by priority.

**Request**:
```bash
curl http://localhost:3002/data
```

**Response**: `200 OK`
```json
[
  {
    "Sl": 1,
    "Patient Name": "Jane Smith",
    "kn_Patient Name": "ಜೇನ್ ಸ್ಮಿತ್",
    "Age": "45",
    "kn_Age": "",
    "Surgery site": "Abdomen",
    "kn_Surgery site": "ಹೊಟ್ಟೆ",
    "Surgery": "Appendectomy",
    "kn_Surgery": "ಅಪೆಂಡೆಕ್ಟಮಿ",
    "Surgeon Name": "Dr. Kumar",
    "kn_Surgeon Name": "ಡಾ. ಕುಮಾರ್",
    "Department": "General Surgery",
    "kn_Department": "ಜನರಲ್ ಸರ್ಜರಿ",
    "Status": "In Progress",
    "kn_Status": "ಇನ್ ಪ್ರೋಗ್ರೆಸ್",
    "Time": "10:00 AM",
    "kn_Time": "10:00 AM"
  }
]
```

**Response Fields**:
- `Sl` (number): Serial number (unique identifier)
- `Patient Name` (string): Patient name in English
- `kn_Patient Name` (string): Patient name in Kannada
- `Age` (string): Patient age
- `kn_Age` (string): Empty (age not translated)
- `Surgery site` (string): Surgery location in English
- `kn_Surgery site` (string): Surgery location in Kannada
- `Surgery` (string): Surgery type in English
- `kn_Surgery` (string): Surgery type in Kannada
- `Surgeon Name` (string): Surgeon name in English
- `kn_Surgeon Name` (string): Surgeon name in Kannada
- `Department` (string): Department in English
- `kn_Department` (string): Department in Kannada
- `Status` (string): Current status
- `kn_Status` (string): Status in Kannada
- `Time` (string): Surgery time
- `kn_Time` (string): Time in Kannada

**Status Values** (in priority order):
1. "In Progress"
2. "Scheduled"
3. "Waiting at Pre-op"
4. "Waiting"
5. "Post-op"
6. "Completed"

**Filtering**: Records without Patient Name or Sl are excluded.

**Sorting**: Records are sorted by status priority (In Progress first).

**Status Codes**:
- `200 OK`: Success
- `500 Internal Server Error`: Server error

---

## Common Patterns

### Error Responses

All services return errors in this format:

```json
{
  "error": "Error message",
  "details": "Detailed error information"
}
```

**Common Error Status Codes**:
- `400 Bad Request`: Invalid request parameters
- `404 Not Found`: Endpoint not found
- `500 Internal Server Error`: Server-side error

### CORS Headers

All services support CORS for cross-origin requests:

```
Access-Control-Allow-Origin: *
Access-Control-Allow-Methods: GET, POST, OPTIONS
Access-Control-Allow-Headers: Content-Type
```

### Content Type

All API responses use JSON:

```
Content-Type: application/json
```

---

## Data Update Frequencies

- **Blood Bank**: Updates every 30 seconds
- **Pharmacy**: Updates every 60 seconds
- **OT**: Updates every 30 seconds

> Note: These are polling intervals. Actual data changes depend on Google Sheets updates.

---

## Authentication

Currently, the public-facing APIs do not require authentication. The backend services use a SECRET_KEY for Google Apps Script communication, but this is not exposed to API consumers.

**For production**, consider implementing:
- API keys
- JWT tokens
- Rate limiting
- IP whitelisting

---

## Rate Limiting

Currently, no rate limiting is implemented. For production deployment, consider:

```javascript
const rateLimit = require('express-rate-limit');

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});

app.use('/api/', limiter);
```

---

## WebSocket Support

Currently, the services use HTTP polling. For real-time updates, consider implementing WebSocket support:

```javascript
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8080 });

wss.on('connection', (ws) => {
  ws.on('message', (message) => {
    console.log('received: %s', message);
  });
  
  // Send updates when data changes
  ws.send(JSON.stringify(bloodData));
});
```

---

## Client Examples

### JavaScript (Fetch API)

```javascript
// Get blood bank data
async function getBloodRequests() {
  try {
    const response = await fetch('http://localhost:3001/data');
    const data = await response.json();
    console.log('Blood requests:', data);
    return data;
  } catch (error) {
    console.error('Error fetching blood requests:', error);
  }
}

// Get available medicines
async function getAvailableMedicines(page = 1, limit = 50) {
  try {
    const response = await fetch(
      `http://localhost:3000/medicines/available?page=${page}&limit=${limit}`
    );
    const data = await response.json();
    console.log('Available medicines:', data);
    return data;
  } catch (error) {
    console.error('Error fetching medicines:', error);
  }
}

// Get OT data
async function getOTData() {
  try {
    const response = await fetch('http://localhost:3002/data');
    const data = await response.json();
    console.log('OT data:', data);
    return data;
  } catch (error) {
    console.error('Error fetching OT data:', error);
  }
}
```

### Python (requests)

```python
import requests

# Get blood bank data
def get_blood_requests():
    try:
        response = requests.get('http://localhost:3001/data')
        response.raise_for_status()
        data = response.json()
        print('Blood requests:', data)
        return data
    except requests.exceptions.RequestException as e:
        print(f'Error fetching blood requests: {e}')

# Get available medicines
def get_available_medicines(page=1, limit=50):
    try:
        response = requests.get(
            f'http://localhost:3000/medicines/available',
            params={'page': page, 'limit': limit}
        )
        response.raise_for_status()
        data = response.json()
        print('Available medicines:', data)
        return data
    except requests.exceptions.RequestException as e:
        print(f'Error fetching medicines: {e}')

# Get OT data
def get_ot_data():
    try:
        response = requests.get('http://localhost:3002/data')
        response.raise_for_status()
        data = response.json()
        print('OT data:', data)
        return data
    except requests.exceptions.RequestException as e:
        print(f'Error fetching OT data: {e}')
```

### cURL

```bash
# Get blood bank data
curl http://localhost:3001/data

# Get all medicines
curl http://localhost:3000/medicines

# Get available medicines (page 2, 25 items)
curl "http://localhost:3000/medicines/available?page=2&limit=25"

# Get OT data
curl http://localhost:3002/data

# Pretty print JSON
curl http://localhost:3001/data | jq

# Save to file
curl http://localhost:3000/medicines > medicines.json
```

### PowerShell

```powershell
# Get blood bank data
$bloodData = Invoke-RestMethod -Uri "http://localhost:3001/data"
$bloodData | ConvertTo-Json

# Get available medicines
$medicines = Invoke-RestMethod -Uri "http://localhost:3000/medicines/available?page=1&limit=50"
$medicines | ConvertTo-Json

# Get OT data
$otData = Invoke-RestMethod -Uri "http://localhost:3002/data"
$otData | ConvertTo-Json
```

---

## Testing

### Manual Testing

Use browser or tools like:
- **Postman**: GUI for API testing
- **Insomnia**: REST client
- **Browser DevTools**: Network tab
- **cURL**: Command-line tool

### Automated Testing

```javascript
// Example with Jest
describe('Blood Bank API', () => {
  test('GET /data returns array', async () => {
    const response = await fetch('http://localhost:3001/data');
    const data = await response.json();
    expect(Array.isArray(data)).toBe(true);
  });
  
  test('Each record has required fields', async () => {
    const response = await fetch('http://localhost:3001/data');
    const data = await response.json();
    if (data.length > 0) {
      expect(data[0]).toHaveProperty('SN');
      expect(data[0]).toHaveProperty('Name');
      expect(data[0]).toHaveProperty('Blood Group');
    }
  });
});
```

---

## API Versioning

Currently, no versioning is implemented. For future versions, consider:

```
http://localhost:3001/v1/data
http://localhost:3001/v2/data
```

---

## Changelog

### Version 1.0 (Current)
- Initial API release
- Blood Bank, Pharmacy, and OT endpoints
- JSON responses
- Kannada transliteration support

---

## Support

For API issues or questions:
- Check service logs
- Review this documentation
- Test endpoints with cURL
- Contact IT department

---

*Last Updated: December 2025*
*Version: 1.0*
