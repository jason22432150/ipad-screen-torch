import UIKit
import SwiftUI

@main
@MainActor final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    private var lamp: LampViewController?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let controller = LampViewController()
        lamp = controller
        window.rootViewController = controller
        self.window = window
        window.makeKeyAndVisible()
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) { lamp?.activate() }
    func applicationWillResignActive(_ application: UIApplication) { lamp?.deactivate() }
    func applicationDidEnterBackground(_ application: UIApplication) { lamp?.deactivate() }
    func applicationWillTerminate(_ application: UIApplication) { lamp?.deactivate() }
}

@MainActor final class UIKitHardware: ScreenBrightnessService, IdleTimerService, BatteryService, ThermalService, ClockService {
    var brightness: Double { Double(UIScreen.main.brightness) }
    func write(_ brightness: Double) {
        guard brightness.isFinite else { return }
        UIScreen.main.brightness = CGFloat(min(1, max(0, brightness)))
    }
    var disabled: Bool {
        get { UIApplication.shared.isIdleTimerDisabled }
        set { UIApplication.shared.isIdleTimerDisabled = newValue }
    }
    var reading: BatteryReading {
        let device = UIDevice.current
        let power: Power
        switch device.batteryState {
        case .charging: power = .charging
        case .full: power = .full
        case .unplugged: power = .unplugged
        case .unknown: power = .unknown
        @unknown default: power = .unknown
        }
        let level = Double(device.batteryLevel)
        return BatteryReading(level: level >= 0 ? level : nil, power: power)
    }
    var heat: Heat {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return .nominal
        case .fair: return .fair
        case .serious: return .serious
        case .critical: return .critical
        @unknown default: return .unknown
        }
    }
    var monotonic: TimeInterval { ProcessInfo.processInfo.systemUptime }
    private var originalBatteryMonitoring: Bool?
    func beginMonitoring() {
        guard originalBatteryMonitoring == nil else { return }
        originalBatteryMonitoring = UIDevice.current.isBatteryMonitoringEnabled
        UIDevice.current.isBatteryMonitoringEnabled = true
    }
    func endMonitoring() {
        guard let original = originalBatteryMonitoring else { return }
        originalBatteryMonitoring = nil
        UIDevice.current.isBatteryMonitoringEnabled = original
    }
}

@MainActor final class LampViewController: UIViewController {
    private let hardware = UIKitHardware()
    private lazy var ownership = ScreenOwnership(screen: hardware, idle: hardware)
    private let store = LampStore()
    private let surface = UIView()
    private var panel: UIHostingController<QuickPanel>?
    private var observers: [NSObjectProtocol] = []
    private var hideTimer: Timer?
    private var recoveryTimer: Timer?
    private var panelEditing = false
    private var panelSettings = false
    private var initialBrightness = 80
    private var initialKelvin = 4000
    private var panAxis: Int?
    private var lastPanUpdate: TimeInterval = 0
    private var lastRendered: (effective: Int, kelvin: Int, heat: Heat, thermalCap: Int, batteryCap: Int)?
    private var lastExternalCorrection: TimeInterval = -.infinity
    private var correctingBrightness = false

