# OT Submission Service Documentation

## Overview

The OT Submission Service is a standalone HTML form interface for OT staff to submit surgery information directly. It's a simple, user-friendly data entry form that doesn't require a backend server.

## Service Information

- **Type**: Static HTML page
- **Technology**: HTML, CSS, JavaScript
- **Server**: Not required (can run locally)
- **Purpose**: Data entry interface for OT staff

## Features

### Core Features
- Simple form interface
- No server required
- Can run offline
- Direct submission to Google Sheets (via Google Forms or Apps Script)
- Client-side validation
- Responsive design

## File Structure

```
OT-submission/
├── index.html          # Main form page
└── .vscode/
    └── settings.json   # VS Code settings
```

## Usage

### Opening the Form

**Method 1: Direct File Access**
1. Navigate to `prod/OT-submission/`
2. Double-click `index.html`
3. Opens in default browser

**Method 2: Local Server** (optional)
```bash
cd prod/OT-submission
python -m http.server 8000
# Visit http://localhost:8000
```

**Method 3: VS Code Live Server**
1. Open folder in VS Code
2. Right-click `index.html`
3. Select "Open with Live Server"

### Filling the Form

The form typically includes fields for:
- Patient Name
- Age
- Surgery Site
- Surgery Type
- Surgeon Name
- Department
- Status
- Time

### Submitting Data

The form can submit data via:

**Option 1: Google Forms Integration**
```html
<form action="https://docs.google.com/forms/d/e/FORM_ID/formResponse" method="POST">
  <input name="entry.123456" placeholder="Patient Name">
  <input name="entry.789012" placeholder="Age">
  <!-- More fields -->
  <button type="submit">Submit</button>
</form>
```

**Option 2: Google Apps Script**
```javascript
async function submitForm(formData) {
  const response = await fetch('YOUR_APPS_SCRIPT_URL', {
    method: 'POST',
    body: JSON.stringify(formData),
    headers: {
      'Content-Type': 'application/json'
    }
  });
  
  if (response.ok) {
    alert('Submitted successfully!');
    form.reset();
  }
}
```

## Customization

### Adding Fields

```html
<!-- Add new field to form -->
<div class="form-group">
  <label for="bloodGroup">Blood Group</label>
  <select id="bloodGroup" name="bloodGroup">
    <option value="">Select...</option>
    <option value="A+">A+</option>
    <option value="B+">B+</option>
    <option value="O+">O+</option>
    <option value="AB+">AB+</option>
  </select>
</div>
```

### Adding Validation

```javascript
function validateForm() {
  const patientName = document.getElementById('patientName').value;
  const age = document.getElementById('age').value;
  
  if (!patientName) {
    alert('Patient name is required');
    return false;
  }
  
  if (age < 0 || age > 150) {
    alert('Please enter a valid age');
    return false;
  }
  
  return true;
}

// Attach to form
document.getElementById('otForm').addEventListener('submit', function(e) {
  if (!validateForm()) {
    e.preventDefault();
  }
});
```

### Styling

```css
/* Custom styles */
.form-group {
  margin-bottom: 20px;
}

label {
  display: block;
  font-weight: bold;
  margin-bottom: 5px;
}

input, select, textarea {
  width: 100%;
  padding: 10px;
  border: 1px solid #ddd;
  border-radius: 4px;
}

button {
  background-color: #4CAF50;
  color: white;
  padding: 12px 24px;
  border: none;
  border-radius: 4px;
  cursor: pointer;
}

button:hover {
  background-color: #45a049;
}
```

## Integration with Google Sheets

### Method 1: Google Forms

1. **Create Google Form** with matching fields
2. **Get form URL** from "Send" button
3. **Inspect form** to get entry IDs:
   ```html
   <!-- Right-click form fields and inspect -->
   <input name="entry.123456789" ...>
   ```
4. **Update HTML form**:
   ```html
   <form action="https://docs.google.com/forms/d/e/FORM_ID/formResponse" 
         method="POST" target="hidden_iframe">
     <input name="entry.123456789" placeholder="Patient Name">
     <button type="submit">Submit</button>
   </form>
   <iframe name="hidden_iframe" style="display:none;"></iframe>
   ```

### Method 2: Apps Script Web App

