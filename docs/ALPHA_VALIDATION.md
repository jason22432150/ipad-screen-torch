# v0.1.0 Alpha release gate — NOT PASSED

Portable Swift checks are not iOS acceptance. Record exact commit, build number, Xcode/SDK, simulator or iPad model/OS, expected/actual, PASS/FAIL/BLOCKED/NOT RUN and sanitized logs for each check. No deliberate heating or deep discharge.

| Scope | Current evidence |
|---|---|
| B01 native Debug/Release device build, availability and arm64 | Device builds and IPA arm64/minOS PASS at CI #4; old-device availability still requires runtime confirmation |
| B02 install and offline use on iPad Air 2, iPadOS 15.8.3 | BLOCKED: physical device and signing |
| B03 four orientations, full-screen | CI #4 four-orientation size and control-state preservation PASS; physical-device full-screen output NOT RUN |
| B04 brightness mapping and monotonicity | Native unit PASS; actual output NOT RUN |
| B06 single/double tap, pan, timeout and settings | CI #3 single/double tap, auto-hide and settings PASS; directional pan test added, pending CI |
| B12 core thermal caps, 120 s recovery, critical latch | Native mock XCTest PASS for implemented core logic; physical integration NOT RUN |
| B13 battery caps and shutdown | Native mock XCTest PASS for implemented core logic; physical integration NOT RUN |
| B14 lifecycle restoration | Native mock ownership PASS; actual device NOT RUN |
| B22 IPA structure/arm64/minOS/signing | CI #3 IPA structure/arm64/minOS/unsigned status/hash PASS; signed install/update NOT RUN |
| B23 offline | app has no intentional network code; device test NOT RUN |

## Mac verification (optional repeat; CI #4 already completed unsigned builds/tests/packaging)
1. scripts/check-env.sh — inspect Xcode, SDK, available simulators; no device changes.
2. scripts/build.sh Debug and scripts/build.sh Release — unsigned device compilation.
3. scripts/test.sh <simulator-UDID> Debug and Release — native XCTest/XCUITest; select a real listed simulator. A recent simulator does not prove iOS 15 compatibility.
4. scripts/release.sh — local unsigned IPA, hash, build-info and verification log only; no publish.
5. Use a personal signing workflow from INSTALLATION.md; install on backed-up iPad Air 2. Verify in flight mode and normal operating temperatures. Never upload signing secrets or device UDID.

## Remaining engineering checks
Physical hybrid 500 ms transition timing, actual iPad Air 2 UI layout, real brightness notifications, safety and lifecycle behavior must be validated before release. CI #3 native suite and unsigned IPA inspection PASS; simulator pan/rotation tests PASS (6/6 UI tests per configuration). Native transition logic and mock emergency-stop tests PASS (13/13 full core suite in Debug and Release). A failed/unrun check is not a PASS. Do not tag or publish v0.1.0 while gates remain open.

## First device acceptance record (pending)
Use the verified CI artifact only after backing up the device and inspecting the battery. Choose personal signing on stock iPadOS, or a compatible installation tool already available on the device. The unsigned IPA is not directly installable on stock iPadOS. Record:
- B02: install, launch, device model/OS, flight mode, no network required.
- B03/B06: four orientations, edge-to-edge color, panel hides in 5 seconds, taps, long press, brightness and Kelvin pan without cross-axis changes.
- B04: 1/3/5/6/50/100% and off in normal use; check brightness and Kelvin retention. Do not hold high brightness for stress testing.
- B12/B13: only ordinary battery/power readings, emergency stop, relaunch latch, explicit recovery. Thermal and low-battery fault injection stays in mocks; never intentionally overheat or discharge.
- B14: record system brightness before launch, Home/return, verify restoration and safe re-entry. Check idle timer with a normal timeout.
- B22/B23: record installation method, app version/build, IPA hash, offline operation; update/overwrite verification when an appropriate second build is available.

## Current handoff: device validation BLOCKED
Source: `77bd45621ddadd5ec2d4820a58eb5d6e29283b5e`, [CI #4](https://github.com/jason22432150/ipad-screen-torch/actions/runs/45956631549). App version 0.1.0, build 1. [Download unsigned IPA](https://github.com/jason22432150/ipad-screen-torch/actions/runs/45956631549/artifacts/15179229182); [CI evidence](https://github.com/jason22432150/ipad-screen-torch/actions/runs/45956631549/artifacts/15179742163). IPA SHA-256: `9bba70cb7cef66b39d11e2a1c022b1baf226fdac9c56695a85d1dba4dc346a73`. Artifact expiry 2026-12-04 UTC. Do not share Apple ID/password, signing private keys, or device UDID in reports.

| Device observation | Actual / result |
|---|---|
| Installation method, iPadOS 15.8.3 / iPad Air 2 | BLOCKED |
| Launch, flight mode, screen color and four directions | NOT RUN |
| Brightness steps, gestures, panel timeout, setting persistence | NOT RUN |
| Emergency stop, latch after relaunch, explicit recovery | NOT RUN |
| Normal charging/unplugged state, system brightness and idle restoration | NOT RUN |
| Unexpected behavior / sanitized screenshot or log | NOT RUN |

No intentional overheat or deep discharge. Automatic tests cannot prove old-device compatibility, real backlight or battery safety. Any swelling, unusual heat or screen lifting: stop and have the battery inspected. Alpha release approval remains blocked until applicable device observations are recorded and failures resolved.
