Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()
$script:startupPaths = @($args | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) })

# Explorer may start one process per selected file even for a Player verb.
# Route later invocations through a per-user queue to the first GUI instance.
$instanceSuffix = [Environment]::GetEnvironmentVariable('WIFC_TEST_INSTANCE_SUFFIX')
$safeInstanceSuffix = ''
if (-not [string]::IsNullOrWhiteSpace($instanceSuffix)) {
    $safeInstanceSuffix = '_' + [regex]::Replace($instanceSuffix, '[^A-Za-z0-9_]', '_')
}
$userSid = [Security.Principal.WindowsIdentity]::GetCurrent().User.Value
$userKey = [regex]::Replace($userSid, '[^A-Za-z0-9_]', '_')
$appMutexName = "Local\WindowsImageFormatConverter_$userKey$safeInstanceSuffix"
$queueMutexName = "Local\WindowsImageFormatConverterQueue_$userKey$safeInstanceSuffix"
$appDataDirectory = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'WindowsImageFormatConverter'
[void][IO.Directory]::CreateDirectory($appDataDirectory)
$script:requestQueuePath = Join-Path $appDataDirectory "pending_$userKey$safeInstanceSuffix.txt"
$script:instanceMutex = New-Object System.Threading.Mutex($false, $appMutexName)
$script:queueMutex = New-Object System.Threading.Mutex($false, $queueMutexName)
$script:ownsInstanceMutex = $false
$queueMutexAcquired = $false
$script:utf8NoBom = New-Object System.Text.UTF8Encoding($false)

try {
    try { $queueMutexAcquired = $script:queueMutex.WaitOne(10000) }
    catch [System.Threading.AbandonedMutexException] { $queueMutexAcquired = $true }
    if (-not $queueMutexAcquired) { throw '等待圖片佇列鎖定逾時，請稍後再試。' }

    $isFirstInstance = $false
    try { $isFirstInstance = $script:instanceMutex.WaitOne(0) }
    catch [System.Threading.AbandonedMutexException] { $isFirstInstance = $true }

    if ($isFirstInstance) {
        $script:ownsInstanceMutex = $true
        $queuedPaths = New-Object System.Collections.ArrayList
        if (Test-Path -LiteralPath $script:requestQueuePath -PathType Leaf) {
            foreach ($request in [IO.File]::ReadAllLines($script:requestQueuePath, $script:utf8NoBom)) {
                if ($request.StartsWith('P:')) {
                    try {
                        $queuedPath = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($request.Substring(2)))
                        if (-not [string]::IsNullOrWhiteSpace($queuedPath)) { [void]$queuedPaths.Add($queuedPath) }
                    } catch { }
                }
            }
            [IO.File]::WriteAllText($script:requestQueuePath, '', $script:utf8NoBom)
        }
        if ($queuedPaths.Count -gt 0) { $script:startupPaths = @($script:startupPaths) + @($queuedPaths.ToArray()) }
    }
    else {
        $requests = New-Object System.Collections.ArrayList
        foreach ($path in $script:startupPaths) {
            $encodedPath = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes([string]$path))
            [void]$requests.Add('P:' + $encodedPath)
        }
        if ($requests.Count -eq 0) { [void]$requests.Add('A:') }
        [IO.File]::AppendAllLines($script:requestQueuePath, [string[]]$requests.ToArray(), $script:utf8NoBom)
    }
}
finally {
    if ($queueMutexAcquired) { $script:queueMutex.ReleaseMutex() }
}

if (-not $script:ownsInstanceMutex) {
    $script:queueMutex.Dispose()
    $script:instanceMutex.Dispose()
    return
}

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

$script:uiColors = [ordered]@{
    Background = [System.Drawing.Color]::FromArgb(255, 255, 255)
    Surface = [System.Drawing.Color]::FromArgb(255, 255, 255)
    SurfaceRaised = [System.Drawing.Color]::FromArgb(247, 247, 247)
    Border = [System.Drawing.Color]::FromArgb(216, 216, 216)
    Divider = [System.Drawing.Color]::FromArgb(232, 232, 232)
    Text = [System.Drawing.Color]::FromArgb(20, 20, 20)
    Secondary = [System.Drawing.Color]::FromArgb(74, 74, 74)
    Muted = [System.Drawing.Color]::FromArgb(105, 105, 105)
    Accent = [System.Drawing.Color]::FromArgb(20, 20, 20)
    AccentHover = [System.Drawing.Color]::FromArgb(55, 55, 55)
    Success = [System.Drawing.Color]::FromArgb(27, 111, 58)
    Warning = [System.Drawing.Color]::FromArgb(133, 86, 0)
    Error = [System.Drawing.Color]::FromArgb(180, 35, 24)
    Info = [System.Drawing.Color]::FromArgb(49, 86, 120)
}

