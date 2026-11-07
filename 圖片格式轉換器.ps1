Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:items = New-Object System.Collections.ArrayList
$script:formats = [ordered]@{
    'PNG（保留透明背景）' = @{ Extension = '.png'; Format = [System.Drawing.Imaging.ImageFormat]::Png }
    'JPEG（白色背景）' = @{ Extension = '.jpg'; Format = [System.Drawing.Imaging.ImageFormat]::Jpeg }
    'BMP' = @{ Extension = '.bmp'; Format = [System.Drawing.Imaging.ImageFormat]::Bmp }
    'GIF（靜態）' = @{ Extension = '.gif'; Format = [System.Drawing.Imaging.ImageFormat]::Gif }
    'TIFF' = @{ Extension = '.tiff'; Format = [System.Drawing.Imaging.ImageFormat]::Tiff }
}
$script:filters = '*.png;*.jpg;*.jpeg;*.jfif;*.bmp;*.gif;*.tif;*.tiff;*.ico'
$script:defaultOutput = Join-Path ([Environment]::GetFolderPath('MyDocuments')) '統一格式\轉換結果'

$form = New-Object System.Windows.Forms.Form
$form.Text = '圖片格式轉換器'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(980, 690)
$form.MinimumSize = New-Object System.Drawing.Size(820, 580)
$form.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$form.BackColor = [System.Drawing.Color]::FromArgb(246, 247, 249)
$form.AllowDrop = $true

$title = New-Object System.Windows.Forms.Label
$title.Text = '圖片格式轉換器'
$title.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 18, [System.Drawing.FontStyle]::Bold)
$title.Location = New-Object System.Drawing.Point(22, 18)
$title.Size = New-Object System.Drawing.Size(450, 38)
$form.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = '一次加入多張圖片，統一轉成你需要的格式。支援 PNG、JPEG、JFIF、BMP、GIF、TIFF、ICO 輸入。'
$subtitle.Location = New-Object System.Drawing.Point(25, 58)
$subtitle.Size = New-Object System.Drawing.Size(900, 24)
$subtitle.ForeColor = [System.Drawing.Color]::FromArgb(90, 98, 108)
$form.Controls.Add($subtitle)

$list = New-Object System.Windows.Forms.ListView
$list.Location = New-Object System.Drawing.Point(24, 96)
$list.Size = New-Object System.Drawing.Size(914, 330)
$list.Anchor = 'Top,Bottom,Left,Right'
$list.View = [System.Windows.Forms.View]::Details
$list.FullRowSelect = $true
$list.GridLines = $true
$list.HideSelection = $false
$list.AllowDrop = $true
[void]$list.Columns.Add('檔案名稱', 470)
[void]$list.Columns.Add('原始格式', 130)
[void]$list.Columns.Add('大小', 110)
[void]$list.Columns.Add('狀態', 180)
$form.Controls.Add($list)

$addButton = New-Object System.Windows.Forms.Button
$addButton.Text = '加入圖片…'
$addButton.Location = New-Object System.Drawing.Point(24, 440)
$addButton.Size = New-Object System.Drawing.Size(112, 34)
$form.Controls.Add($addButton)

$folderButton = New-Object System.Windows.Forms.Button
$folderButton.Text = '加入資料夾…'
$folderButton.Location = New-Object System.Drawing.Point(144, 440)
$folderButton.Size = New-Object System.Drawing.Size(120, 34)
$form.Controls.Add($folderButton)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Text = '移除選取'
$removeButton.Location = New-Object System.Drawing.Point(272, 440)
$removeButton.Size = New-Object System.Drawing.Size(105, 34)
$form.Controls.Add($removeButton)

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = '清空清單'
$clearButton.Location = New-Object System.Drawing.Point(385, 440)
$clearButton.Size = New-Object System.Drawing.Size(105, 34)
$form.Controls.Add($clearButton)

$formatLabel = New-Object System.Windows.Forms.Label
$formatLabel.Text = '轉換格式：'
$formatLabel.Location = New-Object System.Drawing.Point(25, 500)
$formatLabel.Size = New-Object System.Drawing.Size(80, 25)
$form.Controls.Add($formatLabel)

$formatBox = New-Object System.Windows.Forms.ComboBox
$formatBox.DropDownStyle = 'DropDownList'
$formatBox.Location = New-Object System.Drawing.Point(105, 496)
$formatBox.Size = New-Object System.Drawing.Size(220, 28)
foreach ($name in $script:formats.Keys) { [void]$formatBox.Items.Add($name) }
$formatBox.SelectedIndex = 0
$form.Controls.Add($formatBox)

$qualityLabel = New-Object System.Windows.Forms.Label
$qualityLabel.Text = 'JPEG 品質：'
$qualityLabel.Location = New-Object System.Drawing.Point(348, 500)
$qualityLabel.Size = New-Object System.Drawing.Size(88, 25)
$form.Controls.Add($qualityLabel)

