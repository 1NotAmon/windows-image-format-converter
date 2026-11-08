# Windows 批次圖片格式轉換器 v1.2.0 — Release Notes

> 本文件說明 v1.2.0 的功能、測試範圍與尚未完成的驗收。Git 標籤與正式下載資產的目前狀態，請以 [GitHub Releases](https://github.com/1NotAmon/windows-image-format-converter/releases) 頁面為準。

## 版本資訊

- **版本：** `v1.2.0`
- **平台：** Windows x64；Windows 10 或更新版本
- **EXE 檔案版本：** `1.2.0.0`
- **數位簽章：** EXE **未經數位簽署**；Windows 無法透過此 EXE 的數位簽章確認發行者身分。
- **SmartScreen 信任：** 尚未完成 SmartScreen 信譽／信任驗證，也沒有可宣稱 SmartScreen 已認可此程式的資料。

## 主要更新

- 修正檔案總管多選圖片時，圖片路徑可能分別開啟多個轉換器視窗的問題；多次啟動的圖片會合併至同一視窗。
- 支援 PNG、JPG/JPEG、JFIF、BMP、GIF、TIF/TIFF、ICO 輸入；可輸出 PNG、JPEG、BMP、GIF、TIFF。
- 提供可逆的目前使用者右鍵選單安裝／移除工具，不需要系統管理員權限。
- 保護既有檔案，同名輸出會改用序號檔名；JPEG 品質可調整，透明圖片轉 JPEG 時以白色填補透明區。

## 未簽章與 SmartScreen 說明

本版本 EXE 未簽章，因此沒有經驗證的發行者名稱，也無法藉由 Authenticode 簽章確認 EXE 的發行者與簽署後完整性。SmartScreen 的信譽狀態未經測試；Windows 可能依系統版本、下載來源及應用程式信譽顯示「Windows 已保護您的電腦」或其他未識別應用程式警告。警告畫面可能不同；出現警告不單獨證明程式有害，但本 Release 也沒有 SmartScreen 信任背書。

**請勿為了執行本程式而停用 SmartScreen、Microsoft Defender 或其他安全防護，也不建議選擇略過警告或「仍要執行」。**若不確定來源或檔案是否可信，請取消執行。不要只因為掃描未偵測就認定程式一定安全。

可用 PowerShell 計算下載檔案的 SHA-256：

```powershell
Get-FileHash .\圖片格式轉換器-v1.2.0.exe -Algorithm SHA256
```

請將結果與 Release 隨附的 `SHA256SUMS.txt` 比對。來源 ZIP 與 EXE ZIP 的雜湊分別見 `SOURCE-SHA256.txt` 和 `ZIP-SHA256.txt`。雜湊比對可確認檔案與所取得的校驗值相符，**不能證明發行者身分、SmartScreen 信任或檔案絕對安全**。

## 本機與 CI 驗證範圍

本機測試環境為**非乾淨安裝**的 Windows 10 Home 22H2（Build 19045）。本機自動測試通過：25 張 JPG/JFIF 匯入與重複路徑去重；x64 EXE 啟動及多程序併入單一視窗；9 種輸入副檔名 × 5 種輸出格式共 45 組實際轉檔、重新開啟並核對格式與尺寸；100 張批次轉換；PNG 透明度；JPEG 白底及品質；巢狀資料夾；同名不覆寫；以及損毀檔與有效檔混合時的錯誤隔離。

GitHub Actions run #37（commit `50e39da`）成功，執行 25 張 JPG/JFIF 匯入回歸、Windows PowerShell smoke test、v1.2 EXE 單視窗封裝測試、完整轉檔矩陣／100 張批次及檔案總管右鍵整合回歸。[完整轉檔驗收日誌](https://github.com/1NotAmon/windows-image-format-converter/actions/runs/42499248648)顯示：五種輸出格式均以 9 種輸入副檔名轉檔並重新開啟成功；巢狀資料夾／去重、同名不覆寫、損毀檔隔離、100 張輸出及 JPEG 品質比較均為 PASS。

Microsoft Defender 曾對本機 v1.2.0 資料夾執行自訂掃描，當次掃描未偵測到威脅。這只記錄該電腦、該次掃描的結果；**不等於 SmartScreen 驗證、程式簽章、安全認證，也不保證其他電腦或未來掃描結果相同**。

## 尚未完成的驗收

- 尚未完成實際 GUI 拖放操作測試。
- 尚未在乾淨 Windows 10／11 安裝環境驗證；乾淨 Windows 11 檔案總管右鍵操作也尚未人工確認。
- 尚未驗證 SmartScreen 信譽，且目前 EXE 未簽章。

以上限制已獲接受並會在 v1.2.0 發布頁面明確揭露；它們仍屬未驗證，不應對外宣稱已通過。若不確定檔案來源或信任狀態，請勿執行。既有 `v0.1.0` Release 保持不變。

## 授權

原始碼採 MIT License。EXE 使用 PS2EXE 1.0.18 封裝；第三方授權說明隨 EXE 套件提供。
