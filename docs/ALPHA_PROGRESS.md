# v0.1.0 Alpha implementation evidence

- M01: project, scheme, iOS 15.0, Swift 5, iPad-only, local scripts. Native build and XCTest/XCUITest: NOT RUN (Linux execution environment; Xcode unavailable).
- M02: reducer, safety cap/latch, service protocols, fake services. Linux Swift 6.2.1 (Swift 5 language mode): 5/5 XCTest PASS at 5f42118, matching source/test blob SHA.
- M03: brightness map, Kelvin conversion, mock ownership and self-notification filtering. Linux debug and release portable XCTest: 8/8 each PASS at 63253d3, matching source/test blobs.
- M04: native surface, public API hardware adapter, foreground lifecycle, gestures, SwiftUI overlay and UI tests implemented. iOS type checking/build, actual notifications, gesture conflicts, timing, full-screen and animation behavior NOT RUN.
- M05: runtime-state JSON, atomic writes, validation, future-schema rejection, corrupt-file quarantine, foreground marker, persistent safety latch, storage failure stops lighting, debounce. Linux debug/release portable XCTest 11/11 each PASS for core/test sources (blob f532b919b915ce8f9700e6e75ec21f43f45913cc and f6ae59ae1404bb3fd07c532d8ea0d61d4d5c33b8). iOS integration NOT RUN. Full backup/advanced safe mode deferred per roadmap.
- M06–M07: pending.
- No cloud workflow enabled (AGENTS.md requires explicit runner and trigger strategy).
- No IPA, signing, physical-device test or compatibility PASS claimed. Do not deploy as a lamp before native and safety acceptance.
