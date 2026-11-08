# v1.2.0 公開候選版（原始碼與 EXE）

**狀態：公開候選版，不是正式 v1.2.0 Release。** 此資料夾提供測試用的來源碼與 Windows x64 EXE。已發布的 v0.1.0 保持不變；根目錄 `VERSION` 仍標示 `0.1.0`，不代表正式 1.2.0 已完成驗收。

## 下載

- [原始碼候選 ZIP](windows-image-format-converter-v1.2.0-source-candidate.zip)；SHA-256 在 [SOURCE-SHA256.txt](SOURCE-SHA256.txt)。
- [EXE 可攜式候選 ZIP](windows-image-format-converter-v1.2.0-exe-candidate.zip)；SHA-256 在 [ZIP-SHA256.txt](ZIP-SHA256.txt)。解壓後保留同一資料夾內的 EXE、`tools/`、MIT 授權及第三方授權說明。
- [單獨下載 EXE](圖片格式轉換器-v1.2.0.exe)；SHA-256 在 [SHA256SUMS.txt](SHA256SUMS.txt)。

下載後請用 PowerShell 比對校驗碼，例如：

```powershell
Get-FileHash .\圖片格式轉換器-v1.2.0.exe -Algorithm SHA256
```

## 使用

1. 直接雙擊 `圖片格式轉換器-v1.2.0.exe`，或解壓 EXE 候選 ZIP 後再執行。
2. 加入圖片，選擇輸出格式及資料夾，再按「開始轉換」。
3. 可選安裝檔案總管右鍵選單：在含有 `tools/` 的資料夾開啟 PowerShell，執行 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\Install-ContextMenu.ps1"`。
4. 解除右鍵整合時執行 `powershell.exe -NoProfile -ExecutionPolicy Bypass -File ".\tools\Remove-ContextMenu.ps1"`。

此候選版包含多圖單一視窗修正。Windows 對多張圖片各別啟動程式時，後續路徑會合併到已開啟的轉換器視窗。

## 本機測試結果

本機已驗證 x64 PE 與檔案版本資訊 `1.2.0.0`；EXE 可啟動並正常關閉；三個幾乎同時、各帶一張圖片的 EXE 程序合併為一個視窗，三張圖片都載入清單。25 張混合 JPG/JFIF 匯入及去重、影像編碼器 smoke、右鍵路徑回歸、封裝啟動測試，以及來源碼 ZIP 解壓後的 Smoke／匯入／右鍵測試均通過。候選提交會觸發 GitHub Actions 新 run，請在 [Actions](https://github.com/1NotAmon/windows-image-format-converter/actions) 檢查最新結果。

## 尚未完成的正式發布驗收

完整輸出格式轉換後重開驗證、至少 100 張大型批次、乾淨 Windows 10／11 環境、乾淨 Windows 11 右鍵人工驗收，以及 Defender／SmartScreen 檢查仍待完成。EXE 尚未數位簽署；請勿因 SmartScreen 警告而停用安全防護。此 ZIP 與 EXE 為未正式發布的候選成品，請先檢查來源並驗證 SHA-256。

原始碼採 MIT License。EXE 使用 PS2EXE 1.0.18 封裝，相關授權詳見 `THIRD-PARTY-NOTICES.txt`。未建立 v1.2.0 tag 或正式 GitHub Release；目前正式 Release 仍是 v0.1.0。
