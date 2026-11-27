import XCTest
@testable import iPadScreenTorch

final class LampCoreTests: XCTestCase {
    let ac = BatteryReading(level: 0.9, power: .charging)
    func testBatteryBoundaries() {
        for (level, cap) in [(0.51,100),(0.50,80),(0.20,50),(0.10,20),(0.05,0)] {
            XCTAssertEqual(BatteryReading(level: level, power: .unplugged).cap, cap)
        }
        XCTAssertEqual(BatteryReading(level: 0.05, power: .charging).cap, 0)
        XCTAssertEqual(BatteryReading(level: .nan, power: .charging).cap, 40)
        XCTAssertEqual(BatteryReading(level: 0.8, power: .unknown).cap, 40)
        XCTAssertEqual(BatteryReading(level: nil, power: .full).cap, 40)
    }
    func testThermalRecoveryAndRelapse() {
        var s = SafetyState()
        s.observe(heat: .nominal, battery: ac, now: 0)
        s.observe(heat: .serious, battery: ac, now: 1)
        XCTAssertEqual(s.thermalCap, 40)
        s.observe(heat: .nominal, battery: ac, now: 2)
        s.observe(heat: .nominal, battery: ac, now: 122)
        XCTAssertEqual(s.thermalCap, 40)
        s.observe(heat: .nominal, battery: ac, now: 123)
        XCTAssertEqual(s.thermalCap, 42)
        s.observe(heat: .serious, battery: ac, now: 124)
        XCTAssertEqual(s.thermalCap, 40)
    }
    func testCriticalLatchRequiresExplicitRestart() {
        var s = LampState()
        LampReducer.reduce(&s, .activate(.nominal, ac, 0))
        XCTAssertEqual(s.phase, .standby)
        LampReducer.reduce(&s, .toggle)
        XCTAssertEqual(s.effective, 80)
        LampReducer.reduce(&s, .readings(.critical, ac, 1))
        XCTAssertEqual(s.phase, .safetyShutdown)
        LampReducer.reduce(&s, .toggle)
        XCTAssertEqual(s.effective, 0)
        LampReducer.reduce(&s, .readings(.nominal, ac, 2))
        LampReducer.reduce(&s, .confirmSafety(121))
        XCTAssertEqual(s.phase, .safetyShutdown)
        LampReducer.reduce(&s, .confirmSafety(122))
        XCTAssertEqual(s.phase, .standby)
        XCTAssertEqual(s.effective, 0)
        XCTAssertEqual(s.requested, 80)
    }
    func testLowBatteryAndEmergencyLatches() {
        var s = LampState()
        LampReducer.reduce(&s, .activate(.nominal, BatteryReading(level: 0.05, power: .unplugged), 0))
        XCTAssertTrue(s.safety.latch.contains(.lowBattery))
        LampReducer.reduce(&s, .readings(.nominal, BatteryReading(level: nil, power: .unknown), 1))
        LampReducer.reduce(&s, .confirmSafety(1))
        XCTAssertEqual(s.phase, .safetyShutdown)
        LampReducer.reduce(&s, .readings(.nominal, ac, 2))
        LampReducer.reduce(&s, .confirmSafety(2))
        XCTAssertEqual(s.phase, .standby)
        LampReducer.reduce(&s, .emergencyStop)
        XCTAssertEqual(s.effective, 0)
        XCTAssertTrue(s.safety.latch.contains(.emergency))
    }
    func testRequestedIsIndependentAndInactiveCannotLight() {
        var s = LampState()
        LampReducer.reduce(&s, .activate(.fair, BatteryReading(level: 0.1, power: .unplugged), 0))
        LampReducer.reduce(&s, .toggle)
        LampReducer.reduce(&s, .setBrightness(100))
        XCTAssertEqual(s.effective, 20)
        XCTAssertEqual(s.requested, 100)
        LampReducer.reduce(&s, .deactivate)
        XCTAssertEqual(s.phase, .suspended)
        XCTAssertEqual(s.effective, 0)
        LampReducer.reduce(&s, .setBrightness(1))
        XCTAssertEqual(s.requested, 100)
    }
}

@MainActor final class FakeClock: ClockService { var monotonic: TimeInterval = 0 }
@MainActor final class FakeBattery: BatteryService { var reading = BatteryReading(level: nil, power: .unknown) }
@MainActor final class FakeThermal: ThermalService { var heat: Heat = .unknown }
@MainActor final class FakeScreen: ScreenBrightnessService {
    var brightness = 0.5
    var writes: [Double] = []
    func write(_ brightness: Double) { self.brightness = brightness; writes.append(brightness) }
}
@MainActor final class FakeIdleTimer: IdleTimerService { var disabled = false }
