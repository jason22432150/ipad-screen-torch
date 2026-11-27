import Foundation
#if canImport(Combine)
import Combine
#endif

enum Heat: String, Codable {
    case nominal, fair, serious, critical, unknown
    var cap: Int {
        switch self {
        case .nominal: return 100
        case .fair: return 80
        case .serious, .unknown: return 40
        case .critical: return 0
        }
    }
}

enum Power: String, Codable { case charging, full, unplugged, unknown }
enum StopReason: String, Codable, Hashable { case criticalHeat, lowBattery, emergency }
enum LampPhase: String { case initializing, lighting, standby, sleepEligible, safetyShutdown, suspended }

struct BatteryReading: Equatable {
    var level: Double?
    var power: Power
    var knownLevel: Double? {
        guard let value = level, value.isFinite, (0...1).contains(value) else { return nil }
        return value
    }
    var cap: Int {
        guard let level = knownLevel else { return 40 }
        if level <= 0.05 { return 0 }
        switch power {
        case .charging, .full: return 100
        case .unknown: return 40
        case .unplugged:
            if level > 0.50 { return 100 }
            if level > 0.20 { return 80 }
            if level > 0.10 { return 50 }
            return 20
        }
    }
    var canRecover: Bool {
        guard let level = knownLevel else { return false }
        return power != .unknown && level > 0.05
    }
}

struct SafetyState {
    private(set) var heat: Heat = .unknown
    private(set) var thermalCap = 40
    private(set) var battery = BatteryReading(level: nil, power: .unknown)
    private(set) var latch: Set<StopReason> = []
    private var sampled = false
    private var observedAt: TimeInterval = 0
    private var recoverySince: TimeInterval?
    private var nextRecovery: TimeInterval?
    private var nominalSince: TimeInterval?

    mutating func observe(heat newHeat: Heat, battery newBattery: BatteryReading, now: TimeInterval, newSession: Bool = false) {
        battery = newBattery
        if battery.cap == 0 { latch.insert(.lowBattery) }
        if newHeat == .critical { latch.insert(.criticalHeat) }
        let validTime = now.isFinite && now >= 0 && (!sampled || now >= observedAt)
        let changed = !sampled || newHeat != heat || newSession || !validTime
        if !sampled { thermalCap = newHeat.cap }
        if changed {
            recoverySince = validTime ? now : nil
            nextRecovery = nil
            nominalSince = newHeat == .nominal && validTime ? now : nil
        }
        heat = newHeat
        if newHeat.cap <= thermalCap {
            thermalCap = newHeat.cap
            nextRecovery = nil
        } else if validTime, let since = recoverySince, now >= since + 120 {
            let next = nextRecovery ?? (since + 121)
            if now >= next {
                // Never convert a potentially unbounded elapsed value to Int.
                let steps = Int(min(50, floor(now - next) + 1))
                thermalCap = min(newHeat.cap, thermalCap + steps * 2)
                nextRecovery = now + 1
            }
        }
        if validTime { observedAt = now }
        sampled = true
    }

    mutating func restoreLatch(_ reasons: Set<StopReason>) { latch.formUnion(reasons) }
    mutating func emergency() { latch.insert(.emergency) }
    func canConfirm(now: TimeInterval) -> Bool {
        guard !latch.isEmpty, now.isFinite, now >= observedAt,
              heat != .critical, heat != .unknown, battery.canRecover else { return false }
        if latch.contains(.criticalHeat) {
            guard heat == .nominal, let since = nominalSince, now - since >= 120 else { return false }
        }
        return true
    }
    @discardableResult mutating func confirm(now: TimeInterval) -> Bool {
        guard canConfirm(now: now) else { return false }
        latch.removeAll()
        return true
    }
}

struct LampState {
    var requested = 80
    var lastNonZero = 80
    var kelvin = 4000
    var wantsLight = false
    var safety = SafetyState()
    var active = false
    var launched = false
    var storageBlocked = false

    var isBlocked: Bool { storageBlocked || !safety.latch.isEmpty }

    var effective: Int {
        guard active, wantsLight, !isBlocked else { return 0 }
        return min(requested, safety.thermalCap, safety.battery.cap)
    }
    func outputEffective(transition: Int?) -> Int {
        guard active, !isBlocked else { return 0 }
        guard let transition = transition else { return effective }
        return min(max(0, transition), requested, safety.thermalCap, safety.battery.cap)
    }
    var phase: LampPhase {
        if !launched { return .initializing }
        if !active { return .suspended }
        if isBlocked { return .safetyShutdown }
        if wantsLight { return .lighting }
        return safety.battery.power == .charging || safety.battery.power == .full ? .standby : .sleepEligible
    }
}

