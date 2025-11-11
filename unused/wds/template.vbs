' Hospital Service Control Script
' Usage: cscript service_control.vbs [start|stop|restart]

Option Explicit

Dim objShell, objFSO
Dim strAction, strServicePath, strNodePath, strPidFile
Dim intPID

' Initialize objects
Set objShell = CreateObject("WScript.Shell")
Set objFSO = CreateObject("Scripting.FileSystemObject")

' Configuration - Modify these paths for each service
strServicePath = "C:\HospitalServices\BloodBank\server.js"
strNodePath = "C:\Program Files\nodejs\node.exe"
strPidFile = "C:\HospitalServices\BloodBank\service.pid"

' Get command line argument
If WScript.Arguments.Count = 0 Then
    WScript.Echo "Usage: cscript service_control.vbs [start|stop|restart]"
    WScript.Quit 1
End If

strAction = LCase(WScript.Arguments(0))

' Execute action
Select Case strAction
    Case "start"
        StartService
    Case "stop"
        StopService
    Case "restart"
        StopService
        WScript.Sleep 2000
        StartService
    Case Else
        WScript.Echo "Invalid action. Use: start, stop, or restart"
        WScript.Quit 1
End Select

WScript.Quit 0

' Start the Node.js service
Sub StartService()
    Dim strCommand
    
    ' Check if already running
    If IsServiceRunning() Then
        WScript.Echo "Service is already running"
        Exit Sub
    End If
    
    ' Check if Node.js executable exists
    If Not objFSO.FileExists(strNodePath) Then
        WScript.Echo "Error: Node.js not found at " & strNodePath
        WScript.Quit 1
    End If
    
    ' Check if service script exists
    If Not objFSO.FileExists(strServicePath) Then
        WScript.Echo "Error: Service script not found at " & strServicePath
        WScript.Quit 1
    End If
    
    ' Start the service in background
    strCommand = """" & strNodePath & """ """ & strServicePath & """"
    
    ' Run the service and capture PID
    Dim objWMIService, objProcess, objStartup
    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    Set objStartup = objWMIService.Get("Win32_ProcessStartup")
    Set objProcess = objWMIService.Get("Win32_Process")
    
    Dim intReturn, intProcessID
    intReturn = objProcess.Create(strCommand, Null, objStartup, intProcessID)
    
    If intReturn = 0 Then
        ' Save PID to file
        Dim objFile
        Set objFile = objFSO.CreateTextFile(strPidFile, True)
        objFile.WriteLine intProcessID
        objFile.Close
        
        WScript.Echo "Service started successfully (PID: " & intProcessID & ")"
    Else
        WScript.Echo "Error starting service. Error code: " & intReturn
        WScript.Quit 1
    End If
End Sub

' Stop the Node.js service
Sub StopService()
    If Not IsServiceRunning() Then
        WScript.Echo "Service is not running"
        Exit Sub
    End If
    
    ' Read PID from file
    If Not objFSO.FileExists(strPidFile) Then
        WScript.Echo "Error: PID file not found"
        Exit Sub
    End If
    
    Dim objFile, strPID
    Set objFile = objFSO.OpenTextFile(strPidFile, 1)
    strPID = objFile.ReadLine
    objFile.Close
    
    ' Kill the process
    Dim strCommand
    strCommand = "taskkill /F /PID " & strPID
    objShell.Run strCommand, 0, True
    
    ' Delete PID file
    objFSO.DeleteFile strPidFile
    
    WScript.Echo "Service stopped successfully"
End Sub

' Check if service is running
Function IsServiceRunning()
    IsServiceRunning = False
    
    If Not objFSO.FileExists(strPidFile) Then
        Exit Function
    End If
    
    ' Read PID
    Dim objFile, strPID
    Set objFile = objFSO.OpenTextFile(strPidFile, 1)
    strPID = objFile.ReadLine
    objFile.Close
    
    ' Check if process exists
    Dim objWMIService, colProcesses
    Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
    Set colProcesses = objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE ProcessId = " & strPID)
    
    If colProcesses.Count > 0 Then
        IsServiceRunning = True
    Else
        ' PID file exists but process doesn't - clean up
        objFSO.DeleteFile strPidFile
    End If
End Function