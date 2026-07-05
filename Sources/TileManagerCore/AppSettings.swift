import Foundation

public final class AppSettings {
    private enum Key {
        static let enabled = "enabled"
        static let launchAtLogin = "launchAtLogin"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        registerDefaults()
    }

    public var enabled: Bool {
        get { defaults.bool(forKey: Key.enabled) }
        set { defaults.set(newValue, forKey: Key.enabled) }
    }

    public var launchAtLogin: Bool {
        get { defaults.bool(forKey: Key.launchAtLogin) }
        set { defaults.set(newValue, forKey: Key.launchAtLogin) }
    }

    private func registerDefaults() {
        defaults.register(defaults: [
            Key.enabled: true,
            Key.launchAtLogin: false
        ])
    }
}
