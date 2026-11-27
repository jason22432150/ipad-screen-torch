# 自動化與計時

所有規則預設停用或未建立；僅 foreground active + 非安全/省電阻擋時可靠執行。不得用背景音訊等方式保活，也不把通知當喚醒燈。智慧待機黑色且禁止 idle，插電預設；電池且有下一次開燈排程可待機，否則允許休眠；安全/低電量優先。

## 功能
- 倒數關燈1分鐘…24小時，可暫停、延長、取消；快速5/10/15/30/45/60/90/120分鐘；淡出0/1/5/10分鐘（不超過剩餘時間）。倒數以 monotonic elapsed（進程存續）及持久化 deadline/remaining（重啟 best effort）計算，不用 tick count。
- 指定本地時間一次性、每天、選擇星期、多組；動作 on/off/applyPreset；可停用、刪除、預覽下一次時間。
- 日出/日落：1…120分鐘，起訖亮度、Kelvin、linear/easeIn/easeOut/easeInOut；完成維持/關燈/套情境。插值根據實際已過時間，不累加誤差；每秒評估，安全 cap 逐次生效。
- 插入/拔除充電器、電量上/下跨門檻觸發，動作 on/off/限亮/套情境；使用 crossing 而非持續條件，初次觀測只建立基線，不誤觸發。unknown 不假設插電；避免反覆觸發。電量限制動作不得提高 safety cap。
- 日誌最近500筆：ruleID、occurrenceID、timestamp、trigger、action、outcome、reason，失敗不無限重試。

## 排程模型
Rule(id UUID, enabled, trigger, action, order, createdAt, updatedAt)，trigger tagged union：countdown、calendar(oneShotDate 或 hour/minute/weekdays)、powerConnected/powerDisconnected、batteryCrossing(direction,threshold)、ramp(startTrigger,duration,start/end,curve)。使用 Calendar/TimeZone 本地時間；下一次單次 timer，重新進前景/系統時區或顯著時間變動重新計算。跨午夜依實際起始/結束日期，不用只比較 hour。DST 缺失時間預設略過、重複時間只執行一次（初始規則，需測試）；occurrence key 以 ruleID+預定本地日期/時間與規則 revision 去重，儲存有限已執行紀錄。錯過開燈/情境/日出預設不補；錯過關燈或逾時倒數於返回前景先關燈（安全且符合使用者意圖），不在背景宣稱已執行。持久化倒數遭系統時鐘變更可能不準確，需提示/保守停止。手動操作取消衝突的當次 run，不刪未來規則；供電 profile/規則/排程衝突依 STATE_MACHINE。SafetyShutdown 不得自動清除。若同時 on/off，off 優先。

測試需 fake clock、時區/DST、跨午夜、多規則同時觸發、manual override、通知重複、背景/復歸、低電量關燈、刪除情境引用、持久化去重、取消/延長。
