Set shell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
folderPath = fso.GetParentFolderName(WScript.ScriptFullName)
scriptPath = ""
For Each file In fso.GetFolder(folderPath).Files
  If LCase(fso.GetExtensionName(file.Name)) = "ps1" Then
    scriptPath = file.Path
    Exit For
  End If
Next
If scriptPath = "" Then
  MsgBox "Converter PowerShell script (.ps1) not found.", vbExclamation, "Image Converter"
  WScript.Quit 1
End If
command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -WindowStyle Hidden -File " & Chr(34) & scriptPath & Chr(34)
shell.Run command, 0, False
