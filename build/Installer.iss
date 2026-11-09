#ifndef AppVersion
  #define AppVersion "1.4.0"
#endif

#define AppName "圖片格式轉換器"
#ifndef AppIdValue
  #define AppIdValue "1NotAmon.WindowsImageFormatConverter.7D2E0C72-4FB7-45F7-83A8-78D4E7DA4CB1"
#endif
#ifndef AppMenuName
  #define AppMenuName AppName
#endif
#define CandidateDir "..\versions\v" + AppVersion
#define AppExeName "圖片格式轉換器-v" + AppVersion + ".exe"
#define AppVersionInfo AppVersion + ".0"

[Setup]
AppId={#AppIdValue}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher=1NotAmon
AppPublisherURL=https://github.com/1NotAmon/windows-image-format-converter
AppSupportURL=https://github.com/1NotAmon/windows-image-format-converter/issues
AppUpdatesURL=https://github.com/1NotAmon/windows-image-format-converter/releases
DefaultDirName={localappdata}\Programs\WindowsImageFormatConverter
DefaultGroupName={#AppMenuName}
UninstallDisplayName={#AppName}
UninstallDisplayIcon={app}\圖片格式轉換器.exe
VersionInfoVersion={#AppVersionInfo}
VersionInfoProductName={#AppName}
VersionInfoCompany=1NotAmon
VersionInfoDescription={#AppName} Windows 使用者安裝程式
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
DisableProgramGroupPage=yes
CloseApplications=no
RestartApplications=no
OutputDir=..\versions\v{#AppVersion}
OutputBaseFilename=WindowsImageFormatConverter-Setup-v{#AppVersion}
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "chinesetraditional"; MessagesFile: "compiler:Languages\ChineseTraditional.isl"

[Tasks]
Name: "contextmenu"; Description: "加入圖片右鍵選單（會取代本專案舊版本；解除安裝不會還原舊版本）"; GroupDescription: "其他設定："; Flags: unchecked
Name: "desktopicon"; Description: "建立桌面捷徑"; GroupDescription: "其他設定："; Flags: unchecked

[Files]
Source: "{#CandidateDir}\{#AppExeName}"; DestDir: "{app}"; DestName: "圖片格式轉換器.exe"; Flags: ignoreversion
Source: "..\LICENSE"; DestDir: "{app}"; DestName: "LICENSE.txt"; Flags: ignoreversion
Source: "{#CandidateDir}\THIRD-PARTY-NOTICES.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#CandidateDir}\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "{#CandidateDir}\RELEASE-NOTES.md"; DestDir: "{app}"; Flags: ignoreversion

[Icons]
Name: "{autoprograms}\{#AppMenuName}\{#AppName}"; Filename: "{app}\圖片格式轉換器.exe"
Name: "{autodesktop}\{#AppName}"; Filename: "{app}\圖片格式轉換器.exe"; Tasks: desktopicon

[Registry]
Root: HKCU; Subkey: "Software\Classes\SystemFileAssociations\image\shell\WindowsImageFormatConverter"; ValueType: string; ValueName: "MUIVerb"; ValueData: "用圖片格式轉換器轉換"; Flags: uninsdeletevalue; Tasks: contextmenu
Root: HKCU; Subkey: "Software\Classes\SystemFileAssociations\image\shell\WindowsImageFormatConverter"; ValueType: string; ValueName: "MultiSelectModel"; ValueData: "Player"; Flags: uninsdeletevalue; Tasks: contextmenu
Root: HKCU; Subkey: "Software\Classes\SystemFileAssociations\image\shell\WindowsImageFormatConverter\command"; ValueType: string; ValueName: ""; ValueData: """{app}\圖片格式轉換器.exe"" ""%1"""; Flags: uninsdeletevalue; Tasks: contextmenu
Root: HKCU; Subkey: "Software\Classes\SystemFileAssociations\image\shell\WindowsImageFormatConverter"; Flags: uninsdeletekeyifempty; Tasks: contextmenu
