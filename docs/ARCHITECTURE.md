# 架構與效能

## 技術選型
iPad-only Swift 5 language mode、UIKit root surface/手勢/方向、SwiftUI overlay/settings、Foundation、Combine、LocalAuthentication、Security、XCTest/XCUITest。ObservableObject/@Published；不用 @Observable、SwiftData、NavigationStack、Metal、WebView 或常駐 render loop。

```
Presentation: LampViewController + UIHostingController + Feature Views
    -> LampAction -> @MainActor LampStore (Reducer)
    -> Domain: Brightness / Color / Safety / Automation / Lock / Presets
    -> Effects: Screen / IdleTimer / Battery / Thermal / Clock / Persistence / Auth / Diagnostics
    -> Public iPadOS APIs
```
Domain 純邏輯，不依賴 UIKit、真實時鐘或檔案；Store 為唯一 runtime truth。同步 reduce，effects 回傳事件；序列化事件處理，非同步結果需 generation/token 防止過期回寫。硬體 service 唯一寫入者，主執行緒；持久化以序列 queue/actor 執行。UI 不直接改硬體。Mock protocol 注入時間、亮度、idle timer、熱、電量、檔案及驗證；不得讓測試真的過熱或放電到危險。

## 模組目錄（後續建立）
iPadScreenTorch.xcodeproj；iPadScreenTorch/{App,Core/{Models,State,Events,Protocols},Engines/{Brightness,Color,Automation,Safety,Lock},Services/{Hardware,Battery,Thermal,Persistence,Authentication,Diagnostics},Features/{Lamp,ControlPanel,Presets,Schedules,Settings,Diagnostics},Resources/{Assets.xcassets,zh-Hant.lproj,en.lproj}}；iPadScreenTorchTests、iPadScreenTorchUITests、scripts、.github/workflows（可選）。

## Protocol 契約
| Service | 職責 |
|---|---|
| ScreenBrightnessService | read/write normalized backlight、外部變更事件、ownership |
| IdleTimerService | 擷取/恢復初始 idleTimer 設定 |
| BatteryService | level optional、charging/full/unplugged/unknown、事件 |
| ThermalService | nominal/fair/serious/critical/unknown、事件 |
| ClockService | wall Date、monotonic elapsed、一次性 deadline、取消 |
| PersistenceService | load/save validated snapshot、backup、migration |
| AuthenticationService | Keychain PIN verifier、LAContext auth、結果 |
| DiagnosticsService | bounded event ring、按需採樣、匯出 |

## 效能
靜態與待機事件驅動，不自行重繪；手勢/短動畫最多 30 updates/s，日出日落原則每秒更新；排程以最近 deadline 單次 timer，熱/電池採通知；診斷頁顯示時才週期採樣，隱藏面板停止非必要 UI 更新。Serious 停動畫，Critical 立即中止。目標 CPU 平均<1%、RAM<80MB、冷啟動≤2s、手勢≤100ms、IPA≤15MB；屬最佳化目標，B 方案非硬性完整基準驗收。不可宣稱 LCD 自身停止刷新。測試覆蓋核心目標90%、整體80%；紀錄實測而非偽造。
