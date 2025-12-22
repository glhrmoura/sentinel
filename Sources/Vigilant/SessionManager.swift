import AppKit
import Combine

@MainActor
final class SessionManager: ObservableObject {
    enum Session: Equatable {
        case indefinite
        case until(Date)
        case whileRunning(WatchedApp)
    }

    @Published private(set) var session: Session?
    @Published private(set) var activeTrigger: String?
    @Published private(set) var now = Date()

    private let preferences: Preferences
    private let assertion = PowerAssertion()
    private var suppressedTrigger: String?
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()

    init(preferences: Preferences) {
        self.preferences = preferences
        if preferences.startSessionAtLaunch {
            session = .indefinite
        }
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.evaluate() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
        preferences.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.evaluate() }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)
            .sink { [weak self] _ in self?.assertion.release() }
            .store(in: &cancellables)
        evaluate()
    }

    var isActive: Bool { session != nil || activeTrigger != nil }

    var remaining: TimeInterval? {
        guard case .until(let end) = session else { return nil }
        return max(0, end.timeIntervalSince(now))
    }

    var statusTitle: String {
        isActive ? "Ativado" : "Desativado"
    }

    var statusDetail: String {
        switch session {
        case .indefinite:
            return "Por tempo indeterminado"
        case .until:
            return "Restam \(Self.format(remaining ?? 0))"
        case .whileRunning(let app):
            return "Enquanto \(app.name) estiver aberto"
        case nil:
            if let activeTrigger { return "Porque \(activeTrigger)" }
            return "O Mac pode descansar"
        }
    }

    func startIndefinite() {
        session = .indefinite
        evaluate()
    }

    func toggleIndefinite() {
        if !isActive {
            startIndefinite()
        } else {
            end()
        }
    }

    func start(minutes: Int) {
        session = .until(Date().addingTimeInterval(TimeInterval(minutes * 60)))
        evaluate()
    }

    func start(until date: Date) {
        session = .until(date)
        evaluate()
    }

    func start(whileRunning app: WatchedApp) {
        session = .whileRunning(app)
        evaluate()
    }

    func end() {
        suppressedTrigger = activeTrigger
        session = nil
        evaluate()
    }

    private func evaluate() {
        now = Date()
        let power = SystemState.power()

        if preferences.batteryGuardEnabled,
           !power.onExternalPower,
           let percent = power.batteryPercent,
           percent <= preferences.batteryThreshold {
            session = nil
            activeTrigger = nil
            apply()
            return
        }

        switch session {
        case .until(let end) where end <= now:
            session = nil
        case .whileRunning(let app) where !SystemState.isRunning(bundleID: app.bundleID):
            session = nil
        default:
            break
        }

        let candidate = preferences.triggersEnabled ? triggerReason(power: power) : nil
        if candidate == nil {
            suppressedTrigger = nil
        }
        let newTrigger = candidate == suppressedTrigger ? nil : candidate
        if newTrigger != activeTrigger {
            activeTrigger = newTrigger
        }
        apply()
    }

    private func triggerReason(power: PowerStatus) -> String? {
        if let app = preferences.triggerApps.first(where: { SystemState.isRunning(bundleID: $0.bundleID) }) {
            return "\(app.name) está aberto"
        }
        if preferences.triggerOnExternalDisplay && SystemState.hasExternalDisplay() {
            return "há um monitor externo conectado"
        }
        if preferences.triggerOnExternalPower && power.onExternalPower && power.batteryPercent != nil {
            return "o Mac está na tomada"
        }
        return nil
    }

    private func apply() {
        if isActive {
            assertion.hold(keepDisplayAwake: !preferences.allowDisplaySleep, reason: "Vigilant keeping this Mac awake")
        } else {
            assertion.release()
        }
    }

    static func format(_ interval: TimeInterval) -> String {
        let total = Int(interval.rounded(.up))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
