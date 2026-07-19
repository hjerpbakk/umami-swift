import Foundation

/// What crashed, reduced to identifiers that are safe to send: the exception
/// or signal name and the signal number. Never the reason, message, or stack.
struct CrashMarker: Equatable {
    enum Kind: String { case exception, signal }
    let kind: Kind
    let name: String
    let code: Int
}

/// Persists a `CrashMarker` as a tiny single-line file next to the event
/// queue, written at crash time and consumed on the next launch.
enum CrashMarkerStore {
    static func defaultFileURL() -> URL {
        EventQueue.defaultFileURL().deletingLastPathComponent()
            .appendingPathComponent("crash-marker")
    }

    static func write(_ marker: CrashMarker, to url: URL) {
        let line = "\(marker.kind.rawValue):\(marker.name):\(marker.code)"
        if let data = line.data(using: .utf8) {
            try? data.write(to: url, options: .atomic)
        }
    }

    /// Reads and deletes the marker, so a crash is reported exactly once.
    static func consume(at url: URL) -> CrashMarker? {
        guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return nil }
        try? FileManager.default.removeItem(at: url)
        let parts = raw.split(separator: ":", maxSplits: 2).map(String.init)
        guard parts.count == 3,
              let kind = CrashMarker.Kind(rawValue: parts[0]),
              let code = Int(parts[2]) else { return nil }
        return CrashMarker(kind: kind, name: parts[1], code: code)
    }
}