    override var prefersStatusBarHidden: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .all }
    override var preferredScreenEdgesDeferringSystemGestures: UIRectEdge { .all }
    override var shouldAutorotate: Bool { true }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        surface.backgroundColor = .black
        surface.translatesAutoresizingMaskIntoConstraints = false
        surface.isAccessibilityElement = true
        surface.accessibilityIdentifier = "lampSurface"
        surface.accessibilityLabel = tr("燈光畫面", "Lamp surface")
        surface.accessibilityTraits = .button
        surface.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: tr("顯示控制面板", "Show controls"), target: self, selector: #selector(accessibilityShowPanel)),
            UIAccessibilityCustomAction(name: tr("開關燈", "Toggle lamp"), target: self, selector: #selector(accessibilityToggle))
        ]
        view.addSubview(surface)
        NSLayoutConstraint.activate([
            surface.topAnchor.constraint(equalTo: view.topAnchor),
            surface.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            surface.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            surface.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        let single = UITapGestureRecognizer(target: self, action: #selector(singleTap))
        let double = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
        double.numberOfTapsRequired = 2
        single.require(toFail: double)
        let pan = UIPanGestureRecognizer(target: self, action: #selector(panGesture(_:)))
        pan.maximumNumberOfTouches = 1
        let long = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        long.numberOfTouchesRequired = 1
        let emergency = UILongPressGestureRecognizer(target: self, action: #selector(emergencyPress(_:)))
        emergency.minimumPressDuration = 5
        emergency.numberOfTouchesRequired = 4
        for gesture in [single, double, pan, long] as [UIGestureRecognizer] { surface.addGestureRecognizer(gesture) }
        view.addGestureRecognizer(emergency)
        let root = QuickPanel(store: store, send: { [weak self] in self?.dispatch($0) },
                              editing: { [weak self] in self?.setEditing($0) },
                              settingsChanged: { [weak self] in self?.setSettings($0) },
                              close: { [weak self] in self?.setPanel(false) },
                              canConfirm: { [weak self] in self?.canConfirm ?? false })
        let host = UIHostingController(rootView: root)
        addChild(host)
        host.view.backgroundColor = .clear
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        let preferredWidth = host.view.widthAnchor.constraint(equalToConstant: 420)
        preferredWidth.priority = .defaultHigh
        NSLayoutConstraint.activate([
            host.view.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            host.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            host.view.leadingAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            host.view.trailingAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            host.view.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
            preferredWidth
        ])
        host.didMove(toParent: self)
        panel = host
    }

    func activate() {
        guard !store.state.active else { return }
        loadViewIfNeeded()
        hardware.beginMonitoring()
        ownership.acquire()
        lastExternalCorrection = -.infinity
        correctingBrightness = false
        observeHardware()
        store.send(.activate(hardware.heat, hardware.reading, hardware.monotonic))
        render()
        setPanel(true)
    }

    func deactivate() {
        guard store.state.active else { return }
        hideTimer?.invalidate(); hideTimer = nil
        recoveryTimer?.invalidate(); recoveryTimer = nil
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        store.send(.deactivate)
        surface.layer.removeAllAnimations()
        surface.backgroundColor = .black
        lastRendered = nil
        ownership.release()
        hardware.endMonitoring()
    }

    private func observeHardware() {
        let center = NotificationCenter.default
        for name in [ProcessInfo.thermalStateDidChangeNotification, UIDevice.batteryLevelDidChangeNotification, UIDevice.batteryStateDidChangeNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.refresh() }
            })
        }
        observers.append(center.addObserver(forName: UIScreen.brightnessDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.brightnessChanged() }
        })
    }

    private func refresh() {
        guard store.state.active else { return }
        store.send(.readings(hardware.heat, hardware.reading, hardware.monotonic))
        render()
    }

    private var canConfirm: Bool {
        store.state.safety.canConfirm(now: hardware.monotonic)
    }

    private func dispatch(_ action: LampAction) {
        guard store.state.active else { return }
        // Re-read before a user action; no UI action writes hardware directly.
        store.send(.readings(hardware.heat, hardware.reading, hardware.monotonic))
        store.send(action)
        render()
        scheduleHide()
    }

    private func brightnessChanged() {
        guard store.state.active, !correctingBrightness else { return }
        let now = hardware.monotonic
        guard let value = ownership.externalBrightness(hardware.brightness, now: now) else { return }
        store.send(.readings(hardware.heat, hardware.reading, now))
        let state = store.state
        let target = BrightnessOutput.map(state.effective).hardware
        if !state.safety.latch.isEmpty || hardware.brightness > target + 0.001 && state.effective < state.requested {
            // Do not fight an uncooperative system indefinitely.
            if now - lastExternalCorrection < 0.5 {
                store.send(.emergencyStop)
                surface.layer.removeAllAnimations()
                surface.backgroundColor = .black
                render()
                return
            }
            lastExternalCorrection = now
        } else if state.wantsLight {
            store.send(.setBrightness(value))
        }
        render()
    }

    private func render() {
        let state = store.state
        guard state.active else { return }
        let output = BrightnessOutput.map(state.effective)
        let color = LampRGB.kelvin(state.kelvin).scaled(output.software)
        let target = UIColor(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: 1)
        let previous = lastRendered
        let safetyDrop = !state.safety.latch.isEmpty || state.safety.heat == .serious || state.safety.heat == .critical ||
            (previous.map { state.safety.thermalCap < $0.thermalCap || state.safety.battery.cap < $0.batteryCap } ?? true)
        let changed = previous?.effective != state.effective || previous?.kelvin != state.kelvin
        if safetyDrop || UIAccessibility.isReduceMotionEnabled {
            surface.layer.removeAllAnimations()
            surface.backgroundColor = target
        } else if changed {
            let toggled = (previous?.effective == 0) != (state.effective == 0)
            UIView.animate(withDuration: toggled ? 0.5 : 0.2, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction]) {
                self.surface.backgroundColor = target
            }
        }
        correctingBrightness = true
        ownership.apply(state, now: hardware.monotonic)
        correctingBrightness = false
        lastRendered = (state.effective, state.kelvin, state.safety.heat, state.safety.thermalCap, state.safety.battery.cap)
        if !state.safety.latch.isEmpty {
            panel?.view.isHidden = false
            hideTimer?.invalidate(); hideTimer = nil
        }
        scheduleRecovery()
    }

    private func scheduleRecovery() {
        let safety = store.state.safety
        let waiting = safety.thermalCap < safety.heat.cap ||
            (safety.latch.contains(.criticalHeat) && safety.heat == .nominal && !canConfirm)
        guard waiting else { recoveryTimer?.invalidate(); recoveryTimer = nil; return }
        guard recoveryTimer == nil else { return }
        recoveryTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                self.recoveryTimer = nil
                self.refresh()
            }
        }
    }

    private func setPanel(_ visible: Bool) {
        if !visible && (!store.state.safety.latch.isEmpty || panelEditing || panelSettings) { return }
        panel?.view.isHidden = !visible
        scheduleHide()
    }
    private func scheduleHide() {
        hideTimer?.invalidate(); hideTimer = nil
        guard store.state.active, panel?.view.isHidden == false, !panelEditing, !panelSettings, store.state.safety.latch.isEmpty else { return }
        hideTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            Task { @MainActor in self?.setPanel(false) }
        }
    }
    private func setEditing(_ value: Bool) { panelEditing = value; scheduleHide() }
    private func setSettings(_ value: Bool) { panelSettings = value; scheduleHide() }

    @objc private func singleTap() { setPanel(panel?.view.isHidden == true) }
    @objc private func doubleTap() { dispatch(.toggle) }
    @objc private func accessibilityShowPanel() -> Bool { setPanel(true); return true }
    @objc private func accessibilityToggle() -> Bool { dispatch(.toggle); return true }
    @objc private func longPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { setPanel(true); panelSettings = true; panel?.rootView.settingsRequested = true }
    }
    @objc private func emergencyPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { dispatch(.emergencyStop) }
    }
    @objc private func panGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: surface)
        switch gesture.state {
        case .began:
            initialBrightness = store.state.requested; initialKelvin = store.state.kelvin
            panAxis = nil; lastPanUpdate = 0
        case .changed, .ended:
            let now = hardware.monotonic
            guard gesture.state == .ended || now - lastPanUpdate >= 1.0 / 30 else { return }
            if panAxis == nil {
                guard max(abs(translation.x), abs(translation.y)) >= 4 else { return }
                panAxis = abs(translation.y) >= abs(translation.x) ? 0 : 1
            }
            lastPanUpdate = now
            if panAxis == 0 {
                let delta = -translation.y / max(1, surface.bounds.height) * 100
                dispatch(.setBrightness(max(1, min(100, initialBrightness + Int(delta.rounded())))))
            } else {
                let delta = translation.x / max(1, surface.bounds.width) * 9000
                dispatch(.setKelvin(initialKelvin + Int(delta.rounded())))
            }
            if gesture.state == .ended { panAxis = nil }
        default: panAxis = nil
        }
    }
}

