# 資料與復原契約

## 權威來源
UserDefaults 只存小型非關鍵 UI 偏好（面板/教學/語系）；Application Support/config/settings.json 存其他使用者設定（避免重複）；各設定模型 Codable，schemaVersion 整數初始1。config/{settings,presets,schedules,automation,calibration,runtime-state}.json；backups/backup-01…03.json；logs/{safety-events,automation-events,diagnostics}.jsonl；Keychain 獨立儲存 PIN verifier（salted KDF，如公開 API 的 PBKDF2，限速嘗試、非明文；不得匯出），LocalAuthentication 不收集生物資料。

## Schema（欄位契約）
| Model | 必要欄位/型別 |
|---|---|
| Settings | schemaVersion:Int, startupMode:enum(restoreLast,on,standby,preset,powerDependent), startupPresetID:UUID?, autoSwitchPowerProfile:Bool=false, acProfile/batteryProfile:LampProfile, orientationLock:Bool, orientationPreference:enum?, gesture/lockPreferences, standbyPolicy |
| LampProfile | mode:enum(kelvin,rgb,white), modeSettings 每模式獨立 brightness:Int(1…100), kelvin:Int, tint:Int, rgb:R/G/B Int, lastNonZero:Int |
| Preset | id:UUID, name:String, icon:String, mode, brightness:Int, kelvin:Int?, tint:Int?, rgb:triplet?, favorite:Bool, order:Int, createdAt/updatedAt:ISO8601 UTC |
| Schedule/AutomationRule | id, enabled, order, trigger tagged union, action tagged union, timestamps；見 AUTOMATION_ENGINE |
| Calibration | gains R/G/B:finite Double, version:Int |
| RuntimeState | desiredPower/lastMode, lastNonZero/mode settings, safetyLatch/reason, activeCountdown(deadline,pausedRemaining), occurrenceKeys bounded, foregroundRunMarker, suspectLaunchCount, lastSuccessfulSave |
| BackupEnvelope | schemaVersion, createdAt, appVersion, categories, typed payload |
| Event | timestamp, kind, reason, outcome, optional ruleID/effective/requested |

初始 AC 80%/4000K、battery 40%/2700K；自動切 profile 預設 off；autoLock/timer 預設 off；首次啟動與無有效設定採安全待機；正常後預設 restoreLast（也可直接 on、standby、指定情境、供電決定）；安全 latch 高於所有偏好。方向偏好不保證強制旋轉。每模式設定獨立；不持久化 system brightness ownership snapshot 作為下次復原值。

## 儲存與復原
亮度/色彩停止操作500ms debounce，手勢結束 flush；開關、情境、排程、必要安全狀態立即保存；背景 best effort flush；無變更不寫。序列化寫入、temporary/atomic replace、驗證後替換；多檔匯入採 staged snapshot + transaction journal 或 generation manifest，避免半套用。最近3份有效完整備份，每日有變更、匯入、遷移、版本升級前建立；主檔不合法找最新有效備份，全部無效採安全預設/待機提示。保留損壞原檔供本機診斷，不無限增長。
Schema migration 逐版本、idempotent，先備份；未知未來版本拒絕，不破壞既有資料。驗證範圍、enum、UUID 唯一、引用、有限浮點、字串與檔案大小（初始上限5MB、名稱80字元、預設/規則各1000筆）；匯入先 preview，合併（同ID明確提示衝突）、取代或分類，交易失敗 rollback。匯入/重設不得清除 safety latch 或帶入正在執行的 automation runtime；匯入的新規則需明確確認啟用。PIN/系統密碼/生物資料永遠不匯出。

## 安全啟動
前景進入標記 active，正常離開標記 clean；未清理只能推測異常，無法精確分辨 Crash/kill/OS。首次疑似異常安全待機、暫停自動化及完整鎖定（仍保留必要認證），連續3次短期疑似啟動失敗強制 Safe Mode；初始「短期」定義10分鐘，成功穩定前景60秒後清除計數（待實機調整）。Safe Mode 不刪資料，手動確認後回正常待機；Critical latch 不受此確認解除。重設類別：燈光、手勢、校正、情境、排程、供電、鎖定（需驗證）、日誌、全部（雙確認）。核心安全不可停用。
