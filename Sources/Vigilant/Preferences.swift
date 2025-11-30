import Foundation

struct WatchedApp: Codable, Hashable, Identifiable {
    let bundleID: String
    let name: String

    var id: String { bundleID }
}

final class Preferences: ObservableObject {
    private let defaults = UserDefaults.standard

    @Published var allowDisplaySleep: Bool {
        didSet { defaults.set(allowDisplaySleep, forKey: Key.allowDisplaySleep) }
    }
    @Published var startSessionAtLaunch: Bool {
        didSet { defaults.set(startSessionAtLaunch, forKey: Key.startSessionAtLaunch) }
    }
    @Published var batteryGuardEnabled: Bool {
        didSet { defaults.set(batteryGuardEnabled, forKey: Key.batteryGuardEnabled) }
    }
    @Published var batteryThreshold: Int {
        didSet { defaults.set(batteryThreshold, forKey: Key.batteryThreshold) }
    }
    @Published var triggersEnabled: Bool {
        didSet { defaults.set(triggersEnabled, forKey: Key.triggersEnabled) }
    }
    @Published var triggerOnExternalPower: Bool {
        didSet { defaults.set(triggerOnExternalPower, forKey: Key.triggerOnExternalPower) }
    }
    @Published var triggerOnExternalDisplay: Bool {
        didSet { defaults.set(triggerOnExternalDisplay, forKey: Key.triggerOnExternalDisplay) }
    }
    @Published var triggerApps: [WatchedApp] {
        didSet { defaults.set(try? JSONEncoder().encode(triggerApps), forKey: Key.triggerApps) }
    }

    init() {
        allowDisplaySleep = defaults.bool(forKey: Key.allowDisplaySleep)
        startSessionAtLaunch = defaults.bool(forKey: Key.startSessionAtLaunch)
        batteryGuardEnabled = defaults.object(forKey: Key.batteryGuardEnabled) as? Bool ?? true
        batteryThreshold = defaults.object(forKey: Key.batteryThreshold) as? Int ?? 15
        triggersEnabled = defaults.bool(forKey: Key.triggersEnabled)
        triggerOnExternalPower = defaults.bool(forKey: Key.triggerOnExternalPower)
        triggerOnExternalDisplay = defaults.bool(forKey: Key.triggerOnExternalDisplay)
        if let data = defaults.data(forKey: Key.triggerApps),
           let apps = try? JSONDecoder().decode([WatchedApp].self, from: data) {
            triggerApps = apps
        } else {
            triggerApps = []
        }
    }

    private enum Key {
        static let allowDisplaySleep = "allowDisplaySleep"
        static let startSessionAtLaunch = "startSessionAtLaunch"
        static let batteryGuardEnabled = "batteryGuardEnabled"
        static let batteryThreshold = "batteryThreshold"
        static let triggersEnabled = "triggersEnabled"
        static let triggerOnExternalPower = "triggerOnExternalPower"
        static let triggerOnExternalDisplay = "triggerOnExternalDisplay"
        static let triggerApps = "triggerApps"
    }
}