function Set-UiCornerRadius([System.Windows.Forms.Control]$Control, [int]$Radius) {
    if ($null -eq $Control -or $Control.Width -lt 1 -or $Control.Height -lt 1) { return }
    $corner = [Math]::Max(2, [Math]::Min($Radius, [int][Math]::Floor([Math]::Min($Control.Width, $Control.Height) / 2)))
    $diameter = $corner * 2
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    try {
        $path.AddArc(0, 0, $diameter, $diameter, 180, 90)
        $path.AddArc($Control.Width - $diameter, 0, $diameter, $diameter, 270, 90)
        $path.AddArc($Control.Width - $diameter, $Control.Height - $diameter, $diameter, $diameter, 0, 90)
        $path.AddArc(0, $Control.Height - $diameter, $diameter, $diameter, 90, 90)
        $path.CloseFigure()
        $newRegion = New-Object System.Drawing.Region($path)
        $oldRegion = $Control.Region
        $Control.Region = $newRegion
        if ($oldRegion) { $oldRegion.Dispose() }
    }
    finally { $path.Dispose() }
}

$form = New-Object System.Windows.Forms.Form
$form.Text = '圖片格式轉換器'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(1120, 820)
$form.MinimumSize = New-Object System.Drawing.Size(900, 680)
$form.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$form.BackColor = $script:uiColors.Background
$form.ForeColor = $script:uiColors.Text
$form.AllowDrop = $true
$form.KeyPreview = $true
$form.AutoScaleMode = [System.Windows.Forms.AutoScaleMode]::Dpi

$contentPanel = New-Object System.Windows.Forms.Panel
$contentPanel.Dock = 'Fill'
$contentPanel.Padding = [System.Windows.Forms.Padding]::new(24, 20, 24, 20)
$contentPanel.BackColor = $script:uiColors.Background
$form.Controls.Add($contentPanel)

$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = 'Top'
$headerPanel.Height = 92
$headerPanel.BackColor = $script:uiColors.Surface
$form.Controls.Add($headerPanel)
$form.Controls.SetChildIndex($contentPanel, 0)
$form.Controls.SetChildIndex($headerPanel, 1)

$title = New-Object System.Windows.Forms.Label
$title.Text = '圖片格式轉換器'
$title.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 21, [System.Drawing.FontStyle]::Bold)
$title.ForeColor = $script:uiColors.Text
$title.Location = New-Object System.Drawing.Point(26, 14)
$title.Size = New-Object System.Drawing.Size(570, 38)
$headerPanel.Controls.Add($title)

$subtitle = New-Object System.Windows.Forms.Label
$subtitle.Text = '批次整理，格式轉換一目了然。'
$subtitle.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$subtitle.ForeColor = $script:uiColors.Secondary
$subtitle.Location = New-Object System.Drawing.Point(28, 54)
$subtitle.Size = New-Object System.Drawing.Size(500, 22)
$headerPanel.Controls.Add($subtitle)

$localBadge = New-Object System.Windows.Forms.Label
$localBadge.Text = '本機處理'
$localBadge.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$localBadge.ForeColor = $script:uiColors.Secondary
$localBadge.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$localBadge.Location = New-Object System.Drawing.Point(930, 32)
$localBadge.Size = New-Object System.Drawing.Size(150, 26)
$localBadge.Anchor = 'Top,Right'
$headerPanel.Controls.Add($localBadge)

$bodyLayout = New-Object System.Windows.Forms.TableLayoutPanel
$bodyLayout.Dock = 'Fill'
$bodyLayout.ColumnCount = 1
$bodyLayout.RowCount = 7
$bodyLayout.Margin = [System.Windows.Forms.Padding]::Empty
$bodyLayout.Padding = [System.Windows.Forms.Padding]::Empty
$bodyLayout.BackColor = $script:uiColors.Background
[void]$bodyLayout.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 100))
[void]$bodyLayout.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 34))
[void]$bodyLayout.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 48))
[void]$bodyLayout.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Percent, 100))
[void]$bodyLayout.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 38))
[void]$bodyLayout.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 78))
[void]$bodyLayout.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 56))
[void]$bodyLayout.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 64))
$contentPanel.Controls.Add($bodyLayout)

