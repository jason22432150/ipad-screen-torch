# 開發路線與工作清單

| 版本 | 範圍 | 放行條件 |
|---|---|---|
| v0.1.0 Alpha | Xcode target、全螢幕四方向、亮度混合、Kelvin、手勢、面板、基本保存與安全、IPA | B01–04、B06、B12–14 基本安全與真機安裝；適用單元/UI |
| v0.2.0 | RGB/Tint/White/校正、10情境/收藏/排序/JSON | B05/B07 |
| v0.3.0 | 倒數、排程、日出日落、供電觸發、智慧待機 | B08–11、B14 |
| v0.4.0 | 完整安全/恢復、診斷、電源策略 | B12/B13/B21 |
| v0.5.0 | 鎖定、清潔、Guided Access、無障礙完善 | B15–17 |
| v0.6.0 | 備份、遷移、安全模式、完整匯出重設 | B18–20/B22 |
| v0.9.0 RC | 整合、所有 B 測試、實機問題修復 | B01–23 適用項，記錄證據 |
| v1.0.0 | 穩定個人 IPA、安裝/使用說明 | 必測全通過，無未解安全缺陷 |

## 第一批實作工作（依序）
- [ ] M01 Xcode iPad project、scheme、最低 iOS15、Swift5，零依賴；本機檢查/build/test 腳本。
- [ ] M02 Core models、protocols、Store/reducer、fake clock/battery/thermal/screen；安全 cap 與 latch。
- [ ] M03 brightness + color 純函式與 XCTest；硬體 ownership、idle timer、生命週期恢復。
- [ ] M04 UIKit surface + SwiftUI overlay，四方向、手勢、5秒 hide、mode/color controls 基礎。
- [ ] M05 保存最小有效資料、啟動安全待機、基本異常保護。
- [ ] M06 Debug/Release、XCTest/XCUITest、IPA package/verify、iPad Air 2 實機安裝及安全基礎驗收。
- [ ] M07 v0.1.0 release candidate evidence；確認問題再進 v0.2.0。

之後按版本建立小型 issue/commit；每項定義驗收測試、變更與回歸證據。完整診斷/安全恢復於 v0.4.0 補齊，核心保護不可延後。未經使用者確認不自動啟用付費 CI、不實作 App Store/遠端服務。規格變更需更新相應 docs 與 CHANGELOG。

## 待實機核對/設計假設
5%混合門檻、色溫/Tint 校正、外部亮度事件與自動亮度互動、四方向鎖定與系統手勢衝突、熱狀態回報/最低背光、未知電源 cap40、啟動標記誤判、實際 Xcode 工具鏈、個人簽署及覆蓋安裝。補充契約如 HSV value、排程 DST/同級仲裁、匯入限額與短期啟動失敗時間是文件整理時提出的初始工程預設，並非實測或額外使用者確認；可在實作驗證時調整且記錄。效能數字僅目標；不要求長期耐久測試 C。