**Apps Script Code**:
```javascript
function doPost(e) {
  try {
    const data = JSON.parse(e.postData.contents);
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName('OT');
    
    sheet.appendRow([
      new Date(),
      data.patientName,
      data.age,
      data.surgerySite,
      data.surgery,
      data.surgeonName,
      data.department,
      data.status,
      data.time
    ]);
    
    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      message: 'Data submitted successfully'
    })).setMimeType(ContentService.MimeType.JSON);
    
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      message: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}
```

**HTML Form JavaScript**:
```javascript
document.getElementById('otForm').addEventListener('submit', async function(e) {
  e.preventDefault();
  
  const formData = {
    patientName: document.getElementById('patientName').value,
    age: document.getElementById('age').value,
    surgerySite: document.getElementById('surgerySite').value,
    surgery: document.getElementById('surgery').value,
    surgeonName: document.getElementById('surgeonName').value,
    department: document.getElementById('department').value,
    status: document.getElementById('status').value,
    time: document.getElementById('time').value
  };
  
  try {
    const response = await fetch('YOUR_APPS_SCRIPT_URL', {
      method: 'POST',
      body: JSON.stringify(formData)
    });
    
    const result = await response.json();
    
    if (result.success) {
      alert('Surgery information submitted successfully!');
      this.reset();
    } else {
      alert('Error: ' + result.message);
    }
  } catch (error) {
    alert('Submission failed: ' + error.message);
  }
});
```

## Advanced Features

### Auto-fill Current Time

```javascript
// Set current time on page load
window.addEventListener('load', function() {
  const now = new Date();
  const hours = String(now.getHours()).padStart(2, '0');
  const minutes = String(now.getMinutes()).padStart(2, '0');
  document.getElementById('time').value = `${hours}:${minutes}`;
});
```

### Department Dropdown

```html
<select id="department" name="department" required>
  <option value="">Select Department</option>
  <option value="General Surgery">General Surgery</option>
  <option value="Orthopedics">Orthopedics</option>
  <option value="Neurosurgery">Neurosurgery</option>
  <option value="Cardiothoracic">Cardiothoracic</option>
  <option value="Gynecology">Gynecology</option>
  <option value="ENT">ENT</option>
  <option value="Ophthalmology">Ophthalmology</option>
</select>
```

### Status Dropdown

```html
<select id="status" name="status" required>
  <option value="">Select Status</option>
  <option value="Scheduled">Scheduled</option>
  <option value="Waiting">Waiting</option>
  <option value="Waiting at Pre-op">Waiting at Pre-op</option>
  <option value="In Progress">In Progress</option>
  <option value="Post-op">Post-op</option>
  <option value="Completed">Completed</option>
</select>
```

### Form Persistence (Local Storage)

```javascript
// Save form data to local storage
function saveFormData() {
  const formData = {
    patientName: document.getElementById('patientName').value,
    age: document.getElementById('age').value,
    // ... other fields
  };
  localStorage.setItem('otFormDraft', JSON.stringify(formData));
}

// Load form data from local storage
function loadFormData() {
  const saved = localStorage.getItem('otFormDraft');
  if (saved) {
    const formData = JSON.parse(saved);
    document.getElementById('patientName').value = formData.patientName || '';
    document.getElementById('age').value = formData.age || '';
    // ... other fields
  }
}

// Auto-save on input
document.querySelectorAll('input, select, textarea').forEach(field => {
  field.addEventListener('input', saveFormData);
});

// Load on page load
window.addEventListener('load', loadFormData);

// Clear on successful submit
function clearDraft() {
  localStorage.removeItem('otFormDraft');
}
```

## Deployment

### Option 1: File Share
1. Copy `index.html` to shared network drive
2. Staff can open directly from network location

### Option 2: Web Server
```bash
# Using Node.js http-server
npm install -g http-server
cd prod/OT-submission
http-server -p 8080
```

### Option 3: GitHub Pages
1. Push to GitHub repository
2. Enable GitHub Pages in repository settings
3. Access via `https://username.github.io/repo-name/`

### Option 4: Internal Web Server
- Host on hospital intranet
- Configure IIS or Apache to serve the HTML file

## Security Considerations

### Data Privacy
- Form submits directly to Google Sheets
- No data stored locally (except draft in localStorage)
- Use HTTPS for production

### Access Control
- Restrict form access to authorized staff only
- Use authentication if needed
- Consider IP whitelisting

### Input Sanitization
```javascript
function sanitizeInput(input) {
  const div = document.createElement('div');
  div.textContent = input;
  return div.innerHTML;
}

// Use before submission
const sanitizedName = sanitizeInput(document.getElementById('patientName').value);
```