$quality = New-Object System.Windows.Forms.TrackBar
$quality.Location = New-Object System.Drawing.Point(436, 484)
$quality.Size = New-Object System.Drawing.Size(190, 45)
$quality.Minimum = 40
$quality.Maximum = 100
$quality.Value = 92
$quality.TickFrequency = 10
$quality.SmallChange = 1
$quality.LargeChange = 5
$form.Controls.Add($quality)

$qualityValue = New-Object System.Windows.Forms.Label
$qualityValue.Text = '92'
$qualityValue.Location = New-Object System.Drawing.Point(630, 500)
$qualityValue.Size = New-Object System.Drawing.Size(35, 25)
$form.Controls.Add($qualityValue)
$quality.Add_ValueChanged({ $qualityValue.Text = [string]$quality.Value })

$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = '輸出位置：'
$outputLabel.Location = New-Object System.Drawing.Point(25, 548)
$outputLabel.Size = New-Object System.Drawing.Size(80, 25)
$form.Controls.Add($outputLabel)

$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(105, 544)
$outputBox.Size = New-Object System.Drawing.Size(690, 27)
$outputBox.Anchor = 'Bottom,Left,Right'
$outputBox.Text = $script:defaultOutput
$form.Controls.Add($outputBox)

$outputButton = New-Object System.Windows.Forms.Button
$outputButton.Text = '瀏覽…'
$outputButton.Location = New-Object System.Drawing.Point(805, 541)
$outputButton.Size = New-Object System.Drawing.Size(90, 30)
$outputButton.Anchor = 'Bottom,Right'
$form.Controls.Add($outputButton)

$status = New-Object System.Windows.Forms.Label
$status.Text = '尚未加入圖片。也可以直接將圖片拖曳到清單中。'
$status.Location = New-Object System.Drawing.Point(25, 600)
$status.Size = New-Object System.Drawing.Size(650, 28)
$status.Anchor = 'Bottom,Left'
$status.ForeColor = [System.Drawing.Color]::FromArgb(80, 88, 98)
$form.Controls.Add($status)

$convertButton = New-Object System.Windows.Forms.Button
$convertButton.Text = '開始轉換'
$convertButton.Location = New-Object System.Drawing.Point(790, 590)
$convertButton.Size = New-Object System.Drawing.Size(148, 42)
$convertButton.Anchor = 'Bottom,Right'
$convertButton.BackColor = [System.Drawing.Color]::FromArgb(0, 103, 192)
$convertButton.ForeColor = [System.Drawing.Color]::White
$convertButton.FlatStyle = 'Flat'
$convertButton.FlatAppearance.BorderSize = 0
$form.Controls.Add($convertButton)

function Add-ImageFiles([string[]]$Paths) {
    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        $ext = [IO.Path]::GetExtension($path).ToLowerInvariant()
        if ($ext -notin @('.png','.jpg','.jpeg','.jfif','.bmp','.gif','.tif','.tiff','.ico')) { continue }
        $already = $false
        foreach ($existing in $script:items) { if ([string]::Equals($existing.Path, $path, [StringComparison]::OrdinalIgnoreCase)) { $already = $true; break } }
        if ($already) { continue }
        $file = Get-Item -LiteralPath $path -ErrorAction SilentlyContinue
        if (-not $file) { continue }
        $item = [pscustomobject]@{ Path = $file.FullName; Row = $null }
        [void]$script:items.Add($item)
        $row = New-Object System.Windows.Forms.ListViewItem($file.Name)
        [void]$row.SubItems.Add($ext.TrimStart('.').ToUpperInvariant())
        [void]$row.SubItems.Add(('{0:N0} KB' -f ($file.Length / 1KB)))
        [void]$row.SubItems.Add('待轉換')
        $row.Tag = $item
        $item.Row = $row
        [void]$list.Items.Add($row)
    }
    $status.Text = "清單共 $($script:items.Count) 張圖片。"
}

$addButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Title = '選取要轉換的圖片'
    $dialog.Filter = '圖片檔案|*.png;*.jpg;*.jpeg;*.jfif;*.bmp;*.gif;*.tif;*.tiff;*.ico|所有檔案|*.*'
    $dialog.Multiselect = $true
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { Add-ImageFiles $dialog.FileNames }
})

$folderButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = '選取包含圖片的資料夾（搜尋此資料夾及其子資料夾）'
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $found = Get-ChildItem -LiteralPath $dialog.SelectedPath -File -Recurse -ErrorAction SilentlyContinue | Where-Object { $_.Extension.ToLowerInvariant() -in @('.png','.jpg','.jpeg','.jfif','.bmp','.gif','.tif','.tiff','.ico') } | ForEach-Object { $_.FullName }
        Add-ImageFiles @($found)
    }
})

