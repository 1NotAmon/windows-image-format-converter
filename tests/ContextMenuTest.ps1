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
    @{ Name = 'source uses a per-user single-instance mutex'; Text = $sourceText; Token = 'Local\WindowsImageFormatConverter_' },
    @{ Name = 'source queues later image launches'; Text = $sourceText; Token = 'AppendAllLines($script:requestQueuePath' },
    @{ Name = 'source polls queued paths on the WinForms timer'; Text = $sourceText; Token = '$script:requestTimer.Add_Tick' },
    @{ Name = 'launcher targets the exact main script without non-ASCII source'; Text = $launcherText; Token = 'scriptName = ChrW(22294)' },
    @{ Name = 'installer prefers the v1.4.0 packaged EXE'; Text = $installerText; Token = '圖片格式轉換器-v1.4.0.exe' },
    @{ Name = 'installer retains the v1.3.0 package fallback'; Text = $installerText; Token = '圖片格式轉換器-v1.3.0.exe' },
    @{ Name = 'installer retains the v1.2 package fallback'; Text = $installerText; Token = '圖片格式轉換器-v1.2.0.exe' },
    @{ Name = 'installer retains the v1.1 package fallback'; Text = $installerText; Token = '圖片格式轉換器-v1.1.0.exe' },
    @{ Name = 'installer retains the source launcher fallback'; Text = $installerText; Token = '啟動圖片格式轉換器.vbs' },
    @{ Name = 'installer registers a multi-select Explorer verb'; Text = $installerText; Token = "SetValue('MultiSelectModel', 'Player'" },
    @{ Name = 'installer uses the standard Shell file argument placeholder'; Text = $installerText; Token = '"%1"' },
    @{ Name = 'EXE build copies the context-menu tools'; Text = $buildText; Token = "tools\Install-ContextMenu.ps1" },
    @{ Name = 'uninstaller targets only this converter verb'; Text = $removerText; Token = 'WindowsImageFormatConverter' }
)
foreach ($check in $requiredChecks) {
    if (-not $check.Text.Contains($check.Token)) { throw "右鍵整合檢查失敗：$($check.Name)" }
}
$v14Index = $installerText.IndexOf('圖片格式轉換器-v1.4.0.exe', [StringComparison]::Ordinal)
$v13Index = $installerText.IndexOf('圖片格式轉換器-v1.3.0.exe', [StringComparison]::Ordinal)
$v12Index = $installerText.IndexOf('圖片格式轉換器-v1.2.0.exe', [StringComparison]::Ordinal)
$v11Index = $installerText.IndexOf('圖片格式轉換器-v1.1.0.exe', [StringComparison]::Ordinal)
if ($v14Index -lt 0 -or $v13Index -le $v14Index -or $v12Index -le $v13Index -or $v11Index -le $v12Index) { throw '右鍵整合檢查失敗：EXE 候選版本優先順序錯誤。' }
if ($installerText.Contains('%*')) { throw '右鍵整合檢查失敗：安裝器不可使用 Shell 不支援的 %* 替代符。' }

$packageTestPath = Join-Path $projectRoot 'tests\PackageTest.ps1'
$packageTestText = [IO.File]::ReadAllText($packageTestPath, [Text.Encoding]::UTF8)
if (-not $packageTestText.Contains('three independent launches merged into one GUI window')) {
    throw '右鍵整合檢查失敗：EXE 封裝測試必須驗證多次啟動合併到單一視窗。'
}

$launcherBytes = [IO.File]::ReadAllBytes($launcherPath)
if ($launcherBytes | Where-Object { $_ -gt 127 }) { throw 'VBS 啟動器必須保持 ASCII。' }

Write-Host 'Context-menu test passed: startup paths, multi-selection registration, removable HKCU verb, and script syntax.' -ForegroundColor Green
