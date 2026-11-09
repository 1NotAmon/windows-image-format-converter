# Windows 批次圖片格式轉換器

一個以 Windows Forms 製作的輕量桌面工具，可一次把多張圖片轉成統一格式。介面使用繁體中文，轉換全程在本機完成。

> 目前正式版本與可下載成品請以 [GitHub Releases](https://github.com/1NotAmon/windows-image-format-converter/releases) 為準；`main` 分支可能包含尚未打標籤的開發變更。v1.2.0、v1.3.0 與 v0.1.0 歷史發布均保留。

v1.3.0 提供白黑圓角介面、批次匯入與轉檔可靠性改善，以及單檔 Windows 安裝程式。此版本在 Windows 10 本機通過完整功能與隔離安裝測試；乾淨 Windows 10／11、實際 GUI 拖放及 SmartScreen／簽章信任仍未驗證，Setup 與 EXE 未簽署。Inno Setup 7.1.1 編譯器的非商業使用說明及完整限制見 [v1.3.0 Release Notes](versions/v1.3.0/RELEASE-NOTES.md) 與 [驗收紀錄](versions/v1.3.0/CANDIDATE-STATUS.txt)。

`v1.4.0` 改良逐張轉換進度、目前檔名、成功／失敗／待處理計數、目前圖片完成後取消、完成通知、一鍵開啟輸出資料夾、輸出檔名欄、完整失敗詳情及上次格式／品質／輸出位置記憶；是否已建立正式 tag／Release 請查看上述 Releases 頁面。

## 功能

- 一次選取多張圖片、匯入整個資料夾（包含子資料夾），或直接拖放圖片。
- 可選安裝檔案總管圖片右鍵選單，多張圖片會合併載入同一個轉換器視窗。
- 支援 PNG、JPG/JPEG、JFIF、BMP、GIF、TIF/TIFF、ICO 輸入。
- 可輸出 PNG、JPEG、BMP、GIF、TIFF。
- 可調整 JPEG 品質；透明圖片轉成 JPEG 時會以白色填補透明區。
- v1.4.0 逐張顯示轉換進度、目前檔名、成功／失敗／待處理數、輸出檔名及失敗詳情；可在目前圖片完成後取消。
- 一鍵開啟輸出資料夾；記住上次的輸出格式、JPEG 品質與輸出位置（不保存圖片清單）。同名輸出檔自動加上序號，不覆蓋既有檔案。
- v1.3.0 正式介面採白底黑字，按鈕與設定欄位加入圓角。
- 無需第三方套件、安裝程式或網路連線即可使用原始碼版。

## 系統需求

- Windows 10 或更新版本。
- 原始碼版使用 Windows PowerShell 5.1 與 Windows 內建 Windows Forms / GDI+ 元件。
- 目前不支援 macOS、Linux 或瀏覽器執行。

## 使用方式

### 原始碼版

1. 下載 [main 分支原始碼 ZIP](https://github.com/1NotAmon/windows-image-format-converter/archive/refs/heads/main.zip)，解壓縮整個專案資料夾。既有 v0.1.0 Release 保持原樣，尚未包含本頁所述的新右鍵整合；請勿只下載 `.vbs` 或 `.ps1` 單一檔案。
2. 雙擊 `啟動圖片格式轉換器.vbs`。
3. 加入圖片或資料夾，選擇輸出格式與輸出位置，再按「開始轉換」。

預設輸出位置為「文件\統一格式\轉換結果」。也可以把圖片拖曳到程式清單。

### v1.2.0 發布包與驗收範圍

發布包包含[原始碼 ZIP](versions/v1.2.0/windows-image-format-converter-v1.2.0-source-candidate.zip)、[可攜式 EXE ZIP](versions/v1.2.0/windows-image-format-converter-v1.2.0-exe-candidate.zip)、[單獨 EXE](versions/v1.2.0/圖片格式轉換器-v1.2.0.exe)及 SHA-256 校驗碼。GitHub Actions run #37（commit `50e39da`）通過 25 張匯入、smoke、EXE 單視窗、完整轉檔矩陣／100 張批次及右鍵回歸。Windows 10 Home 22H2 本機另驗證 45 組轉檔／重開、透明 PNG、JPEG 白底與品質、巢狀資料夾、同名保護、損毀檔隔離及 Defender 自訂掃描（無偵測）。實際 GUI 拖放、乾淨 Windows 10／11（含 Windows 11 右鍵）與 SmartScreen／簽章信任仍未驗收；EXE 未簽章，請勿停用安全防護。限制詳見 [Release notes](versions/v1.2.0/RELEASE-NOTES.md)；正式 tag 與下載狀態請查看 [GitHub Releases](https://github.com/1NotAmon/windows-image-format-converter/releases)。

### v1.3.0 正式發布

從 [GitHub v1.3.0 Release](https://github.com/1NotAmon/windows-image-format-converter/releases/tag/v1.3.0) 下載單檔 Setup、獨立 EXE、原始碼 ZIP、可攜 ZIP 和校驗清單。Setup 為目前使用者安裝，不需管理員權限；桌面捷徑可選，右鍵整合預設不勾選。勾選右鍵會取代本專案舊版登錄，解除安裝時移除該項而不還原舊版本。Windows 10 Home 22H2 本機轉檔、匯入、單視窗、安裝／解除安裝與 Defender 掃描已完成；Setup／EXE 未簽署，乾淨 Windows 10／11、實際 GUI 拖放與 SmartScreen 信任仍未驗證。詳細範圍、Inno Setup 7.1.1 非商業編譯器說明和 SHA-256 見 [Release Notes](versions/v1.3.0/RELEASE-NOTES.md) 及 [驗收紀錄](versions/v1.3.0/CANDIDATE-STATUS.txt)。

### 從 PowerShell 啟動
在專案資料夾開啟 Windows PowerShell，執行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\圖片格式轉換器.ps1"
```

此命令只為該次 PowerShell 程序指定執行原則，不會修改系統或使用者的全域原則。從網路下載任何腳本前，請先確認來源並閱讀程式內容。

### 檔案總管右鍵選單（可選）

在專案資料夾開啟 PowerShell，執行 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\Install-ContextMenu.ps1"`。之後在檔案總管選取一張或多張圖片，按右鍵選擇「用圖片格式轉換器轉換」。即使 Windows 對多張圖片分別啟動程式，後續圖片也會併入同一視窗，不會每張各開一個視窗。圖片會自動載入清單；仍由你確認輸出格式和位置，再按「開始轉換」。

若要移除選單，執行 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\Remove-ContextMenu.ps1"`。安裝只寫入目前 Windows 使用者的登錄檔，不需要系統管理員權限。Windows 11 若主選單沒有顯示，請選「顯示更多選項」。登錄項目指向目前專案資料夾；搬移專案後請重新執行安裝腳本。非常大量或路徑很長時，建議改用程式內的「加入資料夾」或「加入圖片…」。

## 輸入與輸出格式

| 類型 | 格式 |
| --- | --- |
| 輸入 | PNG、JPG/JPEG、JFIF、BMP、GIF、TIF/TIFF、ICO |
| 輸出 | PNG、JPEG（`.jpg`）、BMP、GIF、TIFF（`.tiff`） |

解碼能力取決於 Windows 內建 GDI+ 對實際圖片內容的支援。副檔名符合但檔案損毀或內容格式不受支援時，該檔會顯示失敗原因。

## 行為與限制

- 轉換不會覆寫既有檔案；若同名檔案已存在，會依序輸出 `_1`、`_2` 等名稱。
- JPEG 品質範圍為 40–100，預設 92；此設定只影響 JPEG 輸出。
- 透明圖片輸出為 JPEG 時，透明區域以白色背景呈現。
- 動畫 GIF 與多頁 TIFF 輸出為靜態圖片，只處理第一個影格／頁面。
- 目前採逐張同步轉換；取消會在目前圖片完成後停止，單張超大圖片仍可能需要等待。
- 程式不會上傳、分析或傳送圖片；所有檔案處理均在本機進行。

## 專案結構

```text
.
├── 圖片格式轉換器.ps1
├── 啟動圖片格式轉換器.vbs
├── build/Build-Exe.ps1
├── build/Build-Installer.ps1
├── build/Installer.iss
├── tests/
│   ├── SmokeTest.ps1
│   ├── ImportCountTest.ps1
│   ├── ContextMenuTest.ps1
│   ├── PackageTest.ps1
│   ├── ConversionAcceptanceTest.ps1
│   ├── SettingsPersistenceTest.ps1
│   └── InstallerTest.ps1
├── tools/
│   ├── Install-ContextMenu.ps1
│   └── Remove-ContextMenu.ps1
├── versions/
│   ├── v1.0.0/              # 來源碼候選快照
│   ├── v1.1.0/              # 舊 x64 EXE 候選包
│   ├── v1.2.0/              # v1.2.0 原始碼、EXE 與驗收／安全說明
│   ├── v1.3.0/              # v1.3.0 已發布版本
│   └── v1.4.0/              # v1.4.0 本機候選與驗收紀錄
├── .github/workflows/       # GitHub Actions 測試
├── README.md
├── ROADMAP.md
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTING.md
├── VERSION
└── 使用說明.txt
```

根目錄是唯一的開發主線；`versions/` 是按版本整理的快照與候選成品。該目錄不會覆蓋或取代已發布的 `v0.1.0`。

## 開發與測試

在 Windows PowerShell 5.1 中執行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tests\SmokeTest.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\tests\ImportCountTest.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tests\ContextMenuTest.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\tests\PackageTest.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\tests\ConversionAcceptanceTest.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\tests\SettingsPersistenceTest.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tests\InstallerTest.ps1" -Version 1.4.0 -ISCCPath "C:\Program Files\Inno Setup 7\ISCC.exe"
```

`ImportCountTest.ps1` 會建立 250 張 JPG/JFIF，確認全數列入且重複與相對路徑別名不增加筆數。`PackageTest.ps1` 驗證 v1.4.0 x64 EXE 的三程序單一視窗行為。`ConversionAcceptanceTest.ps1` 直接執行生產轉檔事件，驗證 9 種輸入副檔名 × 5 種輸出格式、100 張批次、取消按鈕及未處理列、透明背景、JPEG 品質、巢狀匯入、同名與來源圖不覆寫、損毀檔錯誤明細及資源釋放。`SettingsPersistenceTest.ps1` 驗證格式／品質／輸出位置可記憶而不保存圖片清單。`InstallerTest.ps1` 以唯一 AppId／開始功能表名稱編譯隔離安裝器，在唯一暫存路徑測試目前使用者安裝與解除安裝；右鍵不勾選，且不升級／移除既有安裝。v1.4.0 本機功能、EXE、隔離安裝與候選 ZIP 測試已通過；Microsoft Defender 對候選資料夾掃描為 0 偵測，SmartScreen 不在此結果範圍內。GitHub Actions 尚無本版結果；乾淨 Windows 11、實際 GUI 拖放與 SmartScreen／簽章信任仍未驗證。

### 重建 v1.4.0 本機候選 EXE

需先在 Windows 安裝固定版本的 PS2EXE：

```powershell
Install-Module -Name ps2exe -RequiredVersion 1.0.18 -Scope CurrentUser
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\build\Build-Exe.ps1" -Version 1.4.0
```

建置結果會放在 `versions/v1.4.0/`。PS2EXE 相關聲明和版本資訊列於候選包的 `THIRD-PARTY-NOTICES.txt`。EXE 是 PowerShell 程式封裝而非程式碼加密，尚未數位簽署。v1.4.0 目前只在本機；乾淨 Windows、實際 GUI 拖放及 SmartScreen／簽章信任仍未驗證。

### 重建 v1.4.0 安裝程式

安裝 Inno Setup 7 後，執行 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\build\Build-Installer.ps1" -Version 1.4.0 -ISCCPath "C:\Program Files\Inno Setup 7\ISCC.exe"`。安裝程式會輸出至 `versions/v1.4.0/`，並更新 `SETUP-SHA256.txt`。目前候選 Setup 未簽章；安裝程式本身不會消除 SmartScreen 警告。使用 Inno Setup 7.1.1 時，請先確認其非商業版的官方授權適用條件。

## 問題回報

回報問題時，請附上 Windows 版本、輸入副檔名、目標輸出格式，以及清單中顯示的完整錯誤文字。請勿公開上傳含有私人資訊的圖片。

## 授權

本專案原始碼採用 [MIT License](LICENSE)。EXE 候選包另包含 PS2EXE 第三方授權說明；兩者授權範圍請分別閱讀。