$sectionHeader = New-Object System.Windows.Forms.Panel
$sectionHeader.Dock = 'Fill'
$sectionHeader.BackColor = $script:uiColors.Background
$bodyLayout.Controls.Add($sectionHeader, 0, 0)

$listTitle = New-Object System.Windows.Forms.Label
$listTitle.Text = '圖片清單'
$listTitle.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 12, [System.Drawing.FontStyle]::Bold)
$listTitle.ForeColor = $script:uiColors.Text
$listTitle.Location = New-Object System.Drawing.Point(0, 2)
$listTitle.Size = New-Object System.Drawing.Size(250, 28)
$sectionHeader.Controls.Add($listTitle)

$script:imageCountLabel = New-Object System.Windows.Forms.Label
$script:imageCountLabel.Text = '0 張圖片'
$script:imageCountLabel.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$script:imageCountLabel.ForeColor = $script:uiColors.Secondary
$script:imageCountLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$script:imageCountLabel.Location = New-Object System.Drawing.Point(850, 3)
$script:imageCountLabel.Size = New-Object System.Drawing.Size(150, 25)
$script:imageCountLabel.Anchor = 'Top,Right'
$sectionHeader.Controls.Add($script:imageCountLabel)

$toolbar = New-Object System.Windows.Forms.FlowLayoutPanel
$toolbar.Dock = 'Fill'
$toolbar.FlowDirection = [System.Windows.Forms.FlowDirection]::LeftToRight
$toolbar.WrapContents = $false
$toolbar.AutoScroll = $false
$toolbar.Padding = [System.Windows.Forms.Padding]::Empty
$toolbar.Margin = [System.Windows.Forms.Padding]::Empty
$toolbar.BackColor = $script:uiColors.Background
$bodyLayout.Controls.Add($toolbar, 0, 1)

$addButton = New-Object System.Windows.Forms.Button
$addButton.Text = '加入圖片…'
$addButton.Size = New-Object System.Drawing.Size(144, 40)
$addButton.Margin = [System.Windows.Forms.Padding]::new(0, 3, 10, 3)

$folderButton = New-Object System.Windows.Forms.Button
$folderButton.Text = '加入資料夾…'
$folderButton.Size = New-Object System.Drawing.Size(154, 40)
$folderButton.Margin = [System.Windows.Forms.Padding]::new(0, 3, 10, 3)

$removeButton = New-Object System.Windows.Forms.Button
$removeButton.Text = '移除選取'
$removeButton.Size = New-Object System.Drawing.Size(112, 40)
$removeButton.Margin = [System.Windows.Forms.Padding]::new(0, 3, 4, 3)

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = '清空清單'
$clearButton.Size = New-Object System.Drawing.Size(104, 40)
$clearButton.Margin = [System.Windows.Forms.Padding]::new(0, 3, 4, 3)

foreach ($button in @($addButton, $folderButton, $removeButton, $clearButton)) {
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.UseVisualStyleBackColor = $false
    $button.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
    $button.ForeColor = $script:uiColors.Text
    $button.Cursor = [System.Windows.Forms.Cursors]::Hand
    $button.FlatAppearance.BorderColor = $script:uiColors.Border
    $button.FlatAppearance.BorderSize = 1
    $button.FlatAppearance.MouseOverBackColor = $script:uiColors.SurfaceRaised
    $button.FlatAppearance.MouseDownBackColor = $script:uiColors.Border
}
$addButton.BackColor = $script:uiColors.Accent
$addButton.ForeColor = [System.Drawing.Color]::White
$addButton.FlatAppearance.BorderSize = 0
$addButton.FlatAppearance.MouseOverBackColor = $script:uiColors.AccentHover
$addButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(0, 0, 0)
$folderButton.BackColor = $script:uiColors.SurfaceRaised
$removeButton.BackColor = $script:uiColors.Background
$clearButton.BackColor = $script:uiColors.Background
$toolbar.Controls.Add($addButton)
$toolbar.Controls.Add($folderButton)
$toolbar.Controls.Add($removeButton)
$toolbar.Controls.Add($clearButton)

$listBorder = New-Object System.Windows.Forms.Panel
$listBorder.Dock = 'Fill'
$listBorder.Padding = [System.Windows.Forms.Padding]::new(1)
$listBorder.BackColor = $script:uiColors.Border
$bodyLayout.Controls.Add($listBorder, 0, 2)

