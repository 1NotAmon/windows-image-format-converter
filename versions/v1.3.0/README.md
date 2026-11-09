# Windows 批次圖片格式轉換器 v1.3.0

> 正式版本標籤：`v1.3.0`。請從 [GitHub v1.3.0 Release](https://github.com/1NotAmon/windows-image-format-converter/releases/tag/v1.3.0) 下載；v1.2.0 與 v0.1.0 歷史發布保持不變。

## Release 下載項目

- `WindowsImageFormatConverter-Setup-v1.3.0.exe`：繁體中文 Windows x64 安裝程式，預設安裝到目前使用者資料夾，不需管理員權限。
- `WindowsImageFormatConverter-v1.3.0.exe`：獨立可攜版 x64 EXE。GitHub Release 使用 ASCII 檔名以確保附件名稱完整；檔案內容與本版本資料夾中的 `圖片格式轉換器-v1.3.0.exe` 相同。
- `windows-image-format-converter-v1.3.0-source-candidate.zip`：原始碼與建置／測試文件。
- `windows-image-format-converter-v1.3.0-exe-candidate.zip`：可攜 EXE 套件。
- `RELEASE-ASSET-SHA256.txt`：Release 頁面上 Setup、獨立 EXE 和兩個 ZIP 的校驗值。ZIP／資料夾內另有對應的 SHA-256 manifest。

所有檔案均列於 [GitHub v1.3.0 Release](https://github.com/1NotAmon/windows-image-format-converter/releases/tag/v1.3.0)。

## 安裝方式

執行 `WindowsImageFormatConverter-Setup-v1.3.0.exe`，依安裝精靈操作。安裝程式只為目前使用者安裝，不需管理員權限，並建立開始功能表捷徑；桌面捷徑可選。解除安裝可從 Windows「設定 > 應用程式」或開始功能表中的解除安裝項目執行。

圖片右鍵整合預設不勾選。若你明確勾選，安裝程式會取代本專案舊版本的右鍵登錄；解除安裝會移除該登錄，但不會還原舊版本的設定。安裝測試刻意未勾選右鍵整合，以免變更使用者既有設定。

如果舊版轉換器視窗還開著，先確認圖片清單中的檔案不再需要，再關閉舊視窗後使用新版本右鍵選單。新舊版共用單一視窗佇列，舊視窗仍開啟時，新圖片可能送入舊視窗。安裝器不會強制關閉既有程式。

## v1.3.0 變更

- 主介面改為白底黑字與黑色主要操作按鈕，按鈕、輸出設定欄位及圖片清單外框加入圓角。
- 匯入前將路徑正規化，避免相對路徑與 `.`／`..` 別名造成重複列。
- 改善 JPEG 編碼參數與 GDI+ 影像資源在成功和例外路徑的釋放。
- 新增目前使用者免管理員的繁體中文安裝程式，支援開始功能表捷徑、選擇性桌面捷徑和選擇性 Explorer 圖片右鍵選單。
- 延續 v1.2.0 的單一視窗、批次轉檔、不覆寫既有檔案及右鍵選單安裝／移除功能。

## 驗收與安全說明

本機於 Windows 10 Home 22H2／Windows PowerShell 5.1 執行驗收：250 張 JPG/JFIF 匯入與路徑別名去重；9 種輸入副檔名 × 5 種輸出格式，共 45 組轉檔後重新開啟核對；100 張批次；透明 PNG、JPEG 白底與品質、巢狀資料夾、既有檔案保護、損毀檔隔離、30 次連續 JPEG 資源釋放、EXE 單一視窗，以及 Setup 隔離安裝／解除安裝測試通過。完整記錄見 `CANDIDATE-STATUS.txt`。

Setup 與 EXE 均未數位簽署，Windows SmartScreen 可能顯示警告；請勿停用安全防護。Microsoft Defender 對本機候選資料夾掃描無偵測，不代表 SmartScreen 信任或簽章驗證。尚未在乾淨 Windows 10／11 環境驗收，也未完成實際 Explorer 拖放圖片至 GUI 的人工測試。

安裝程式使用 Inno Setup 7.1.1 編譯器；該編譯器輸出標示 `Non-commercial use only`。官方說明非商業使用可免費使用；官方商業用戶條件、開源／免費軟體捐款如何計入收入，以及完整授權資訊，請見套件內 `THIRD-PARTY-NOTICES.txt`。若專案用於營利或符合官方商業用戶條件，發布者應先確認商業授權需求。

本專案程式碼採 MIT License。PS2EXE、Inno Setup 等第三方授權資訊見 `THIRD-PARTY-NOTICES.txt`。
