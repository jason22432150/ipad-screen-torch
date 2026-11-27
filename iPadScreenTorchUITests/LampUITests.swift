import XCTest

final class LampUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        // A unique simulator-only runtime directory avoids cross-test latch state.
        app.launchEnvironment["SCREEN_TORCH_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        return app
    }

    func testLaunchAndControls() {
        let app = launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.buttons["toggleLamp"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.sliders["brightnessSlider"].exists)
        XCTAssertTrue(app.sliders["kelvinSlider"].exists)
    }

    func testEmergencyBlocksToggleAcrossRelaunch() {
        let app = launch()
        let emergency = app.buttons["emergencyStop"]
        XCTAssertTrue(emergency.waitForExistence(timeout: 3))
        emergency.tap()
        XCTAssertTrue(app.buttons["confirmSafety"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["toggleLamp"].isEnabled)
        app.terminate()
        app.launch()
        XCTAssertTrue(app.buttons["confirmSafety"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["toggleLamp"].isEnabled)
    }

    func testPanelAutoHideAndTap() {
        let app = launch()
        let toggle = app.buttons["toggleLamp"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        let initial = toggle.label
        let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: toggle)
        XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 8), .completed)
        let surface = app.descendants(matching: .any).matching(identifier: "lampSurface").firstMatch
        let point = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.9))
        point.doubleTap()
        point.tap()
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertNotEqual(toggle.label, initial)
    }

    func testSettingsRemainVisible() {
        let app = launch()
        let settings = app.buttons["settingsButton"]
        XCTAssertTrue(settings.waitForExistence(timeout: 3))
        settings.tap()
        let back = app.buttons["backSettings"]
        XCTAssertTrue(back.waitForExistence(timeout: 3))
        let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: back)
        XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 6), .timedOut)
    }
}
