# Windows 批次圖片格式轉換器

一個以 Windows Forms 製作的輕量桌面工具，可一次把多張圖片轉成統一格式。介面使用繁體中文，轉換全程在本機完成。

> 目前版本：`0.1.0`（早期版本）

版本規劃與測試驗收條件請見 [ROADMAP.md](ROADMAP.md)；其中 v1.0.0 與 v1.1.0 均為尚未發布的規劃。

## 功能

- 一次選取多張圖片、匯入整個資料夾（包含子資料夾），或直接拖放圖片。
- 支援 PNG、JPG/JPEG、JFIF、BMP、GIF、TIF/TIFF、ICO 輸入。
- 可輸出 PNG、JPEG、BMP、GIF、TIFF。
- 可調整 JPEG 品質；透明圖片轉成 JPEG 時會以白色填補透明區。
- 逐檔顯示轉換狀態；同名輸出檔自動加上序號，不覆蓋既有檔案。
- 無需第三方套件、安裝程式或網路連線。

## 系統需求

- Windows 10 或更新版本。
- Windows PowerShell 5.1 與 Windows 內建 Windows Forms / GDI+ 元件。
- 目前不支援 macOS、Linux 或瀏覽器執行。

## 使用方式

### 一般使用者

1. 到 [GitHub Releases](https://github.com/1NotAmon/windows-image-format-converter/releases/latest) 下載最新來源碼 ZIP，解壓縮整個專案資料夾。請勿只下載 `.vbs` 或 `.ps1` 單一檔案。
2. 雙擊 `啟動圖片格式轉換器.vbs`。
3. 加入圖片或資料夾，選擇輸出格式與輸出位置，再按「開始轉換」。

預設輸出位置為「文件\統一格式\轉換結果」。也可以把圖片拖曳到程式清單。

### 從 PowerShell 啟動

在專案資料夾開啟 Windows PowerShell，執行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File ".\圖片格式轉換器.ps1"
```

此命令只為該次 PowerShell 程序指定執行原則，不會修改系統或使用者的全域原則。從網路下載任何腳本前，請先確認來源並閱讀程式內容。

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
├── 圖片格式轉換器.ps1        # Windows Forms 主程式
├── 啟動圖片格式轉換器.vbs    # 隱藏命令視窗的啟動器
├── tests/
│   └── SmokeTest.ps1          # 語法與影像編碼器基本測試
├── .github/workflows/         # GitHub Actions 自動測試
├── README.md
├── ROADMAP.md                 # v1.0.0 / v1.1.0 規劃與驗收條件
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTING.md
├── VERSION
└── 使用說明.txt
```

## 開發與測試

在 Windows PowerShell 5.1 中執行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tests\SmokeTest.ps1"
```

GitHub Actions 會在 Windows runner 上執行相同的 smoke test。測試不會啟動主視窗，JFIF 測試圖片也會在系統暫存目錄建立後立即刪除。

## 問題回報

回報問題時，請附上 Windows 版本、輸入副檔名、目標輸出格式，以及清單中顯示的完整錯誤文字。請勿公開上傳含有私人資訊的圖片。

## 授權

本專案採用 [MIT License](LICENSE)。授權文字中的版權標示為 `1NotAmon`。
