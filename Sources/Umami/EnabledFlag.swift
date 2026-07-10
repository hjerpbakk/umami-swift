import Foundation

/// Persists the opt-out flag directly in `UserDefaults`, independent of whether
/// a `UmamiClient` has been created yet. This lets `Umami.setEnabled(false)`
/// take effect even when called before `Umami.configure()`.
enum EnabledFlag {
    static let key = "umami.enabled"

    static func get(_ defaults: UserDefaults = .standard) -> Bool {
        defaults.object(forKey: key) == nil ? true : defaults.bool(forKey: key)
    }

    static func set(_ enabled: Bool, _ defaults: UserDefaults = .standard) {
        defaults.set(enabled, forKey: key)
    }
}
