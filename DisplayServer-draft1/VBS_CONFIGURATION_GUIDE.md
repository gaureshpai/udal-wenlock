# VBS Configuration Guide

## File Structure Requirements

Your VBS files should follow this standardized structure for the Microservice Manager to properly parse and manage them:

### 1. Configuration Header (Required)
```vbs
' ============= SERVICE CONFIGURATION =============
' Service Name: Your Service Display Name
' Description: Brief description of what this service does
' Port: 3001
' Start Command: npm run start
' Stop Command: taskkill /f /im node.exe
' Dependencies: npm install
' ================================================
```

### 2. Service Variables (Required)
```vbs
Set WshShell = CreateObject("WScript.Shell")

' Service Configuration Variables
serviceName = "Your Service Display Name"
serviceDescription = "Brief description of what this service does"
servicePort = "3001"
projectDir = "C:\path\to\your\project"
nodeExe = "C:\Program Files\nodejs\node.exe"
startCommand = "npm run start"
stopCommand = "taskkill /f /im node.exe"
```

### 3. Required Functions

#### StartService Function
```vbs
Function StartService()
    WshShell.CurrentDirectory = projectDir
    
    ' Install dependencies if needed
    WshShell.Run "cmd /c npm install --silent", 0, True
    
    ' Start the service with a named window
    WshShell.Run "cmd /c start """ & serviceName & """ " & startCommand, 0, False
    
    StartService = True
End Function
```

#### StopService Function
```vbs
Function StopService()
    ' Primary stop method
    WshShell.Run "cmd /c " & stopCommand, 0, True
    
    ' Backup: Kill by port if primary method fails
    WshShell.Run "cmd /c netstat -ano | findstr :" & servicePort & " | for /f ""tokens=5"" %a in ('more') do taskkill /f /pid %a", 0, True
    
    StopService = True
End Function
```

#### GetServiceStatus Function
```vbs
Function GetServiceStatus()
    ' Check if service is running on the specified port
    result = WshShell.Run("cmd /c netstat -an | findstr :" & servicePort, 0, True)
    If result = 0 Then
        GetServiceStatus = "Running"
    Else
        GetServiceStatus = "Stopped"
    End If
End Function
```

### 4. Main Execution Logic (Required)
```vbs
' Main execution based on command line argument
If WScript.Arguments.Count > 0 Then
    action = WScript.Arguments(0)
    Select Case LCase(action)
        Case "start"
            StartService()
        Case "stop"
            StopService()
        Case "status"
            WScript.Echo GetServiceStatus()
        Case Else
            WScript.Echo "Usage: cscript your_service.vbs [start|stop|status]"
    End Select
Else
    ' Default action when no arguments provided
    StartService()
End If
```

## Common Service Types

### Node.js Services
```vbs
' Configuration for Node.js microservices
serviceName = "Medical Display Service"
servicePort = "3001"
projectDir = "D:\projects\medical-service"
startCommand = "npm run med"
stopCommand = "taskkill /f /fi ""WINDOWTITLE eq Medical*"""
```

### Python Services
```vbs
' Configuration for Python services
serviceName = "Python Analytics Service"
servicePort = "5000"
projectDir = "D:\projects\analytics-service"
startCommand = "python app.py"
stopCommand = "taskkill /f /fi ""WINDOWTITLE eq Python*"""
```

### Java Services
```vbs
' Configuration for Java Spring Boot services
serviceName = "Hospital Management API"
servicePort = "8080"
projectDir = "D:\projects\hospital-api"
startCommand = "java -jar target\hospital-api.jar"
stopCommand = "taskkill /f /fi ""WINDOWTITLE eq Hospital*"""
```

### .NET Core Services
```vbs
' Configuration for .NET Core services
serviceName = "Patient Records Service"
servicePort = "5001"
projectDir = "D:\projects\patient-records"
startCommand = "dotnet run"
stopCommand = "taskkill /f /fi ""WINDOWTITLE eq Patient*"""
```

## Best Practices

### 1. Use Descriptive Names
- Make service names clear and descriptive
- Include the purpose in the description
- Use consistent naming conventions

### 2. Port Management
- Use unique ports for each service
- Document port assignments
- Consider port ranges (e.g., 3000-3099 for Node.js services)

### 3. Error Handling
```vbs
Function StartService()
    On Error Resume Next
    WshShell.CurrentDirectory = projectDir
    If Err.Number <> 0 Then
        WScript.Echo "Error: Project directory not found - " & projectDir
        StartService = False
        Exit Function
    End If
    On Error GoTo 0
    
    ' Continue with service start logic...
End Function
```

### 4. Logging
```vbs
Function LogMessage(message)
    Dim logFile, fso
    Set fso = CreateObject("Scripting.FileSystemObject")
    Set logFile = fso.OpenTextFile(projectDir & "\service.log", 8, True)
    logFile.WriteLine Now & " - " & message
    logFile.Close
End Function
```

### 5. Environment Variables
```vbs
' Read environment-specific configuration
Function GetEnvironmentValue(keyName, defaultValue)
    Dim envValue
    envValue = WshShell.ExpandEnvironmentStrings("%" & keyName & "%")
    If envValue = "%" & keyName & "%" Then
        GetEnvironmentValue = defaultValue
    Else
        GetEnvironmentValue = envValue
    End If
End Function

' Usage
projectDir = GetEnvironmentValue("SERVICE_PROJECT_DIR", "D:\default\project\path")
```

## Testing Your VBS File

Before adding to the Microservice Manager, test your VBS file manually:

```cmd
# Test starting the service
cscript your_service.vbs start

# Test checking status
cscript your_service.vbs status

# Test stopping the service
cscript your_service.vbs stop
```

## Troubleshooting

### Common Issues

1. **"Project directory not found"**
   - Verify the `projectDir` path is correct
   - Use absolute paths, not relative paths

2. **"Service won't start"**
   - Check if the start command is correct
   - Verify all dependencies are installed
   - Check if the port is already in use

3. **"Service won't stop"**
   - Try different stop commands
   - Use port-based killing as backup
   - Check Windows Task Manager for hung processes

4. **"Status shows incorrect information"**
   - Verify port checking logic
   - Consider using process name checking instead of port checking

### Debug Mode
Add debugging to your VBS files during development:

```vbs
debugMode = True

Function DebugLog(message)
    If debugMode Then
        WScript.Echo "[DEBUG] " & Now & " - " & message
    End If
End Function

Function StartService()
    DebugLog "Starting service: " & serviceName
    DebugLog "Project directory: " & projectDir
    DebugLog "Start command: " & startCommand
    
    ' Your service start logic here...
End Function
```

This guide ensures your VBS files will work seamlessly with the Microservice Manager application!