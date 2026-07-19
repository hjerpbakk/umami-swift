import Foundation

/// Last-resort handlers for uncaught exceptions and fatal signals. A crash
/// writes a `CrashMarker` (the exception or signal name, nothing else) that
/// the next launch reports as an `error_app_crashed` event. Reporting from a
/// crashing process is unreliable, so the marker-then-report-next-launch
/// split is deliberate. Previously installed handlers are chained, and the
/// signal is re-raised with the default handler so the system crash reporter
/// still runs.
enum CrashWatcher {
    nonisolated(unsafe) private static var markerURL: URL?
    nonisolated(unsafe) private static var previousExceptionHandler: (@convention(c) (NSException) -> Void)?
    nonisolated(unsafe) private static var installed = false
    /// Pre-baked path and content bytes per signal, so the signal handler
    /// does no allocation: just open/write/close, which are async-signal-safe.
    nonisolated(unsafe) private static var signalPayloads: [(sig: Int32, path: [CChar], content: [CChar])] = []

    private static let watchedSignals: [Int32] = [SIGABRT, SIGILL, SIGSEGV, SIGFPE, SIGBUS, SIGTRAP]

    static func install(markerURL url: URL) {
        guard !installed else { return }
        installed = true
        markerURL = url
        signalPayloads = watchedSignals.map { sig in
            (sig, Array(url.path.utf8CString),
             Array("signal:\(signalName(sig)):\(sig)".utf8CString))
        }
        previousExceptionHandler = NSGetUncaughtExceptionHandler()
        NSSetUncaughtExceptionHandler { exception in
            CrashWatcher.uncaughtException(exception)
        }
        for sig in watchedSignals {
            signal(sig) { sig in CrashWatcher.fatalSignal(sig) }
        }
    }

    private static func uncaughtException(_ exception: NSException) {
        if let url = markerURL {
            handleException(exception, markerURL: url)
        }
        previousExceptionHandler?(exception)
    }

    /// Writes the exception marker. Only the exception name is recorded;
    /// `reason` and `userInfo` can carry user content and are never read.
    static func handleException(_ exception: NSException, markerURL: URL) {
        let name = sanitized(exception.name.rawValue)
        CrashMarkerStore.write(CrashMarker(kind: .exception, name: name, code: 0), to: markerURL)
    }

    private static func fatalSignal(_ sig: Int32) {
        for payload in signalPayloads where payload.sig == sig {
            writeRaw(path: payload.path, content: payload.content)
        }
        signal(sig, SIG_DFL)
        raise(sig)
    }

    /// Test seam: the same raw write path the signal handler uses.
    static func writeSignalMarker(_ sig: Int32, to url: URL) {
        writeRaw(path: Array(url.path.utf8CString),
                 content: Array("signal:\(signalName(sig)):\(sig)".utf8CString))
    }

    private static func writeRaw(path: [CChar], content: [CChar]) {
        let fd = open(path, O_WRONLY | O_CREAT | O_TRUNC, 0o644)
        guard fd >= 0 else { return }
        content.withUnsafeBufferPointer { buffer in
            // utf8CString includes a trailing NUL; don't write it.
            if let base = buffer.baseAddress, buffer.count > 1 {
                _ = write(fd, base, buffer.count - 1)
            }
        }
        close(fd)
    }

    static func signalName(_ sig: Int32) -> String {
        switch sig {
        case SIGABRT: return "SIGABRT"
        case SIGILL: return "SIGILL"
        case SIGSEGV: return "SIGSEGV"
        case SIGFPE: return "SIGFPE"
        case SIGBUS: return "SIGBUS"
        case SIGTRAP: return "SIGTRAP"
        default: return "SIG\(sig)"
        }
    }

    /// Keeps the single-line marker format parseable whatever the name is.
    private static func sanitized(_ name: String) -> String {
        name.replacingOccurrences(of: ":", with: "_")
            .replacingOccurrences(of: "\n", with: "_")
    }
}