## Troubleshooting

### Form Not Submitting

**Issue**: Form submission fails

**Solutions**:
- Check Apps Script URL is correct
- Verify Apps Script is deployed as web app
- Check Apps Script permissions
- Look for CORS errors in browser console

### Data Not Appearing in Sheet

**Issue**: Submission succeeds but no data in sheet

**Solutions**:
- Verify sheet name matches Apps Script
- Check column order matches
- Review Apps Script logs
- Ensure sheet is not protected

### Browser Compatibility

**Issue**: Form doesn't work in certain browsers

**Solutions**:
- Use modern JavaScript features with polyfills
- Test in multiple browsers
- Provide fallback for older browsers

## Best Practices

1. **Required Fields**: Mark essential fields as required
2. **Validation**: Validate data before submission
3. **Feedback**: Show success/error messages
4. **Clear Form**: Reset form after successful submission
5. **Accessibility**: Use proper labels and ARIA attributes
6. **Mobile Friendly**: Ensure responsive design
7. **Error Handling**: Handle network errors gracefully

## Sample Complete Form

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>OT Submission Form</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 600px;
      margin: 50px auto;
      padding: 20px;
    }
    .form-group {
      margin-bottom: 15px;
    }
    label {
      display: block;
      margin-bottom: 5px;
      font-weight: bold;
    }
    input, select, textarea {
      width: 100%;
      padding: 8px;
      border: 1px solid #ddd;
      border-radius: 4px;
      box-sizing: border-box;
    }
    button {
      background-color: #4CAF50;
      color: white;
      padding: 10px 20px;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 16px;
    }
    button:hover {
      background-color: #45a049;
    }
  </style>
</head>
<body>
  <h1>OT Surgery Submission</h1>
  <form id="otForm">
    <div class="form-group">
      <label for="patientName">Patient Name *</label>
      <input type="text" id="patientName" required>
    </div>
    
    <div class="form-group">
      <label for="age">Age *</label>
      <input type="number" id="age" min="0" max="150" required>
    </div>
    
    <div class="form-group">
      <label for="surgerySite">Surgery Site *</label>
      <input type="text" id="surgerySite" required>
    </div>
    
    <div class="form-group">
      <label for="surgery">Surgery Type *</label>
      <input type="text" id="surgery" required>
    </div>
    
    <div class="form-group">
      <label for="surgeonName">Surgeon Name *</label>
      <input type="text" id="surgeonName" required>
    </div>
    
    <div class="form-group">
      <label for="department">Department *</label>
      <select id="department" required>
        <option value="">Select...</option>
        <option value="General Surgery">General Surgery</option>
        <option value="Orthopedics">Orthopedics</option>
        <option value="Neurosurgery">Neurosurgery</option>
      </select>
    </div>
    
    <div class="form-group">
      <label for="status">Status *</label>
      <select id="status" required>
        <option value="">Select...</option>
        <option value="Scheduled">Scheduled</option>
        <option value="In Progress">In Progress</option>
        <option value="Completed">Completed</option>
      </select>
    </div>
    
    <div class="form-group">
      <label for="time">Time *</label>
      <input type="time" id="time" required>
    </div>
    
    <button type="submit">Submit</button>
  </form>
  
  <script>
    document.getElementById('otForm').addEventListener('submit', async function(e) {
      e.preventDefault();
      
      const formData = {
        patientName: document.getElementById('patientName').value,
        age: document.getElementById('age').value,
        surgerySite: document.getElementById('surgerySite').value,
        surgery: document.getElementById('surgery').value,
        surgeonName: document.getElementById('surgeonName').value,
        department: document.getElementById('department').value,
        status: document.getElementById('status').value,
        time: document.getElementById('time').value
      };
      
      try {
        const response = await fetch('YOUR_APPS_SCRIPT_URL', {
          method: 'POST',
          body: JSON.stringify(formData)
        });
        
        const result = await response.json();
        
        if (result.success) {
          alert('Submitted successfully!');
          this.reset();
        } else {
          alert('Error: ' + result.message);
        }
      } catch (error) {
        alert('Submission failed: ' + error.message);
      }
    });
  </script>
</body>
</html>
```

## Support

For issues or questions:
- Check browser console for errors (F12)
- Verify Google Apps Script is accessible
- Test form submission manually
- Contact IT department

---

*Last Updated: December 2025*
*Version: 1.0*
