# 驗收方案 B — 完整測試

狀態：Alpha 已完成 CI #4 的適用自動化測試（Debug/Release 各 19/19）及未簽署 IPA 結構驗證；實機、後續版本測試及尚未覆蓋部分仍待執行，詳見 [ALPHA_VALIDATION](ALPHA_VALIDATION.md)。必測 Debug/Release、XCTest、XCUITest、iOS15 API/實機、保護模擬、設定復原、排程、IPA、更新/遷移。選用（非 release gate）：專項記憶體洩漏、1/8/24/72/168h 耐久、異常中斷壓力、完整效能 benchmark、自動測試報告；但必要功能的背景/異常復原測試不省略。核心覆蓋90%、整體80%及效能目標為追蹤目標，不以未量測值冒充結果。

| ID | 驗收步驟與預期 | 類型 |
|---|---|---|
| B01 | Debug/Release build、iOS15 availability、arm64/minOS；無必需依賴 | CI/local |
| B02 | IPA 真機 iPad Air 2 15.8.3 安裝、啟動、飛航模式操作 | device |
| B03 | 四方向照明，隱藏面板後無 App 邊框/文字；旋轉保持設定與計時 | UI/device |
| B04 | brightness 0/1/3/5/6/50/100 映射及單調；雙擊開關保留 lastNonZero | unit/device |
| B05 | Kelvin 1000/10000 step100、Tint ±100、RGB/HEX/HSV、White、各模式記憶與校正 | unit/UI |
| B06 | 單/雙擊不互觸，手勢方向，面板5秒消失，編輯不消失 | UI/device |
| B07 | 10預設、修改/刪除/收藏/排序/匯入/匯出、錯誤檔不覆蓋、引用停用 | unit/UI |
| B08 | 倒數1m/24h、暫停/延長/取消、漸暗、逾期復歸關燈 | fake clock |
| B09 | 每日/星期/一次性、多規則、跨午夜、時區/DST、去重、手動覆蓋 | unit |
| B10 | 日出/日落1…120分鐘、曲線、取消、完成動作 | unit/UI |
| B11 | 插拔、電量 crossing、unknown、profile off/on、不重複觸發 | mock/device |
| B12 | 熱四級、未知、120秒恢復、2%/s、再次升熱、critical latch及手動確認 | mock |
| B13 | 電量各門檻、插電≤5/未知、低電量停止、min仲裁；鎖定/情境不能繞過 | mock |
| B14 | background/inactive 恢復 brightness/idle、復歸重驗；sleep 無自動喚醒承諾 | device/mock |
| B15 | 部分鎖定、完整鎖定、解鎖/PIN/Touch ID/取消/忘記PIN、緊急關燈 | UI/device |
| B16 | 清潔15…120秒恢復、不覆寫期間安全停止；自動鎖定/Guided Access 偵測 | UI/device |
| B17 | VoiceOver 替代操作、Dynamic Type、Reduce Motion、四方向/方向鎖 | device |
| B18 | debounce/atomic 保存、重啟、五啟動模式、AC/battery獨立 | unit/device |
| B19 | 損毀主檔、三備份、全壞、未知 schema、匯入 rollback、分類重設、PIN排除 | unit |
| B20 | 模擬疑似異常/連續3次啟動失敗、安全模式、latch持久化 | unit/device |
| B21 | 診斷內容/上限/匯出、未知指標標 unavailable、不含秘密 | unit/UI |
| B22 | IPA ZIP/arch/minOS/signing type/hash，實機覆蓋更新資料遷移、失敗回報 | local/device |
| B23 | 完全離線操作，無未預期網路行為，無背景權限濫用 | inspection/device |

## 證據與放行
每個測試記錄 ID、commit、App/build、裝置/OS 或 simulator/Mock、步驟、預期/實際、PASS/FAIL/BLOCKED/NOT RUN、日誌/截圖（移除敏感資料）。核心安全與 iPadOS15.8.3 真機相容、B01–B23 適用項必須通過 v1.0；無設備/簽署時標 BLOCKED，不可用模擬器冒充。分版本按已交付功能測試，回歸先前項目。安全測試使用 mock，不刻意加熱/深度放電，不要求最高亮度長期插電。選用耐久須檢查老電池、正常環境、有人監控、異常即停止。
