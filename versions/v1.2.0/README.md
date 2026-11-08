# v1.2.0 正式發布包準備（原始碼與 EXE）

**狀態：本機正式發布包已準備，尚未同步到 GitHub。** 目前尚未建立 `v1.2.0` tag／Release；線上正式版仍為 `v0.1.0`。已獲授權在明列限制下發布，但最新檔案同步逾時，尚需完成 GitHub 同步與 CI。已知未驗收的實際 GUI 拖放、乾淨 Windows 10／11（含 Windows 11 右鍵）及 SmartScreen／簽章信任檢查會留在正式 Release notes 中；EXE 未簽章，請勿停用安全防護。

## 下載

- [原始碼 ZIP](windows-image-format-converter-v1.2.0-source-candidate.zip)；SHA-256 在 [SOURCE-SHA256.txt](SOURCE-SHA256.txt)。
- [EXE 可攜式 ZIP](windows-image-format-converter-v1.2.0-exe-candidate.zip)；SHA-256 在 [ZIP-SHA256.txt](ZIP-SHA256.txt)。解壓後保留同一資料夾內的 EXE、`tools/`、MIT 授權及第三方授權說明。
- [單獨下載 EXE](圖片格式轉換器-v1.2.0.exe)；SHA-256 在 [SHA256SUMS.txt](SHA256SUMS.txt)。
- [Release notes](RELEASE-NOTES.md)：系統需求、已完成測試、尚未驗收項目及安全注意事項。

下載後請用 PowerShell 比對校驗碼，例如：

```powershell
Get-FileHash .\圖片格式轉換器-v1.2.0.exe -Algorithm SHA256
```

## 使用

1. 直接雙擊 `圖片格式轉換器-v1.2.0.exe`，或解壓 EXE 候選 ZIP 後再執行。
2. 加入圖片，選擇輸出格式及資料夾，再按「開始轉換」。
3. 可選安裝檔案總管右鍵選單：在含有 `tools/` 的資料夾開啟 PowerShell，執行 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\Install-ContextMenu.ps1"`。
4. 解除右鍵整合時執行 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\Remove-ContextMenu.ps1"`。

此 v1.2.0 發布包包含多圖單一視窗修正。Windows 對多張圖片各別啟動程式時，後續路徑會合併到已開啟的轉換器視窗。

## 本機測試結果

本機 Windows 10 Home 22H2 已驗證 x64 PE `1.2.0.0`、EXE 啟動／正常關閉，以及三個幾乎同時啟動的圖片程序合併成一個視窗。25 張 JPG/JFIF 匯入、去重、右鍵路徑回歸與來源碼 ZIP 解壓測試通過；新增完整驗收也通過 9 種輸入副檔名 × 5 種輸出格式（45 組實際轉檔並重新開啟核對格式與尺寸）、100 張批次、透明 PNG、JPEG 白底與品質、巢狀資料夾、同名不覆寫及損毀檔隔離。Microsoft Defender 自訂掃描完成，未偵測 v1.2.0 資料夾中的威脅。完整驗收 workflow 已在本機準備，尚未同步，故沒有新的 GitHub Actions run。

## 尚未驗收的發布限制

尚未完成實際 GUI 拖放、乾淨 Windows 10／11 環境驗收（包含乾淨 Windows 11 右鍵人工測試），以及 SmartScreen／數位簽章信任檢查。此裝置是非乾淨的 Windows 10 Home 22H2；雖然本機 Defender 掃描無偵測，EXE 仍未數位簽署。使用者已同意在明列限制下發布，但目前仍因 GitHub 同步逾時而未建立正式 Release；請勿因 SmartScreen 警告而停用安全防護。下載後請核對 SHA-256。

原始碼採 MIT License。EXE 使用 PS2EXE 1.0.18 封裝，相關授權詳見 `THIRD-PARTY-NOTICES.txt`。`v1.2.0` 尚未建立正式 tag／Release；既有 `v0.1.0` Release 保持不變。
