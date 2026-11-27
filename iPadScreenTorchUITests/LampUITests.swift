import XCTest

final class LampUITests: XCTestCase {
    func testLaunchAndControls() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 10))
        XCTAssertTrue(app.buttons["toggleLamp"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.sliders["brightnessSlider"].exists)
        XCTAssertTrue(app.sliders["kelvinSlider"].exists)
    }

    func testEmergencyBlocksToggle() {
        let app = XCUIApplication()
        app.launch()
        let emergency = app.buttons["emergencyStop"]
        XCTAssertTrue(emergency.waitForExistence(timeout: 3))
        emergency.tap()
        XCTAssertTrue(app.buttons["confirmSafety"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["toggleLamp"].isEnabled)
    }
}
