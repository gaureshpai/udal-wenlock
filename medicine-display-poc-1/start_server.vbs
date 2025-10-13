Set WshShell = CreateObject("WScript.Shell")

' Change these paths accordingly
projectDir = "D:\Projects\UDAL_Fellowship_Wenlock_Hospital\udal-wenlock\medicine-display-poc-1"
nodeExe = "C:\Program Files\nodejs\node.exe"
entryFile = projectDir & "\server.js"

' Move into project directory
WshShell.CurrentDirectory = projectDir

' Install dependencies silently
WshShell.Run "cmd /c npm install --silent", 0, True

' Run Node.js server hidden (no terminal)
WshShell.Run Chr(34) & nodeExe & Chr(34) & " " & Chr(34) & entryFile & Chr(34), 0, False