$removeButton.Add_Click({
    foreach ($row in @($list.SelectedItems)) { [void]$script:items.Remove($row.Tag); [void]$list.Items.Remove($row) }
    $status.Text = "清單共 $($script:items.Count) 張圖片。"
})
$clearButton.Add_Click({ $list.Items.Clear(); $script:items.Clear(); $status.Text = '清單已清空。' })
$outputButton.Add_Click({
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = '選取轉換後圖片的儲存資料夾'
    if (Test-Path -LiteralPath $outputBox.Text) { $dialog.SelectedPath = $outputBox.Text }
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) { $outputBox.Text = $dialog.SelectedPath }
})

$form.Add_DragEnter({ if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) { $_.Effect = [Windows.Forms.DragDropEffects]::Copy } else { $_.Effect = [Windows.Forms.DragDropEffects]::None } })
$form.Add_DragDrop({ $dropped = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop); Add-ImageFiles $dropped })
$list.Add_DragEnter({ if ($_.Data.GetDataPresent([Windows.Forms.DataFormats]::FileDrop)) { $_.Effect = [Windows.Forms.DragDropEffects]::Copy } })
$list.Add_DragDrop({ $dropped = $_.Data.GetData([Windows.Forms.DataFormats]::FileDrop); Add-ImageFiles $dropped })

$convertButton.Add_Click({
    if ($script:items.Count -eq 0) { [void][System.Windows.Forms.MessageBox]::Show('請先加入至少一張圖片。', '尚未加入圖片', 'OK', 'Information'); return }
    $outDir = $outputBox.Text.Trim()
    if ([string]::IsNullOrWhiteSpace($outDir)) { [void][System.Windows.Forms.MessageBox]::Show('請指定輸出資料夾。', '缺少輸出位置', 'OK', 'Warning'); return }
    try { [void][IO.Directory]::CreateDirectory($outDir) } catch { [void][System.Windows.Forms.MessageBox]::Show("無法建立輸出資料夾：`r`n$($_.Exception.Message)", '資料夾錯誤', 'OK', 'Error'); return }
    $choice = [string]$formatBox.SelectedItem
    $target = $script:formats[$choice]
    $converted = 0; $failed = 0
    $convertButton.Enabled = $false
    $form.UseWaitCursor = $true
    try {
        foreach ($entry in @($script:items)) {
            $form.Refresh()
            $entry.Row.SubItems[3].Text = '轉換中…'
            $src = $null; $bitmap = $null; $graphics = $null
            try {
                $src = [System.Drawing.Image]::FromFile($entry.Path)
                $base = [IO.Path]::GetFileNameWithoutExtension($entry.Path)
                $destination = Join-Path $outDir ($base + $target.Extension)
                $index = 1
                while (Test-Path -LiteralPath $destination) { $destination = Join-Path $outDir ("{0}_{1}{2}" -f $base, $index, $target.Extension); $index++ }
                if ($target.Extension -eq '.jpg') {
                    $bitmap = New-Object System.Drawing.Bitmap($src.Width, $src.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
                    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
                    $graphics.Clear([System.Drawing.Color]::White)
                    $graphics.DrawImage($src, 0, 0, $src.Width, $src.Height)
                    $encoder = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' } | Select-Object -First 1
                    $params = New-Object System.Drawing.Imaging.EncoderParameters(1)
                    $params.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter([System.Drawing.Imaging.Encoder]::Quality, [long]$quality.Value)
                    $bitmap.Save($destination, $encoder, $params)
                    $params.Dispose()
                } else { $src.Save($destination, $target.Format) }
                $entry.Row.SubItems[3].Text = '完成'
                $entry.Row.SubItems[3].ForeColor = [System.Drawing.Color]::FromArgb(16, 124, 16)
                $converted++
            } catch {
                $entry.Row.SubItems[3].Text = '失敗：' + $_.Exception.Message
                $entry.Row.SubItems[3].ForeColor = [System.Drawing.Color]::FromArgb(196, 43, 28)
                $failed++
            } finally {
                if ($graphics) { $graphics.Dispose() }
                if ($bitmap) { $bitmap.Dispose() }
                if ($src) { $src.Dispose() }
            }
        }
    } finally { $form.UseWaitCursor = $false; $convertButton.Enabled = $true }
    $status.Text = "轉換完成：成功 $converted 張，失敗 $failed 張。"
    [void][System.Windows.Forms.MessageBox]::Show("轉換完成！`r`n成功：$converted 張`r`n失敗：$failed 張`r`n`r`n輸出位置：$outDir", '轉換結果', 'OK', 'Information')
})

[void]$form.ShowDialog()
