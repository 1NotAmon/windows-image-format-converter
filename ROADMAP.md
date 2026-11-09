# 版本路線圖與發布驗收計畫

> 更新日期：2026-11-09。v1.2.0、v1.3.0 與 v0.1.0 的既有發布保持不變。v1.4.0 功能／EXE／隔離安裝／ZIP 驗收通過，Defender 自訂掃描為 0 偵測；正式標籤與 Release 狀態請以 [GitHub Releases](https://github.com/1NotAmon/windows-image-format-converter/releases) 為準。乾淨 Windows 10／11、實際 GUI 拖放與 SmartScreen／簽章信任仍未驗證。

## 版本資料夾原則

- 已發布的 `v0.1.0` 標籤與 Release 保持原樣，不移動、不覆寫、不刪除。
- 根目錄是唯一開發主線；`VERSION` 為 `1.4.0`，正式發布狀態以 GitHub Releases 的標籤為準。
- `versions/` 保存 `v1.0.0` 與 `v1.1.0` 歷史候選快照，以及 v1.2.0 起各版本的發布包與驗收資料。
- 未完成的驗收仍須標記為未驗證；不得把 Defender 無偵測等同 SmartScreen 或簽章信任。

## 版本概覽

| 版本 | 目的 | 狀態 |
| --- | --- | --- |
| `v1.0.0` | PowerShell／Windows Forms 來源碼版 | 來源碼候選快照；完整 GUI 驗收尚未完成 |
| `v1.1.0` | Windows x64 EXE 封裝 | 舊候選包，已由 v1.2.0 候選更新取代 |
| `v1.2.0` | 修正多圖多視窗並提供來源碼及 EXE | 已同步至 `main`；Actions #37 通過；正式 tag／Release 狀態見 Releases 頁面 |
| `v1.3.0` | 白黑圓角介面、匯入路徑正規化、資源釋放補強及單檔安裝程式 | 已建立正式 GitHub Release；Windows 10 本機功能／EXE／隔離安裝與解除安裝測試通過；乾淨 Windows、拖放、SmartScreen／簽章信任未驗證 |
| `v1.4.0` | 即時逐檔進度、取消、結果欄／錯誤明細、輸出資料夾捷徑及設定記憶 | 本機來源／格式／取消／設定／EXE／隔離安裝／ZIP／hash 測試通過；Defender 候選資料夾掃描 0 偵測；正式發布狀態以 Releases 為準，乾淨 Windows、GUI 拖放與 SmartScreen／簽章信任未驗證 |

## v1.0.0：來源碼正式版驗收條件

1. **匯入計數可靠。** 檔案選取、資料夾遞迴匯入及拖放使用同一套副檔名白名單與去重規則；25 張混合 JPG/JFIF 測試需全數列入，沒有 16／21 張的人為上限。
2. **輸出結果可驗證。** PNG、JPEG、BMP、GIF、TIFF 實際轉換後須重新開啟驗證；透明圖片轉 JPEG 為白底，JPEG 品質設定有效。
3. **保護既有檔案。** 不覆寫來源或既有輸出；同名輸出採序號命名。單張失敗須顯示檔名及可理解原因，且不阻止其他可處理檔案。
4. **操作狀態清楚。** 顯示逐檔狀態與成功／失敗數；未支援取消時不提供假取消功能。
5. **啟動器明確。** VBS 只啟動主程式 `圖片格式轉換器.ps1`。
6. **下載內容完整。** MIT 授權、系統需求與使用說明隨來源包保留。
7. **右鍵整合可還原。** 支援目前使用者範圍的圖片 verb、多選路徑與單一視窗併入；提供精確移除腳本且不需管理員權限。

### v1.2.0 正式發布驗收矩陣

- 25 張 JPG/JFIF 匯入及重複路徑去重：本機測試及 GitHub Actions run #37 通過。
- 語法、UTF-8 BOM、VBS 編碼及 PNG/JPEG/BMP/GIF/TIFF 編碼器 smoke test：本機通過。
- 右鍵路徑傳送與空格／中文檔名：當時的 Windows 10 Home 22H2 右鍵登錄指向 v1.2.0，並確認 Explorer 啟動流程載入圖片列；仍需乾淨 Windows 11 人工驗收。
- 近乎同時啟動多個程式並合併到單一視窗：來源碼及候選 EXE 的回歸測試通過。
- 巢狀資料夾遞迴、重複路徑、同名輸出不覆寫、損毀圖片隔離：本機驗收測試通過；實際 GUI 拖放操作仍待人工驗證。
- 9 種輸入副檔名 × 5 種輸出格式共 45 組實際轉檔後重新開啟並核對格式與尺寸：本機及 GitHub Actions run #37 通過；PNG 透明度、JPEG 白底與品質設定也通過。
- 100 張批次轉檔：本機及 GitHub Actions run #37 通過。乾淨 Windows 10／11 環境驗收仍待取得對應測試環境。
- 實際拖放、乾淨 Windows 10／11 與 Windows 11 右鍵、SmartScreen／簽章檢查未完成，不能標為通過；限制見 v1.2.0 Release Notes。

## v1.1.0：舊 EXE 候選版

- 曾以固定版 PS2EXE 1.0.18 建置 x64 GUI EXE，版本資訊為 `1.1.0.0`。
- 此候選已由 v1.2.0 修正版包取代；舊檔保留供追溯，不應作為最新下載。
- v1.1.0 沒有正式建立 tag 或 GitHub Release。

## v1.2.0：發布驗收紀錄（已知限制明列）

- 此版本修正 Windows 檔案總管分別啟動多個圖片程序時，圖片會各自開啟視窗的問題；後續圖片路徑會合併至單一轉換器視窗。
- 提供來源碼 ZIP、以 PS2EXE 1.0.18 打包的 x64 EXE、可攜式 EXE ZIP、安裝／移除右鍵選單工具、Release notes 及 SHA-256 校驗碼。
- EXE 檔案版本資訊為 `1.2.0.0`；根目錄 `VERSION` 曾更新為 `1.2.0`。
- 本機已通過 25 張 JPG/JFIF 匯入、去重、影像編碼器 smoke、右鍵參數／安裝器回歸、三個近乎同時 EXE 啟動合併為一個視窗，以及 9×5 實際轉檔與重開、100 張批次、巢狀資料夾、同名不覆寫、損毀檔隔離、透明度及 JPEG 品質驗收；來源碼 ZIP 解壓後的既有測試也通過。Microsoft Defender 自訂掃描 v1.2.0 資料夾完成，沒有該目錄的威脅偵測。
- 發布準備更新已同步至 GitHub `main` commit `50e39da`；Actions run #37 成功（22 秒），包括 25 張匯入、smoke、EXE 單視窗、完整轉檔矩陣／100 張批次及右鍵整合測試。詳細結果見 [run #37](https://github.com/1NotAmon/windows-image-format-converter/actions/runs/42499248648)。
- 實際 GUI 拖放、乾淨 Windows 10／11 與 Windows 11 右鍵人工驗收，以及 SmartScreen／簽章信任檢查仍未完成。EXE 未數位簽署，這些限制不能視為通過。

## 目前狀態

- `v0.1.0`、v1.2.0 與 v1.3.0 的歷史發布保持不變；目前正式標籤與資產狀態以 [GitHub Releases](https://github.com/1NotAmon/windows-image-format-converter/releases) 為準。
- `versions/v1.0.0/` 與 `versions/v1.1.0/` 保留歷史候選；`versions/v1.2.0/`、`versions/v1.3.0/` 與 `versions/v1.4.0/` 保存各版資產與驗收資料。
- 根目錄 `VERSION=1.4.0`；此檔不作為 GitHub tag／Release 是否建立的證據，請查閱 Releases 頁面。
- v1.3.0 的 250 張匯入、45 組轉檔、100 張批次、來源檔保護、損毀檔隔離、30 次 JPEG 資源釋放、單一視窗及右鍵安裝／移除往返已在本機 Windows 10 通過；HKCU 原始設定測試後逐位元還原。新增 Setup 已於唯一暫存路徑完成目前使用者安裝／解除安裝、開始功能表捷徑與卸載紀錄測試；右鍵任務刻意未啟用，現有 HKCU 右鍵設定未變。
- v1.3.0 實際 GUI 拖放、乾淨 Windows 11 右鍵與 SmartScreen／簽章信任仍未驗收；不能標為通過。
- v1.4.0 的 Smoke、250 張匯入、右鍵靜態、45 組轉檔、100 張批次、取消後列／輸出、設定記憶、EXE 三程序單一視窗、隔離安裝／解除安裝及 source／portable ZIP 雜湊驗收已在本機通過；候選資料夾 Defender 自訂掃描為 0 偵測。乾淨 Windows、實際 GUI 拖放與 SmartScreen／簽章信任未完成；GitHub Actions 狀態請查看倉庫 Actions 頁面。