$listLayout = New-Object System.Windows.Forms.TableLayoutPanel
$listLayout.Dock = 'Fill'
$listLayout.ColumnCount = 1
$listLayout.RowCount = 3
$listLayout.Margin = [System.Windows.Forms.Padding]::Empty
$listLayout.Padding = [System.Windows.Forms.Padding]::Empty
$listLayout.BackColor = $script:uiColors.Surface
[void]$listLayout.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 100))
[void]$listLayout.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 40))
[void]$listLayout.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Percent, 100))
[void]$listLayout.RowStyles.Add([System.Windows.Forms.RowStyle]::new([System.Windows.Forms.SizeType]::Absolute, 34))
$listBorder.Controls.Add($listLayout)

$listHeader = New-Object System.Windows.Forms.TableLayoutPanel
$listHeader.Dock = 'Fill'
$listHeader.ColumnCount = 4
$listHeader.RowCount = 1
$listHeader.Margin = [System.Windows.Forms.Padding]::Empty
$listHeader.Padding = [System.Windows.Forms.Padding]::Empty
$listHeader.BackColor = $script:uiColors.SurfaceRaised
[void]$listHeader.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 49))
[void]$listHeader.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 15))
[void]$listHeader.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 16))
[void]$listHeader.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 20))
$headerLabels = @('檔案名稱', '格式', '大小', '狀態')
for ($headerIndex = 0; $headerIndex -lt $headerLabels.Count; $headerIndex++) {
    $headerLabel = New-Object System.Windows.Forms.Label
    $headerLabel.Text = $headerLabels[$headerIndex]
    $headerLabel.Dock = 'Fill'
    $headerLabel.Margin = [System.Windows.Forms.Padding]::Empty
    $headerLabel.Padding = [System.Windows.Forms.Padding]::new(14, 0, 4, 0)
    $headerLabel.BackColor = $script:uiColors.SurfaceRaised
    $headerLabel.ForeColor = $script:uiColors.Secondary
    $headerLabel.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
    $headerLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $listHeader.Controls.Add($headerLabel, $headerIndex, 0)
}
$listLayout.Controls.Add($listHeader, 0, 0)

$list = New-Object System.Windows.Forms.ListView
$list.Dock = 'Fill'
$list.View = [System.Windows.Forms.View]::Details
$list.FullRowSelect = $true
$list.GridLines = $false
$list.HideSelection = $false
$list.MultiSelect = $true
$list.AllowDrop = $true
$list.OwnerDraw = $true
$list.HeaderStyle = [System.Windows.Forms.ColumnHeaderStyle]::None
$list.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$list.BackColor = $script:uiColors.Surface
$list.ForeColor = $script:uiColors.Text
$list.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
[void]$list.Columns.Add('檔案名稱', 500)
[void]$list.Columns.Add('格式', 140)
[void]$list.Columns.Add('大小', 150)
[void]$list.Columns.Add('狀態', 180)
$list.Add_DrawItem({
    $e = $_
    if ($e.Item.Selected) {
        $selectionBrush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(235, 235, 235))
        $e.Graphics.FillRectangle($selectionBrush, $e.Bounds)
        $selectionBrush.Dispose()
    }
})
$list.Add_DrawSubItem({
    $e = $_
    $selected = $e.Item.Selected
    $backColor = if ($selected) { [System.Drawing.Color]::FromArgb(235, 235, 235) } else { $script:uiColors.Surface }
    $textColor = $script:uiColors.Text
    if ($e.ColumnIndex -eq 3) {
        $rowStatus = [string]$e.SubItem.Text
        if ($rowStatus -eq '完成') { $textColor = $script:uiColors.Success }
        elseif ($rowStatus -like '失敗*') { $textColor = $script:uiColors.Error }
        elseif ($rowStatus -like '轉換中*') { $textColor = $script:uiColors.AccentHover }
        else { $textColor = $script:uiColors.Secondary }
    }
    $backBrush = New-Object System.Drawing.SolidBrush($backColor)
    $textBrush = New-Object System.Drawing.SolidBrush($textColor)
    $separatorPen = New-Object System.Drawing.Pen($script:uiColors.Border)
    $textBounds = New-Object System.Drawing.Rectangle($e.Bounds.X + 12, $e.Bounds.Y, [Math]::Max(0, $e.Bounds.Width - 18), $e.Bounds.Height)
    $textFlags = [System.Windows.Forms.TextFormatFlags]::Left -bor [System.Windows.Forms.TextFormatFlags]::VerticalCenter -bor [System.Windows.Forms.TextFormatFlags]::EndEllipsis -bor [System.Windows.Forms.TextFormatFlags]::SingleLine
    $e.Graphics.FillRectangle($backBrush, $e.Bounds)
    [System.Windows.Forms.TextRenderer]::DrawText($e.Graphics, [string]$e.SubItem.Text, $list.Font, $textBounds, $textColor, $textFlags)
    $e.Graphics.DrawLine($separatorPen, $e.Bounds.Left, $e.Bounds.Bottom - 1, $e.Bounds.Right, $e.Bounds.Bottom - 1)
    $backBrush.Dispose()
    $textBrush.Dispose()
    $separatorPen.Dispose()
})
$list.Add_SizeChanged({
    if ($list.Columns.Count -lt 4) { return }
    $available = [Math]::Max(500, $list.ClientSize.Width - 8)
    $nameWidth = [Math]::Max(220, [int]($available * 0.49))
    $formatWidth = [Math]::Max(90, [int]($available * 0.15))
    $sizeWidth = [Math]::Max(100, [int]($available * 0.16))
    $list.Columns[0].Width = $nameWidth
    $list.Columns[1].Width = $formatWidth
    $list.Columns[2].Width = $sizeWidth
    $list.Columns[3].Width = [Math]::Max(100, $available - $nameWidth - $formatWidth - $sizeWidth)
})
$listLayout.Controls.Add($list, 0, 1)

