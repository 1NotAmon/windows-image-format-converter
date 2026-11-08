# 版本資料夾

此資料夾依版本整理來源碼快照與 Windows 下載成品。根目錄仍是目前唯一的開發主線；版本資料夾是可下載快照，不取代或搬走根目錄原始碼。

- `v1.0.0/`：PowerShell/Windows Forms 來源碼候選快照，保留歷史驗收記錄；尚未建立正式 GitHub Release。
- `v1.1.0/`：舊版 EXE 打包候選包，已由 v1.2.0 單視窗修正版發布包取代；保留舊檔供追溯，不建議新下載者使用。
- `v1.2.0/`：原始碼 ZIP、x64 EXE、可攜式 EXE ZIP、右鍵選單工具、Release notes 及 SHA-256 校驗碼。內容已同步至公開 `main`（commit `50e39da`）；GitHub Actions run #37 通過。已知未驗收項目詳見 Release notes；目前正式標籤與資產狀態請見 [GitHub Releases](https://github.com/1NotAmon/windows-image-format-converter/releases)。

根目錄 `VERSION` 為 `1.2.0`，且已包含在 GitHub `main`。既有 `v0.1.0` 標籤與 Release 保持原樣，未發布的 `v1.0.0` 與 `v1.1.0` 候選快照也未更動；正式版狀態以 Releases 頁面為準。
