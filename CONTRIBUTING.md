# 貢獻指南

感謝你想協助改善本專案。提交 Issue 或 Pull Request 前，請先遵守以下原則。

## 回報問題

請提供：

- Windows 版本與 PowerShell 版本（`$PSVersionTable.PSVersion`）。
- 重現步驟、來源圖片副檔名、目標格式。
- 程式清單顯示的錯誤訊息或相關截圖。

請勿在公開 Issue 上傳私人圖片、個人資料或其他敏感檔案。若問題可用虛構圖片重現，請使用小型測試圖片。

## 提交修改

1. 先開 Issue 或在既有 Issue 討論較大的功能變更。
2. 保持主程式相容 Windows PowerShell 5.1；不要要求使用者額外安裝套件，除非先在 Issue 討論。
3. `.ps1` 檔必須以 UTF-8 BOM 儲存，確保 Windows PowerShell 5.1 可正確讀取繁體中文。
4. 執行 `tests/SmokeTest.ps1` 與 `tests/ImportCountTest.ps1`；後者需以 STA 執行，並在 Pull Request 描述中註明結果。
5. 若修改 EXE 打包內容，請先重建候選 EXE，再執行 `tests/PackageTest.ps1`。
6. 說明使用者可見行為的變更，並同步更新 README 與 CHANGELOG。

## 授權

本專案採用 MIT License，詳見 [`LICENSE`](LICENSE)。貢獻內容將依本專案的 MIT License 發布；提交前請確認你有權提供該內容。
