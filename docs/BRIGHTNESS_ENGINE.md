# 亮度引擎

使用者要求整數 1…100%，0 為獨立關燈；lastNonZero 保存。effective=min(requested, thermalCap, batteryCap)，不可改寫要求值。初始映射（待 Air 2 校正）：有效 E≥5 時 backlight=E/100、software=1；0<E<5 時 backlight=0.05、software=E/5；E=0 時 backlight=0、顏色黑。UIScreen.brightness 0…1 表示系統設定，不是物理照度或背光斷電；比例為軟體色彩乘數，非光學校準。5% 門檻可透過測試調整，不得提升安全上限（低於硬體可用最低時採黑色/軟體補償）。

| E | 硬體設定 | 軟體比例 |
|---:|---:|---:|
| 100 | 1.00 | 1 |
| 50 | 0.50 | 1 |
| 5 | 0.05 | 1 |
| 3 | 0.05 | 0.60 |
| 1 | 0.05 | 0.20 |
| 0 | 0 | 0 |

先取得模式的 sRGB，再乘軟體比例（初版 sRGB code value scaling；非線性物理亮度，未來校正）；保留 base color。開/關 500ms 淡入淡出，情境 300ms，色彩 200ms；安全降限/停止不等待動畫。Reduce Motion 或 serious 立即切換。

UIKit UIScreen.brightness 唯一 service 在主執行緒控制；前景開始取得原系統亮度，退出/非 active 釋放並恢復（best effort）；不得持續覆寫系統自動亮度。監聽 UIScreen.brightnessDidChangeNotification，對自身寫入以值/短時 token 去重，不形成 feedback loop。外部控制中心變更在 active 且亮度未鎖定時轉成使用者要求（按百分比近似，極暗區逆映射有歧義，記錄）；若安全限制存在，立即重新仲裁；背景不寫入。鎖定時不得用外部事件偷偷改偏好，亦不無限與 OS 競爭。系統限亮/色彩設定由系統控制，不可保證亮度達標。面板顯示 requested/effective 及保護原因。

測試：邊界0/1/4/5/6/100、非法值/NaN reject或 clamp、單調性、熱/電源 cap、外部通知去重、生命周期 restoration、rapid toggle、動畫中 safety stop。
