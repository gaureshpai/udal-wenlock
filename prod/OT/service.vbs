
' ==============================
' Wenlock Display Service - Pharmacy
' ==============================

Option Explicit
Dim WshShell, projectDir, nodeExe, entryFile, port

Set WshShell = CreateObject("WScript.Shell")

' === CONFIGURATION ===
projectDir = "D:\webdev\udal-wenlock\prod\OT"
nodeExe    = "C:\Program Files\nodejs\node.exe"
entryFile  = projectDir & "\server.js"
port       = 3001

' === FUNCTIONS ===
Sub StartService()
    WshShell.CurrentDirectory = projectDir
    WshShell.Run "cmd /c npm install --silent", 0, True
    WshShell.Run Chr(34) & nodeExe & Chr(34) & " " & Chr(34) & entryFile & Chr(34), 0, False
End Sub

Sub StopService()
    Dim cmd
    cmd = "cmd /c for /f ""tokens=5"" %a in ('netstat -ano ^| findstr :" & port & "') do taskkill /F /PID %a"
    WshShell.Run cmd, 0, True
End Sub

' === ENTRYPOINT ===
If WScript.Arguments.Count > 0 Then
    Select Case LCase(WScript.Arguments(0))
        Case "start"
            StartService
        Case "stop"
            StopService
        Case Else
            WScript.Echo "Usage: wscript service.vbs [start|stop]"
    End Select
Else
    WScript.Echo "Usage: wscript service.vbs [start|stop]"
End If
