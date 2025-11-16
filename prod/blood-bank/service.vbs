
' ==============================
' Wenlock Display Service - Pharmacy
' ==============================

Option Explicit
Dim WshShell, projectDir, nodeExe, entryFile, port

Set WshShell = CreateObject("WScript.Shell")

' === CONFIGURATION ===
projectDir = "D:\Projects\UDAL_Fellowship_Wenlock_Hospital\gauresh\udal-wenlock\prod\blood-bank"
nodeExe    = "C:\Program Files\nodejs\node.exe"
entryFile  = projectDir & "\server.js"
port       = 3001

' === FUNCTIONS ===
Sub StartService()
    Dim cmd, tempFile, fso, objFile, pid, pidFile
    
    WshShell.CurrentDirectory = projectDir
    WshShell.Run "cmd /c npm install --silent", 0, True
    
    ' Create temp file to capture PID
    tempFile = WshShell.ExpandEnvironmentStrings("%TEMP%") & "\node_pid_" & port & ".txt"
    
    ' Start node process and capture PID
    cmd = "cmd /c start /B " & Chr(34) & Chr(34) & " " & Chr(34) & nodeExe & Chr(34) & " " & Chr(34) & entryFile & Chr(34) & " & for /f ""tokens=2"" %a in ('tasklist /FI ""IMAGENAME eq node.exe"" /FO LIST ^| findstr /I ""PID:""') do @echo %a > " & Chr(34) & tempFile & Chr(34)
    WshShell.Run cmd, 0, True
    
    ' Wait a moment for the file to be written
    WScript.Sleep 1000
    
    ' Read PID from temp file and save to service.pid
    Set fso = CreateObject("Scripting.FileSystemObject")
    If fso.FileExists(tempFile) Then
        Set objFile = fso.OpenTextFile(tempFile, 1)
        If Not objFile.AtEndOfStream Then
            pid = Trim(objFile.ReadLine)
            objFile.Close
            
            ' Save PID to service.pid in project directory
            pidFile = projectDir & "\service.pid"
            Set objFile = fso.CreateTextFile(pidFile, True)
            objFile.WriteLine pid
            objFile.Close
        End If
        
        ' Clean up temp file
        fso.DeleteFile tempFile
    End If
End Sub

Sub StopService()
    Dim cmd, fso, pidFile, objFile, pid
    
    Set fso = CreateObject("Scripting.FileSystemObject")
    pidFile = projectDir & "\service.pid"
    
    ' Try to stop using stored PID first
    If fso.FileExists(pidFile) Then
        Set objFile = fso.OpenTextFile(pidFile, 1)
        If Not objFile.AtEndOfStream Then
            pid = Trim(objFile.ReadLine)
            objFile.Close
            
            ' Kill process by PID
            WshShell.Run "cmd /c taskkill /F /PID " & pid, 0, True
        End If
        
        ' Delete PID file
        fso.DeleteFile pidFile
    End If
    
    ' Fallback: kill by port
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
