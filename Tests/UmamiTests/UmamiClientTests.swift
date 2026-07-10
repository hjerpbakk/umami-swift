import XCTest
@testable import Umami

final class RecordingUploader: EventUploader {
    var captured: [[UmamiPayload]] = []
    var result = true
    func send(_ payloads: [UmamiPayload], to baseURL: URL, userAgent: String,
              completion: @escaping (Bool) -> Void) {
        captured.append(payloads)
        completion(result)
    }
}

final class UmamiClientTests: XCTestCase {
    private func tempFile() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("umami-client-\(UUID().uuidString).json")
    }
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "umami.client.\(UUID().uuidString)")!
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

    func testReachingBatchSizeFlushesWithMergedMetadata() {
        let uploader = RecordingUploader()
        let client = UmamiClient(config: config(batchSize: 1), deviceInfo: device(),
                                 installId: "inst", queue: EventQueue(fileURL: tempFile(), maxSize: 500),
                                 uploader: uploader, defaults: makeDefaults())
        let exp = expectation(description: "uploaded")
        client.onUploadFinished = { _ in exp.fulfill() }
        client.track("game_started", ["difficulty": "hard"])
        wait(for: [exp], timeout: 2)

        XCTAssertEqual(uploader.captured.count, 1)
        let payload = uploader.captured[0][0]
        XCTAssertEqual(payload.payload.name, "game_started")
        XCTAssertEqual(payload.payload.data["difficulty"], .string("hard"))
        XCTAssertEqual(payload.payload.data["app_version"], .string("1.0"))
    }

    func testSuccessfulSendEmptiesQueue() {
        let uploader = RecordingUploader()
        let queue = EventQueue(fileURL: tempFile(), maxSize: 500)
        let client = UmamiClient(config: config(batchSize: 1), deviceInfo: device(),
                                 installId: "i", queue: queue, uploader: uploader,
                                 defaults: makeDefaults())
        let exp = expectation(description: "done")
        client.onUploadFinished = { _ in exp.fulfill() }
        client.track("e")
        wait(for: [exp], timeout: 2)
        client.drainForTesting()
        XCTAssertEqual(queue.count, 0)
    }

    func testFailedSendKeepsQueue() {
        let uploader = RecordingUploader()
        uploader.result = false
        let queue = EventQueue(fileURL: tempFile(), maxSize: 500)
        let client = UmamiClient(config: config(batchSize: 1), deviceInfo: device(),
                                 installId: "i", queue: queue, uploader: uploader,
                                 defaults: makeDefaults())
        let exp = expectation(description: "done")
        client.onUploadFinished = { _ in exp.fulfill() }
        client.track("e")
        wait(for: [exp], timeout: 2)
        client.drainForTesting()
        XCTAssertEqual(queue.count, 1)
    }

    func testDisabledDropsEvents() {
        let uploader = RecordingUploader()
        let queue = EventQueue(fileURL: tempFile(), maxSize: 500)
        let client = UmamiClient(config: config(batchSize: 1), deviceInfo: device(),
                                 installId: "i", queue: queue, uploader: uploader,
                                 defaults: makeDefaults())
        client.setEnabled(false)
        client.track("e")
        client.drainForTesting()
        XCTAssertEqual(queue.count, 0)
        XCTAssertTrue(uploader.captured.isEmpty)
    }
}
