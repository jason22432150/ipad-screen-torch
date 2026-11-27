# AI 開發代理必讀

## 任務
依 README 與 docs/ 實作 iPad Screen Torch。規格已確認；目前只有文件，從 v0.1.0 開始，不一次實作全部版本。

## 不可違反
- iOS 15.0 Deployment Target，iPad Air 2 / iPadOS 15.8.3 實機為必要驗收；arm64、Swift 5 language mode、原生 UIKit + SwiftUI。
- 不用 Private API、Jailbreak 特權、第三方必要套件、網路依賴、廣告、追蹤。不得修改系統安全設定。
- 所有硬體寫入經單一 service，在 MainActor 執行；所有操作走 Store/reducer/安全仲裁；不能繞過過熱、低電量、緊急停止。
- 只在前景可照明及可靠排程；背景不得偽造常駐，不濫用音訊或定位背景模式；不可宣稱能喚醒鎖定裝置、關閉 LCD 背光或讀取精確溫度。
- 使用者要求亮度與有效亮度分開；保護不覆寫偏好。Critical 停止後須手動確認。
- 不將 PIN、憑證、描述檔、Apple ID、裝置 UDID 或真實診斷資料提交至 Git。
- 不使用 iOS 16/17+ 必要 API；必要的新 API 必須有 availability guard 與 iOS 15 fallback。
- 測試方案 B：Debug/Release、XCTest、XCUITest、Mock、安全、排程、遷移、IPA、實機；不得假稱未跑的測試通過。耐久/效能基準自動報告選用。
- 既有通過測試不得刪除以掩蓋錯誤；遇實機驗證、簽名或安全問題，明確報告需要使用者介入的項目。
- 每個階段先讀文件、確認 Git 狀態、實作小步驟、編譯測試、記錄結果；使用 Conventional Commits，禁止無授權 force push。
- 本機腳本為 CI 共用入口；不擅自啟用耗用額度的雲端 workflow，先明確 runner 與觸發策略。

## 文件優先序
PRODUCT_SPEC 定義範圍，STATE_MACHINE/SAFETY 定義安全仲裁，專項 engine/UI/data 文件定義契約，TESTING 定義必要驗收。遇矛盾優先安全、iOS 15 公開 API、最後確認的 B 安裝與 B 測試；仍無法解決則記錄並詢問，不偷偷改規格。

## 第一個任務
建立 Xcode iPad target、零依賴 Core、UIKit lamp surface + SwiftUI overlay、Store、Mock services、基本亮度/色溫、手勢與最低安全保護；建立測試與本機 build 腳本。第一版即須驗證真機 IPA 安裝，不可延後核心安全。
