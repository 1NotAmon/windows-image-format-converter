param(
    [string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) { $ProjectRoot = Split-Path -Parent $PSScriptRoot }
$sourceCandidates = @(Get-ChildItem -LiteralPath $ProjectRoot -File -Filter '*.ps1' | Where-Object {
    $candidateText = [IO.File]::ReadAllText($_.FullName, [Text.Encoding]::UTF8)
    $candidateText.Contains('$script:startupPaths') -and $candidateText.Contains('$script:formats = [ordered]@{')
})
if ($sourceCandidates.Count -ne 1) { throw "Expected one converter source script; found $($sourceCandidates.Count)." }
$sourcePath = $sourceCandidates[0].FullName
$sourceText = [IO.File]::ReadAllText($sourcePath, [Text.Encoding]::UTF8)
$tokens = $null
$parseErrors = $null
$sourceAst = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
if ($parseErrors.Count -gt 0) { throw 'Source has PowerShell parse errors.' }

$formatAssignment = $sourceAst.Find({
    param($node)
    $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
    $node.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
    $node.Left.VariablePath.UserPath -eq 'script:formats'
}, $true)
if (-not $formatAssignment) { throw 'Could not locate the production output-format table.' }
Invoke-Expression $formatAssignment.Extent.Text

$filterAssignment = $sourceAst.Find({
    param($node)
    $node -is [System.Management.Automation.Language.AssignmentStatementAst] -and
    $node.Left -is [System.Management.Automation.Language.VariableExpressionAst] -and
    $node.Left.VariablePath.UserPath -eq 'script:filters'
}, $true)
if (-not $filterAssignment) { throw 'Could not locate the production input filter.' }
Invoke-Expression $filterAssignment.Extent.Text
$script:supportedExtensions = @($script:filters.Split(';') | ForEach-Object { $_.Substring(1).ToLowerInvariant() })

$importFunction = $sourceAst.Find({
    param($node)
    $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
    $node.Name -eq 'Add-ImageFiles'
}, $true)
if (-not $importFunction) { throw 'Could not locate the production Add-ImageFiles function.' }
Invoke-Expression $importFunction.Extent.Text

$folderSearchToken = 'Get-ChildItem -LiteralPath $dialog.SelectedPath -File -Recurse'
if (-not $sourceText.Contains($folderSearchToken)) { throw 'Folder import no longer uses recursive file discovery.' }
if ($sourceText -notmatch '(?s)\$form\.Add_DragDrop\(\{.*?Add-ImageFiles \$dropped') { throw 'Form drag/drop no longer routes through Add-ImageFiles.' }
if ($sourceText -notmatch '(?s)\$list\.Add_DragDrop\(\{.*?Add-ImageFiles \$dropped') { throw 'List drag/drop no longer routes through Add-ImageFiles.' }

$convertEvent = $sourceAst.Find({
    param($node)
    $node -is [System.Management.Automation.Language.InvokeMemberExpressionAst] -and
    $node.Member.Value -eq 'Add_Click' -and
    $node.Expression.Extent.Text -eq '$convertButton'
}, $true)
if (-not $convertEvent -or $convertEvent.Arguments.Count -ne 1) { throw 'Could not locate the production Convert button event.' }
$convertBlock = $convertEvent.Arguments[0].ScriptBlock
$finalStatement = $convertBlock.EndBlock.Statements[-1]
if ($finalStatement.Extent.Text -notmatch 'MessageBox.*::Show') { throw 'Unexpected final statement in production conversion event.' }
$handlerText = $sourceText.Substring($convertBlock.Extent.StartOffset, $convertBlock.Extent.EndOffset - $convertBlock.Extent.StartOffset)
$cutAt = $finalStatement.Extent.StartOffset - $convertBlock.Extent.StartOffset
$handlerText = $handlerText.Substring(0, $cutAt) + "`r`n}"
$handlerErrors = $null
[System.Management.Automation.Language.Parser]::ParseInput($handlerText, [ref]$tokens, [ref]$handlerErrors) | Out-Null
if ($handlerErrors.Count -gt 0) { throw 'Could not prepare production conversion event for non-interactive validation.' }
$handlerBody = $handlerText.Substring(1, $handlerText.Length - 2)
$script:conversionHandler = [scriptblock]::Create($handlerBody)

function New-PatternBitmap([int]$Width, [int]$Height, [bool]$Transparent) {
    $bitmap = New-Object System.Drawing.Bitmap($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($y = 0; $y -lt $Height; $y++) {
        for ($x = 0; $x -lt $Width; $x++) {
            if ($Transparent -and $x -lt 8 -and $y -lt 8) {
                $bitmap.SetPixel($x, $y, [System.Drawing.Color]::Transparent)
            } else {
                $r = ($x * 37 + $y * 19 + 31) % 256
                $g = ($x * 13 + $y * 47 + 73) % 256
                $b = ($x * 53 + $y * 7 + 11) % 256
                $bitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $r, $g, $b))
            }
        }
    }
    return $bitmap
}