enum LampAction {
    case activate(Heat, BatteryReading, TimeInterval)
    case deactivate
    case readings(Heat, BatteryReading, TimeInterval)
    case toggle
    case setBrightness(Int)
    case setKelvin(Int)
    case emergencyStop
    case restoreLatch(Set<StopReason>)
    case confirmSafety(TimeInterval)
    case restoreRuntime(RuntimeSnapshot)
    case storageFailure
}

enum LampReducer {
    static func reduce(_ state: inout LampState, _ action: LampAction) {
        switch action {
        case let .activate(heat, battery, now):
            state.safety.observe(heat: heat, battery: battery, now: now, newSession: !state.active)
            state.active = true
            state.launched = true
        case .deactivate:
            state.active = false
        case let .readings(heat, battery, now):
            guard state.active else { return }
            state.safety.observe(heat: heat, battery: battery, now: now)
        case .toggle:
            guard state.active, !state.isBlocked else { return }
            state.wantsLight.toggle()
            if state.wantsLight { state.requested = state.lastNonZero }
        case let .setBrightness(value):
            guard state.active, !state.isBlocked else { return }
            if value <= 0 { state.wantsLight = false }
            else {
                state.requested = min(100, value)
                state.lastNonZero = state.requested
            }
        case let .setKelvin(value):
            guard state.active, !state.isBlocked else { return }
            let clamped = min(10000, max(1000, value))
            state.kelvin = ((clamped + 50) / 100) * 100
        case .emergencyStop:
            state.safety.emergency()
        case let .restoreLatch(reasons):
            state.safety.restoreLatch(reasons)
        case let .confirmSafety(now):
            guard state.active, !state.storageBlocked, state.safety.confirm(now: now) else { return }
            state.wantsLight = false
        case let .restoreRuntime(snapshot):
            guard !state.launched, snapshot.isValid else { return }
            state.requested = snapshot.requested
            state.lastNonZero = snapshot.lastNonZero
            state.kelvin = snapshot.kelvin
            state.safety.restoreLatch(snapshot.safetyLatch)
            state.wantsLight = !snapshot.foregroundRunMarker && snapshot.desiredPower
        case .storageFailure:
            state.storageBlocked = true
        }
        if state.isBlocked { state.wantsLight = false }
    }
}

@MainActor protocol ClockService { var monotonic: TimeInterval { get } }
@MainActor protocol BatteryService { var reading: BatteryReading { get } }
@MainActor protocol ThermalService { var heat: Heat { get } }
@MainActor protocol ScreenBrightnessService {
    var brightness: Double { get }
    func write(_ brightness: Double)
}
@MainActor protocol IdleTimerService: AnyObject { var disabled: Bool { get set } }

#if canImport(Combine)
@MainActor final class LampStore: ObservableObject {
    @Published private(set) var state: LampState
    init(state: LampState = LampState()) { self.state = state }
    func send(_ action: LampAction) {
        var next = state
        LampReducer.reduce(&next, action)
        state = next
    }
}
#endif

struct BrightnessOutput: Equatable {
    let hardware: Double
    let software: Double
    static func map(_ effective: Int) -> Self {
        let e = min(100, max(0, effective))
        if e == 0 { return Self(hardware: 0, software: 0) }
        if e < 5 { return Self(hardware: 0.05, software: Double(e) / 5) }
        return Self(hardware: Double(e) / 100, software: 1)
    }
}

struct LampRGB: Equatable {
    let red: Double
    let green: Double
    let blue: Double
    static func kelvin(_ value: Int) -> Self {
        let t = Double(min(10000, max(1000, value))) / 100
        let r = t <= 66 ? 255 : 329.698727446 * pow(t - 60, -0.1332047592)
        let g = t <= 66 ? 99.4708025861 * log(t) - 161.1195681661 : 288.1221695283 * pow(t - 60, -0.0755148492)
        let b = t >= 66 ? 255 : (t <= 19 ? 0 : 138.5177312231 * log(t - 10) - 305.0447927307)
        func normalize(_ v: Double) -> Double { min(255, max(0, v)) / 255 }
        return Self(red: normalize(r), green: normalize(g), blue: normalize(b))
    }
    func scaled(_ value: Double) -> Self {
        let factor = value.isFinite ? min(1, max(0, value)) : 0
        return Self(red: red * factor, green: green * factor, blue: blue * factor)
    }
}

