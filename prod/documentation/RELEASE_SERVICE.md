# Release Service Documentation

## Overview

The Release Service is a Windows desktop application built with Flutter that provides a centralized management interface for all UDAL Wenlock Hospital display services.

## Service Information

- **Type**: Desktop Application (Windows)
- **Technology**: Flutter
- **Platform**: Windows
- **Purpose**: Service management dashboard
- **Executable**: `wenlock_display_server.exe`

## Features

### Core Features
- **Start/Stop Services**: Control all display services from one interface
- **Service Status Monitoring**: Real-time status of each service
- **Service Configuration**: View and edit service settings
- **Log Viewing**: Access service logs
- **Port Management**: Monitor which ports are in use
- **Auto-start Configuration**: Set services to start automatically

### Managed Services
The Release service manages:
1. Blood Bank Display (Port 3001)
2. Pharmacy Medicine Display (Port 3000)
3. Operation Theatre Display (Port 3002)

## File Structure

```
Release/
├── wenlock_display_server.exe    # Main application
├── flutter_windows.dll            # Flutter runtime
├── url_launcher_windows_plugin.dll # URL launcher plugin
├── services.json                  # Service configuration
└── data/                          # Application data
    ├── app_icon.png
    ├── flutter_assets/
    └── ... (other assets)
```

## Configuration File

### services.json

This file contains configuration for all managed services.

**Location**: `prod/Release/services.json`

**Structure**:
```json
{
  "services": [
    {
      "id": "blood_bank",
      "department": "Blood Bank",
      "vbs_path": "D:\\...\\blood-bank\\service.vbs",
      "project_dir": "D:\\...\\blood-bank",
      "csv_path": "D:\\...\\blood-bank\\public\\alerts.csv",
      "port": "3001",
      "status": "stopped"
    },
    {
      "id": "pharmacy",
      "department": "Pharmacy",
      "vbs_path": "D:\\...\\pharmacy\\service.vbs",
      "project_dir": "D:\\...\\pharmacy",
      "csv_path": null,
      "port": "3000",
      "status": "stopped"
    },
    {
      "id": "operation_theatre_-_ot",
      "department": "Operation Theatre - OT",
      "vbs_path": "D:\\...\\OT\\service.vbs",
      "project_dir": "D:\\...\\OT",
      "csv_path": null,
      "port": "3002",
      "status": "stopped"
    }
  ]
}
```

**Field Descriptions**:
- `id`: Unique identifier for the service
- `department`: Display name
- `vbs_path`: Path to VBS startup script
- `project_dir`: Service project directory
- `csv_path`: Path to CSV data file (if applicable)
- `port`: Port number the service runs on
- `status`: Current status (running/stopped)

## Installation

### Prerequisites
- Windows 10 or later
- .NET Framework (usually pre-installed)
- Node.js (for the services themselves)

### Steps

1. **Extract Application**:
   - Copy entire `Release` folder to desired location
   - Recommended: `C:\Program Files\UDAL Wenlock\`

2. **Update Configuration**:
   - Open `services.json`
   - Update all paths to match your installation
   - Save the file

3. **Run Application**:
   - Double-click `wenlock_display_server.exe`
   - Or create desktop shortcut

## Usage

### Starting the Application

**Method 1: Direct Launch**
```
Double-click wenlock_display_server.exe
```

**Method 2: Command Line**
```cmd
cd C:\path\to\Release
wenlock_display_server.exe
```

**Method 3: Desktop Shortcut**
1. Right-click `wenlock_display_server.exe`
2. Send to > Desktop (create shortcut)
3. Double-click shortcut to launch

### Managing Services

#### Start a Service
1. Open Release application
2. Find service in list
3. Click "Start" button
4. Status changes to "Running"
5. Green indicator appears

#### Stop a Service
1. Find running service
2. Click "Stop" button
3. Status changes to "Stopped"
4. Red indicator appears

#### View Service Details
1. Click on service name
2. View configuration details
3. See port number
4. Check project directory

#### Open Service Display
1. Find running service
2. Click "Open Display" button
3. Browser opens to service URL

### Monitoring

#### Check Service Status
- **Green**: Service is running
- **Red**: Service is stopped
- **Yellow**: Service status unknown

#### View Logs
1. Click "View Logs" button
2. Opens log file in default text editor
3. Review recent activity

#### Check Port Usage
1. Click "Port Info" button
2. See which ports are in use
3. Identify port conflicts

## Configuration

### Adding New Service

1. **Update services.json**:
```json
{
  "id": "new_service",
  "department": "New Service Name",
  "vbs_path": "D:\\path\\to\\service.vbs",
  "project_dir": "D:\\path\\to\\service",
  "csv_path": null,
  "port": "3003",
  "status": "stopped"
}
```

2. **Restart Release application**
3. New service appears in list

### Updating Service Paths

If you move service folders:

1. Open `services.json` in text editor
2. Update `vbs_path` and `project_dir` for each service
3. Save file
4. Restart Release application

### Changing Ports

1. Update port in `services.json`
2. Update port in service's `server.js`
3. Restart both Release app and service

## Troubleshooting

### Common Issues

**1. Application Won't Start**

**Error**: Double-clicking does nothing

**Solutions**:
- Check Windows Event Viewer for errors
- Ensure all DLL files are present
- Run as Administrator
- Check antivirus isn't blocking

**2. Service Won't Start**

**Error**: Click "Start" but service doesn't start

**Solutions**:
- Check VBS path is correct
- Verify Node.js is installed
- Check port isn't already in use
- Review service logs

**3. Incorrect Service Status**

**Error**: Status shows wrong state

**Solutions**:
- Click "Refresh" button
- Restart Release application
- Check task manager for node.exe processes

**4. Can't Open Display**

**Error**: "Open Display" button doesn't work

**Solutions**:
- Verify service is actually running
- Check port number is correct
- Try manually opening `http://localhost:PORT`
- Check firewall settings

