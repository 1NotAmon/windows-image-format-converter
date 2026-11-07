# v1.1.0 EXE 打包候選版

**狀態：本機打包候選，尚未正式發布。** 此執行檔以目前 0.1.0 原始碼作為打包輸入，版本資訊標為 `1.1.0.0`，提供測試之用；它不代表 v1.0.0 已先行正式發布。

## 使用方式

1. 將本資料夾完整解壓縮，保留 EXE、MIT 授權及第三方授權說明。
2. 雙擊 `圖片格式轉換器-v1.1.0.exe`。
3. 加入圖片，選擇輸出格式和資料夾，再按「開始轉換」。

此候選檔為 Windows x64 GUI 應用，使用 PS2EXE 1.0.18 將 Windows PowerShell 5.x 相容腳本包裝成 EXE。它不是原生 C# 重寫，也不是程式碼加密；EXE 內的 PowerShell 腳本可被抽出。請參閱 `THIRD-PARTY-NOTICES.txt`。此檔尚未簽署，Windows SmartScreen 或防毒軟體可能顯示警告；不要因警告而停用安全防護。

## 已執行的本機測試

- EXE 為 x64 PE，檔案版本資訊為 `1.1.0.0`。
- EXE 主視窗可啟動並正常關閉。
- 25 張混合 JPG/JFIF 匯入及重複路徑去重測試通過。
- PowerShell 語法、JFIF 解碼及 PNG/JPEG/BMP/GIF/TIFF 編碼器 smoke test 通過。

## 尚未完成的正式發布驗收

尚未在 EXE 中完成完整格式轉換矩陣、100 張大型批次、Windows 11 乾淨環境及 Defender 掃描驗收。v1.0.0 的完整 GUI 驗收亦未結束。因此這是測試候選檔，不是正式 v1.1.0 Release。校驗碼位於 `SHA256SUMS.txt`。
