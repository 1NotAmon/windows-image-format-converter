param(
    [string]$Version = '1.3.0',
    [string]$ISCCPath
)

$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "版本格式必須是 MAJOR.MINOR.PATCH，例如 1.3.0；目前值：$Version"
}

$projectRoot = Split-Path -Parent $PSScriptRoot
$candidate = Join-Path $projectRoot (Join-Path 'versions' ('v' + $Version))
$issPath = Join-Path $PSScriptRoot 'Installer.iss'
$setupName = 'WindowsImageFormatConverter-Setup-v{0}.exe' -f $Version
$setupPath = Join-Path $candidate $setupName

foreach ($required in @(
    $issPath,
    (Join-Path $candidate ('圖片格式轉換器-v{0}.exe' -f $Version)),
    (Join-Path $candidate 'THIRD-PARTY-NOTICES.txt'),
    (Join-Path $candidate 'README.md'),
    (Join-Path $candidate 'RELEASE-NOTES.md'),
    (Join-Path $projectRoot 'LICENSE')
)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "缺少安裝器輸入檔案：$required"
    }
}

if ([string]::IsNullOrWhiteSpace($ISCCPath)) {
    $fromEnvironment = [Environment]::GetEnvironmentVariable('WIFC_ISCC')
    if (-not [string]::IsNullOrWhiteSpace($fromEnvironment)) { $ISCCPath = $fromEnvironment }
}
if ([string]::IsNullOrWhiteSpace($ISCCPath)) {
    $isccCommand = Get-Command 'ISCC.exe' -ErrorAction SilentlyContinue
    if ($isccCommand) { $ISCCPath = $isccCommand.Source }
}
if ([string]::IsNullOrWhiteSpace($ISCCPath)) {
    $roots = @(
        (Join-Path $env:ProgramFiles 'Inno Setup 7'),
        (Join-Path $env:ProgramFiles 'Inno Setup 6'),
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 7'),
        (Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 7'),
        (Join-Path $env:LOCALAPPDATA 'Programs\Inno Setup 6')
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    foreach ($root in $roots) {
        $candidateCompiler = Join-Path $root 'ISCC.exe'
        if (Test-Path -LiteralPath $candidateCompiler -PathType Leaf) { $ISCCPath = $candidateCompiler; break }
    }
}
if ([string]::IsNullOrWhiteSpace($ISCCPath) -or -not (Test-Path -LiteralPath $ISCCPath -PathType Leaf)) {
    throw '找不到 Inno Setup 命令列編譯器 ISCC.exe。請安裝 Inno Setup 7，或以 -ISCCPath 指定 ISCC.exe 的完整路徑。'
}

$compilerSignature = Get-AuthenticodeSignature -LiteralPath $ISCCPath
if ($compilerSignature.Status -notin @('Valid', 'NotSigned')) {
    throw "ISCC.exe 簽章狀態異常：$($compilerSignature.Status)"
}

& $ISCCPath "/DAppVersion=$Version" $issPath
if ($LASTEXITCODE -ne 0) { throw "Inno Setup 編譯失敗，結束碼：$LASTEXITCODE" }
if (-not (Test-Path -LiteralPath $setupPath -PathType Leaf)) { throw "編譯完成但找不到安裝檔：$setupPath" }

$hash = (Get-FileHash -LiteralPath $setupPath -Algorithm SHA256).Hash.ToUpperInvariant()
$manifest = Join-Path $candidate 'SETUP-SHA256.txt'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($manifest, "$hash  $setupName`r`n", $utf8NoBom)

Write-Host "安裝程式：$setupPath" -ForegroundColor Green
Write-Host "版本：$Version x64；目前使用者安裝，無需系統管理員權限" -ForegroundColor Green
Write-Host "SHA-256：$hash" -ForegroundColor Green
Write-Host "ISCC：$ISCCPath" -ForegroundColor Green
