# v0.1.0 Alpha implementation evidence

- M01: project, scheme, iOS 15.0, Swift 5, iPad-only, local scripts. Native build and XCTest/XCUITest: NOT RUN (Linux execution environment; Xcode unavailable).
- M02: reducer, safety cap/latch, service protocols, fake services. Linux Swift 6.2.1 (Swift 5 language mode): 5/5 XCTest PASS, matching source/test blob SHA at 5f42118.
- M03: brightness map, Kelvin conversion, mock ownership and self-notification filtering. Linux debug and release portable XCTest: 8/8 each PASS; first compile detected idle-service value semantics, fixed with AnyObject constraint and retested. iOS adapter/notification integration and native lifecycle validation pending. Portable test evidence does not cover UIKit or Combine.
- M04–M07: pending.
- No cloud workflow enabled (AGENTS.md requires explicit runner and trigger strategy).
- No IPA, signing, physical-device test or compatibility PASS claimed. Do not deploy as a lamp yet.
