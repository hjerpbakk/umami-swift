import Foundation
import os
#if os(watchOS)
import WatchKit
#elseif canImport(UIKit)
import UIKit
#endif

final class UmamiClient {
    private let config: Configuration
    private let deviceInfo: DeviceInfo
    private let visitorId: VisitorID
    private let queue: EventQueue
    private let uploader: EventUploader
    private let defaults: UserDefaults
    private let work = DispatchQueue(label: "com.hjerpbakk.umami")
    private let log = Logger(subsystem: "com.hjerpbakk.umami", category: "client")

    private var timer: DispatchSourceTimer?
    private var flushing = false
    private var consecutiveFailures = 0
    private var nextAttempt = Date.distantPast

    // Test hooks (internal).
    var onUploadFinished: ((Bool) -> Void)?
    func drainForTesting() { work.sync {} }

    init(config: Configuration, deviceInfo: DeviceInfo, visitorId: VisitorID,
         queue: EventQueue, uploader: EventUploader, defaults: UserDefaults) {
        self.config = config
        self.deviceInfo = deviceInfo
        self.visitorId = visitorId
        self.queue = queue
        self.uploader = uploader
        self.defaults = defaults
    }

    var isEnabled: Bool { EnabledFlag.get(defaults) }

    func setEnabled(_ enabled: Bool) { EnabledFlag.set(enabled, defaults) }

    func start() {
        startTimer()
        observeLifecycle()
        screen("/")
        track("app_started")
    }

    func track(_ name: String, _ data: [String: AnalyticsValue] = [:]) {
        enqueue(Event(name: name, data: data))
    }

    /// Reports a handled error as a custom event named `error_<name>`,
    /// carrying only the error's type, domain, and code.
    func error(_ name: String, _ error: (any Error)? = nil) {
        let prefixed = name.hasPrefix("error_") ? name : "error_" + name
        enqueue(Event(name: prefixed, data: ErrorMetadata.data(for: error)))
    }

    /// Records a screen view as a pageview (a payload without an event name),
    /// which is what the dashboard's Overview tab counts.
    func screen(_ name: String, _ data: [String: AnalyticsValue] = [:]) {
        let path = name.hasPrefix("/") ? name : "/" + name
        let title = path == "/" ? nil : String(path.dropFirst())
        enqueue(Event(name: nil, url: path, title: title, data: data))
    }

    private func enqueue(_ event: Event) {
        guard isEnabled else { return }
        work.async {
            self.queue.append(event)
            if self.queue.count >= self.config.batchSize {
                self.flushLocked()
            }
        }
    }

    func flush() {
        work.async { self.flushLocked() }
    }

    // Must be called on `work`.
    private func flushLocked() {
        guard isEnabled, !flushing, queue.count > 0, Date() >= nextAttempt else { return }
        let batch = queue.peekBatch(config.batchSize)
        guard !batch.isEmpty else { return }
        let visitor = visitorId.current()
        let payloads = batch.map {
            PayloadBuilder.build(event: $0, config: config, device: deviceInfo, visitorId: visitor)
        }
        let userAgent = PayloadBuilder.userAgent(config: config, device: deviceInfo)
        flushing = true
        uploader.send(payloads, to: config.baseURL, userAgent: userAgent) { [weak self] success in
            guard let self else { return }
            self.work.async {
                self.flushing = false
                if success {
                    self.queue.remove(batch)
                    self.consecutiveFailures = 0
                    self.nextAttempt = .distantPast
                    self.onUploadFinished?(true)
                    if self.queue.count > 0 { self.flushLocked() }
                } else {
                    self.consecutiveFailures += 1
                    self.nextAttempt = Date().addingTimeInterval(
                        Backoff.delay(failures: self.consecutiveFailures))
                    self.log.debug("umami: batch upload failed, will retry (\(self.consecutiveFailures) consecutive failures)")
                    self.onUploadFinished?(false)
                }
            }
        }
    }

    private func startTimer() {
        let t = DispatchSource.makeTimerSource(queue: work)
        t.schedule(deadline: .now() + config.flushInterval, repeating: config.flushInterval)
        t.setEventHandler { [weak self] in self?.flushLocked() }
        t.resume()
        timer = t
    }

    private func observeLifecycle() {
        #if os(watchOS)
        let nc = NotificationCenter.default
        nc.addObserver(forName: WKApplication.didEnterBackgroundNotification,
                       object: nil, queue: nil) { [weak self] _ in self?.flush() }
        nc.addObserver(forName: WKApplication.willEnterForegroundNotification,
                       object: nil, queue: nil) { [weak self] _ in
            self?.screen("/")
            self?.track("app_started")
        }
        #elseif canImport(UIKit)
        let nc = NotificationCenter.default
        nc.addObserver(forName: UIApplication.didEnterBackgroundNotification,
                       object: nil, queue: nil) { [weak self] _ in self?.flush() }
        nc.addObserver(forName: UIApplication.willEnterForegroundNotification,
                       object: nil, queue: nil) { [weak self] _ in
            self?.screen("/")
            self?.track("app_started")
        }
        #endif
    }
}
