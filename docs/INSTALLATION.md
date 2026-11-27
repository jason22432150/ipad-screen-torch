# 個人專用安裝 B

App 不依賴特殊 entitlement/私有 API，無需完整 Jailbreak。Bundle ID 建議固定 com.jason22432150.ipadscreentorch；Display Name Screen Torch；版本 v0.1.0 起，build number 遞增。Mac 本機 Xcode/CLI，Debug + Release；不要求 App Store、TestFlight、付費會員。

## 安裝途徑
1. Xcode 個人 Apple ID 免費簽署（通常7天 provisioning，需續簽）；開發首選，信任裝置、選擇 Team、以真機 Run。不要提交 Apple ID/憑證。
2. 已自行安裝且相容的 TrollStore 可作個人長期 IPA 方案，非 Apple 官方、依賴 CoreTrust 漏洞。iPad Air 2/A8X/iPadOS15.8.3 曾列於社群相容範圍，實際安裝工具及版本須使用者核對；不在專案內實作漏洞利用、安裝器或修改 OS。參考 https://github.com/opa334/TrollStore 及 https://ios.cfw.guide/ 。不要求採用；裝置應先備份，不保留重要敏感資料。
3. AltStore Classic/Sideloadly 等相容側載工具為備案；免費帳號通常仍有7天限制。更新時同一 App identity/team/工具才可能保留資料；先備份，不保證跨簽署方式覆蓋成功。一般未修改 iPadOS 不可直接安裝未適當簽署 IPA。

## 後續腳本（尚未建立）
check-env.sh 檢查 Xcode/SDK/toolchain；build.sh Debug/Release；test.sh 單元/UI 測試（指定可用 simulator）；package-ipa.sh 產生 Payload/App.app ZIP，區分未完成分發簽署與已簽署；verify-ipa.sh 檢查 ZIP、Info.plist MinimumOSVersion、device family、Mach-O arm64/min OS、bundleID、簽署狀態及 SHA256；install-device.sh 僅呼叫相容合法安裝流程或提示手動；release.sh 打包。皆提供 --help、明確原因/錯誤與 exit code，不擅自改系統設定。

開發者預檢命令（之後手動執行）：
- xcodebuild -version：顯示 Xcode/Build 版本，確認工具鏈。
- xcodebuild -showsdks：列出 SDK，確認可用 iOS SDK，不會安裝任何東西。
- xcodebuild -list -project iPadScreenTorch.xcodeproj：列出 target/scheme，需先建立專案。
- shasum -a 256 <IPA路徑>：計算雜湊比對 Release 清單，不修改檔案。

## CI / Release
共用本機腳本，self-hosted runner 優先可選，GitHub Actions 另行啟用；先驗證 runner Xcode 與 simulator，不假定現有 macOS runner 有 iOS15 simulator。CI 無簽名編譯/測試可行，但不能取代實機。公開 Release 可包含 IPA（標明簽署適用性）、dSYM.zip、SHA256SUMS.txt、build-info.json（commit SHA、Xcode/SDK、minimum OS、version/build、簽署類型）、測試結果（手動或 CI 輸出均可）、RELEASE_NOTES。不得包含簽署機密。更新檢查未列 MVP，選用且預設關閉；預設零網路。Apple 參考 https://developer.apple.com/support/compare-memberships/ 及 https://developer.apple.com/support/xcode/ 。
