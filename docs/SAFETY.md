# 安全與診斷

## 熱保護（不可停用）
ProcessInfo.thermalState 與 thermalStateDidChangeNotification；啟動、復歸先讀狀態。Nominal 100%、Fair 80%、Serious 40%（停止非必要動畫）、Critical 0%（立即關燈、允許休眠、persistent latch、禁止自動開燈）。未知狀態初始保守上限40%。降限立即執行；較低熱狀態持續120秒後，每秒最多恢復2個百分點，回熱立即降限並取消恢復。Critical latch 需熱狀態正常持續120秒且使用者確認（初始保守條件），先進待機再明確開燈。不得刻意加熱裝置測試。公開 API 無法讀取精確電池/CPU攝氏溫度。

## 電源策略
UIDevice.isBatteryMonitoringEnabled、batteryLevel/batteryState、通知；使用時啟用，釋放時恢復監控偏好。charging/full 視插電；unplugged 電池；unknown 保守。電池供電（整數顯示非實際精度）：>50% cap100，>20…50 cap80，>10…20 cap50，>5…10 cap20，≤5 cap0；插電>5 cap100，≤5 cap0，unknown level/state cap40（暫定）。切換供電立即重新計算；低電量停機需電量恢復安全範圍並手動確認，不因插電自動重新開燈。未知狀態不能清除 latch。使用者 profile 不能提高安全上限。最終 effective 為 requested/thermal/battery 最低值，安全停止與 emergency 覆蓋0。

## 診斷
裝置型號（可用 identifier 映射，未知不猜）、OS、App version/build、uptime、CPU/RAM（公開可用方式或標 unavailable，不能造數）、battery/power/thermal、requested/effective、color mode、觸發次數；頁面可見時採樣，安全/自動化事件驅動，按需匯出 JSON。安全事件最多1000、自動化500；診斷日誌建議最多1000筆及5MB上限，循環截斷，不含 PIN/憑證/識別帳號，匯出由使用者主動發起。錯誤重試有界；記憶體警告清理非必要 cache。

## 實體設備
Apple 建議環境0…35°C（參考 https://support.apple.com/en-us/118431 ）。通風支架、可靠充電器，不遮蓋背面、不曝曬；電池膨脹、螢幕隆起或異常熱立即停止使用/充電，先檢修。軟體不能保證老電池安全、不能控制充電停止百分比。使用者需能以實體按鍵/拔電停止；拔電本身不保證關燈（仍可能用電池）。安全門檻為專案初始策略，不是 Apple 規定，需用 Mock 驗證；實機僅正常環境測試。

## 失敗模式
Crash/系統終止無保證清理、自動重啟或開機自動啟動；狀態標記推測異常，安全待機，禁止補開燈。設定無效以有效備份/安全預設復原；診斷失敗不可阻塞安全。保護狀態持久化優先，寫入失敗應保守啟動並告知。