$dropHintPanel = New-Object System.Windows.Forms.Panel
$dropHintPanel.Dock = 'Fill'
$dropHintPanel.BackColor = $script:uiColors.Surface
$dropHint = New-Object System.Windows.Forms.Label
$dropHint.Text = '也可以將圖片拖放到此處'
$dropHint.Dock = 'Fill'
$dropHint.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$dropHint.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$dropHint.ForeColor = $script:uiColors.Muted
$dropHintPanel.Controls.Add($dropHint)
$listLayout.Controls.Add($dropHintPanel, 0, 2)

$settingsHeader = New-Object System.Windows.Forms.Panel
$settingsHeader.Dock = 'Fill'
$settingsHeader.BackColor = $script:uiColors.Background
$bodyLayout.Controls.Add($settingsHeader, 0, 3)
$settingsTitle = New-Object System.Windows.Forms.Label
$settingsTitle.Text = '轉換設定'
$settingsTitle.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 12, [System.Drawing.FontStyle]::Bold)
$settingsTitle.ForeColor = $script:uiColors.Text
$settingsTitle.Location = New-Object System.Drawing.Point(0, 7)
$settingsTitle.Size = New-Object System.Drawing.Size(250, 26)
$settingsHeader.Controls.Add($settingsTitle)

$settingsLayout = New-Object System.Windows.Forms.TableLayoutPanel
$settingsLayout.Dock = 'Fill'
$settingsLayout.ColumnCount = 2
$settingsLayout.RowCount = 1
$settingsLayout.Margin = [System.Windows.Forms.Padding]::Empty
$settingsLayout.Padding = [System.Windows.Forms.Padding]::Empty
$settingsLayout.BackColor = $script:uiColors.Background
[void]$settingsLayout.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 55))
[void]$settingsLayout.ColumnStyles.Add([System.Windows.Forms.ColumnStyle]::new([System.Windows.Forms.SizeType]::Percent, 45))
$bodyLayout.Controls.Add($settingsLayout, 0, 4)

$formatPanel = New-Object System.Windows.Forms.Panel
$formatPanel.Dock = 'Fill'
$formatPanel.BackColor = $script:uiColors.Background
$settingsLayout.Controls.Add($formatPanel, 0, 0)
$formatLabel = New-Object System.Windows.Forms.Label
$formatLabel.Text = '輸出格式'
$formatLabel.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$formatLabel.ForeColor = $script:uiColors.Secondary
$formatLabel.Location = New-Object System.Drawing.Point(0, 0)
$formatLabel.Size = New-Object System.Drawing.Size(200, 22)
$formatPanel.Controls.Add($formatLabel)
$formatBox = New-Object System.Windows.Forms.ComboBox
$formatBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$formatBox.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$formatBox.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$formatBox.BackColor = $script:uiColors.SurfaceRaised
$formatBox.ForeColor = $script:uiColors.Text
$formatBox.Location = New-Object System.Drawing.Point(1, 1)
$formatBox.Size = New-Object System.Drawing.Size(498, 24)
$formatBox.Anchor = 'Top,Left,Right'
foreach ($name in $script:formats.Keys) { [void]$formatBox.Items.Add($name) }
$formatBox.SelectedIndex = 0
$formatFrame = New-Object System.Windows.Forms.Panel
$formatFrame.Location = New-Object System.Drawing.Point(0, 27)
$formatFrame.Size = New-Object System.Drawing.Size(500, 26)
$formatFrame.Anchor = 'Top,Left,Right'
$formatFrame.BackColor = $script:uiColors.Border
$formatFrame.Controls.Add($formatBox)
$formatPanel.Controls.Add($formatFrame)

