import XCTest
@testable import Umami

final class UploaderTests: XCTestCase {
    override func tearDown() {
        MockURLProtocol.handler = nil
        MockURLProtocol.lastRequest = nil
        MockURLProtocol.lastBody = nil
        super.tearDown()
    }

    private func samplePayload() -> UmamiPayload {
        UmamiPayload(payload: .init(website: "w", hostname: "h", id: "i",
            name: "n", title: nil, url: "/", language: "nb-NO", screen: "1x1", data: [:]))
    }

    func testPostsBatchWithHeaders() {
        MockURLProtocol.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 200,
                             httpVersion: nil, headerFields: nil)!, Data())
        }
        let uploader = NetworkUploader(session: MockURLProtocol.session())
        let exp = expectation(description: "sent")
        uploader.send([samplePayload()], to: URL(string: "https://x.test")!,
                      userAgent: "UA/1.0") { success in
            XCTAssertTrue(success)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)

        let req = MockURLProtocol.lastRequest!
        XCTAssertEqual(req.url?.absoluteString, "https://x.test/api/batch")
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(req.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertEqual(req.value(forHTTPHeaderField: "User-Agent"), "UA/1.0")

        let body = try! JSONSerialization.jsonObject(with: MockURLProtocol.lastBody!) as! [Any]
        XCTAssertEqual(body.count, 1)
    }

    func testNon2xxIsFailure() {
        MockURLProtocol.handler = { _ in
            (HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 500,
                             httpVersion: nil, headerFields: nil)!, Data())
        }
        let uploader = NetworkUploader(session: MockURLProtocol.session())
        let exp = expectation(description: "failed")
        uploader.send([samplePayload()], to: URL(string: "https://x.test")!,
                      userAgent: "UA/1.0") { success in
            XCTAssertFalse(success)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2)
    }
}
