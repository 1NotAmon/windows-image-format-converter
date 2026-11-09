# v1.4.0 — Release Notes

v1.4.0 著重於批次轉換狀態可見性、取消控制、結果診斷與重複使用設定。

## 改良

- 加入整批即時進度、目前正在處理的檔名，以及成功、失敗、待處理數量。
- 增加取消批次操作；點選後先完成目前正在轉換的圖片，再停止後續工作。
- 批次完成或取消時顯示摘要通知；增加一鍵開啟輸出資料夾。
- 結果清單增加實際輸出檔名；失敗項目可查看及複製完整錯誤詳情。
- 記住使用者上次選擇的輸出格式、JPEG 品質和輸出資料夾；不保存圖片清單或圖片內容。

## 驗收範圍

Windows 10 本機已通過 250 張 JPG/JFIF 匯入、右鍵靜態回歸、9 種輸入副檔名 × 5 種輸出格式並重新開啟驗證、透明 PNG／JPEG 品質、巢狀匯入、既有檔案與來源保護、損毀檔錯誤明細、30 次 JPEG 資源釋放、100 張批次、取消後列狀態、設定記憶、v1.4.0 x64 EXE 單視窗，以及以唯一 AppId 執行的隔離安裝／解除安裝測試。原有 v1.3.0 安裝與 Explorer 右鍵設定未在安裝測試中被修改。source／portable ZIP 結構及 SHA-256 已核對。Microsoft Defender 對候選資料夾自訂掃描為 0 偵測；這不代表 SmartScreen 信任或程式碼已簽章。GitHub Actions 執行狀態可從本版本 commit／tag 的 Checks 頁面確認。

## 尚未驗證與注意事項

- 未在乾淨 Windows 10／11 環境驗收；實際 GUI 拖放也未完成人工驗收。
- EXE 與 Setup 未數位簽署，SmartScreen 信譽未驗證。不要為了執行程式而停用 Windows 安全防護。
- 安裝器以 Inno Setup 7.1.1 非商業版編譯器建置，編譯器標示「Non-commercial use only」。公開散布或商業使用前，請確認符合 Inno Setup 官方授權／商業使用政策。
- 右鍵整合安裝選項預設關閉。若選用，它會取代本專案現有右鍵登錄；解除安裝會移除本版登錄，但不會還原舊版本設定。

正式標籤與下載資產請以 [GitHub Releases](https://github.com/1NotAmon/windows-image-format-converter/releases) 為準；可下載資產的 SHA-256 見 `RELEASE-ASSET-SHA256.txt`。