function New-TestEntry([string]$Path) {
    $file = Get-Item -LiteralPath $Path
    $row = New-Object System.Windows.Forms.ListViewItem($file.Name)
    [void]$row.SubItems.Add($file.Extension.TrimStart('.').ToUpperInvariant())
    [void]$row.SubItems.Add(('{0:N0} KB' -f ($file.Length / 1KB)))
    [void]$row.SubItems.Add('pending')
    return [pscustomobject]@{ Path = $file.FullName; Row = $row }
}

function Invoke-ProductionConversion([object[]]$Entries, [string]$FormatName, [string]$OutputDirectory, [int]$QualityValue = 92) {
    $script:items = New-Object System.Collections.ArrayList
    foreach ($entry in $Entries) { [void]$script:items.Add($entry) }
    $script:form = New-Object System.Windows.Forms.Form
    $script:formatBox = New-Object System.Windows.Forms.ComboBox
    foreach ($name in $script:formats.Keys) { [void]$script:formatBox.Items.Add([string]$name) }
    $formatNames = [string[]]@($script:formats.Keys)
    $formatIndex = [Array]::IndexOf($formatNames, $FormatName)
    if ($formatIndex -lt 0) { throw "Unknown format choice: $FormatName" }
    $script:formatBox.SelectedIndex = $formatIndex
    $script:outputBox = New-Object System.Windows.Forms.TextBox
    $script:outputBox.Text = $OutputDirectory
    $script:convertButton = New-Object System.Windows.Forms.Button
    $script:quality = New-Object System.Windows.Forms.TrackBar
    $script:quality.Minimum = 40
    $script:quality.Maximum = 100
    $script:quality.Value = $QualityValue
    $script:status = New-Object System.Windows.Forms.Label
    try {
        & $script:conversionHandler
        $rowStatuses = @($Entries | ForEach-Object { $_.Row.SubItems[3].Text })
        return [pscustomobject]@{ Status = $script:status.Text; RowStatuses = $rowStatuses }
    }
    finally {
        $script:form.Dispose()
        $script:formatBox.Dispose()
        $script:outputBox.Dispose()
        $script:convertButton.Dispose()
        $script:quality.Dispose()
        $script:status.Dispose()
    }
}

function Assert-ConversionCounts([string]$StatusText, [int]$ExpectedSuccess, [int]$ExpectedFailure, [string]$Context) {
    $numbers = [regex]::Matches($StatusText, '\d+')
    if ($numbers.Count -lt 2) { throw "$Context returned an unrecognized status: $StatusText" }
    $success = [int]$numbers[0].Value
    $failure = [int]$numbers[1].Value
    if ($success -ne $ExpectedSuccess -or $failure -ne $ExpectedFailure) {
        throw "$Context count mismatch: expected $ExpectedSuccess success/$ExpectedFailure failure; got $success/$failure. $StatusText"
    }
}

function New-IcoFile([string]$Path) {
    $width = 32
    $height = 32
    $xorBytes = $width * $height * 4
    $maskBytes = $height * 4
    $imageBytes = 40 + $xorBytes + $maskBytes
    $stream = [IO.File]::Create($Path)
    $writer = New-Object System.IO.BinaryWriter($stream)
    try {
        $writer.Write([UInt16]0)
        $writer.Write([UInt16]1)
        $writer.Write([UInt16]1)
        $writer.Write([byte]$width)
        $writer.Write([byte]$height)
        $writer.Write([byte]0)
        $writer.Write([byte]0)
        $writer.Write([UInt16]1)
        $writer.Write([UInt16]32)
        $writer.Write([UInt32]$imageBytes)
        $writer.Write([UInt32]22)
        $writer.Write([UInt32]40)
        $writer.Write([Int32]$width)
        $writer.Write([Int32]($height * 2))
        $writer.Write([UInt16]1)
        $writer.Write([UInt16]32)
        $writer.Write([UInt32]0)
        $writer.Write([UInt32]($xorBytes + $maskBytes))
        $writer.Write([Int32]0)
        $writer.Write([Int32]0)
        $writer.Write([UInt32]0)
        $writer.Write([UInt32]0)
        for ($y = $height - 1; $y -ge 0; $y--) {
            for ($x = 0; $x -lt $width; $x++) {
                $r = ($x * 37 + $y * 19 + 31) % 256
                $g = ($x * 13 + $y * 47 + 73) % 256
                $b = ($x * 53 + $y * 7 + 11) % 256
                $writer.Write([byte]$b)
                $writer.Write([byte]$g)
                $writer.Write([byte]$r)
                $writer.Write([byte]255)
            }
        }
        for ($i = 0; $i -lt $maskBytes; $i++) { $writer.Write([byte]0) }
    }
    finally { $writer.Dispose() }
}

