# v1.3.0 — Windows 批次圖片格式轉換器

- **發布日期：** 2026-11-09
- **標籤：** `v1.3.0`
- **下載：** [GitHub v1.3.0 Release](https://github.com/1NotAmon/windows-image-format-converter/releases/tag/v1.3.0)

## 下載

GitHub Release 提供繁體中文單檔 Setup `WindowsImageFormatConverter-Setup-v1.3.0.exe`、獨立 x64 EXE `WindowsImageFormatConverter-v1.3.0.exe`、原始碼 ZIP、可攜 EXE ZIP，以及 `RELEASE-ASSET-SHA256.txt` 校驗清單。獨立 EXE 在 Release 頁使用 ASCII 檔名，以避免附件名稱被截短；其內容與版本資料夾內的 `圖片格式轉換器-v1.3.0.exe` 相同。下載後請先核對 SHA-256；如檔案名稱或校驗值不符，請勿執行。

## 更新內容

- 主介面調整為白底黑字及黑色主要操作按鈕，按鈕、設定欄位與圖片清單外框加入圓角。
- 匯入前將圖片路徑正規化，改善相對路徑以及 `.`／`..` 別名造成的重複判斷。
- JPEG 編碼參數、Image／Bitmap 與 Graphics 資源於成功或例外路徑均會釋放。
- 延續批次格式轉換、支援的輸入／輸出格式、同名輸出不覆寫、多圖併入單一視窗，以及目前使用者範圍的檔案總管右鍵功能。
- 新增繁體中文 Windows x64 單檔安裝程式。安裝到目前使用者資料夾，不需要管理員權限，建立開始功能表捷徑；桌面捷徑可選，右鍵整合預設未勾選。

## 安裝與右鍵選單注意事項

安裝程式只為目前使用者安裝，不需管理員權限。若勾選「加入圖片右鍵選單」，它會取代本專案舊版本的右鍵登錄；解除安裝會移除該登錄，但不會還原舊版本。測試與日常使用若不需要右鍵功能，請保持未勾選。

若舊版轉換器視窗仍開啟，先確認圖片清單中的檔案不再需要，再關閉舊版視窗後使用新版本右鍵選單。程式不會強制關閉既有視窗；由於多版本共用單一視窗佇列，新圖片可能被送入仍開啟的舊版視窗。

## 本機驗收範圍

本機測試環境為 Windows 10 Home 22H2、Windows PowerShell 5.1。Smoke、250 張 JPG/JFIF 匯入與路徑別名去重、右鍵靜態回歸、9 種輸入副檔名 × 5 種輸出格式的 45 組轉檔後重開核對、100 張批次、透明 PNG、JPEG 白底與品質、巢狀資料夾、同名輸出保護、同資料夾不覆蓋原圖、損毀檔隔離、30 次 JPEG 資源釋放、EXE 三次近乎同時啟動合併為單一視窗，以及 Setup 隔離安裝／解除安裝測試均已通過。Setup 測試使用唯一暫存路徑，刻意不啟用右鍵整合，並確認使用者原有右鍵登錄未改變。

Microsoft Defender 即時防護已開啟；最終候選資料夾自訂掃描於 2026-11-09 完成，未偵測威脅。這只代表該次 Defender 掃描結果，**不代表 SmartScreen 信任、無警告或數位簽章有效**。

## 已知限制

- Setup 與應用 EXE 均未數位簽署；SmartScreen 可能顯示「Windows 已保護您的電腦」或其他未知應用警告。請勿停用 Windows 安全防護；若對來源或雜湊有疑慮，請勿執行。
- 本版本尚未在乾淨 Windows 10 VM 或 Windows 11 桌面環境驗收安裝、相容性與右鍵行為；目前本機驗收是在非乾淨 Windows 10 主機完成。
- 實際從檔案總管拖放圖片到 GUI 的人工驗收尚未完成。
- SmartScreen 信譽及簽章信任尚未驗證；Defender 掃描不能替代這些驗收。

## 安裝器工具授權提示

本安裝程式使用 Inno Setup 7.1.1 x64 編譯器產生；本次使用的編譯器輸出標示 `Non-commercial use only`。官方指出 Inno Setup 可供非商業使用，並請商業用戶購買授權。官方商業用戶條件包括年營收超過 USD 5,000 的營利組織，或以 Inno Setup 從事營利工作的個人／自由工作者；官方亦說明，開源／免費軟體收到的金錢捐款會計入該收入門檻。請由發布者依實際情況確認授權需求。細節及 Inno Setup 授權全文見 `THIRD-PARTY-NOTICES.txt`，官方資訊見 [下載與授權說明](https://jrsoftware.org/isdl.php/Inno-Setup-Downloads)、[商業授權 FAQ](https://jrsoftware.org/isorder.php) 與 [授權文本](https://jrsoftware.org/files/is/license.txt)。

本專案程式碼採 MIT License；第三方著作權與授權資訊另見 `THIRD-PARTY-NOTICES.txt`。
