import Foundation

enum InstallID {
    static func get(defaults: UserDefaults = .standard,
                    key: String = "umami.installId") -> String {
        if let existing = defaults.string(forKey: key) { return existing }
        let id = UUID().uuidString
        defaults.set(id, forKey: key)
        return id
    }
}