@MainActor final class ScreenOwnership {
    private let screen: ScreenBrightnessService
    private let idle: IdleTimerService
    private var snapshot: (brightness: Double, idle: Bool)?
    private var lastWrite: (value: Double, time: TimeInterval)?
    init(screen: ScreenBrightnessService, idle: IdleTimerService) {
        self.screen = screen
        self.idle = idle
    }
    func acquire() {
        guard snapshot == nil else { return }
        snapshot = (screen.brightness, idle.disabled)
        lastWrite = nil
    }
    func release() {
        guard let original = snapshot else { return }
        snapshot = nil
        lastWrite = nil
        idle.disabled = original.idle
        if original.brightness.isFinite { screen.write(min(1, max(0, original.brightness))) }
    }
    func apply(_ state: LampState, now: TimeInterval, allowBrightnessWrite: Bool = true, transitionEffective: Int? = nil) {
        guard state.active, let original = snapshot else { return }
        let output = BrightnessOutput.map(state.outputEffective(transition: transitionEffective))
        idle.disabled = state.phase == .lighting || state.phase == .standby ? true : original.idle
        if allowBrightnessWrite && (!screen.brightness.isFinite || abs(screen.brightness - output.hardware) > 0.0005) {
            lastWrite = (output.hardware, now)
            screen.write(output.hardware)
        }
    }
    func externalBrightness(_ value: Double, now: TimeInterval) -> Int? {
        guard snapshot != nil, value.isFinite, (0...1).contains(value), now.isFinite else { return nil }
        if let write = lastWrite, now >= write.time, now - write.time <= 0.5, abs(value - write.value) <= 0.0005 { return nil }
        lastWrite = nil
        return Int((value * 100).rounded())
    }
}

struct RuntimeSnapshot: Codable, Equatable {
    var schemaVersion = 1
    var requested: Int
    var lastNonZero: Int
    var kelvin: Int
    var desiredPower: Bool
    var safetyLatch: Set<StopReason>
    var foregroundRunMarker: Bool
    var isValid: Bool {
        schemaVersion == 1 && (1...100).contains(requested) && (1...100).contains(lastNonZero) &&
            (1000...10000).contains(kelvin) && kelvin % 100 == 0
    }
    init(state: LampState, active: Bool) {
        requested = state.requested
        lastNonZero = state.lastNonZero
        kelvin = state.kelvin
        desiredPower = state.wantsLight && !state.isBlocked
        safetyLatch = state.safety.latch
        foregroundRunMarker = active
    }
}

enum RuntimeLoad {
    case missing, valid(RuntimeSnapshot), invalid
}

enum RuntimePersistenceError: Error { case invalidSnapshot, futureSchema, oversized }

final class RuntimePersistence {
    private let url: URL
    private let queue = DispatchQueue(label: "ScreenTorch.runtimePersistence")
    private let maxBytes = 5 * 1024 * 1024
    init(url: URL) { self.url = url }
    func load() -> RuntimeLoad {
        queue.sync {
            guard FileManager.default.fileExists(atPath: url.path) else { return .missing }
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
                guard let size = attributes[.size] as? NSNumber, size.intValue <= maxBytes else { return .invalid }
                let data = try Data(contentsOf: url)
                guard data.count <= maxBytes else { return .invalid }
                let snapshot = try JSONDecoder().decode(RuntimeSnapshot.self, from: data)
                return snapshot.isValid ? .valid(snapshot) : .invalid
            } catch { return .invalid }
        }
    }
    func save(_ snapshot: RuntimeSnapshot) throws {
        try queue.sync {
            guard snapshot.isValid else { throw RuntimePersistenceError.invalidSnapshot }
            let manager = FileManager.default
            try manager.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            if manager.fileExists(atPath: url.path) {
                let size = try manager.attributesOfItem(atPath: url.path)[.size] as? NSNumber
                guard let size = size, size.intValue <= maxBytes else { throw RuntimePersistenceError.oversized }
                let old = try Data(contentsOf: url)
                if let raw = try? JSONSerialization.jsonObject(with: old) as? [String: Any],
                   let version = raw["schemaVersion"] as? Int, version > 1 { throw RuntimePersistenceError.futureSchema }
                if (try? JSONDecoder().decode(RuntimeSnapshot.self, from: old).isValid) != true {
                    let quarantine = url.appendingPathExtension("invalid")
                    if !manager.fileExists(atPath: quarantine.path) { try old.write(to: quarantine, options: .atomic) }
                }
            }
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: url, options: .atomic)
        }
    }
}

struct BrightnessTransition {
    let from: Int
    let to: Int
    let start: TimeInterval
    func sample(now: TimeInterval) -> (effective: Int, complete: Bool) {
        guard now.isFinite, start.isFinite, now >= start else { return (0, true) }
        let a = Double(min(100, max(0, from)))
        let b = Double(min(100, max(0, to)))
        let progress = min(1, (now - start) / 0.5)
        return (Int((a + (b - a) * progress).rounded()), progress >= 1)
    }
}
