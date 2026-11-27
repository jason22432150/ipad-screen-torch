# v0.1.0 Alpha implementation evidence

- M01: project, scheme, iOS 15.0, Swift 5, iPad-only, local scripts. Native build and XCTest/XCUITest: NOT RUN (Linux execution environment; Xcode unavailable).
- M02: reducer, safety cap/latch, service protocols, fake services. Linux Swift 6.2.1 (Swift 5 language mode): 5/5 XCTest PASS at 5f42118, matching source/test blob SHA.
- M03: brightness map, Kelvin conversion, mock ownership and self-notification filtering. Linux debug and release portable XCTest: 8/8 each PASS at 63253d3, matching source/test blobs.
- M04: native surface, public hardware adapter, lifecycle, gestures, SwiftUI overlay, UI tests. Native type checking/build, actual notifications, gestures, timing, four orientations and animation behavior NOT RUN. 500 ms mixed brightness transition now implemented with bounded 30 Hz ticks, each re-sampling safety. Actual backlight timing NOT RUN.
- M05: runtime-state JSON, atomic write, future-schema rejection, corrupt-file quarantine, foreground marker, persistent safety latch, storage-failure stop, debounce. Linux debug/release portable XCTest 11/11 each PASS at 4d067dc (core blob f532b919b915ce8f9700e6e75ec21f43f45913cc, test blob f6ae59ae1404bb3fd07c532d8ea0d61d4d5c33b8). Native persistence integration NOT RUN. Full backup/advanced safe mode deferred per roadmap.
- M06: local package/verify/install-guidance/release scripts added; shell syntax and --help tested on Linux for the four new scripts only. No actual Mach-O/IPA/signature check, native XCTest/XCUITest or device acceptance.
- M07: evidence checklist prepared; release gate NOT PASSED. No version tag or GitHub Release.
- User authorized GitHub Actions CI on 2026-11-27. Standard macos-15 runner; push limited to Alpha branch and relevant files; manual dispatch; canceled superseded runs; no signing secrets. Native CI results pending; physical release gate remains blocked.
- Do not deploy as a lamp before native and safety acceptance.

- Final portable regression: Linux Swift 6.2.1 Swift 5 mode, Debug 13/13 PASS and Release 13/13 PASS (core blob add89eac106d0d2c9835d62a8d04d98769b799c3; test blob bb81c70bcd730a174086c818aa1a44fa39120695). Covers transition timing, cap arbitration and immediate Mock emergency stop. UIKit/Combine, actual iOS hardware and UI remain NOT RUN.

## Native CI #1 — a57c7d9
- Run 45945349489: Xcode environment, Debug/Release device builds and simulator selection PASS.
- Debug native XCTest: 13/13 PASS. XCUITest: 3/4 PASS; emergency persistence test failed to tap emergencyStop after the quick panel auto-hid (accessibility hierarchy contained lampSurface only). Release tests and IPA skipped, not PASS.
- Revised XCUITest to enter settings through the existing long-press gesture before interacting, preserving the production 5-second hide timer. Explicitly closes settings before testing auto-hide. Retry pending.

## Native CI #2 — 217da3e
- Run 45950420650: Debug and Release device builds PASS; native Debug core XCTest 13/13 PASS.
- XCUITest 3/4 PASS. Emergency latch across relaunch now PASS. Auto-hide test failed at backSettings: element found, but AX could not compute a hit point (scroll-to-visible failed). Release tests and IPA skipped.
- Corrective UI changes: explicit measured hosting height constrained to safe area, scrollable content, return action moved to header so it remains reachable; no deployment-target or hide-time changes. XCUITest now asserts that Back is hittable and actually closes settings. Native regression pending.
