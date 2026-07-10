import Foundation
import os

/// Lightweight analytics client that reports app events to a self-hosted Umami backend.
public enum Umami {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var client: UmamiClient?
    private static let log = Logger(subsystem: "com.hjerpbakk.umami", category: "facade")

    /// Configure once at launch. Auto-sends `app_started` and begins flushing.
    public static func configure(websiteId: String,
                                 host: String,
                                 baseURL: URL = URL(string: "https://hjerpbakk-analytics.fly.dev")!,
                                 flushInterval: TimeInterval = 15,
                                 maxQueueSize: Int = 500) {
        lock.lock(); defer { lock.unlock() }
        guard client == nil else {
            log.debug("Umami.configure called more than once; ignoring")
            return
        }
        let config = Configuration(websiteId: websiteId, host: host, baseURL: baseURL,
                                   flushInterval: flushInterval, maxQueueSize: maxQueueSize,
                                   batchSize: 20)
        let c = UmamiClient(config: config,
                            deviceInfo: .current(),
                            installId: InstallID.get(),
                            queue: EventQueue(fileURL: EventQueue.defaultFileURL(),
                                              maxSize: maxQueueSize),
                            uploader: NetworkUploader(session: .shared),
                            defaults: .standard)
        client = c
        c.start()
    }

    public static func track(_ name: String, _ data: [String: AnalyticsValue] = [:]) {
        currentClient()?.track(name, data)
    }

    public static func setEnabled(_ enabled: Bool) { EnabledFlag.set(enabled) }

    public static var isEnabled: Bool { EnabledFlag.get() }

    public static func flush() { currentClient()?.flush() }

    /// Test hook: tears down the shared client.
    static func reset() {
        lock.lock(); defer { lock.unlock() }
        client = nil
    }

    private static func currentClient() -> UmamiClient? {
        lock.lock(); defer { lock.unlock() }
        return client
    }
}
