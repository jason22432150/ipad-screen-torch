# v0.1.0 Alpha implementation evidence

- M01: project, scheme, iOS 15.0, Swift 5, iPad-only, local scripts. Native device builds and simulator tests PASS in CI #4 (see below).
- M02: reducer, safety cap/latch, service protocols, fake services. Linux Swift 6.2.1 (Swift 5 language mode): 5/5 XCTest PASS at 5f42118, matching source/test blob SHA.
- M03: brightness map, Kelvin conversion, mock ownership and self-notification filtering. Linux debug and release portable XCTest: 8/8 each PASS at 63253d3, matching source/test blobs.
- M04: native surface, public hardware adapter, lifecycle, gestures, SwiftUI overlay, UI tests. Native compilation and simulator gesture/orientation tests PASS in CI #4; real hardware notifications, timing and animation remain NOT RUN. 500 ms mixed brightness transition now implemented with bounded 30 Hz ticks, each re-sampling safety. Actual backlight timing NOT RUN.
- M05: runtime-state JSON, atomic write, future-schema rejection, corrupt-file quarantine, foreground marker, persistent safety latch, storage-failure stop, debounce. Linux debug/release portable XCTest 11/11 each PASS at 4d067dc (core blob f532b919b915ce8f9700e6e75ec21f43f45913cc, test blob f6ae59ae1404bb3fd07c532d8ea0d61d4d5c33b8). Emergency latch relaunch integration PASS on simulator in CI #4; physical-device persistence NOT RUN. Full backup/advanced safe mode deferred per roadmap.
- M06: local package/verify/install-guidance/release scripts added; shell syntax and --help tested on Linux for the four new scripts only. Native Debug/Release XCTest/XCUITest and unsigned IPA structural checks PASS in CI #4; device acceptance BLOCKED.
- M07: evidence checklist prepared; release gate NOT PASSED. No version tag or GitHub Release.
- User authorized GitHub Actions CI on 2026-11-27. Standard macos-15 runner; push limited to Alpha branch and relevant files; manual dispatch; canceled superseded runs; no signing secrets. Native CI #4 PASS; physical release gate remains blocked.
- Do not deploy as a lamp before native and safety acceptance.

- Final portable regression: Linux Swift 6.2.1 Swift 5 mode, Debug 13/13 PASS and Release 13/13 PASS (core blob add89eac106d0d2c9835d62a8d04d98769b799c3; test blob bb81c70bcd730a174086c818aa1a44fa39120695). Covers transition timing, cap arbitration and immediate Mock emergency stop. At the time of these portable tests, UIKit/Combine and native UI were NOT RUN; later native CI evidence is below.

## Native CI #1 — a57c7d9
- Run 45945349489: Xcode environment, Debug/Release device builds and simulator selection PASS.
- Debug native XCTest: 13/13 PASS. XCUITest: 3/4 PASS; emergency persistence test failed to tap emergencyStop after the quick panel auto-hid (accessibility hierarchy contained lampSurface only). Release tests and IPA skipped, not PASS.
- Revised XCUITest to enter settings through the existing long-press gesture before interacting, preserving the production 5-second hide timer. Explicitly closes settings before testing auto-hide. Retry subsequently passed in CI #2.

## Native CI #2 — 217da3e
- Run 45950420650: Debug and Release device builds PASS; native Debug core XCTest 13/13 PASS.
- XCUITest 3/4 PASS. Emergency latch across relaunch now PASS. Auto-hide test failed at backSettings: element found, but AX could not compute a hit point (scroll-to-visible failed). Release tests and IPA skipped.
- Corrective UI changes: explicit measured hosting height constrained to safe area, scrollable content, return action moved to header so it remains reachable; no deployment-target or hide-time changes. XCUITest now asserts that Back is hittable and actually closes settings. Native regression subsequently passed in CI #3.

## Native CI #3 — 5e98c5a (2026-11-27)
- [Run 45952311447](https://github.com/jason22432150/ipad-screen-torch/actions/runs/45952311447): SUCCESS. Xcode 16.4 (16F6), iPhoneOS SDK 18.5; runner log selected iPad mini (A17 Pro), simulator runtime 26.2.
- Debug and Release device builds PASS. Each configuration: 13/13 native XCTest and 4/4 XCUITest PASS; 34 test executions total, zero failures.
- IPA structure, iPad device family, arm64, bundle ID, Mach-O platform IOS and minimum OS 15.0 verified by CI. SIGNING=UNSIGNED. No device install.
- IPA SHA-256: `0603fb5068c88114e4d6a592399edd411a6a06ce147780f905677f77a609b1ff`.
- [Unsigned IPA artifact](https://github.com/jason22432150/ipad-screen-torch/actions/runs/45952311447/artifacts/15177358369) and [test evidence](https://github.com/jason22432150/ipad-screen-torch/actions/runs/45952311447/artifacts/15177652685) expire 2026-12-04 UTC.
- Additional directional pan and orientation UI tests authored after run #3; pending native regression. Actual iPad Air 2 / iPadOS 15.8.3 checks remain BLOCKED; do not mark release gate passed.

## Native CI #4 — 77bd45621ddadd5ec2d4820a58eb5d6e29283b5e (2026-11-27)
- [Run 45956631549](https://github.com/jason22432150/ipad-screen-torch/actions/runs/45956631549): SUCCESS. Xcode 16.4 (16F6), runner-selected iPad mini (A17 Pro), simulator runtime reported as 26.2. Device Debug/Release builds PASS.
- Debug: 13/13 native XCTest and 6/6 XCUITest PASS. Release: 13/13 native XCTest and 6/6 XCUITest PASS. Total 38 executions, zero failures. Both directional pan and four-orientation preservation tests PASS in both configurations.
- IPA structure, iPad device family, bundle ID, arm64 and Mach-O minimum OS 15.0 PASS. Signing status UNSIGNED; stock iPadOS installation requires personal signing.
- Build 1 IPA SHA-256: `9bba70cb7cef66b39d11e2a1c022b1baf226fdac9c56695a85d1dba4dc346a73`.
- [Unsigned IPA artifact](https://github.com/jason22432150/ipad-screen-torch/actions/runs/45956631549/artifacts/15179229182) and [test evidence](https://github.com/jason22432150/ipad-screen-torch/actions/runs/45956631549/artifacts/15179742163); expiry 2026-12-04 07:23 UTC.
- M01–M05 Alpha implementation and current automated suites complete. Physical-device portions of M03–M05 remain unverified. M06 installation/safety acceptance BLOCKED until physical iPad Air 2 / iPadOS 15.8.3 and a suitable installation method are available. M07 release gate NOT PASSED; no release/tag or main merge. Do not deploy as a permanent lamp until device acceptance.
- Subsequent documentation-only commit records this run without altering the tested source or retriggering the path-filtered CI. Artifact is associated with 77bd456, not the documentation commit.

## Installation decision — 2026-11-27
- User selected AltStore Classic for personal signing/install. Instructions recorded in INSTALLATION.md. CI #4 unsigned IPA remains the candidate; install and physical acceptance NOT RUN. No signing credentials collected, no source changes, no new CI trigger or release/tag.
