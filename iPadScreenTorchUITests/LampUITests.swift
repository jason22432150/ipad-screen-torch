import XCTest

final class LampUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        // A unique simulator-only runtime directory avoids cross-test latch state.
        app.launchEnvironment["SCREEN_TORCH_UI_TEST_ID"] = UUID().uuidString
        app.launch()
        return app
    }

    private func surfacePoint(_ app: XCUIApplication) -> XCUICoordinate {
        app.buttons["lampSurface"].coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.9))
    }

    private func openSettings(_ app: XCUIApplication) {
        let back = app.buttons["backSettings"]
        if !back.exists {
            // Use the real long-press gesture, even if the quick panel already timed out.
            surfacePoint(app).press(forDuration: 1.0)
        }
        XCTAssertTrue(back.waitForExistence(timeout: 5))
        XCTAssertTrue(back.isHittable, "Settings back control must be reachable")
    }

    func testLaunchAndControls() {
        let app = launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        openSettings(app)
        XCTAssertTrue(app.buttons["toggleLamp"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.sliders["brightnessSlider"].exists)
        XCTAssertTrue(app.sliders["kelvinSlider"].exists)
    }

    func testEmergencyBlocksToggleAcrossRelaunch() {
        let app = launch()
        openSettings(app)
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
        openSettings(app)
        let toggle = app.buttons["toggleLamp"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        let initial = toggle.label
        app.buttons["backSettings"].tap()
        XCTAssertFalse(app.buttons["backSettings"].exists, "Returning to quick controls must close settings")
        let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: toggle)
        XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 8), .completed)
        let point = surfacePoint(app)
        point.doubleTap()
        point.tap()
        XCTAssertTrue(toggle.waitForExistence(timeout: 3))
        XCTAssertNotEqual(toggle.label, initial)
    }

    func testSettingsRemainVisible() {
        let app = launch()
        openSettings(app)
        let back = app.buttons["backSettings"]
        XCTAssertTrue(back.waitForExistence(timeout: 3))
        let hidden = XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: back)
        XCTAssertEqual(XCTWaiter.wait(for: [hidden], timeout: 6), .timedOut)
    }

    func testDirectionalPanPreservesOtherAxis() throws {
        let app = launch()
        XCUIDevice.shared.orientation = .portrait
        openSettings(app)
        let brightness = app.sliders["brightnessSlider"]
        let kelvin = app.sliders["kelvinSlider"]
        let initialBrightness = try XCTUnwrap(brightness.value as? String)
        let initialKelvin = try XCTUnwrap(kelvin.value as? String)
        let surface = app.buttons["lampSurface"]
        // The left margin and lower half remain outside the top-centered panel.
        let start = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.60))
        let down = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.08, dy: 0.86))
        start.press(forDuration: 0.05, thenDragTo: down)
        XCTAssertNotEqual(brightness.value as? String, initialBrightness)
        XCTAssertEqual(kelvin.value as? String, initialKelvin)
        let changedBrightness = try XCTUnwrap(brightness.value as? String)
        let left = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.15, dy: 0.86))
        let right = surface.coordinate(withNormalizedOffset: CGVector(dx: 0.75, dy: 0.86))
        left.press(forDuration: 0.05, thenDragTo: right)
        XCTAssertEqual(brightness.value as? String, changedBrightness)
        XCTAssertNotEqual(kelvin.value as? String, initialKelvin)
    }

    func testFourOrientationsPreserveControls() throws {
        let app = launch()
        let device = XCUIDevice.shared
        defer { device.orientation = .portrait }
        device.orientation = .portrait
        openSettings(app)
        let brightness = app.sliders["brightnessSlider"]
        let kelvin = app.sliders["kelvinSlider"]
        let expectedBrightness = try XCTUnwrap(brightness.value as? String)
        let expectedKelvin = try XCTUnwrap(kelvin.value as? String)
        let surface = app.buttons["lampSurface"]
        let orientations: [(UIDeviceOrientation, Bool)] = [
            (.landscapeLeft, true), (.portraitUpsideDown, false),
            (.landscapeRight, true), (.portrait, false)
        ]
        for (orientation, landscape) in orientations {
            device.orientation = orientation
            let predicate = NSPredicate { _, _ in
                let frame = surface.frame
                return surface.exists && !frame.isEmpty &&
                    (landscape ? frame.width > frame.height : frame.height > frame.width)
            }
            let expectation = XCTNSPredicateExpectation(predicate: predicate, object: surface)
            XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: 10), .completed)
            XCTAssertTrue(app.buttons["backSettings"].isHittable)
            XCTAssertEqual(brightness.value as? String, expectedBrightness)
            XCTAssertEqual(kelvin.value as? String, expectedKelvin)
        }
    }
}
