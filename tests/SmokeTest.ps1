$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot '圖片格式轉換器.ps1'
$launcherPath = Join-Path $projectRoot '啟動圖片格式轉換器.vbs'

if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "主程式不存在：$sourcePath"
}
if (-not (Test-Path -LiteralPath $launcherPath -PathType Leaf)) {
    throw "啟動器不存在：$launcherPath"
}

$sourceBytes = [IO.File]::ReadAllBytes($sourcePath)
if ($sourceBytes.Length -lt 3 -or $sourceBytes[0] -ne 0xEF -or $sourceBytes[1] -ne 0xBB -or $sourceBytes[2] -ne 0xBF) {
    throw '主程式必須使用 UTF-8 BOM，確保 Windows PowerShell 5.1 正確讀取繁體中文。'
}

$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors) | Out-Null
if ($parseErrors.Count -gt 0) {
    $details = ($parseErrors | ForEach-Object { $_.Message }) -join [Environment]::NewLine
    throw "PowerShell 語法錯誤：`n$details"
}

$sourceText = [IO.File]::ReadAllText($sourcePath, [Text.Encoding]::UTF8)
$requiredTokens = @('.jfif', 'System.Windows.Forms', 'EncoderParameters', 'Add-ImageFiles')
foreach ($required in $requiredTokens) {
    if (-not $sourceText.Contains($required)) {
        throw "主程式缺少必要內容：$required"
    }
}

$launcherBytes = [IO.File]::ReadAllBytes($launcherPath)
if ($launcherBytes | Where-Object { $_ -gt 127 }) {
    throw 'VBS 啟動器必須保持 ASCII，避免 Windows Script Host 的原始碼編碼問題。'
}

Add-Type -AssemblyName System.Drawing
$samplePath = Join-Path ([IO.Path]::GetTempPath()) ('image-converter-smoke-' + [Guid]::NewGuid().ToString('N') + '.jfif')
$sample = $null
$decoded = $null
$jpegBitmap = $null
$encoderParameters = $null
$streams = New-Object System.Collections.ArrayList

try {
    $sample = New-Object System.Drawing.Bitmap(2, 2)
    $sample.SetPixel(0, 0, [System.Drawing.Color]::CornflowerBlue)
    $sample.Save($samplePath, [System.Drawing.Imaging.ImageFormat]::Jpeg)

    $decoded = [System.Drawing.Image]::FromFile($samplePath)
    if ($decoded.Width -ne 2 -or $decoded.Height -ne 2) {
        throw 'JFIF 測試圖片解碼後尺寸不符。'
    }
    $decoded.Dispose()
    $decoded = $null

    $formats = @(
        [System.Drawing.Imaging.ImageFormat]::Png,
        [System.Drawing.Imaging.ImageFormat]::Bmp,
        [System.Drawing.Imaging.ImageFormat]::Gif,
        [System.Drawing.Imaging.ImageFormat]::Tiff
    )
    foreach ($format in $formats) {
        $stream = New-Object IO.MemoryStream
        [void]$streams.Add($stream)
        $sample.Save($stream, $format)
        if ($stream.Length -eq 0) {
            throw "影像編碼器沒有輸出資料：$format"
        }
    }

    $jpegBitmap = New-Object System.Drawing.Bitmap(2, 2, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $jpegEncoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
    if (-not $jpegEncoder) {
        throw '找不到 Windows JPEG 編碼器。'
    }
    $encoderParameters = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParameters.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]92)
    $jpegStream = New-Object IO.MemoryStream
    [void]$streams.Add($jpegStream)
    $jpegBitmap.Save($jpegStream, $jpegEncoder, $encoderParameters)
    if ($jpegStream.Length -eq 0) {
        throw 'JPEG 品質編碼器沒有輸出資料。'
    }

    Write-Host 'Smoke test passed: syntax, JFIF decode, PNG/BMP/GIF/TIFF and JPEG encoding.' -ForegroundColor Green
}
finally {
    if ($decoded) { $decoded.Dispose() }
    if ($sample) { $sample.Dispose() }
    if ($jpegBitmap) { $jpegBitmap.Dispose() }
    if ($encoderParameters) { $encoderParameters.Dispose() }
    foreach ($stream in $streams) { $stream.Dispose() }
    if (Test-Path -LiteralPath $samplePath) { Remove-Item -LiteralPath $samplePath -Force -ErrorAction SilentlyContinue }
}
