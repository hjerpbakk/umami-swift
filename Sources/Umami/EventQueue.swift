import Foundation

/// A persisted, size-bounded FIFO queue of events.
///
/// - Important: `EventQueue` is NOT internally synchronized. It is not
///   thread-safe on its own; callers must serialize all access (a later
///   serial-queue-based client owns synchronization).
final class EventQueue {
    private var events: [Event] = []
    private let fileURL: URL
    private let maxSize: Int

    init(fileURL: URL, maxSize: Int) {
        self.fileURL = fileURL
        self.maxSize = maxSize
        load()
    }

    var count: Int { events.count }

    func append(_ event: Event) {
        events.append(event)
        enforceMaxSize()
        persist()
    }

    func peekBatch(_ n: Int) -> [Event] {
        Array(events.prefix(n))
    }

    func removeFirst(_ n: Int) {
        events.removeFirst(min(n, events.count))
        persist()
    }

    private func persist() {
        do {
            let data = try JSONEncoder().encode(events)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Persistence is best-effort; never crash the host app.
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([Event].self, from: data) else { return }
        events = decoded
        enforceMaxSize()
    }

    private func enforceMaxSize() {
        if events.count > maxSize {
            events.removeFirst(events.count - maxSize)
        }
    }

    static func defaultFileURL() -> URL {
        let fm = FileManager.default
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fm.temporaryDirectory
        let dir = base.appendingPathComponent("Umami", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("queue.json")
    }
}