$qualityPanel = New-Object System.Windows.Forms.Panel
$qualityPanel.Dock = 'Fill'
$qualityPanel.BackColor = $script:uiColors.Background
$settingsLayout.Controls.Add($qualityPanel, 1, 0)
$qualityLabel = New-Object System.Windows.Forms.Label
$qualityLabel.Text = 'JPEG 品質'
$qualityLabel.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$qualityLabel.ForeColor = $script:uiColors.Secondary
$qualityLabel.Location = New-Object System.Drawing.Point(0, 0)
$qualityLabel.Size = New-Object System.Drawing.Size(200, 22)
$qualityPanel.Controls.Add($qualityLabel)
$quality = New-Object System.Windows.Forms.TrackBar
$quality.Minimum = 40
$quality.Maximum = 100
$quality.TickFrequency = 1
$quality.Value = 92
$quality.TickStyle = [System.Windows.Forms.TickStyle]::None
$quality.SmallChange = 1
$quality.LargeChange = 5
$quality.BackColor = $script:uiColors.Background
$quality.Location = New-Object System.Drawing.Point(0, 25)
$quality.Size = New-Object System.Drawing.Size(360, 38)
$quality.Anchor = 'Top,Left,Right'
$qualityPanel.Controls.Add($quality)
$qualityValue = New-Object System.Windows.Forms.Label
$qualityValue.Text = '92'
$qualityValue.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 10)
$qualityValue.ForeColor = $script:uiColors.Text
$qualityValue.TextAlign = [System.Drawing.ContentAlignment]::MiddleRight
$qualityValue.Location = New-Object System.Drawing.Point(380, 29)
$qualityValue.Size = New-Object System.Drawing.Size(42, 25)
$qualityValue.Anchor = 'Top,Right'
$qualityPanel.Controls.Add($qualityValue)
$quality.Add_ValueChanged({ $qualityValue.Text = [string]$quality.Value })
$qualityPanel.Add_SizeChanged({
    $qualityValue.Left = [Math]::Max(220, $qualityPanel.ClientSize.Width - 44)
    $quality.Width = [Math]::Max(180, $qualityPanel.ClientSize.Width - 58)
})
$formatBox.Add_SelectedIndexChanged({
    $jpegSelected = ([string]$formatBox.SelectedItem -like 'JPEG*')
    $quality.Enabled = $jpegSelected
    $qualityLabel.Enabled = $jpegSelected
    $qualityValue.Enabled = $jpegSelected
})
$jpegSelected = ([string]$formatBox.SelectedItem -like 'JPEG*')
$quality.Enabled = $jpegSelected
$qualityLabel.Enabled = $jpegSelected
$qualityValue.Enabled = $jpegSelected

$outputRow = New-Object System.Windows.Forms.Panel
$outputRow.Dock = 'Fill'
$outputRow.BackColor = $script:uiColors.Background
$bodyLayout.Controls.Add($outputRow, 0, 5)
$outputLabel = New-Object System.Windows.Forms.Label
$outputLabel.Text = '輸出位置'
$outputLabel.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$outputLabel.ForeColor = $script:uiColors.Secondary
$outputLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
$outputLabel.Location = New-Object System.Drawing.Point(0, 8)
$outputLabel.Size = New-Object System.Drawing.Size(84, 34)
$outputRow.Controls.Add($outputLabel)
$outputFrame = New-Object System.Windows.Forms.Panel
$outputFrame.Location = New-Object System.Drawing.Point(94, 7)
$outputFrame.Size = New-Object System.Drawing.Size(800, 36)
$outputFrame.Anchor = 'Top,Left,Right'
$outputFrame.BackColor = $script:uiColors.Border
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(1, 1)
$outputBox.AutoSize = $false
$outputBox.Size = New-Object System.Drawing.Size(798, 34)
$outputBox.Anchor = 'Top,Left,Right'
$outputBox.Text = $script:defaultOutput
$outputBox.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$outputBox.BackColor = $script:uiColors.SurfaceRaised
$outputBox.ForeColor = $script:uiColors.Text
$outputBox.BorderStyle = [System.Windows.Forms.BorderStyle]::None
$outputFrame.Controls.Add($outputBox)
$outputRow.Controls.Add($outputFrame)
$outputButton = New-Object System.Windows.Forms.Button
$outputButton.Text = '瀏覽…'
$outputButton.Location = New-Object System.Drawing.Point(906, 5)
$outputButton.Size = New-Object System.Drawing.Size(112, 38)
$outputButton.Anchor = 'Top,Right'
$outputButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$outputButton.UseVisualStyleBackColor = $false
$outputButton.BackColor = $script:uiColors.SurfaceRaised
$outputButton.ForeColor = $script:uiColors.Text
$outputButton.FlatAppearance.BorderColor = $script:uiColors.Border
$outputButton.FlatAppearance.BorderSize = 1
$outputButton.FlatAppearance.MouseOverBackColor = $script:uiColors.SurfaceRaised
$outputButton.FlatAppearance.MouseDownBackColor = $script:uiColors.Border
$outputButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$outputRow.Controls.Add($outputButton)