**5. Services.json Not Found**

**Error**: Configuration file missing

**Solutions**:
- Restore from backup
- Create new services.json with correct structure
- Check file permissions

### Debug Mode

**Enable verbose logging**:
1. Run from command line
2. Check console output
3. Look for error messages

```cmd
cd C:\path\to\Release
wenlock_display_server.exe --verbose
```

## Advanced Features

### Auto-Start on Windows Boot

**Method 1: Startup Folder**
1. Press `Win + R`
2. Type `shell:startup`
3. Create shortcut to `wenlock_display_server.exe`
4. Place in startup folder

**Method 2: Task Scheduler**
1. Open Task Scheduler
2. Create Basic Task
3. Trigger: At startup
4. Action: Start program
5. Program: Path to `wenlock_display_server.exe`

### Command Line Arguments

```cmd
# Start with specific config file
wenlock_display_server.exe --config="custom_services.json"

# Start minimized
wenlock_display_server.exe --minimized

# Enable debug mode
wenlock_display_server.exe --debug
```

### Batch Operations

**Start all services**:
```cmd
# Create batch file: start_all.bat
@echo off
wscript "D:\path\to\blood-bank\service.vbs"
timeout /t 5
wscript "D:\path\to\pharmacy\service.vbs"
timeout /t 5
wscript "D:\path\to\OT\service.vbs"
```

**Stop all services**:
```cmd
# Create batch file: stop_all.bat
@echo off
taskkill /F /IM node.exe
```

## Development

### Building from Source

If you have the Flutter source code:

```bash
# Navigate to project directory
cd wenlock_display_server

# Get dependencies
flutter pub get

# Build Windows executable
flutter build windows --release

# Output in: build/windows/runner/Release/
```

### Modifying the Application

**Update UI**:
- Edit Flutter source files
- Rebuild application
- Replace executable

**Add Features**:
- Implement in Flutter code
- Update services.json schema if needed
- Rebuild and test

## Security

### Permissions
- Application requires write access to `services.json`
- Services require network access
- May need admin rights to start services

### Best Practices
- Run with minimum necessary privileges
- Keep services.json secure
- Regularly update dependencies
- Monitor service logs

## Backup and Recovery

### Backup Configuration

```cmd
# Backup services.json
copy services.json services.json.backup

# Backup entire Release folder
xcopy Release Release_backup /E /I
```

### Restore Configuration

```cmd
# Restore from backup
copy services.json.backup services.json
```

### Export/Import Settings

**Export**:
1. Copy `services.json`
2. Save to safe location

**Import**:
1. Replace `services.json` with saved version
2. Update paths if needed
3. Restart application

## Performance

### Resource Usage
- **Memory**: ~50-100 MB
- **CPU**: Minimal when idle
- **Disk**: ~100 MB installation

### Optimization
- Close when not actively managing services
- Use Task Scheduler for automated management
- Monitor system resources

## Integration

### With Other Tools

**PowerShell Script**:
```powershell
# Check if service is running
$port = 3001
$connection = Test-NetConnection -ComputerName localhost -Port $port
if ($connection.TcpTestSucceeded) {
    Write-Host "Service on port $port is running"
} else {
    Write-Host "Service on port $port is not running"
}
```

**Monitoring Script**:
```powershell
# Monitor all services
$ports = @(3000, 3001, 3002)
foreach ($port in $ports) {
    $status = Test-NetConnection -ComputerName localhost -Port $port
    Write-Host "Port $port : $($status.TcpTestSucceeded)"
}
```

## Updates

### Updating the Application

1. **Download new version**
2. **Stop all services**
3. **Backup current installation**
4. **Replace executable and DLLs**
5. **Keep services.json**
6. **Restart application**

### Version Management

Keep track of versions:
```
Release/
├── wenlock_display_server.exe (v1.0.0)
├── CHANGELOG.md
└── VERSION.txt
```

## Support

### Getting Help

**For technical issues**:
- Check application logs
- Review services.json configuration
- Verify service paths
- Contact IT department

**For service-specific issues**:
- Refer to individual service documentation
- Check service logs
- Test service independently

### Reporting Bugs

Include:
1. Windows version
2. Application version
3. Error message
4. Steps to reproduce
5. services.json content (sanitized)

## Maintenance

### Regular Tasks

**Daily**:
- Verify all services are running
- Check for errors in logs

**Weekly**:
- Review service performance
- Update services.json if paths changed
- Backup configuration

**Monthly**:
- Check for application updates
- Review and clean logs
- Test disaster recovery

---

*Last Updated: December 2025*
*Version: 1.0*
