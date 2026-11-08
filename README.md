# Windows 批次圖片格式轉換器

一個以 Windows Forms 製作的輕量桌面工具，可一次把多張圖片轉成統一格式。介面使用繁體中文，轉換全程在本機完成。

> 根目錄本機版本：`1.2.0`（正式發布包已準備）；GitHub 同步尚未完成，線上目前仍只有 `v0.1.0` 正式 Release。

`versions/` 保存 `v1.0.0` 來源碼候選、`v1.1.0` 舊 EXE 候選及本機已準備的 `v1.2.0` 原始碼／EXE 發布包。v1.2.0 尚未同步至 GitHub、尚無正式 tag／Release；已知未驗收項目見 [Release notes](versions/v1.2.0/RELEASE-NOTES.md)、[版本索引](versions/README.md) 與 [ROADMAP.md](ROADMAP.md)。

## 功能

- 一次選取多張圖片、匯入整個資料夾（包含子資料夾），或直接拖放圖片。
- 可選安裝檔案總管圖片右鍵選單，多張圖片會合併載入同一個轉換器視窗。
- 支援 PNG、JPG/JPEG、JFIF、BMP、GIF、TIF/TIFF、ICO 輸入。
- 可輸出 PNG、JPEG、BMP、GIF、TIFF。
- 可調整 JPEG 品質；透明圖片轉成 JPEG 時會以白色填補透明區。
- 逐檔顯示轉換狀態；同名輸出檔自動加上序號，不覆蓋既有檔案。
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

### v1.2.0 發布包準備（尚未同步至 GitHub）

本機已準備[原始碼 ZIP](versions/v1.2.0/windows-image-format-converter-v1.2.0-source-candidate.zip)、[可攜式 EXE ZIP](versions/v1.2.0/windows-image-format-converter-v1.2.0-exe-candidate.zip)、[單獨 EXE](versions/v1.2.0/圖片格式轉換器-v1.2.0.exe)及 SHA-256 校驗碼。Windows 10 Home 22H2 本機通過 45 組轉檔／重開、100 張批次、透明 PNG、JPEG 白底與品質、巢狀資料夾、同名保護、損毀檔隔離及 Defender 自訂掃描（無偵測）。實際 GUI 拖放、乾淨 Windows 10／11（含 Windows 11 右鍵）與 SmartScreen／簽章信任仍未驗收；EXE 未簽章，請勿停用安全防護。這些限制已獲接受並列入 Release notes；但最新檔案尚未同步、CI 尚未重跑，所以不建立 tag／Release。`v0.1.0` 仍是 GitHub 上唯一正式 Release。

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
- 目前採逐張同步轉換，大量或超大圖片可能需要等待；請勿在轉換途中關閉視窗。
- 程式不會上傳、分析或傳送圖片；所有檔案處理均在本機進行。

## 專案結構

```text
.
├── 圖片格式轉換器.ps1
├── 啟動圖片格式轉換器.vbs
├── build/Build-Exe.ps1
├── tests/
│   ├── SmokeTest.ps1
│   ├── ImportCountTest.ps1
│   ├── ContextMenuTest.ps1
│   ├── PackageTest.ps1
│   └── ConversionAcceptanceTest.ps1
├── tools/
│   ├── Install-ContextMenu.ps1
│   └── Remove-ContextMenu.ps1
├── versions/
│   ├── v1.0.0/              # 來源碼候選快照
│   ├── v1.1.0/              # 舊 x64 EXE 候選包
│   └── v1.2.0/              # 本機已準備、尚未同步的正式發布包
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
```

`ImportCountTest.ps1` 會建立 21 張 JPG 與 4 張 JFIF，呼叫主程式實際使用的匯入函式，確認 25 張全數列入且重複路徑不增加筆數。`PackageTest.ps1` 會幾乎同時啟動三個各帶一張圖片的 EXE，確認只有一個主視窗且清單共三張，最後正常關閉。`ConversionAcceptanceTest.ps1` 直接執行主程式實際使用的匯入函式與轉檔事件（只略過完成提示視窗），驗證 9 種輸入副檔名 × 5 種輸出格式、輸出重開／尺寸、100 張批次、透明背景、JPEG 品質、巢狀資料夾、同名不覆寫與損毀檔隔離。GitHub Actions 也會執行封裝及完整轉檔驗收；乾淨 Windows 10/11、實際拖放和 SmartScreen 仍需人工驗證。
`ImportCountTest.ps1` 會建立 21 張 JPG 與 4 張 JFIF，呼叫主程式實際使用的匯入函式，確認 25 張全數列入且重複路徑不增加筆數。`PackageTest.ps1` 會幾乎同時啟動三個各帶一張圖片的 EXE，確認只有一個主視窗且清單共三張，最後正常關閉。`ConversionAcceptanceTest.ps1` 直接執行主程式實際使用的匯入函式與轉檔事件（只略過完成提示視窗），驗證 9 種輸入副檔名 × 5 種輸出格式、輸出重開／尺寸、100 張批次、透明背景、JPEG 品質、巢狀資料夾、同名不覆寫與損毀檔隔離。GitHub Actions 工作流程也涵蓋完整轉檔驗收；實際 GUI 拖放、乾淨 Windows 10／11 與 SmartScreen／簽章信任未驗證，詳見 Release notes。

### 重建 v1.2.0 EXE

需先在 Windows 安裝固定版本的 PS2EXE：

```powershell
Install-Module -Name ps2exe -RequiredVersion 1.0.18 -Scope CurrentUser
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\build\Build-Exe.ps1" -Version 1.2.0
```

建置結果會放在 `versions/v1.2.0/`。PS2EXE 相關聲明和版本資訊列於 `versions/v1.2.0/THIRD-PARTY-NOTICES.txt`。EXE 只是 PowerShell 程式的 Windows 封裝，不是程式碼加密；本專案的 EXE 尚未數位簽署。此候選版尚未建立 Git tag 或正式 GitHub Release。
建置結果會放在 `versions/v1.2.0/`。PS2EXE 相關聲明和版本資訊列於 `versions/v1.2.0/THIRD-PARTY-NOTICES.txt`。EXE 只是 PowerShell 程式的 Windows 封裝，不是程式碼加密；本專案的 EXE 尚未數位簽署。正式版未驗證項目與安全注意事項列於 [`RELEASE-NOTES.md`](versions/v1.2.0/RELEASE-NOTES.md)。

## 問題回報

回報問題時，請附上 Windows 版本、輸入副檔名、目標輸出格式，以及清單中顯示的完整錯誤文字。請勿公開上傳含有私人資訊的圖片。

## 授權

本專案原始碼採用 [MIT License](LICENSE)。EXE 候選包另包含 PS2EXE 第三方授權說明；兩者授權範圍請分別閱讀。
