# v0.1.0 Alpha implementation evidence

- M01: project, scheme, iOS 15.0, Swift 5, iPad-only, local scripts. Native build and XCTest/XCUITest: NOT RUN (Linux execution environment; Xcode unavailable).
- M02: reducer, safety cap/latch, service protocols, fake services. Linux Swift 6.2.1 (Swift 5 language mode): 5/5 XCTest PASS at 5f42118, matching source/test blob SHA.
- M03: brightness map, Kelvin conversion, mock ownership and self-notification filtering. Linux debug and release portable XCTest: 8/8 each PASS at 63253d3, matching source/test blobs.
- M04: native surface, public hardware adapter, lifecycle, gestures, SwiftUI overlay, UI tests. Native type checking/build, actual notifications, gestures, timing, four orientations and animation behavior NOT RUN. On/off visual color animation exists but physical backlight currently changes immediately; full mixed brightness transition remains to be implemented/validated.
- M05: runtime-state JSON, atomic write, future-schema rejection, corrupt-file quarantine, foreground marker, persistent safety latch, storage-failure stop, debounce. Linux debug/release portable XCTest 11/11 each PASS at 4d067dc (core blob f532b919b915ce8f9700e6e75ec21f43f45913cc, test blob f6ae59ae1404bb3fd07c532d8ea0d61d4d5c33b8). Native persistence integration NOT RUN. Full backup/advanced safe mode deferred per roadmap.
- M06: local package/verify/install-guidance/release scripts added; shell syntax and --help tested on Linux for the four new scripts only. No actual Mach-O/IPA/signature check, native XCTest/XCUITest or device acceptance.
- M07: evidence checklist prepared; release gate NOT PASSED. No version tag or GitHub Release.
- No cloud workflow enabled (AGENTS.md requires explicit runner and trigger strategy).
- Do not deploy as a lamp before native and safety acceptance.
