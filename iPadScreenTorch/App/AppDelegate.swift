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
    private var suppressBrightnessWrites = false
    private var persistence: RuntimePersistence?
    private var lastSaved: RuntimeSnapshot?
    private var persistTimer: Timer?
    private var sessionGeneration = 0
    private var hideGeneration = 0
    private var persistGeneration = 0
    private var loadedRuntime = false

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
                              canConfirm: { [weak self] in self?.canConfirm ?? false },
                              changeLanguage: { [weak self] in self?.changeLanguage() })
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
        sessionGeneration += 1
        if !loadedRuntime {
            loadedRuntime = true
            if var root = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                #if targetEnvironment(simulator)
                if let id = ProcessInfo.processInfo.environment["SCREEN_TORCH_UI_TEST_ID"], UUID(uuidString: id) != nil {
                    root = root.appendingPathComponent("UITestRuntime").appendingPathComponent(id)
                }
                #endif
                let persistence = RuntimePersistence(url: root.appendingPathComponent("config/runtime-state.json"))
                self.persistence = persistence
                switch persistence.load() {
                case .missing:
                    panel?.rootView.notice = tr("首次使用：先檢查電池，保持背面通風。", "First use: inspect the battery and keep the back ventilated.")
                case let .valid(snapshot):
                    lastSaved = snapshot
                    store.send(.restoreRuntime(snapshot))
                    if snapshot.foregroundRunMarker {
                        panel?.rootView.notice = tr("疑似異常關閉，已進入安全待機。", "Possible abnormal termination; resumed in safe standby.")
                    }
                case .invalid:
                    panel?.rootView.notice = tr("設定無效，已使用安全預設。", "Invalid settings; safe defaults loaded.")
                }
            } else {
                store.send(.storageFailure)
            }
        }
        hardware.beginMonitoring()
        ownership.acquire()
        lastExternalCorrection = -.infinity
        correctingBrightness = false
        suppressBrightnessWrites = false
        observeHardware()
        store.send(.activate(hardware.heat, hardware.reading, hardware.monotonic))
        persistNow(active: true)
        render()
        setPanel(true)
    }

    func deactivate() {
        guard store.state.active else { return }
        sessionGeneration += 1
        hideGeneration += 1
        persistGeneration += 1
        panelEditing = false
        hideTimer?.invalidate(); hideTimer = nil
        persistTimer?.invalidate(); persistTimer = nil
        recoveryTimer?.invalidate(); recoveryTimer = nil
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        observers.removeAll()
        store.send(.deactivate)
        surface.layer.removeAllAnimations()
        surface.backgroundColor = .black
        lastRendered = nil
        ownership.release()
        hardware.endMonitoring()
        persistNow(active: false)
    }

    private func persistNow(active: Bool) {
        persistTimer?.invalidate(); persistTimer = nil
        persistGeneration += 1
        if active && store.state.storageBlocked { return }
        let snapshot = RuntimeSnapshot(state: store.state, active: active)
        if snapshot == lastSaved { return }
        do {
            guard let persistence = persistence else { throw RuntimePersistenceError.invalidSnapshot }
            try persistence.save(snapshot)
            lastSaved = snapshot
        } catch {
            store.send(.storageFailure)
            panel?.rootView.notice = tr("安全狀態無法保存，已禁止照明。請檢查儲存空間並重新啟動 App。", "Cannot save safety state. Lighting disabled; check storage and restart the app.")
            if active { render() }
        }
    }

    private func persistChanged() {
        guard !store.state.storageBlocked else { return }
        let snapshot = RuntimeSnapshot(state: store.state, active: true)
        guard snapshot != lastSaved else { return }
        if snapshot.safetyLatch != lastSaved?.safetyLatch || snapshot.desiredPower != lastSaved?.desiredPower {
            persistNow(active: true)
            return
        }
        persistTimer?.invalidate()
        persistGeneration += 1
        let generation = persistGeneration
        persistTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.store.state.active, self.persistGeneration == generation else { return }
                self.persistNow(active: true)
            }
        }
    }

    private func observeHardware() {
        let center = NotificationCenter.default
        let generation = sessionGeneration
        for name in [ProcessInfo.thermalStateDidChangeNotification, UIDevice.batteryLevelDidChangeNotification, UIDevice.batteryStateDidChangeNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in if let self = self, self.sessionGeneration == generation { self.refresh() } }
            })
        }
        observers.append(center.addObserver(forName: UIScreen.brightnessDidChangeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in if let self = self, self.sessionGeneration == generation { self.brightnessChanged() } }
        })
    }

    private func refresh() {
        guard store.state.active else { return }
        store.send(.readings(hardware.heat, hardware.reading, hardware.monotonic))
        render()
        persistChanged()
    }

    private var canConfirm: Bool {
        !suppressBrightnessWrites && !store.state.storageBlocked && store.state.safety.canConfirm(now: hardware.monotonic)
    }

    private func dispatch(_ action: LampAction) {
        guard store.state.active else { return }
        // Re-read before a user action; no UI action writes hardware directly.
        let now = hardware.monotonic
        store.send(.readings(hardware.heat, hardware.reading, now))
        if case .confirmSafety = action { if canConfirm { store.send(.confirmSafety(now)) } }
        else { store.send(action) }
        render()
        persistChanged()
        scheduleHide()
    }

    private func brightnessChanged() {
        guard store.state.active, !correctingBrightness, !suppressBrightnessWrites else { return }
        let now = hardware.monotonic
        guard let value = ownership.externalBrightness(hardware.brightness, now: now) else { return }
        store.send(.readings(hardware.heat, hardware.reading, now))
        let state = store.state
        let target = BrightnessOutput.map(state.effective).hardware
        if abs(hardware.brightness - target) <= 0.0005 { render(); persistChanged(); return }
        if state.isBlocked || hardware.brightness > target + 0.001 && state.effective < state.requested {
            // Do not fight an uncooperative system indefinitely.
            if now - lastExternalCorrection < 0.5 {
                suppressBrightnessWrites = true
                panel?.rootView.notice = tr("系統亮度設定未能確認，已停止照明。請離開 App 再返回後手動確認。", "System brightness could not be confirmed. Leave and return to the app before confirming the stop.")
                store.send(.emergencyStop)
                surface.layer.removeAllAnimations()
                surface.backgroundColor = .black
                render()
                persistChanged()
                return
            }
            lastExternalCorrection = now
        } else if state.wantsLight {
            store.send(.setBrightness(value))
        }
        render()
        persistChanged()
    }

    private func render() {
        let state = store.state
        guard state.active else { return }
        let output = BrightnessOutput.map(state.effective)
        let color = LampRGB.kelvin(state.kelvin).scaled(output.software)
        let target = UIColor(red: CGFloat(color.red), green: CGFloat(color.green), blue: CGFloat(color.blue), alpha: 1)
        let previous = lastRendered
        let safetyDrop = state.isBlocked || state.safety.heat == .serious || state.safety.heat == .critical ||
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
        ownership.apply(state, now: hardware.monotonic, allowBrightnessWrite: !suppressBrightnessWrites)
        correctingBrightness = false
        lastRendered = (state.effective, state.kelvin, state.safety.heat, state.safety.thermalCap, state.safety.battery.cap)
        if state.isBlocked {
            panel?.view.isHidden = false
            hideTimer?.invalidate(); hideTimer = nil
        }
        scheduleRecovery()
    }

    private func scheduleRecovery() {
        let safety = store.state.safety
        let waiting = safety.thermalCap < safety.heat.cap ||
            (safety.latch.contains(.criticalHeat) && safety.heat == .nominal && !safety.canConfirm(now: hardware.monotonic))
        guard waiting else { recoveryTimer?.invalidate(); recoveryTimer = nil; return }
        guard recoveryTimer == nil else { return }
        let generation = sessionGeneration
        recoveryTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, self.sessionGeneration == generation else { return }
                self.recoveryTimer = nil
                self.refresh()
            }
        }
    }

    private func setPanel(_ visible: Bool) {
        if !visible && (store.state.isBlocked || panelEditing || panelSettings) { return }
        panel?.view.isHidden = !visible
        scheduleHide()
    }
    private func scheduleHide() {
        hideTimer?.invalidate(); hideTimer = nil
        hideGeneration += 1
        let generation = hideGeneration
        guard store.state.active, panel?.view.isHidden == false, !panelEditing, !panelSettings, !store.state.isBlocked else { return }
        hideTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                if let self = self, self.hideGeneration == generation { self.setPanel(false) }
            }
        }
    }
    private func setEditing(_ value: Bool) { panelEditing = value; if !value { persistNow(active: store.state.active) }; scheduleHide() }
    private func changeLanguage() {
        let current = UserDefaults.standard.string(forKey: "uiLanguage") ?? "zh-Hant"
        UserDefaults.standard.set(current == "en" ? "zh-Hant" : "en", forKey: "uiLanguage")
        surface.accessibilityLabel = tr("燈光畫面", "Lamp surface")
        surface.accessibilityCustomActions = [
            UIAccessibilityCustomAction(name: tr("顯示控制面板", "Show controls"), target: self, selector: #selector(accessibilityShowPanel)),
            UIAccessibilityCustomAction(name: tr("開關燈", "Toggle lamp"), target: self, selector: #selector(accessibilityToggle))
        ]
        if var root = panel?.rootView { root.languageRevision += 1; panel?.rootView = root }
    }
    private func setSettings(_ value: Bool) { panelSettings = value; panel?.rootView.settingsRequested = value; scheduleHide() }

    @objc private func singleTap() { setPanel(panel?.view.isHidden == true) }
    @objc private func doubleTap() { dispatch(.toggle) }
    @objc private func accessibilityShowPanel() -> Bool { setPanel(true); return true }
    @objc private func accessibilityToggle() -> Bool { dispatch(.toggle); return true }
    @objc private func longPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began { setPanel(true); setSettings(true) }
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
            if gesture.state == .ended { panAxis = nil; persistNow(active: store.state.active) }
        default: panAxis = nil
        }
    }
}