private func tr(_ zh: String, _ en: String) -> String {
    Locale.preferredLanguages.first?.hasPrefix("en") == true ? en : zh
}

@MainActor struct QuickPanel: View {
    @ObservedObject var store: LampStore
    var send: (LampAction) -> Void
    var editing: (Bool) -> Void
    var settingsChanged: (Bool) -> Void
    var close: () -> Void
    var canConfirm: () -> Bool
    var settingsRequested = false
    @State private var settings = false

    var body: some View {
        let state = store.state
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Screen Torch").font(.headline)
                Spacer()
                Button(tr("隱藏", "Hide"), action: close).accessibilityIdentifier("hidePanel")
            }
            if !state.safety.latch.isEmpty {
                Text(tr("安全停止：", "Safety stop: ") + state.safety.latch.map { reason in
                    switch reason {
                    case .criticalHeat: return tr("過熱", "Critical heat")
                    case .lowBattery: return tr("低電量", "Low battery")
                    case .emergency: return tr("緊急停止", "Emergency stop")
                    }
                }.sorted().joined(separator: " / ")).foregroundColor(.red)
                Button(tr("確認並回到待機", "Confirm and return to standby")) {
                    send(.confirmSafety(ProcessInfo.processInfo.systemUptime))
                }.disabled(!canConfirm()).accessibilityIdentifier("confirmSafety")
            }
            Button(state.wantsLight ? tr("關燈", "Turn off") : tr("開燈", "Turn on")) { send(.toggle) }
                .buttonStyle(.borderedProminent)
                .disabled(!state.safety.latch.isEmpty)
                .accessibilityIdentifier("toggleLamp")
            Text(tr("要求 / 有效亮度", "Requested / effective") + ": \(state.requested)% / \(state.effective)%")
                .accessibilityIdentifier("brightnessSummary")
            Slider(value: Binding(get: { Double(store.state.requested) }, set: { send(.setBrightness(Int($0.rounded()))) }),
                   in: 1...100, step: 1, onEditingChanged: editing)
                .accessibilityLabel(Text(tr("亮度", "Brightness"))).accessibilityIdentifier("brightnessSlider")
                .disabled(!state.safety.latch.isEmpty)
            Text(tr("色溫", "Color temperature") + ": \(state.kelvin) K")
            Slider(value: Binding(get: { Double(store.state.kelvin) }, set: { send(.setKelvin(Int($0.rounded()))) }),
                   in: 1000...10000, step: 100, onEditingChanged: editing)
                .accessibilityLabel(Text(tr("色溫", "Color temperature"))).accessibilityIdentifier("kelvinSlider")
                .disabled(!state.safety.latch.isEmpty)
            HStack {
                Button(tr("設定 / 安全", "Settings / Safety")) { settings.toggle(); settingsChanged(settings) }
                Spacer()
                Button(tr("緊急關燈", "Emergency stop"), role: .destructive) { send(.emergencyStop) }
                    .accessibilityIdentifier("emergencyStop")
            }
            if settings || settingsRequested {
                Text(tr("熱狀態", "Thermal") + ": \(state.safety.heat.rawValue) · \(state.safety.thermalCap)%")
                Text(tr("電量上限", "Battery cap") + ": \(state.safety.battery.cap)%")
                Text(tr("上下滑動亮度，左右滑動色溫；雙擊開關。老舊電池須先檢查，異常發熱立即停用。", "Swipe vertically for brightness, horizontally for color; double tap to toggle. Inspect old batteries; stop if unusually hot.")).font(.footnote)
                Button(tr("返回", "Back")) { settings = false; settingsChanged(false) }
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .onChange(of: settingsRequested) { requested in if requested { settings = true } }
    }
}
