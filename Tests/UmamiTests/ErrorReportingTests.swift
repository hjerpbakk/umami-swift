import XCTest
@testable import Umami

enum SampleEnumError: Error { case failed }

final class ErrorReportingTests: XCTestCase {
    private func tempFile() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("umami-error-\(UUID().uuidString).json")
    }
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "umami.error.\(UUID().uuidString)")!
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
    private func makeClient(uploader: RecordingUploader, queue: EventQueue,
                            defaults: UserDefaults? = nil) -> UmamiClient {
        UmamiClient(config: config(batchSize: 1), deviceInfo: device(),
                    visitorId: VisitorID(), queue: queue,
                    uploader: uploader, defaults: defaults ?? makeDefaults())
    }

    // MARK: ErrorMetadata

    func testMetadataForNSErrorHasExactlyTypeDomainAndCode() {
        let error = NSError(domain: "TestDomain", code: 42,
                            userInfo: [NSLocalizedDescriptionKey: "secret user content"])
        let data = ErrorMetadata.data(for: error)

        XCTAssertEqual(Set(data.keys), ["error_type", "error_domain", "error_code"])
        XCTAssertEqual(data["error_type"], .string("NSError"))
        XCTAssertEqual(data["error_domain"], .string("TestDomain"))
        XCTAssertEqual(data["error_code"], .int(42))
    }

    func testMetadataNeverContainsMessageText() {
        let error = NSError(domain: "TestDomain", code: 1,
                            userInfo: [NSLocalizedDescriptionKey: "secret user content",
                                       NSFilePathErrorKey: "/Users/someone/private.txt"])
        let data = ErrorMetadata.data(for: error)

        for value in data.values {
            if case let .string(s) = value {
                XCTAssertFalse(s.contains("secret user content"))
                XCTAssertFalse(s.contains("private.txt"))
            }
        }
    }

    func testMetadataForSwiftErrorUsesTypeName() {
        let data = ErrorMetadata.data(for: SampleEnumError.failed)

        XCTAssertEqual(data["error_type"], .string("SampleEnumError"))
        guard case let .string(domain)? = data["error_domain"] else {
            return XCTFail("missing error_domain")
        }
        XCTAssertTrue(domain.hasSuffix("SampleEnumError"))
        guard case .int? = data["error_code"] else {
            return XCTFail("missing error_code")
        }
    }

    func testMetadataForNilErrorIsEmpty() {
        XCTAssertTrue(ErrorMetadata.data(for: nil).isEmpty)
    }

    // MARK: Client

    func testErrorSendsPrefixedEventWithMetadata() {
        let uploader = RecordingUploader()
        let client = makeClient(uploader: uploader,
                                queue: EventQueue(fileURL: tempFile(), maxSize: 500))
        let exp = expectation(description: "uploaded")
        client.onUploadFinished = { _ in exp.fulfill() }
        client.error("save_failed", NSError(domain: "TestDomain", code: 7))
        wait(for: [exp], timeout: 2)

        XCTAssertEqual(uploader.captured.count, 1)
        let payload = uploader.captured[0][0]
        XCTAssertEqual(payload.payload.name, "error_save_failed")
        XCTAssertEqual(payload.payload.data["error_domain"], .string("TestDomain"))
        XCTAssertEqual(payload.payload.data["error_code"], .int(7))
        XCTAssertEqual(payload.payload.data["app_version"], .string("1.0"))
    }

    func testErrorDoesNotDoubleThePrefix() {
        let uploader = RecordingUploader()
        let client = makeClient(uploader: uploader,
                                queue: EventQueue(fileURL: tempFile(), maxSize: 500))
        let exp = expectation(description: "uploaded")
        client.onUploadFinished = { _ in exp.fulfill() }
        client.error("error_save_failed")
        wait(for: [exp], timeout: 2)

        XCTAssertEqual(uploader.captured[0][0].payload.name, "error_save_failed")
    }

    func testErrorWithoutErrorValueSendsOnlyDeviceMetadata() {
        let uploader = RecordingUploader()
        let client = makeClient(uploader: uploader,
                                queue: EventQueue(fileURL: tempFile(), maxSize: 500))
        let exp = expectation(description: "uploaded")
        client.onUploadFinished = { _ in exp.fulfill() }
        client.error("save_failed")
        wait(for: [exp], timeout: 2)

        let data = uploader.captured[0][0].payload.data
        XCTAssertEqual(Set(data.keys), ["app_version", "build", "os_version", "device_model"])
    }

    func testDisabledDropsErrorEvents() {
        let uploader = RecordingUploader()
        let queue = EventQueue(fileURL: tempFile(), maxSize: 500)
        let client = makeClient(uploader: uploader, queue: queue)
        client.setEnabled(false)
        client.error("save_failed", SampleEnumError.failed)
        client.drainForTesting()

        XCTAssertEqual(queue.count, 0)
        XCTAssertTrue(uploader.captured.isEmpty)
    }
}
