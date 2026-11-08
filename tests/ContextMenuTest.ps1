$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot '圖片格式轉換器.ps1'
$launcherPath = Join-Path $projectRoot '啟動圖片格式轉換器.vbs'
$installerPath = Join-Path $projectRoot 'tools\Install-ContextMenu.ps1'
$removerPath = Join-Path $projectRoot 'tools\Remove-ContextMenu.ps1'
$buildScriptPath = Join-Path $projectRoot 'build\Build-Exe.ps1'

foreach ($path in @($sourcePath, $launcherPath, $installerPath, $removerPath, $buildScriptPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "必要檔案不存在：$path" }
}

foreach ($path in @($sourcePath, $installerPath, $removerPath, $buildScriptPath)) {
    $tokens = $null
    $parseErrors = $null
    [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$tokens, [ref]$parseErrors) | Out-Null
    if ($parseErrors.Count -gt 0) {
        $details = ($parseErrors | ForEach-Object { $_.Message }) -join [Environment]::NewLine
        throw "PowerShell 語法錯誤（$path）：`n$details"
    }
}

$sourceText = [IO.File]::ReadAllText($sourcePath, [Text.Encoding]::UTF8)
$launcherText = [IO.File]::ReadAllText($launcherPath, [Text.Encoding]::ASCII)
$installerText = [IO.File]::ReadAllText($installerPath, [Text.Encoding]::UTF8)
$removerText = [IO.File]::ReadAllText($removerPath, [Text.Encoding]::UTF8)
$buildText = [IO.File]::ReadAllText($buildScriptPath, [Text.Encoding]::UTF8)

$requiredChecks = @(
    @{ Name = 'source accepts startup file paths'; Text = $sourceText; Token = '$script:startupPaths' },
    @{ Name = 'source adds startup paths to the image list'; Text = $sourceText; Token = 'Add-ImageFiles -Paths $script:startupPaths' },
    @{ Name = 'launcher forwards all received arguments'; Text = $launcherText; Token = 'For Each argument In WScript.Arguments' },
    @{ Name = 'launcher targets the exact main script without non-ASCII source'; Text = $launcherText; Token = 'scriptName = ChrW(22294)' },
    @{ Name = 'installer looks for the packaged EXE'; Text = $installerText; Token = '圖片格式轉換器-v1.1.0.exe' },
    @{ Name = 'installer retains the source launcher fallback'; Text = $installerText; Token = '啟動圖片格式轉換器.vbs' },
    @{ Name = 'installer registers a multi-select Explorer verb'; Text = $installerText; Token = "SetValue('MultiSelectModel', 'Player'" },
    @{ Name = 'installer passes the selected shell items'; Text = $installerText; Token = '%*' },
    @{ Name = 'EXE build copies the context-menu tools'; Text = $buildText; Token = "tools\Install-ContextMenu.ps1" },
    @{ Name = 'uninstaller targets only this converter verb'; Text = $removerText; Token = 'WindowsImageFormatConverter' }
)
foreach ($check in $requiredChecks) {
    if (-not $check.Text.Contains($check.Token)) { throw "右鍵整合檢查失敗：$($check.Name)" }
}

$launcherBytes = [IO.File]::ReadAllBytes($launcherPath)
if ($launcherBytes | Where-Object { $_ -gt 127 }) { throw 'VBS 啟動器必須保持 ASCII。' }

Write-Host 'Context-menu test passed: startup paths, multi-selection registration, removable HKCU verb, and script syntax.' -ForegroundColor Green
