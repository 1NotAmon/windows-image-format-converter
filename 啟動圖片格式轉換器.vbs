Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
folderPath = fso.GetParentFolderName(WScript.ScriptFullName)
scriptName = ChrW(22294) & ChrW(29255) & ChrW(26684) & ChrW(24335) & ChrW(36681) & ChrW(25563) & ChrW(22120) & ".ps1"
scriptPath = fso.BuildPath(folderPath, scriptName)
If Not fso.FileExists(scriptPath) Then
  MsgBox "Converter PowerShell script (.ps1) not found.", vbExclamation, "Image Converter"
  WScript.Quit 1
End If
command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File " & QuoteArgument(scriptPath)
For Each argument In WScript.Arguments
  command = command & " " & QuoteArgument(argument)
Next
shell.Run command, 0, False

Function QuoteArgument(value)
  QuoteArgument = Chr(34) & CStr(value) & Chr(34)
End Function
