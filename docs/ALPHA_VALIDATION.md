# v0.1.0 Alpha release gate — NOT PASSED

Portable Swift checks are not iOS acceptance. Record exact commit, build number, Xcode/SDK, simulator or iPad model/OS, expected/actual, PASS/FAIL/BLOCKED/NOT RUN and sanitized logs for each check. No deliberate heating or deep discharge.

| Scope | Current evidence |
|---|---|
| B01 native Debug/Release device build, availability and arm64 | Device builds and IPA arm64/minOS PASS at CI #3; old-device availability still requires runtime confirmation |
| B02 install and offline use on iPad Air 2, iPadOS 15.8.3 | BLOCKED: physical device and signing |
| B03 four orientations, full-screen | Additional simulator orientation test authored; pending CI. Physical device NOT RUN |
| B04 brightness mapping and monotonicity | Native unit PASS; actual output NOT RUN |
| B06 single/double tap, pan, timeout and settings | CI #3 single/double tap, auto-hide and settings PASS; directional pan test added, pending CI |
| B12 core thermal caps, 120 s recovery, critical latch | Native mock XCTest PASS for implemented core logic; physical integration NOT RUN |
| B13 battery caps and shutdown | Native mock XCTest PASS for implemented core logic; physical integration NOT RUN |
| B14 lifecycle restoration | Native mock ownership PASS; actual device NOT RUN |
| B22 IPA structure/arm64/minOS/signing | CI #3 IPA structure/arm64/minOS/unsigned status/hash PASS; signed install/update NOT RUN |
| B23 offline | app has no intentional network code; device test NOT RUN |

## Mac verification
1. scripts/check-env.sh — inspect Xcode, SDK, available simulators; no device changes.
2. scripts/build.sh Debug and scripts/build.sh Release — unsigned device compilation.
3. scripts/test.sh <simulator-UDID> Debug and Release — native XCTest/XCUITest; select a real listed simulator. A recent simulator does not prove iOS 15 compatibility.
4. scripts/release.sh — local unsigned IPA, hash, build-info and verification log only; no publish.
5. Use a personal signing workflow from INSTALLATION.md; install on backed-up iPad Air 2. Verify in flight mode and normal operating temperatures. Never upload signing secrets or device UDID.

## Remaining engineering checks
Physical hybrid 500 ms transition timing, actual iPad Air 2 UI layout, real brightness notifications, safety and lifecycle behavior must be validated before release. CI #3 native suite and unsigned IPA inspection PASS; additional simulator pan/rotation coverage pending. Native transition logic and mock emergency-stop tests PASS (13/13 full core suite in Debug and Release). A failed/unrun check is not a PASS. Do not tag or publish v0.1.0 while gates remain open.

## First device acceptance record (pending)
Use the verified CI artifact only after backing up the device and inspecting the battery. Choose personal signing on stock iPadOS, or a compatible installation tool already available on the device. The unsigned IPA is not directly installable on stock iPadOS. Record:
- B02: install, launch, device model/OS, flight mode, no network required.
- B03/B06: four orientations, edge-to-edge color, panel hides in 5 seconds, taps, long press, brightness and Kelvin pan without cross-axis changes.
- B04: 1/3/5/6/50/100% and off in normal use; check brightness and Kelvin retention. Do not hold high brightness for stress testing.
- B12/B13: only ordinary battery/power readings, emergency stop, relaunch latch, explicit recovery. Thermal and low-battery fault injection stays in mocks; never intentionally overheat or discharge.
- B14: record system brightness before launch, Home/return, verify restoration and safe re-entry. Check idle timer with a normal timeout.
- B22/B23: record installation method, app version/build, IPA hash, offline operation; update/overwrite verification when an appropriate second build is available.
