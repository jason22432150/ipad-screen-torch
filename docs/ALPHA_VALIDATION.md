# v0.1.0 Alpha release gate — NOT PASSED

Portable Swift checks are not iOS acceptance. Record exact commit, build number, Xcode/SDK, simulator or iPad model/OS, expected/actual, PASS/FAIL/BLOCKED/NOT RUN and sanitized logs for each check. No deliberate heating or deep discharge.

| Scope | Current evidence |
|---|---|
| B01 native Debug/Release device build, availability and arm64 | BLOCKED: Xcode/macOS |
| B02 install and offline use on iPad Air 2, iPadOS 15.8.3 | BLOCKED: physical device and signing |
| B03 four orientations, full-screen | NOT RUN |
| B04 brightness mapping and monotonicity | Portable unit PASS; actual output and gestures NOT RUN |
| B06 single/double tap, pan, timeout and settings | XCUITest authored; NOT RUN |
| B12 core thermal caps, 120 s recovery, critical latch | Portable partial unit PASS; native integration NOT RUN |
| B13 battery caps and shutdown | Portable partial unit PASS; native integration NOT RUN |
| B14 lifecycle restoration | Mock partial PASS; actual device NOT RUN |
| B22 IPA structure/arm64/minOS/signing | scripts authored; actual IPA NOT RUN |
| B23 offline | app has no intentional network code; device test NOT RUN |

## Mac verification
1. scripts/check-env.sh — inspect Xcode, SDK, available simulators; no device changes.
2. scripts/build.sh Debug and scripts/build.sh Release — unsigned device compilation.
3. scripts/test.sh <simulator-UDID> Debug and Release — native XCTest/XCUITest; select a real listed simulator. A recent simulator does not prove iOS 15 compatibility.
4. scripts/release.sh — local unsigned IPA, hash, build-info and verification log only; no publish.
5. Use a personal signing workflow from INSTALLATION.md; install on backed-up iPad Air 2. Verify in flight mode and normal operating temperatures. Never upload signing secrets or device UDID.

## Remaining engineering checks
Physical hybrid 500 ms transition timing, native UI layout, real brightness notifications, safety and lifecycle behavior, and actual IPA inspection must be validated before release. Portable transition logic and mock emergency-stop tests PASS (13/13 full core suite in Debug and Release). A failed/unrun check is not a PASS. Do not tag or publish v0.1.0 while gates remain open.
