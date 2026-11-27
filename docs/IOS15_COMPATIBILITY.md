# iPadOS 15 相容性與限制

Deployment Target 15.0、TARGETED_DEVICE_FAMILY=2、arm64、Swift 5 language mode；目標實機 iPad Air 2 iPadOS 15.8.3。較新 SDK 不代表提高 Deployment Target；使用能在開發 Mac 運行且支援 iOS 15 裝置偵錯的 Xcode，實際版本須先確認並在 build-info 記錄，不硬鎖未驗證版本。

| API | 使用 |
|---|---|
| UIKit UIScreen.brightness / brightnessDidChangeNotification | 系統亮度控制及觀察 |
| UIApplication.isIdleTimerDisabled | 前景保持螢幕，離開恢復 |
| ProcessInfo.thermalState / thermalStateDidChangeNotification | 熱級別 |
| UIDevice.batteryLevel / batteryState / notifications | 電源及電量 |
| UIViewController.prefersStatusBarHidden / preferredScreenEdgesDeferringSystemGestures | 隱藏狀態列、延後邊緣手勢 |
| supportedInterfaceOrientations / attemptRotationToDeviceOrientation() | 四方向、限制可用方向；不保證強制旋轉 |
| UIRequiresFullScreen | iPadOS 15 全螢幕、多工排除 |
| UIAccessibility.isGuidedAccessEnabled / guidedAccessStatusDidChangeNotification | 引導使用狀態 |
| ObservableObject/Combine / SwiftUI UIHostingController | UI state |
| LocalAuthentication / Security | Touch ID、裝置驗證、Keychain |
| UIDocumentPickerViewController / Codable | 本機匯入匯出 |

禁止 iOS 16+ requestGeometryUpdate 作為必要依賴；NavigationStack、@Observable、SwiftData、ActivityKit 不使用。不要用 KVC 改 UIDevice orientation、Private API、背景保活。App 無法阻止 Home/電源/通知所有系統行為、無法從鎖屏自動開燈、無法強制自動重啟、無法真正關閉背光同時維持觸控、無法自行調整充電上限；Night Shift/色彩濾鏡/系統自動亮度可影響輸出。真機驗證必要。

## 官方參考（實作時核對 API availability）
- https://developer.apple.com/documentation/uikit/uiscreen/brightness
- https://developer.apple.com/documentation/uikit/uiapplication/isidletimerdisabled
- https://developer.apple.com/documentation/foundation/processinfo/thermalstate
- https://developer.apple.com/documentation/uikit/uidevice/batterylevel
- https://developer.apple.com/documentation/uikit/uiviewcontroller/supportedinterfaceorientations
- https://developer.apple.com/support/xcode/
- https://support.apple.com/en-us/111795
