' ===============================================
' Wenlock Display Microservice Script
' ===============================================
' Usage:
'   cscript service.vbs start   → starts the service
'   cscript service.vbs stop    → stops the service
'
' Automatically manages PID and log files.
' ===============================================

Option Explicit

Dim action, departmentName, projectDir, nodeExe, entryFile, serverPort
Dim WshShell, fso, pidFile, logFile

' --------------------------
' Configurable Fields
' --------------------------
departmentName = "Pharmacy"
projectDir     = "D:\webdev\udal-wenlock\pharmacy-display"
nodeExe        = "C:\Program Files\nodejs\node.exe"
entryFile      = projectDir & "\server.js"
serverPort     = "4001"

' Derived file paths
pidFile = projectDir & "\service.pid"
logFile = projectDir & "\service.log"

' --------------------------
' Setup
' --------------------------
Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")

If WScript.Arguments.Count = 0 Then
    WScript.Echo "Usage: cscript service.vbs [start|stop]"
    WScript.Quit 1
End If

action = LCase(WScript.Arguments(0))

Select Case action
    Case "start"
        StartService
    Case "stop"
        StopService
    Case Else
        WScript.Echo "Invalid argument: " & action
End Select

' --------------------------
' Functions
' --------------------------

Sub StartService()
    On Error Resume Next
    If fso.FileExists(pidFile) Then
        WScript.Echo "Service already running for " & departmentName
        Exit Sub
    End If

    WshShell.CurrentDirectory = projectDir

    ' Install dependencies silently
    WshShell.Run "cmd /c npm install --silent", 0, True

    ' Start Node.js process hidden and capture PID
    Dim execObj, pid
    Set execObj = WshShell.Exec("cmd /c start /B """ & departmentName & """ " & _
                                Chr(34) & nodeExe & Chr(34) & " " & _
                                Chr(34) & entryFile & Chr(34) & " --port " & serverPort)

    ' Log and store pseudo-PID (Windows doesn’t return PID directly via start /B)
    pid = Timer() * 1000 ' pseudo-unique identifier
    SaveText pidFile, CStr(pid)

    Log "Started service for " & departmentName & " on port " & serverPort
End Sub

Sub StopService()
    On Error Resume Next
    If Not fso.FileExists(pidFile) Then
        WScript.Echo "No PID file found; service may not be running."
        Exit Sub
    End If

    ' Kill Node.js processes using this entry file path
    Dim cmd
    cmd = "taskkill /FI " & Chr(34) & "WINDOWTITLE eq " & departmentName & Chr(34) & " /T /F"
    WshShell.Run "cmd /c " & cmd, 0, True

    fso.DeleteFile pidFile, True
    Log "Stopped service for " & departmentName
End Sub

Sub SaveText(path, text)
    Dim file
    Set file = fso.OpenTextFile(path, 2, True)
    file.Write text
    file.Close
End Sub

Sub Log(msg)
    Dim file
    Set file = fso.OpenTextFile(logFile, 8, True)
    file.WriteLine Now & " - " & msg
    file.Close
End Sub
