import Foundation

/// The visitor id sent to Umami. It is random, lives only in memory, and is
/// regenerated when the calendar day changes, so events from different days
/// can never be linked to each other. Nothing is written to the device: a new
/// process gets a new id, which makes one day the id's maximum lifetime, not
/// its typical one.
final class VisitorID {
    static let legacyInstallIdKey = "umami.installId"

    private var id = UUID().uuidString
    private var day: Date

    init(now: Date = Date()) {
        day = Calendar.current.startOfDay(for: now)
    }

    /// Returns the current id, rotating it first when `now` falls on another
    /// day than the previous call. Not internally synchronized; the client
    /// only calls it on its serial work queue.
    func current(now: Date = Date()) -> String {
        let today = Calendar.current.startOfDay(for: now)
        if today != day {
            id = UUID().uuidString
            day = today
        }
        return id
    }

    /// Versions 1.0 and 1.1 stored a persistent install id in `UserDefaults`
    /// and sent it as the visitor. Deleting it here means updating the package
    /// also removes the identifier from the device.
    static func removeLegacyInstallId(from defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: legacyInstallIdKey)
    }
}
