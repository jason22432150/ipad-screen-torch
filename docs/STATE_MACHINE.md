# 狀態機與生命週期

## 狀態與事件
LampState: initializing / lighting / standby / sleepEligible / safetyShutdown / suspended。獨立子狀態：BrightnessState(requested,effective,hardware,software)、ColorState、SafetyState(thermal,batteryCap,latch)、AutomationState(activeRun,nextDue)、LockState、PowerState、LifecycleState、UIState。另有 safeMode、cleaning、animation；非獨立硬體控制器。事件包括 launch/active/inactive/background、tap/gesture/setBrightness/setColor/preset、power/battery/thermal changed、timerDue/timeChanged、lock/auth/clean、emergencyStop。

| From / event | To / effect |
|---|---|
| initializing / valid settings + safe | 按啟動策略 lighting/standby/sleepEligible |
| initializing / corruption or suspect shutdown | 安全待機（若 safety latch 則 safetyShutdown） |
| lighting / manual off or timer off | 按供電、排程進 standby 或 sleepEligible |
| standby / allowed on | lighting，先仲裁安全 |
| sleepEligible / foreground interaction | 重算安全後可 lighting |
| any / critical, low battery shutdown, emergency | safetyShutdown，取消漸變與本次自動化、允許休眠 |
| safetyShutdown / safe + explicit confirmation | standby；重新開燈需明確操作（不可偷偷恢復） |
| any / inactive/background | suspended，暫停硬體控制並恢復原系統設定 |
| suspended / foreground active | 重取系統快照、熱與電量、排程；按保存的意圖恢復但不得跳過 latch |

Standby: black + min backlight + idle disabled; sleepEligible: black + min backlight、idle 恢復，系統可能鎖屏。安全停止：黑色最低可用背光、idle 恢復，不自動重啟。實際鎖屏後不保證 App 執行。初始硬體快照只在取得前景照明 ownership 時擷取；release 時解除 observer 自寫入回饋及恢復原值，重返前景新取快照；不要以持久化的舊系統亮度覆蓋新工作階段。Crash/kill 無法保證執行清理。

## 仲裁（由高到低）
1. 硬性安全（Critical、低電量停止、未知狀態保守限制）及緊急停止。
2. 生命週期/安全啟動限制（非 active 不輸出，safeMode 暫停自動化）。
3. 授權後人為操作；鎖定拒絕未授權手勢。手動操作取消當次衝突的漸變/排程，可暫停本次自動化，不永久刪排程。
4. 供電狀態觸發；可選自動套供電 profile（預設 off），先套 profile 再執行電源規則。
5. 時間排程及日出日落；同級衝突 off 優先，否則穩定 rule ID/排序決勝。
6. 一般情境/啟動預設。
所有輸出取 min(requested,thermalCap,batteryCap)，停止狀態覆蓋為0。硬體寫入與動畫 tick 都要重檢安全與 generation；降上限立即生效。清潔/鎖定不能阻擋 safety 或合法自動化；清潔退出時若狀態已被更新則不可復寫舊狀態。
