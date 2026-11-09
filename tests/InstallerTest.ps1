param([string]$Version = '1.3.0')

$ErrorActionPreference = 'Stop'
if ($Version -notmatch '^\d+\.\d+\.\d+$') { throw "Invalid version: $Version" }
$projectRoot = Split-Path -Parent $PSScriptRoot
$candidate = Join-Path $projectRoot (Join-Path 'versions' ('v' + $Version))
$setupPath = Join-Path $candidate ('WindowsImageFormatConverter-Setup-v{0}.exe' -f $Version)
$manifestPath = Join-Path $candidate 'SETUP-SHA256.txt'
if (-not (Test-Path -LiteralPath $setupPath -PathType Leaf)) { throw "Setup EXE not found: $setupPath" }
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) { throw "Setup hash manifest not found: $manifestPath" }

$setupHash = (Get-FileHash -LiteralPath $setupPath -Algorithm SHA256).Hash.ToUpperInvariant()
$manifestLine = [IO.File]::ReadAllText($manifestPath).Trim()
if ($manifestLine -ne "$setupHash  $(Split-Path -Leaf $setupPath)") { throw 'Setup SHA-256 manifest mismatch.' }

$uninstallRoot = 'Registry::HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Uninstall'
$existingEntries = @()
if (Test-Path -LiteralPath $uninstallRoot) {
    $existingEntries = @(Get-ChildItem -LiteralPath $uninstallRoot | ForEach-Object { Get-ItemProperty -LiteralPath $_.PSPath } | Where-Object { $_.DisplayName -eq '圖片格式轉換器' -and $_.Publisher -eq '1NotAmon' })
}
if ($existingEntries.Count -gt 0) { throw 'A per-user app with this product name/publisher is already installed; refusing to modify it during QA.' }

$verbKey = 'Registry::HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\image\shell\WindowsImageFormatConverter'
$commandKey = Join-Path $verbKey 'command'
$originalVerb = $null
$originalModel = $null
$originalCommand = $null
if (Test-Path -LiteralPath $verbKey) {
    $properties = Get-ItemProperty -LiteralPath $verbKey
    $originalVerb = $properties.MUIVerb
    $originalModel = $properties.MultiSelectModel
}
if (Test-Path -LiteralPath $commandKey) { $originalCommand = (Get-ItemProperty -LiteralPath $commandKey).'(default)' }

$testId = [guid]::NewGuid().ToString('N')
$testRoot = Join-Path $env:LOCALAPPDATA (Join-Path 'Temp' ('WIFC-InstallerTest-' + $testId))
$installDir = Join-Path $testRoot 'Installed'
$programs = [Environment]::GetFolderPath('Programs')
$startMenuDir = Join-Path $programs '圖片格式轉換器'
$shortcut = Join-Path $startMenuDir '圖片格式轉換器.lnk'
if (Test-Path -LiteralPath $startMenuDir) { throw 'The product Start Menu folder already exists; refusing to change it during QA.' }

$wasInstalled = $false
$cleanupComplete = $false
$uninstallKeyPath = $null
try {
    [void][IO.Directory]::CreateDirectory($testRoot)
    $installArgs = '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART /SP- /DIR="{0}" /TASKS="!contextmenu,!desktopicon"' -f $installDir
    $installProcess = Start-Process -FilePath $setupPath -ArgumentList $installArgs -PassThru -Wait
    if ($installProcess.ExitCode -ne 0) { throw "Installer exit code: $($installProcess.ExitCode)" }
    $wasInstalled = $true

    $installedExe = Join-Path $installDir '圖片格式轉換器.exe'
    if (-not (Test-Path -LiteralPath $installedExe -PathType Leaf)) { throw 'Installed application EXE is missing.' }
    if ((Get-Item -LiteralPath $installedExe).VersionInfo.FileVersion -ne ($Version + '.0')) { throw 'Installed application version mismatch.' }
    if (-not (Test-Path -LiteralPath $shortcut -PathType Leaf)) { throw 'Start Menu shortcut was not created.' }

    $expectedLocation = [IO.Path]::GetFullPath($installDir).TrimEnd('\')
    $installedEntry = @(Get-ChildItem -LiteralPath $uninstallRoot | ForEach-Object { Get-ItemProperty -LiteralPath $_.PSPath } | Where-Object {
        $_.DisplayName -eq '圖片格式轉換器' -and $_.Publisher -eq '1NotAmon' -and $_.DisplayVersion -eq $Version -and
        ([string]$_.InstallLocation).TrimEnd('\') -ieq $expectedLocation
    }) | Select-Object -First 1
    if (-not $installedEntry) { throw 'Per-user Apps and Features uninstall entry was not found for the isolated install path.' }
    $uninstallKeyPath = $installedEntry.PSPath

    $uninstaller = Get-ChildItem -LiteralPath $installDir -Filter 'unins*.exe' -File | Select-Object -First 1
    if (-not $uninstaller) { throw 'Uninstaller was not installed.' }

    $afterVerb = $null; $afterModel = $null; $afterCommand = $null
    if (Test-Path -LiteralPath $verbKey) { $after = Get-ItemProperty -LiteralPath $verbKey; $afterVerb = $after.MUIVerb; $afterModel = $after.MultiSelectModel }
    if (Test-Path -LiteralPath $commandKey) { $afterCommand = (Get-ItemProperty -LiteralPath $commandKey).'(default)' }
    if ($afterVerb -cne $originalVerb -or $afterModel -cne $originalModel -or $afterCommand -cne $originalCommand) {
        throw 'The Explorer context-menu registration changed although the context-menu task was deselected.'
    }

    $uninstallProcess = Start-Process -FilePath $uninstaller.FullName -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -PassThru -Wait
    if ($uninstallProcess.ExitCode -ne 0) { throw "Uninstaller exit code: $($uninstallProcess.ExitCode)" }
    $cleanupComplete = $true
    if (Test-Path -LiteralPath $installedExe) { throw 'Application EXE remained after uninstall.' }
    if (Test-Path -LiteralPath $shortcut) { throw 'Start Menu shortcut remained after uninstall.' }
    if ($uninstallKeyPath -and (Test-Path -LiteralPath $uninstallKeyPath)) { throw 'Uninstall registry entry remained after uninstall.' }

    Write-Host "Installer test passed: v$Version installed per-user, Start Menu shortcut/uninstaller created and removed." -ForegroundColor Green
    Write-Host 'Explorer context-menu registration was deliberately not selected and remained unchanged.' -ForegroundColor Green
}
finally {
    if ($wasInstalled -and -not $cleanupComplete) {
        $fallbackUninstaller = Get-ChildItem -LiteralPath $installDir -Filter 'unins*.exe' -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($fallbackUninstaller) {
            try {
                $fallback = Start-Process -FilePath $fallbackUninstaller.FullName -ArgumentList '/VERYSILENT /SUPPRESSMSGBOXES /NORESTART' -PassThru -Wait
                if ($fallback.ExitCode -eq 0) { $cleanupComplete = $true }
            } catch { }
        }
    }
    if ($cleanupComplete -or -not $wasInstalled) {
        if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue }
        if (Test-Path -LiteralPath $startMenuDir) { Remove-Item -LiteralPath $startMenuDir -Recurse -Force -ErrorAction SilentlyContinue }
    } elseif (Test-Path -LiteralPath $testRoot) {
        Write-Warning "Automatic cleanup failed; do not use the test installation at: $installDir"
    }
}
