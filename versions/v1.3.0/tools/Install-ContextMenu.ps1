$ErrorActionPreference = 'Stop'

$packageRoot = Split-Path -Parent $PSScriptRoot
$exeCandidates = @(
    (Join-Path $packageRoot '圖片格式轉換器-v1.3.0.exe'),
    (Join-Path $packageRoot 'versions\v1.3.0\圖片格式轉換器-v1.3.0.exe'),
    (Join-Path $packageRoot '圖片格式轉換器-v1.2.0.exe'),
    (Join-Path $packageRoot 'versions\v1.2.0\圖片格式轉換器-v1.2.0.exe'),
    (Join-Path $packageRoot '圖片格式轉換器-v1.1.0.exe'),
    (Join-Path $packageRoot 'versions\v1.1.0\圖片格式轉換器-v1.1.0.exe')
)
$exePath = $exeCandidates | Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } | Select-Object -First 1

if ($exePath) {
    $command = '"{0}" "%1"' -f $exePath
    $launchTarget = $exePath
}
else {
    $launcherPath = Join-Path $packageRoot '啟動圖片格式轉換器.vbs'
    if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
        throw "找不到轉換器 EXE 或原始碼啟動器：$launcherPath"
    }
    $wscriptPath = Join-Path $env:WINDIR 'System32\wscript.exe'
    if (-not (Test-Path -LiteralPath $wscriptPath -PathType Leaf)) {
        throw "找不到 Windows Script Host：$wscriptPath"
    }
    $command = '"{0}" "{1}" "%1"' -f $wscriptPath, $launcherPath
    $launchTarget = $launcherPath
}

$registrySubKey = 'Software\Classes\SystemFileAssociations\image\shell\WindowsImageFormatConverter'
$verbKey = $null
$commandKey = $null

try {
    $verbKey = [Microsoft.Win32.Registry]::CurrentUser.CreateSubKey($registrySubKey)
    if (-not $verbKey) { throw '無法建立目前使用者的右鍵選單登錄項目。' }
    $verbKey.SetValue('MUIVerb', '用圖片格式轉換器轉換', [Microsoft.Win32.RegistryValueKind]::String)
    $verbKey.SetValue('MultiSelectModel', 'Player', [Microsoft.Win32.RegistryValueKind]::String)
    $commandKey = $verbKey.CreateSubKey('command')
    if (-not $commandKey) { throw '無法建立右鍵選單命令。' }
    $commandKey.SetValue('', $command, [Microsoft.Win32.RegistryValueKind]::String)
}
finally {
    if ($commandKey) { $commandKey.Dispose() }
    if ($verbKey) { $verbKey.Dispose() }
}

Write-Host '已加入檔案總管圖片右鍵選單（僅目前 Windows 使用者）。' -ForegroundColor Green
Write-Host "啟動目標：$launchTarget"
Write-Host '在圖片上按右鍵，選擇「用圖片格式轉換器轉換」。'
Write-Host 'Windows 11 若未直接顯示，請先選「顯示更多選項」。'
