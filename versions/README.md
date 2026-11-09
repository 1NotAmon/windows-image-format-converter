# 版本資料夾

此資料夾依版本整理來源碼快照與 Windows 下載成品。根目錄仍是目前唯一的開發主線；版本資料夾保存可追溯的發行資產與驗收紀錄。

- `v1.0.0/`：PowerShell／Windows Forms 來源碼候選快照，保留歷史驗收記錄；沒有正式 Release。
- `v1.1.0/`：舊版 EXE 打包候選包，已由 v1.2.0 多圖單視窗修正版取代；保留舊檔供追溯。
- `v1.2.0/`：原始碼 ZIP、x64 EXE、可攜式 EXE ZIP、右鍵工具、Release notes 及 SHA-256。Actions run #37 通過；歷史發布維持不變。
- `v1.3.0/`：已發布版本，提供繁體中文單檔 Setup、獨立 x64 EXE、原始碼／可攜 ZIP 與 SHA-256。Setup／EXE 未簽署；乾淨 Windows、實際 GUI 拖放與 SmartScreen／簽章信任未驗證。
- `v1.4.0/`：即時進度、批次取消、結果欄／錯誤明細、輸出資料夾捷徑與設定記憶。Windows 10 本機功能、EXE、隔離安裝／解除安裝、ZIP／hash 測試通過；Defender 自訂掃描為 0 偵測。乾淨 Windows 10／11、GUI 拖放及 SmartScreen／簽章信任未驗證；Inno Setup 7.1.1 使用限制見該版第三方聲明。

正式 tag、Release 與下載狀態請以 [GitHub Releases](https://github.com/1NotAmon/windows-image-format-converter/releases) 為準。v0.1.0、v1.2.0 與 v1.3.0 歷史發布不因新版本而覆寫或刪除。