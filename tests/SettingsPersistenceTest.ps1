param([string]$ProjectRoot)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }
$sourceCandidates = @(Get-ChildItem -LiteralPath $ProjectRoot -File -Filter '*.ps1' | Where-Object {
    $text = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8)
    $text.Contains('function Get-UserSettings') -and $text.Contains('function Save-UserSettings')
})
if ($sourceCandidates.Count -ne 1) { throw "Expected one source with settings functions; found $($sourceCandidates.Count)." }
$sourcePath = $sourceCandidates[0].FullName
$tokens = $null
$errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$errors)
if ($errors.Count -gt 0) { throw 'Source contains PowerShell parse errors.' }

$formatAssignment = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and $node.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and $node.Left.VariablePath.UserPath -eq 'script:formats' }, $true)
if (-not $formatAssignment) { throw 'Could not locate the production output format table.' }
Invoke-Expression $formatAssignment.Extent.Text

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('WIFC-SettingsTest-' + [Guid]::NewGuid().ToString('N'))
$script:settingsPath = Join-Path $testRoot 'settings.json'
$script:defaultOutput = Join-Path $testRoot 'default-output'
$script:utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[void][IO.Directory]::CreateDirectory($testRoot)
try {
    foreach ($functionName in @('Get-UserSettings','Save-UserSettings')) {
        $functionAst = $ast.Find({ param($node) $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq $functionName }, $true)
        if (-not $functionAst) { throw "Could not locate production function $functionName." }
        Invoke-Expression $functionAst.Extent.Text
    }

    $defaults = Get-UserSettings
    if ($defaults.Quality -ne 92 -or $defaults.OutputDirectory -ne $script:defaultOutput) { throw 'Default settings are not applied correctly.' }

    $script:formatBox = New-Object System.Windows.Forms.ComboBox
    foreach ($formatName in $script:formats.Keys) { [void]$script:formatBox.Items.Add([string]$formatName) }
    $script:formatBox.SelectedItem = 'JPEG（白色背景）'
    $script:quality = New-Object System.Windows.Forms.TrackBar
    $script:quality.Minimum = 40
    $script:quality.Maximum = 100
    $script:quality.Value = 77
    $script:outputBox = New-Object System.Windows.Forms.TextBox
    $script:outputBox.Text = Join-Path $testRoot 'chosen-output'

    Save-UserSettings
    $savedJson = [IO.File]::ReadAllText($script:settingsPath, [Text.Encoding]::UTF8) | ConvertFrom-Json
    if ($savedJson.Format -ne 'JPEG（白色背景）' -or $savedJson.Quality -ne 77 -or $savedJson.OutputDirectory -ne $script:outputBox.Text) {
        throw 'Saved format, JPEG quality or output directory does not match the controls.'
    }
    $propertyNames = @($savedJson.PSObject.Properties.Name | Sort-Object)
    if (($propertyNames -join ',') -ne 'Format,OutputDirectory,Quality') { throw 'Settings file contains unexpected fields; only format, quality and output directory may be stored.' }

    $reloaded = Get-UserSettings
    if ($reloaded.Format -ne $savedJson.Format -or $reloaded.Quality -ne 77 -or $reloaded.OutputDirectory -ne $savedJson.OutputDirectory) {
        throw 'Production settings reader did not restore the saved values.'
    }
    Write-Host 'Settings persistence test passed: format, JPEG quality and output path are restored; no image list is stored.' -ForegroundColor Green
}
finally {
    foreach ($controlName in @('formatBox','quality','outputBox')) {
        $control = Get-Variable -Name $controlName -Scope Script -ValueOnly -ErrorAction SilentlyContinue
        if ($control -and -not $control.IsDisposed) { $control.Dispose() }
    }
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
