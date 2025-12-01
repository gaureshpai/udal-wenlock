# UDAL Wenlock Hospital Display System - User Guide

## Table of Contents
1. [Introduction](#introduction)
2. [Blood Bank Display](#blood-bank-display)
3. [Pharmacy Medicine Availability](#pharmacy-medicine-availability)
4. [Operation Theatre (OT) Display](#operation-theatre-ot-display)
5. [Managing Data with Google Sheets](#managing-data-with-google-sheets)
6. [Troubleshooting](#troubleshooting)

---

## Introduction

The UDAL Wenlock Hospital Display System is a collection of digital displays designed to provide real-time information to patients and visitors. Each service displays information from Google Sheets, making it easy for hospital staff to update information without technical knowledge.

### Key Features
- **Real-time Updates**: Information is automatically fetched from Google Sheets
- **Bilingual Support**: Displays show information in both English and Kannada
- **Offline Capability**: Some services continue working even without internet
- **Easy to Update**: Just edit a Google Sheet - no technical skills required

---

## Blood Bank Display

### What It Shows
The Blood Bank Display has two screens:

#### 1. Blood Requests Screen
Shows urgent blood requirements for patients, including:
- Patient name (in English and Kannada)
- Blood group needed
- Blood components required (PRBC, FFP, Platelets, etc.)
- Request status (Emergency requests appear at the top)

#### 2. Inventory Screen
Displays current blood bank stock:
- Available units for each blood group (A+, B+, O+, AB+, etc.)
- Different blood components (FFP, Platelets, Cryoprecipitate, etc.)
- Rotates through different component types

### How to Update Blood Bank Data

1. **Open the Google Sheet** (link provided by IT department)
2. **Go to the "Blood Requests" tab**
3. **Add a new row** with the following information:
   - Serial Number (SN)
   - Patient Name
   - Blood Group
   - Components needed (mark with checkmarks or "yes")
   - Status (Normal or Emergency)
   - Timestamp (automatically added)

4. **Save the sheet** - Changes appear on the display within 30 seconds

> **Note**: Emergency requests automatically appear at the top of the display

### Accessing the Display
- **URL**: `http://[server-ip]:3001`
- **Requests Screen**: `http://[server-ip]:3001/display.html`
- **Inventory Screen**: `http://[server-ip]:3001/inventory.html`

---

## Pharmacy Medicine Availability

### What It Shows
A scrolling list of medicines currently available at the pharmacy, displayed in both English and Kannada.

### How to Update Pharmacy Data

1. **Open the Pharmacy Google Sheet** (link provided by IT department)
2. **Find the medicine** you want to update
3. **Mark availability**:
   - Put a checkmark (✓) or "TRUE" if available
   - Leave empty or put "FALSE" if not available
4. **Save the sheet** - Changes appear within 1 minute

### Adding New Medicines

1. Add a new row in the Google Sheet
2. Enter the medicine name in the "Medicine Name" column
3. Mark availability in the "Available" column
4. The Kannada translation is generated automatically

### Accessing the Display
- **URL**: `http://[server-ip]:3000`
- **Display Screen**: `http://[server-ip]:3000/display.html`

> **Offline Mode**: If internet is lost, the display continues showing the last known data

---

## Operation Theatre (OT) Display

### What It Shows
Real-time status of all operation theatres, including:
- Patient name (English and Kannada)
- Surgery type and site
- Surgeon name
- Department
- Current status (In Progress, Scheduled, Waiting, etc.)
- Time information

### Surgery Status Priority
The display automatically sorts surgeries by priority:
1. **In Progress** - Currently ongoing
2. **Scheduled** - Confirmed for today
3. **Waiting at Pre-op** - Patient ready
4. **Waiting** - Patient waiting
5. **Post-op** - Surgery completed
6. **Completed** - Fully finished

### How to Update OT Data

1. **Open the OT Google Sheet**
2. **Go to the "OT" tab**
3. **Add or update surgery information**:
   - Serial Number (Sl)
   - Patient Name
   - Age
   - Surgery Site
   - Surgery Type
   - Surgeon Name
   - Department
   - Status
   - Time

4. **Save the sheet** - Updates appear within 30 seconds

### Accessing the Display
- **URL**: `http://[server-ip]:3002`
- **Display Screen**: `http://[server-ip]:3002/display.html`

---

## Managing Data with Google Sheets

### Best Practices

#### 1. **Don't Delete Columns**
- The system expects specific column names
- Deleting columns will break the display

#### 2. **Use Consistent Formatting**
- For availability: Use ✓, TRUE, or YES
- For dates: Use consistent date format
- For status: Use exact status names (Emergency, Normal, etc.)

#### 3. **Keep Data Clean**
- Remove old/completed entries regularly
- Don't leave empty rows in the middle of data
- Use the same spelling for repeated items

#### 4. **Test Your Changes**
- After updating, check the display to ensure it looks correct
- If something looks wrong, undo your changes and try again

### Common Column Names

#### Blood Bank Sheet
- `SN` - Serial Number
- `Name` - Patient Name
- `Blood Group` - A+, B+, O+, etc.
- `PRBC`, `FFP`, `Platlet Concentrate`, etc. - Blood components
- `Status` - Emergency or Normal
- `Timestamp` - When the request was made

#### Pharmacy Sheet
- `Medicine Name` or `Name` - Medicine name
- `Available` or `Availability` - Checkmark or TRUE/FALSE

#### OT Sheet
- `Sl` - Serial Number
- `Patient Name` - Patient's name
- `Age` - Patient's age
- `Surgery site` - Where surgery is performed
- `Surgery` - Type of surgery
- `Surgeon Name` - Operating surgeon
- `Department` - Hospital department
- `Status` - Current status
- `Time` - Surgery time

---

## Troubleshooting

### Display Not Updating

**Problem**: Changes in Google Sheet don't appear on display

**Solutions**:
1. Wait 30-60 seconds - updates aren't instant
2. Refresh the browser page (press F5)
3. Check if the Google Sheet is shared properly
4. Contact IT support if problem persists

### Kannada Text Not Showing

**Problem**: Only English text appears, no Kannada

**Solutions**:
1. Wait a few minutes - translation takes time for new entries
2. Check internet connection
3. Refresh the browser page
4. Contact IT support if problem persists

### Display Shows Old Data

**Problem**: Display shows outdated information

**Solutions**:
1. Check if you saved the Google Sheet
2. Refresh the browser (F5)
3. Check internet connection
4. Restart the display service (contact IT support)

### Display Not Loading

**Problem**: Browser shows error or blank page

**Solutions**:
1. Check if the computer/device is on
2. Check internet connection
3. Try accessing the URL again
4. Contact IT support to restart the service

### Emergency Requests Not at Top

**Problem**: Emergency blood requests not showing first

**Solutions**:
1. Make sure Status column says exactly "Emergency"
2. Wait 30 seconds for update
3. Refresh the page
4. Check spelling of "Emergency" in the sheet

---

## Getting Help

### For Technical Issues
- Contact IT Department
- Email: [IT support email]
- Phone: [IT support phone]

### For Content Issues
- Contact respective department heads
- Blood Bank: [contact info]
- Pharmacy: [contact info]
- OT: [contact info]

---

## Quick Reference Card

### Update Frequency
- **Blood Bank**: Every 30 seconds
- **Pharmacy**: Every 60 seconds
- **OT**: Every 30 seconds

### Display URLs
- **Blood Bank**: Port 3001
- **Pharmacy**: Port 3000
- **OT**: Port 3002

### Common Actions
- **Add new entry**: Add new row in Google Sheet
- **Update existing**: Edit the row in Google Sheet
- **Remove entry**: Delete the row in Google Sheet
- **Mark as available**: Put ✓ or TRUE
- **Mark as unavailable**: Leave empty or put FALSE

---

*Last Updated: December 2025*
*Version: 1.0*
