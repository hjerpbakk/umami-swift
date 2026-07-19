import Foundation
import os

/// Lightweight analytics client that reports app events to a self-hosted Umami backend.
public enum Umami {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var client: UmamiClient?
    private static let log = Logger(subsystem: "com.hjerpbakk.umami", category: "facade")

    /// Configure once at launch. Auto-sends a launch pageview plus `app_started`
    /// and begins flushing. With `reportCrashes` (the default), a crash leaves
    /// a marker holding only the exception or signal name, and the next launch
    /// reports it as an `error_app_crashed` event; pass `false` to opt out.
    public static func configure(websiteId: String,
                                 host: String,
                                 baseURL: URL,
                                 flushInterval: TimeInterval = 15,
                                 maxQueueSize: Int = 500,
                                 reportCrashes: Bool = true) {
        lock.lock(); defer { lock.unlock() }
        guard client == nil else {
            log.debug("Umami.configure called more than once; ignoring")
            return
        }
        let config = Configuration(websiteId: websiteId, host: host, baseURL: baseURL,
                                   flushInterval: flushInterval, maxQueueSize: maxQueueSize,
                                   batchSize: 20)
        // 1.0 and 1.1 stored a persistent install id; updating removes it.
        VisitorID.removeLegacyInstallId()
        let c = UmamiClient(config: config,
                            deviceInfo: .current(),
                            visitorId: VisitorID(),
                            queue: EventQueue(fileURL: EventQueue.defaultFileURL(),
                                              maxSize: maxQueueSize),
                            uploader: NetworkUploader(session: .shared),
                            defaults: .standard,
                            crashMarkerURL: reportCrashes ? CrashMarkerStore.defaultFileURL() : nil)
        client = c
        c.start()
        if reportCrashes {
            CrashWatcher.install(markerURL: CrashMarkerStore.defaultFileURL())
        }
    }

    public static func track(_ name: String, _ data: [String: AnalyticsValue] = [:]) {
        currentClient()?.track(name, data)
    }

    /// Records a screen view, e.g. `Umami.screen("calendar")`. Sent as an Umami
    /// pageview, so it populates the dashboard's Overview tab (visitors, visits,
    /// views) and the pages list, in addition to the automatic launch pageview.
    public static func screen(_ name: String, _ data: [String: AnalyticsValue] = [:]) {
        currentClient()?.screen(name, data)
    }

    /// Reports a handled error, e.g. `Umami.error("save_failed", error)`. Sent
    /// as an event named `error_<name>` so errors group together in the Events
    /// tab. Only the error's type, domain, and code are attached; the message
    /// and `userInfo` are never read, so no user content can leak into
    /// analytics. Pass a static, snake-case name describing the failure path.
    public static func error(_ name: String, _ error: (any Error)? = nil) {
        currentClient()?.error(name, error)
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