$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('WIFC-V120-Acceptance-' + [Guid]::NewGuid().ToString('N'))
$inputRoot = Join-Path $testRoot 'inputs'
$outputRoot = Join-Path $testRoot 'outputs'
[void][IO.Directory]::CreateDirectory($inputRoot)
[void][IO.Directory]::CreateDirectory($outputRoot)
$fixtureBitmap = $null
$alphaBitmap = $null
$opaqueBitmap = $null
try {
    $fixtureBitmap = New-PatternBitmap 48 32 $false
    $alphaBitmap = New-PatternBitmap 48 32 $true
    $fixtures = New-Object System.Collections.ArrayList
    $definitions = @(
        @{ Name = 'sample_png'; Extension = '.png'; Format = [System.Drawing.Imaging.ImageFormat]::Png; Bitmap = $alphaBitmap },
        @{ Name = 'sample_jpg'; Extension = '.jpg'; Format = [System.Drawing.Imaging.ImageFormat]::Jpeg; Bitmap = $fixtureBitmap },
        @{ Name = 'sample_jpeg'; Extension = '.jpeg'; Format = [System.Drawing.Imaging.ImageFormat]::Jpeg; Bitmap = $fixtureBitmap },
        @{ Name = 'sample_jfif'; Extension = '.jfif'; Format = [System.Drawing.Imaging.ImageFormat]::Jpeg; Bitmap = $fixtureBitmap },
        @{ Name = 'sample_bmp'; Extension = '.bmp'; Format = [System.Drawing.Imaging.ImageFormat]::Bmp; Bitmap = $fixtureBitmap },
        @{ Name = 'sample_gif'; Extension = '.gif'; Format = [System.Drawing.Imaging.ImageFormat]::Gif; Bitmap = $fixtureBitmap },
        @{ Name = 'sample_tif'; Extension = '.tif'; Format = [System.Drawing.Imaging.ImageFormat]::Tiff; Bitmap = $fixtureBitmap },
        @{ Name = 'sample_tiff'; Extension = '.tiff'; Format = [System.Drawing.Imaging.ImageFormat]::Tiff; Bitmap = $fixtureBitmap }
    )
    foreach ($definition in $definitions) {
        $path = Join-Path $inputRoot ($definition.Name + $definition.Extension)
        $definition.Bitmap.Save($path, $definition.Format)
        [void]$fixtures.Add([pscustomobject]@{ Path = $path; Width = 48; Height = 32 })
    }
    $icoPath = Join-Path $inputRoot 'sample_ico.ico'
    New-IcoFile $icoPath
    [void]$fixtures.Add([pscustomobject]@{ Path = $icoPath; Width = 32; Height = 32 })

    foreach ($formatName in $script:formats.Keys) {
        $definition = $script:formats[$formatName]
        $outputDirectory = Join-Path $outputRoot ([IO.Path]::GetExtension('x' + $definition.Extension).TrimStart('.'))
        [void][IO.Directory]::CreateDirectory($outputDirectory)
        $entries = @($fixtures | ForEach-Object { New-TestEntry $_.Path })
        $result = Invoke-ProductionConversion -Entries $entries -FormatName $formatName -OutputDirectory $outputDirectory
        Assert-ConversionCounts $result.Status 9 0 "Output format $formatName"
        $files = @(Get-ChildItem -LiteralPath $outputDirectory -File)
        if ($files.Count -ne 9) { throw "Output format $formatName produced $($files.Count) files instead of 9." }
        foreach ($fixture in $fixtures) {
            $destination = Join-Path $outputDirectory ([IO.Path]::GetFileNameWithoutExtension($fixture.Path) + $definition.Extension)
            if (-not (Test-Path -LiteralPath $destination -PathType Leaf)) { throw "Missing output for $($fixture.Path): $destination" }
            $image = [System.Drawing.Image]::FromFile($destination)
            try {
                if ($image.Width -ne $fixture.Width -or $image.Height -ne $fixture.Height) { throw "Dimensions changed for $destination." }
                if ([string]$image.RawFormat.Guid -ne [string]$definition.Format.Guid) { throw "Reopened output format is wrong for $destination." }
            }
            finally { $image.Dispose() }
        }
        if ($definition.Extension -eq '.png') {
            $pngProbe = [System.Drawing.Image]::FromFile((Join-Path $outputDirectory 'sample_png.png'))
            try { if ($pngProbe.GetPixel(0, 0).A -ne 0) { throw 'PNG output did not preserve transparent pixels.' } }
            finally { $pngProbe.Dispose() }
        }
        if ($definition.Extension -eq '.jpg') {
            $jpgProbe = [System.Drawing.Image]::FromFile((Join-Path $outputDirectory 'sample_png.jpg'))
            try {
                $pixel = $jpgProbe.GetPixel(0, 0)
                if ($pixel.R -lt 220 -or $pixel.G -lt 220 -or $pixel.B -lt 220) { throw 'Transparent PNG pixels were not composited onto white for JPEG.' }
            }
            finally { $jpgProbe.Dispose() }
        }
        Write-Host ("PASS output {0}: 9 input extensions converted and reopened." -f $definition.Extension) -ForegroundColor Green
    }

    $nestedRoot = Join-Path $inputRoot 'nested'
    [void][IO.Directory]::CreateDirectory((Join-Path $nestedRoot 'one\two'))
    Copy-Item -LiteralPath $fixtures[0].Path -Destination (Join-Path $nestedRoot 'root.png')
    Copy-Item -LiteralPath $fixtures[1].Path -Destination (Join-Path $nestedRoot 'one\middle.jpg')
    Copy-Item -LiteralPath $fixtures[5].Path -Destination (Join-Path $nestedRoot 'one\two\deep.gif')
    $list = New-Object System.Windows.Forms.ListView
    $status = New-Object System.Windows.Forms.Label
    $script:items = New-Object System.Collections.ArrayList
    try {
        $discovered = @(Get-ChildItem -LiteralPath $nestedRoot -File -Recurse | Where-Object { $_.Extension.ToLowerInvariant() -in $script:supportedExtensions } | ForEach-Object { $_.FullName })
        Add-ImageFiles -Paths ([string[]]$discovered)
        Add-ImageFiles -Paths ([string[]]$discovered)
        if ($script:items.Count -ne 3 -or $list.Items.Count -ne 3) { throw "Recursive folder import/duplicate suppression mismatch: $($script:items.Count) items, $($list.Items.Count) rows." }
        Write-Host 'PASS recursive nested-folder discovery and duplicate import suppression.' -ForegroundColor Green
    }
    finally { $list.Dispose(); $status.Dispose() }

    $collisionSource = $fixtures[0].Path
    $collisionDirectory = Join-Path $outputRoot 'collision'
    [void][IO.Directory]::CreateDirectory($collisionDirectory)
    $existing = Join-Path $collisionDirectory 'sample_png.png'
    Copy-Item -LiteralPath $collisionSource -Destination $existing
    $beforeHash = (Get-FileHash -LiteralPath $existing -Algorithm SHA256).Hash
    $collisionResult = Invoke-ProductionConversion -Entries @((New-TestEntry $collisionSource)) -FormatName ([string]@($script:formats.Keys)[0]) -OutputDirectory $collisionDirectory
    Assert-ConversionCounts $collisionResult.Status 1 0 'No-overwrite test'
    $alternate = Join-Path $collisionDirectory 'sample_png_1.png'
    if (-not (Test-Path -LiteralPath $alternate -PathType Leaf)) { throw 'Converter did not create a numbered alternative when output already existed.' }
    if ((Get-FileHash -LiteralPath $existing -Algorithm SHA256).Hash -ne $beforeHash) { throw 'Converter overwrote an existing output file.' }
    Write-Host 'PASS existing output is preserved and a numbered filename is used.' -ForegroundColor Green

    $corruptDirectory = Join-Path $outputRoot 'corrupt-isolation'
    [void][IO.Directory]::CreateDirectory($corruptDirectory)
    $corruptPath = Join-Path $inputRoot 'corrupt.png'
    [IO.File]::WriteAllBytes($corruptPath, [Text.Encoding]::ASCII.GetBytes('not an image'))
    $corruptEntries = @((New-TestEntry $fixtures[0].Path), (New-TestEntry $corruptPath))
    $corruptResult = Invoke-ProductionConversion -Entries $corruptEntries -FormatName ([string]@($script:formats.Keys)[0]) -OutputDirectory $corruptDirectory
    Assert-ConversionCounts $corruptResult.Status 1 1 'Corrupt-file isolation test'
    if (-not (Test-Path -LiteralPath (Join-Path $corruptDirectory 'sample_png.png') -PathType Leaf)) { throw 'A corrupt input prevented a valid image from converting.' }
    Write-Host 'PASS corrupt image is isolated while a valid image in the same batch converts.' -ForegroundColor Green

    $batchDirectory = Join-Path $outputRoot 'batch-100'
    [void][IO.Directory]::CreateDirectory($batchDirectory)
    $batchBitmap = New-PatternBitmap 24 16 $false
    $batchEntries = New-Object System.Collections.ArrayList
    try {
        for ($i = 1; $i -le 100; $i++) {
            $path = Join-Path $inputRoot ('batch-{0:D3}.png' -f $i)
            $batchBitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
            [void]$batchEntries.Add((New-TestEntry $path))
        }
    }
    finally { $batchBitmap.Dispose() }
    $batchFormat = [string]@($script:formats.Keys)[0]
    $batchResult = Invoke-ProductionConversion -Entries ([object[]]$batchEntries.ToArray()) -FormatName $batchFormat -OutputDirectory $batchDirectory
    Assert-ConversionCounts $batchResult.Status 100 0 '100-image batch test'
    $batchOutputs = @(Get-ChildItem -LiteralPath $batchDirectory -File -Filter '*.png')
    if ($batchOutputs.Count -ne 100) { throw "100-image batch produced $($batchOutputs.Count) outputs." }
    $batchProbe = [System.Drawing.Image]::FromFile($batchOutputs[0].FullName)
    try { if ($batchProbe.Width -ne 24 -or $batchProbe.Height -ne 16) { throw '100-image batch output failed reopen/dimension validation.' } }
    finally { $batchProbe.Dispose() }
    Write-Host 'PASS 100-image batch converted; all 100 outputs exist and a sample reopened.' -ForegroundColor Green

    $qualityInput = Join-Path $inputRoot 'quality.png'
    $qualityBitmap = New-Object System.Drawing.Bitmap(256, 256, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $random = New-Object System.Random(73129)
    for ($y = 0; $y -lt 256; $y++) {
        for ($x = 0; $x -lt 256; $x++) {
            $qualityBitmap.SetPixel($x, $y, [System.Drawing.Color]::FromArgb(255, $random.Next(256), $random.Next(256), $random.Next(256)))
        }
    }
    try { $qualityBitmap.Save($qualityInput, [System.Drawing.Imaging.ImageFormat]::Png) }
    finally { $qualityBitmap.Dispose() }
    $jpegFormat = @($script:formats.Keys | Where-Object { $script:formats[$_].Extension -eq '.jpg' })[0]
    $lowDirectory = Join-Path $outputRoot 'quality-40'
    $highDirectory = Join-Path $outputRoot 'quality-100'
    [void][IO.Directory]::CreateDirectory($lowDirectory)
    [void][IO.Directory]::CreateDirectory($highDirectory)
    $lowResult = Invoke-ProductionConversion -Entries @((New-TestEntry $qualityInput)) -FormatName ([string]$jpegFormat) -OutputDirectory $lowDirectory -QualityValue 40
    $highResult = Invoke-ProductionConversion -Entries @((New-TestEntry $qualityInput)) -FormatName ([string]$jpegFormat) -OutputDirectory $highDirectory -QualityValue 100
    Assert-ConversionCounts $lowResult.Status 1 0 'JPEG quality 40 test'
    Assert-ConversionCounts $highResult.Status 1 0 'JPEG quality 100 test'
    $lowSize = (Get-Item -LiteralPath (Join-Path $lowDirectory 'quality.jpg')).Length
    $highSize = (Get-Item -LiteralPath (Join-Path $highDirectory 'quality.jpg')).Length
    if ($lowSize -ge $highSize) { throw "JPEG quality slider did not reduce file size at 40 (low=$lowSize, high=$highSize)." }
    Write-Host 'PASS JPEG quality 40 produces a smaller file than quality 100.' -ForegroundColor Green

    Write-Host 'ALL CONVERSION ACCEPTANCE TESTS PASSED.' -ForegroundColor Green
}
finally {
    if ($fixtureBitmap) { $fixtureBitmap.Dispose() }
    if ($alphaBitmap) { $alphaBitmap.Dispose() }
    if ($opaqueBitmap) { $opaqueBitmap.Dispose() }
    if (Test-Path -LiteralPath $testRoot) { Remove-Item -LiteralPath $testRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
