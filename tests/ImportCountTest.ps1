$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$sourcePath = Join-Path $projectRoot '圖片格式轉換器.ps1'
if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
    throw "主程式不存在：$sourcePath"
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$tempRoot = Join-Path ([IO.Path]::GetTempPath()) ('image-converter-import-' + [Guid]::NewGuid().ToString('N'))
$bitmap = $null
$list = $null
$status = $null
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

try {
    $bitmap = New-Object System.Drawing.Bitmap(3, 3)
    $bitmap.SetPixel(0, 0, [System.Drawing.Color]::CornflowerBlue)

    $paths = New-Object System.Collections.ArrayList
    for ($i = 1; $i -le 250; $i++) {
        $extension = if ($i -le 246) { '.jpg' } else { '.jfif' }
        $path = Join-Path $tempRoot ('sample-{0:D2}{1}' -f $i, $extension)
        $bitmap.Save($path, [System.Drawing.Imaging.ImageFormat]::Jpeg)
        [void]$paths.Add($path)
    }

    $tokens = $null
    $parseErrors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($sourcePath, [ref]$tokens, [ref]$parseErrors)
    if ($parseErrors.Count -gt 0) {
        $details = ($parseErrors | ForEach-Object { $_.Message }) -join [Environment]::NewLine
        throw "PowerShell 語法錯誤：`n$details"
    }

    $functionAst = $ast.Find({
        param($node)
        $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq 'Add-ImageFiles'
    }, $true)
    if (-not $functionAst) {
        throw '找不到主程式的 Add-ImageFiles 函式。'
    }

    $sourceText = [IO.File]::ReadAllText($sourcePath, [Text.Encoding]::UTF8)
    $functionText = $sourceText.Substring($functionAst.Extent.StartOffset, $functionAst.Extent.EndOffset - $functionAst.Extent.StartOffset)
    $script:items = New-Object System.Collections.ArrayList
    $list = New-Object System.Windows.Forms.ListView
    $status = New-Object System.Windows.Forms.Label
    Invoke-Expression $functionText

    Add-ImageFiles -Paths ([string[]]$paths.ToArray())
    if ($script:items.Count -ne 250 -or $list.Items.Count -ne 250) {
        throw "250 張回歸集匯入筆數不符：資料項目 $($script:items.Count) 張，清單列 $($list.Items.Count) 列。"
    }

    $jfifCount = @($script:items | Where-Object { [IO.Path]::GetExtension($_.Path).Equals('.jfif', [StringComparison]::OrdinalIgnoreCase) }).Count
    if ($jfifCount -ne 4) {
        throw "JFIF 檔案數量不符：預期 4 張，實際 $jfifCount 張。"
    }

    Add-ImageFiles -Paths ([string[]]$paths.ToArray())
    if ($script:items.Count -ne 250 -or $list.Items.Count -ne 250) {
        throw '重複匯入後出現重複列或計數改變。'
    }
    Push-Location $tempRoot
    try { Add-ImageFiles -Paths @('.\sample-001.jpg') }
    finally { Pop-Location }
    if ($script:items.Count -ne 250 -or $list.Items.Count -ne 250) {
        throw '以相對路徑重複加入既有圖片後，清單筆數發生變化。'
    }

    Write-Host 'Import-count regression passed: 250/250 JPG+JFIF images imported; duplicate and relative-alias paths ignored.' -ForegroundColor Green
}
finally {
    if ($list) { $list.Dispose() }
    if ($status) { $status.Dispose() }
    if ($bitmap) { $bitmap.Dispose() }
    if (Test-Path -LiteralPath $tempRoot) { Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