private func tr(_ zh: String, _ en: String) -> String {
    UserDefaults.standard.string(forKey: "uiLanguage") == "en" ? en : zh
}

@MainActor struct QuickPanel: View {
    @ObservedObject var store: LampStore
    var send: (LampAction) -> Void
    var editing: (Bool) -> Void
    var settingsChanged: (Bool) -> Void
    var close: () -> Void
    var canConfirm: () -> Bool
    var changeLanguage: () -> Void
    var languageRevision = 0
    var settingsRequested = false
    var notice: String? = nil

    var body: some View {
        let state = store.state
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Screen Torch").font(.headline)
                Spacer()
                Button(tr("隱藏", "Hide"), action: close).accessibilityIdentifier("hidePanel")
            }
            if let notice = notice { Text(notice).font(.footnote) }
            if state.storageBlocked {
                Text(tr("儲存保護：照明已停用", "Storage protection: lighting disabled")).foregroundColor(.red)
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
                .disabled(state.isBlocked)
                .accessibilityIdentifier("toggleLamp")
            Text(tr("要求 / 有效亮度", "Requested / effective") + ": \(state.requested)% / \(state.effective)%")
                .accessibilityIdentifier("brightnessSummary")
            Slider(value: Binding(get: { Double(store.state.requested) }, set: { send(.setBrightness(Int($0.rounded()))) }),
                   in: 1...100, step: 1, onEditingChanged: editing)
                .accessibilityLabel(Text(tr("亮度", "Brightness"))).accessibilityIdentifier("brightnessSlider")
                .disabled(state.isBlocked)
            Text(tr("色溫", "Color temperature") + ": \(state.kelvin) K")
            Slider(value: Binding(get: { Double(store.state.kelvin) }, set: { send(.setKelvin(Int($0.rounded()))) }),
                   in: 1000...10000, step: 100, onEditingChanged: editing)
                .accessibilityLabel(Text(tr("色溫", "Color temperature"))).accessibilityIdentifier("kelvinSlider")
                .disabled(state.isBlocked)
            HStack {
                Button(tr("設定 / 安全", "Settings / Safety")) { settingsChanged(!settingsRequested) }.accessibilityIdentifier("settingsButton")
                Spacer()
                Button(tr("緊急關燈", "Emergency stop"), role: .destructive) { send(.emergencyStop) }
                    .accessibilityIdentifier("emergencyStop")
            }
            if settingsRequested {
                Text(tr("熱狀態", "Thermal") + ": \(state.safety.heat.rawValue) · \(state.safety.thermalCap)%")
                Text(tr("電量上限", "Battery cap") + ": \(state.safety.battery.cap)%")
                Text(tr("上下滑動亮度，左右滑動色溫；雙擊開關。老舊電池須先檢查，異常發熱立即停用。", "Swipe vertically for brightness, horizontally for color; double tap to toggle. Inspect old batteries; stop if unusually hot.")).font(.footnote)
                Button(tr("English", "繁體中文"), action: changeLanguage)
                Button(tr("返回", "Back")) { settingsChanged(false) }.accessibilityIdentifier("backSettings")
            }
        }
        .padding(16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
