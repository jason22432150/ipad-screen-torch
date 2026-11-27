# iPad Screen Torch

將閒置 iPad Air 2 改造成全螢幕智慧檯燈。目標實機：iPadOS 15.8.3；最低 iOS 15.0；arm64；完全離線；不需 Jailbreak。個人 IPA 安裝為主，不規劃 App Store 或 TestFlight。

**狀態：v0.1.0 Alpha 開發中；尚未放行。** CI #4 原生 Debug/Release 編譯、各 19 項測試（13 XCTest + 6 XCUITest）及未簽署 IPA 驗證通過；iPad Air 2 實機安裝與安全驗收仍待執行。詳見 [Alpha 進度](docs/ALPHA_PROGRESS.md) 與 [驗收清單](docs/ALPHA_VALIDATION.md)。

## 開發入口
先閱讀 [AGENTS.md](AGENTS.md) 與 [產品規格](docs/PRODUCT_SPEC.md)，依 [開發路線](docs/ROADMAP.md) 從 v0.1.0 開始。其他文件：

| 文件 | 內容 |
|---|---|
| [ARCHITECTURE](docs/ARCHITECTURE.md) | 模組、依賴、效能 |
| [UI_UX](docs/UI_UX.md) | 手勢、全螢幕、鎖定、頁面 |
| [STATE_MACHINE](docs/STATE_MACHINE.md) | 狀態轉移、仲裁、生命週期 |
| [BRIGHTNESS_ENGINE](docs/BRIGHTNESS_ENGINE.md) | 背光、極暗、同步 |
| [COLOR_ENGINE](docs/COLOR_ENGINE.md) | Kelvin、RGB、校正、情境 |
| [AUTOMATION_ENGINE](docs/AUTOMATION_ENGINE.md) | 計時、排程及電源事件 |
| [SAFETY](docs/SAFETY.md) | 熱、電池、診斷 |
| [DATA_SCHEMA](docs/DATA_SCHEMA.md) | 設定、備份、遷移 |
| [IOS15_COMPATIBILITY](docs/IOS15_COMPATIBILITY.md) | API 與平台限制 |
| [INSTALLATION](docs/INSTALLATION.md) | 個人簽署、IPA、CI |
| [TESTING](docs/TESTING.md) | 方案 B 驗收矩陣 |
| [ROADMAP](docs/ROADMAP.md) | 里程碑、實作順序 |

不應將本 App 視為經校準的光源或硬體安全控制器；老舊電池應先檢查。[CI #4 未簽署 IPA](https://github.com/jason22432150/ipad-screen-torch/actions/runs/45956631549/artifacts/15179229182) 可供個人簽署與驗收（尚未放行，Artifact 有效期至 2026-12-04 UTC）。
