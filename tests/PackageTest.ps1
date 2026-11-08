$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$exePath = Join-Path $projectRoot 'versions\v1.1.0\圖片格式轉換器-v1.1.0.exe'
if (-not (Test-Path -LiteralPath $exePath -PathType Leaf)) {
    Write-Host 'Package test skipped: this source-only package does not contain the v1.1.0 EXE.' -ForegroundColor Yellow
    return
}

$bytes = [IO.File]::ReadAllBytes($exePath)
if ($bytes.Length -lt 512 -or $bytes[0] -ne 0x4D -or $bytes[1] -ne 0x5A) {
    throw '輸出檔不是有效的 Windows EXE（缺少 MZ 標記或檔案過小）。'
}

$peOffset = [BitConverter]::ToInt32($bytes, 0x3C)
if ($peOffset -lt 0 -or $peOffset + 6 -ge $bytes.Length -or [BitConverter]::ToUInt32($bytes, $peOffset) -ne 0x00004550) {
    throw '輸出檔缺少有效的 PE 標頭。'
}
$machine = [BitConverter]::ToUInt16($bytes, $peOffset + 4)
if ($machine -ne 0x8664) {
    throw ('EXE 架構不是預期的 x64，Machine=0x{0:X4}。' -f $machine)
}

$fileVersion = (Get-Item -LiteralPath $exePath).VersionInfo.FileVersion
if ($fileVersion -ne '1.1.0.0') {
    throw "EXE 版本資訊不符：預期 1.1.0.0，實際 $fileVersion。"
}

$process = $null
try {
    $process = Start-Process -FilePath $exePath -PassThru
    $deadline = (Get-Date).AddSeconds(25)
    $windowReady = $false
    do {
        Start-Sleep -Milliseconds 500
        $process.Refresh()
        if ($process.HasExited) {
            throw "EXE 啟動後立即結束，ExitCode=$($process.ExitCode)。"
        }
        if ($process.MainWindowHandle -ne [IntPtr]::Zero -and $process.MainWindowTitle -like '*圖片格式轉換器*') {
            $windowReady = $true
            break
        }
    } while ((Get-Date) -lt $deadline)

    if (-not $windowReady) {
        throw "EXE 未在 25 秒內顯示圖片格式轉換器主視窗，目前視窗標題：'$($process.MainWindowTitle)'。"
    }

    if (-not $process.CloseMainWindow()) {
        throw 'EXE 主視窗未接受正常關閉要求。'
    }
    if (-not $process.WaitForExit(10000)) {
        throw 'EXE 主視窗收到關閉要求後未在 10 秒內結束。'
    }

    Write-Host "Package test passed: x64 PE, file version $fileVersion, WinForms window launched and closed normally." -ForegroundColor Green
}
finally {
    if ($process) {
        try {
            $process.Refresh()
            if (-not $process.HasExited) {
                [void]$process.CloseMainWindow()
                [void]$process.WaitForExit(5000)
            }
        } catch { }
        $process.Dispose()
    }
}
