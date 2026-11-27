# v0.1.0 Alpha implementation evidence

- M01: project, scheme, iOS 15.0, Swift 5, iPad-only, local scripts. Native build and XCTest/XCUITest: NOT RUN (Linux execution environment; Xcode unavailable).
- M02: reducer, safety cap/latch, service protocols, fake services. Linux Swift 6.2.1 (Swift 5 language mode): 5/5 XCTest PASS, matching source/test blob SHA at 5f42118.
- M03: brightness map, Kelvin conversion, mock ownership and self-notification filtering. Linux debug and release portable XCTest: 8/8 each PASS at 63253d3, matching source/test blobs. First compile found idle-service value semantics error, fixed with AnyObject constraint.
- M04: native UIKit lamp surface, public API hardware adapter, foreground lifecycle, gestures, SwiftUI overlay and initial UI tests implemented. Native type checking/build, real notifications, gestures, timing, full-screen and animation behavior NOT RUN. Not a release gate PASS.
- M05–M07: pending. Persistent latch is not yet implemented. Do not install/use this intermediate build as a lamp.
- No cloud workflow enabled (AGENTS.md requires explicit runner and trigger strategy).
- No IPA, signing, physical-device test or compatibility PASS claimed.
