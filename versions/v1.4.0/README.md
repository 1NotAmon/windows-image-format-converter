# 圖片格式轉換器 v1.4.0

本資料夾保存 v1.4.0 Windows 安裝程式、可攜版、原始碼與驗收紀錄。正式 tag、Release 狀態及下載頁請以 [GitHub Releases](https://github.com/1NotAmon/windows-image-format-converter/releases) 為準。

## 本版改良

- 顯示整批即時進度、目前處理的圖片名稱，以及成功、失敗、待處理數量。
- 可取消批次；會先完成目前圖片，再停止後續圖片。
- 完成／取消時提供結果通知，並可一鍵開啟輸出資料夾。
- 結果清單新增輸出檔名；失敗項目可檢視並複製完整錯誤資訊。
- 記住上次的輸出格式、JPEG 品質與輸出資料夾；設定只保存在目前 Windows 使用者本機，不保存圖片清單。

## 下載成品

- `WindowsImageFormatConverter-Setup-v1.4.0.exe`：目前使用者安裝程式，不需系統管理員權限。
- `WindowsImageFormatConverter-v1.4.0.exe`：獨立 x64 應用程式。
- `windows-image-format-converter-v1.4.0-portable.zip`：可攜 EXE 與必要說明。
- `windows-image-format-converter-v1.4.0-source.zip`：原始碼、測試、工具與文件。
- `RELEASE-ASSET-SHA256.txt`：Release 二進位檔 SHA-256 校驗清單。

安裝程式中的桌面捷徑與 Explorer 右鍵整合可選；右鍵整合預設不勾選。若勾選，會取代本專案既有右鍵登錄；解除安裝時只移除本版登錄，不會還原先前版本的設定。

## 驗收與安全限制

Windows 10 本機已通過 250 張 JPG/JFIF 匯入、9×5 轉檔與輸出重開、100 張批次、取消、設定記憶、既有檔案保護、錯誤明細、JPEG 資源釋放、x64 EXE 單視窗及隔離安裝／解除安裝測試。封存結構與 SHA-256 亦已核對；Microsoft Defender 自訂掃描在候選資料夾 0 偵測。完整驗收快照見 [`CANDIDATE-STATUS.txt`](CANDIDATE-STATUS.txt)。

尚未在乾淨 Windows 10／11 驗收，實際 GUI 拖放也未完成人工驗收。EXE 與 Setup 未數位簽署，SmartScreen 信譽未驗證；Defender 無偵測不代表 SmartScreen 或程式碼簽章信任。正式 tag 的 Actions 狀態可在 GitHub commit 的 Checks／Actions 頁面查看。

安裝程式以 Inno Setup 7.1.1 非商業版編譯器建置（編譯器標示「Non-commercial use only」）。使用或散布此 Setup 前，請確認符合 Inno Setup 官方授權與商業使用政策；第三方聲明見 [`THIRD-PARTY-NOTICES.txt`](THIRD-PARTY-NOTICES.txt)。