$footerPanel = New-Object System.Windows.Forms.Panel
$footerPanel.Dock = 'Fill'
$footerPanel.BackColor = $script:uiColors.Background
$bodyLayout.Controls.Add($footerPanel, 0, 6)
$footerRule = New-Object System.Windows.Forms.Panel
$footerRule.Dock = 'Top'
$footerRule.Height = 1
$footerRule.BackColor = $script:uiColors.Border
$footerPanel.Controls.Add($footerRule)
$status = New-Object System.Windows.Forms.Label
$status.Text = '尚未加入圖片。可直接將圖片拖曳到清單中。'
$status.Location = New-Object System.Drawing.Point(0, 20)
$status.Size = New-Object System.Drawing.Size(660, 28)
$status.Anchor = 'Top,Left,Right'
$status.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 9)
$status.ForeColor = $script:uiColors.Secondary
$footerPanel.Controls.Add($status)
$convertButton = New-Object System.Windows.Forms.Button
$convertButton.Text = '開始轉換'
$convertButton.Location = New-Object System.Drawing.Point(850, 9)
$convertButton.Size = New-Object System.Drawing.Size(168, 46)
$convertButton.Anchor = 'Top,Right'
$convertButton.BackColor = $script:uiColors.Accent
$convertButton.ForeColor = [System.Drawing.Color]::White
$convertButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$convertButton.UseVisualStyleBackColor = $false
$convertButton.Font = New-Object System.Drawing.Font('Microsoft JhengHei UI', 10, [System.Drawing.FontStyle]::Bold)
$convertButton.FlatAppearance.BorderSize = 0
$convertButton.FlatAppearance.MouseOverBackColor = $script:uiColors.AccentHover
$convertButton.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(0, 0, 0)
$convertButton.Cursor = [System.Windows.Forms.Cursors]::Hand
$footerPanel.Controls.Add($convertButton)

$roundedControls = @($addButton, $folderButton, $removeButton, $clearButton, $formatFrame, $formatBox, $outputFrame, $outputBox, $outputButton, $convertButton, $listBorder)
foreach ($roundedControl in $roundedControls) {
    $cornerRadius = if ($roundedControl -eq $listBorder) { 12 } elseif ($roundedControl -eq $formatBox -or $roundedControl -eq $outputBox) { 6 } else { 8 }
    $resizeHandler = {
        param($sender, $eventArgs)
        Set-UiCornerRadius -Control $sender -Radius $cornerRadius
    }.GetNewClosure()
    $roundedControl.Add_SizeChanged($resizeHandler)
    Set-UiCornerRadius -Control $roundedControl -Radius $cornerRadius
}

