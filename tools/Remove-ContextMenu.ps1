$ErrorActionPreference = 'Stop'

$registryPath = 'Registry::HKEY_CURRENT_USER\Software\Classes\SystemFileAssociations\image\shell\WindowsImageFormatConverter'
if (Test-Path -LiteralPath $registryPath) {
    Remove-Item -LiteralPath $registryPath -Recurse -Force
    Write-Host '已移除圖片格式轉換器的檔案總管右鍵選單。' -ForegroundColor Green
}
else {
    Write-Host '目前使用者的右鍵選單項目不存在，無需移除。'
}
