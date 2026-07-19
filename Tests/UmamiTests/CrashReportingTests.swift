import XCTest
@testable import Umami

final class CrashReportingTests: XCTestCase {
    private func tempMarker() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("umami-crash-\(UUID().uuidString)")
    }
    private func tempFile() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("umami-crashq-\(UUID().uuidString).json")
    }
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "umami.crash.\(UUID().uuidString)")!
    }
    private func config(batchSize: Int) -> Configuration {
        Configuration(websiteId: "w", host: "app.ios",
                      baseURL: URL(string: "https://x.test")!,
                      flushInterval: 3600, maxQueueSize: 500, batchSize: batchSize)
    }
    private func device() -> DeviceInfo {
        DeviceInfo(appVersion: "1.0", build: "1", osName: "iOS", osVersion: "18",
                   deviceModel: "iPhone", locale: "nb-NO", screen: "1x1")
    }

    // MARK: Marker store

    func testMarkerRoundTripAndConsumeDeletes() {
        let url = tempMarker()
        let marker = CrashMarker(kind: .signal, name: "SIGSEGV", code: 11)
        CrashMarkerStore.write(marker, to: url)

        XCTAssertEqual(CrashMarkerStore.consume(at: url), marker)
        XCTAssertNil(CrashMarkerStore.consume(at: url))
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testConsumeWithoutFileReturnsNil() {
        XCTAssertNil(CrashMarkerStore.consume(at: tempMarker()))
    }

    // MARK: Exception path

    func testExceptionHandlerWritesNameWithoutReason() {
        let url = tempMarker()
        let exception = NSException(name: .rangeException,
                                    reason: "secret user content",
                                    userInfo: ["path": "/Users/someone/private.txt"])
        CrashWatcher.handleException(exception, markerURL: url)

        let raw = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
        XCTAssertFalse(raw.contains("secret user content"))
        XCTAssertFalse(raw.contains("private.txt"))
        XCTAssertEqual(CrashMarkerStore.consume(at: url),
                       CrashMarker(kind: .exception, name: "NSRangeException", code: 0))
    }

    // MARK: Signal path (writer only; raising real signals would kill the test runner)

    func testSignalMarkerWriterWritesSignalName() {
        let url = tempMarker()
        CrashWatcher.writeSignalMarker(SIGSEGV, to: url)

        XCTAssertEqual(CrashMarkerStore.consume(at: url),
                       CrashMarker(kind: .signal, name: "SIGSEGV", code: Int(SIGSEGV)))
    }

    // MARK: Client integration

    func testStartReportsPendingCrashBeforeLaunchEvents() {
        let markerURL = tempMarker()
        CrashMarkerStore.write(CrashMarker(kind: .signal, name: "SIGSEGV", code: 11), to: markerURL)
        let uploader = RecordingUploader()
        let queue = EventQueue(fileURL: tempFile(), maxSize: 500)
        let client = UmamiClient(config: config(batchSize: 20), deviceInfo: device(),
                                 visitorId: VisitorID(), queue: queue, uploader: uploader,
                                 defaults: makeDefaults(), crashMarkerURL: markerURL)
        client.start()
        client.drainForTesting()

        let queued = queue.peekBatch(3)
        XCTAssertEqual(queued.count, 3)
        XCTAssertEqual(queued[0].name, "error_app_crashed")
        XCTAssertEqual(queued[0].data["error_type"], .string("SIGSEGV"))
        XCTAssertEqual(queued[0].data["error_domain"], .string("signal"))
        XCTAssertEqual(queued[0].data["error_code"], .int(11))
        XCTAssertFalse(FileManager.default.fileExists(atPath: markerURL.path))
    }

    func testStartWithoutMarkerSendsNoCrashEvent() {
        let uploader = RecordingUploader()
        let queue = EventQueue(fileURL: tempFile(), maxSize: 500)
        let client = UmamiClient(config: config(batchSize: 20), deviceInfo: device(),
                                 visitorId: VisitorID(), queue: queue, uploader: uploader,
                                 defaults: makeDefaults(), crashMarkerURL: tempMarker())
        client.start()
        client.drainForTesting()

        let queued = queue.peekBatch(3)
        XCTAssertEqual(queued.count, 2)
        XCTAssertNil(queued[0].name)
        XCTAssertEqual(queued[1].name, "app_started")
    }

    func testDisabledDropsPendingCrashReport() {
        let markerURL = tempMarker()
        CrashMarkerStore.write(CrashMarker(kind: .exception, name: "NSRangeException", code: 0),
                               to: markerURL)
        let uploader = RecordingUploader()
        let queue = EventQueue(fileURL: tempFile(), maxSize: 500)
        let defaults = makeDefaults()
        EnabledFlag.set(false, defaults)
        let client = UmamiClient(config: config(batchSize: 20), deviceInfo: device(),
                                 visitorId: VisitorID(), queue: queue, uploader: uploader,
                                 defaults: defaults, crashMarkerURL: markerURL)
        client.start()
        client.drainForTesting()

        XCTAssertEqual(queue.count, 0)
        XCTAssertTrue(uploader.captured.isEmpty)
    }
}