function Add-ImageFiles([string[]]$Paths) {
    foreach ($path in $Paths) {
        if ([string]::IsNullOrWhiteSpace([string]$path)) { continue }
        try { $normalizedPath = [IO.Path]::GetFullPath([string]$path) } catch { continue }
        if (-not (Test-Path -LiteralPath $normalizedPath -PathType Leaf)) { continue }
        $ext = [IO.Path]::GetExtension($normalizedPath).ToLowerInvariant()
        if ($ext -notin @('.png','.jpg','.jpeg','.jfif','.bmp','.gif','.tif','.tiff','.ico')) { continue }
        $already = $false
        foreach ($existing in $script:items) { if ([string]::Equals($existing.Path, $normalizedPath, [StringComparison]::OrdinalIgnoreCase)) { $already = $true; break } }
        if ($already) { continue }
        $file = Get-Item -LiteralPath $normalizedPath -ErrorAction SilentlyContinue
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
    if ($script:imageCountLabel) { $script:imageCountLabel.Text = '{0} 張圖片' -f $script:items.Count }
    $testResultPath = [Environment]::GetEnvironmentVariable('WIFC_TEST_RESULT_PATH')
    if (-not [string]::IsNullOrWhiteSpace($testResultPath)) {
        try { [IO.File]::WriteAllText($testResultPath, [string]$script:items.Count, $script:utf8NoBom) } catch { }
    }
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
    $script:imageCountLabel.Text = '{0} 張圖片' -f $script:items.Count
})
$clearButton.Add_Click({ $list.Items.Clear(); $script:items.Clear(); $status.Text = '清單已清空。'; $script:imageCountLabel.Text = '0 張圖片' })
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
            $src = $null; $bitmap = $null; $graphics = $null; $params = $null
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
                } else { $src.Save($destination, $target.Format) }
                $entry.Row.SubItems[3].Text = '完成'
                if ($script:uiColors) { $entry.Row.SubItems[3].ForeColor = $script:uiColors.Success }
                else { $entry.Row.SubItems[3].ForeColor = [System.Drawing.Color]::FromArgb(16, 124, 16) }
                $converted++
            } catch {
                $entry.Row.SubItems[3].Text = '失敗：' + $_.Exception.Message
                if ($script:uiColors) { $entry.Row.SubItems[3].ForeColor = $script:uiColors.Error }
                else { $entry.Row.SubItems[3].ForeColor = [System.Drawing.Color]::FromArgb(196, 43, 28) }
                $failed++
            } finally {
                if ($params) { $params.Dispose() }
                if ($graphics) { $graphics.Dispose() }
                if ($bitmap) { $bitmap.Dispose() }
                if ($src) { $src.Dispose() }
            }
        }
    } finally { $form.UseWaitCursor = $false; $convertButton.Enabled = $true }
    $status.Text = "轉換完成：成功 $converted 張，失敗 $failed 張。"
    [void][System.Windows.Forms.MessageBox]::Show("轉換完成！`r`n成功：$converted 張`r`n失敗：$failed 張`r`n`r`n輸出位置：$outDir", '轉換結果', 'OK', 'Information')
})

if ($script:startupPaths.Count -gt 0) {
    Add-ImageFiles -Paths $script:startupPaths
    if ($script:items.Count -gt 0) { $status.Text = "從檔案總管加入 $($script:items.Count) 張圖片。" }
}

$script:requestTimer = New-Object System.Windows.Forms.Timer
$script:requestTimer.Interval = 350
$script:requestTimer.Add_Tick({
    $hasQueueLock = $false
    $pendingPaths = New-Object System.Collections.ArrayList
    $shouldActivate = $false
    try {
        try { $hasQueueLock = $script:queueMutex.WaitOne(0) }
        catch [System.Threading.AbandonedMutexException] { $hasQueueLock = $true }
        if ($hasQueueLock -and (Test-Path -LiteralPath $script:requestQueuePath -PathType Leaf)) {
            $requests = [IO.File]::ReadAllLines($script:requestQueuePath, $script:utf8NoBom)
            if ($requests.Count -gt 0) {
                [IO.File]::WriteAllText($script:requestQueuePath, '', $script:utf8NoBom)
                foreach ($request in $requests) {
                    if ($request -eq 'A:') { $shouldActivate = $true }
                    elseif ($request.StartsWith('P:')) {
                        try {
                            $queuedPath = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($request.Substring(2)))
                            if (-not [string]::IsNullOrWhiteSpace($queuedPath)) { [void]$pendingPaths.Add($queuedPath) }
                        } catch { }
                    }
                }
            }
        }
    }
    finally {
        if ($hasQueueLock) { $script:queueMutex.ReleaseMutex() }
    }

    if ($pendingPaths.Count -gt 0) {
        Add-ImageFiles -Paths ([string[]]$pendingPaths.ToArray())
        $shouldActivate = $true
    }
    if ($shouldActivate -and -not $form.IsDisposed) {
        if ($form.WindowState -eq [System.Windows.Forms.FormWindowState]::Minimized) {
            $form.WindowState = [System.Windows.Forms.FormWindowState]::Normal
        }
        [void]$form.Activate()
        $form.BringToFront()
    }
})
$script:requestTimer.Start()
try {
    [void]$form.ShowDialog()
}
finally {
    $script:requestTimer.Stop()
    $script:requestTimer.Dispose()
    if ($script:ownsInstanceMutex) { $script:instanceMutex.ReleaseMutex() }
    $script:queueMutex.Dispose()
    $script:instanceMutex.Dispose()
}
