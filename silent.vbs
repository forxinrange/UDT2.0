Dim shell,command
command = "powershell.exe -nologo -File D:\myscript.ps1"
Set shell = CreateObject("WScript.Shell")
shell.Run command,0