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

function Start-ConverterProcess([string]$Executable, [string]$ImagePath, [string]$InstanceSuffix, [string]$ResultPath) {
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $Executable
    $startInfo.Arguments = '"' + $ImagePath.Replace('"', '\"') + '"'
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.EnvironmentVariables['WIFC_TEST_INSTANCE_SUFFIX'] = $InstanceSuffix
    $startInfo.EnvironmentVariables['WIFC_TEST_RESULT_PATH'] = $ResultPath
    return [System.Diagnostics.Process]::Start($startInfo)
}

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('WIFC-PackageTest-' + [Guid]::NewGuid().ToString('N'))
[void][IO.Directory]::CreateDirectory($testRoot)
$testImages = @(
    (Join-Path $testRoot 'first image.jpg'),
    (Join-Path $testRoot '第二張測試.jfif'),
    (Join-Path $testRoot 'third image.png')
)
$resultPath = Join-Path $testRoot 'loaded-count.txt'
$primary = $null
$launchedProcesses = New-Object System.Collections.ArrayList
$testBitmap = $null
$instanceSuffix = 'PackageTest_' + [Guid]::NewGuid().ToString('N')

try {
    Add-Type -AssemblyName System.Drawing
    $testBitmap = New-Object System.Drawing.Bitmap(4, 4)
    $testBitmap.SetPixel(0, 0, [System.Drawing.Color]::CornflowerBlue)
    $testBitmap.Save($testImages[0], [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $testBitmap.Save($testImages[1], [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $testBitmap.Save($testImages[2], [System.Drawing.Imaging.ImageFormat]::Png)
    $testBitmap.Dispose()
    $testBitmap = $null

    foreach ($imagePath in $testImages) {
        $process = Start-ConverterProcess -Executable $exePath -ImagePath $imagePath -InstanceSuffix $instanceSuffix -ResultPath $resultPath
        [void]$launchedProcesses.Add($process)
    }

    $deadline = (Get-Date).AddSeconds(25)
    $windowReady = $false
    do {
        $windowOwners = @()
        $activeCount = 0
        foreach ($candidate in $launchedProcesses) {
            $candidate.Refresh()
            if ($candidate.HasExited) { continue }
            $activeCount++
            if ($candidate.MainWindowHandle -ne [IntPtr]::Zero -and $candidate.MainWindowTitle -like '*圖片格式轉換器*') {
                $windowOwners += $candidate
            }
        }
        if ($windowOwners.Count -gt 1) { throw '多選啟動建立了多個轉換器視窗。' }
        if ($windowOwners.Count -eq 1) {
            $primary = $windowOwners[0]
            $windowReady = $true
            break
        }
        if ($activeCount -eq 0) { throw '三個 EXE 啟動程序都在主視窗建立前結束。' }
        Start-Sleep -Milliseconds 250
    } while ((Get-Date) -lt $deadline)
    if (-not $windowReady) { throw 'EXE 未在 25 秒內顯示唯一主視窗。' }

    foreach ($candidate in $launchedProcesses) {
        if ($candidate.Id -ne $primary.Id -and -not $candidate.WaitForExit(10000)) {
            throw "後續圖片啟動程序未轉交路徑後結束，疑似另開視窗：PID $($candidate.Id)"
        }
    }

    $deadline = (Get-Date).AddSeconds(12)
    $allImagesLoaded = $false
    $observedItemCount = -1
    do {
        Start-Sleep -Milliseconds 350
        $primary.Refresh()
        if ($primary.HasExited) { throw '主轉換器在合併多次啟動時意外結束。' }
        if (Test-Path -LiteralPath $resultPath) {
            $observedItemCount = [int]([IO.File]::ReadAllText($resultPath).Trim())
            if ($observedItemCount -eq 3) { $allImagesLoaded = $true; break }
        }
    } while ((Get-Date) -lt $deadline)
    if (-not $allImagesLoaded) {
        throw "多次啟動後，單一視窗未載入三張圖片。程式內部清單筆數：$observedItemCount"
    }

    if (-not $primary.CloseMainWindow()) { throw 'EXE 主視窗未接受正常關閉要求。' }
    if (-not $primary.WaitForExit(10000)) { throw 'EXE 主視窗收到關閉要求後未在 10 秒內結束。' }
    Write-Host "Package test passed: x64 PE v$fileVersion; three independent launches merged into one GUI window and closed normally." -ForegroundColor Green
}
finally {
    foreach ($process in $launchedProcesses) {
        try {
            $process.Refresh()
            if (-not $process.HasExited) { [void]$process.CloseMainWindow(); [void]$process.WaitForExit(5000) }
        } catch { }
        $process.Dispose()
    }
    if ($testBitmap) { $testBitmap.Dispose() }
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
