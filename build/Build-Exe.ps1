param(
    [string]$ModulePath,
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
$requiredModuleVersion = [version]'1.0.18'
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot '圖片格式轉換器.ps1'
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "主程式不存在：$sourcePath"
}
$contextMenuTools = @(
    (Join-Path $projectRoot 'tools\Install-ContextMenu.ps1'),
    (Join-Path $projectRoot 'tools\Remove-ContextMenu.ps1')
)
foreach ($toolPath in $contextMenuTools) {
    if (-not (Test-Path -LiteralPath $toolPath -PathType Leaf)) { throw "右鍵選單工具不存在：$toolPath" }
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot 'versions\v1.1.0'
}
[void][IO.Directory]::CreateDirectory($OutputDirectory)

if (-not [string]::IsNullOrWhiteSpace($ModulePath)) {
    if (-not (Test-Path -LiteralPath $ModulePath -PathType Leaf)) {
        throw "找不到指定的 PS2EXE 模組檔：$ModulePath"
    }
    Import-Module $ModulePath -Force
} else {
    $moduleInfo = Get-Module -ListAvailable -Name ps2exe |
        Where-Object { $_.Version -eq $requiredModuleVersion } |
        Select-Object -First 1
    if (-not $moduleInfo) {
        throw "需要 PS2EXE $requiredModuleVersion。可執行：Install-Module -Name ps2exe -RequiredVersion $requiredModuleVersion -Scope CurrentUser"
    }
    Import-Module $moduleInfo.Path -Force
}

$loadedModule = Get-Module ps2exe
if (-not $loadedModule -or $loadedModule.Version -ne $requiredModuleVersion) {
    throw "載入的 PS2EXE 版本不符；需要 $requiredModuleVersion。"
}
if (-not (Get-Command Invoke-PS2EXE -ErrorAction SilentlyContinue)) {
    throw 'PS2EXE 模組未提供 Invoke-PS2EXE。'
}

$outputPath = Join-Path $OutputDirectory '圖片格式轉換器-v1.1.0.exe'
Invoke-PS2EXE `
    -inputFile $sourcePath `
    -outputFile $outputPath `
    -x64 `
    -STA `
    -noConsole `
    -DPIAware `
    -supportOS `
    -title '圖片格式轉換器' `
    -description 'Windows Forms batch image format converter with Traditional Chinese UI' `
    -company '1NotAmon' `
    -product 'Windows Image Format Converter' `
    -copyright 'Copyright (c) 2026 1NotAmon' `
    -version '1.1.0.0'

if (-not (Test-Path -LiteralPath $outputPath -PathType Leaf)) {
    throw "建置完成但未產生 EXE：$outputPath"
}

$packageToolsPath = Join-Path $OutputDirectory 'tools'
[void][IO.Directory]::CreateDirectory($packageToolsPath)
foreach ($toolPath in $contextMenuTools) {
    Copy-Item -LiteralPath $toolPath -Destination (Join-Path $packageToolsPath (Split-Path -Leaf $toolPath)) -Force
}

$hash = Get-FileHash -LiteralPath $outputPath -Algorithm SHA256
$sumPath = Join-Path $OutputDirectory 'SHA256SUMS.txt'
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[IO.File]::WriteAllText($sumPath, "$($hash.Hash)  $([IO.Path]::GetFileName($outputPath))`r`n", $utf8NoBom)
Write-Host "Built: $outputPath" -ForegroundColor Green
Write-Host "PS2EXE: $($loadedModule.Version)" -ForegroundColor Green
Write-Host "SHA-256: $($hash.Hash)" -ForegroundColor Green
