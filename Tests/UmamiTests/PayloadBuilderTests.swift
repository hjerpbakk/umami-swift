import XCTest
@testable import Umami

final class PayloadBuilderTests: XCTestCase {
    private func fixtureConfig() -> Configuration {
        Configuration(websiteId: "web-123", host: "cardgame.ios",
                      baseURL: URL(string: "https://example.test")!,
                      flushInterval: 15, maxQueueSize: 500, batchSize: 20)
    }
    private func fixtureDevice() -> DeviceInfo {
        DeviceInfo(appVersion: "1.2.0", build: "42", osName: "iOS",
                   osVersion: "18.5", deviceModel: "iPhone16,2",
                   locale: "nb-NO", screen: "1179x2556")
    }

    func testMapsFieldsAndInjectsMetadata() throws {
        let event = Event(name: "game_started", data: ["difficulty": "hard"])
        let payload = PayloadBuilder.build(event: event, config: fixtureConfig(),
                                           device: fixtureDevice(), installId: "install-9")
        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["type"] as? String, "event")
        let p = json["payload"] as! [String: Any]
        XCTAssertEqual(p["website"] as? String, "web-123")
        XCTAssertEqual(p["hostname"] as? String, "cardgame.ios")
        XCTAssertEqual(p["id"] as? String, "install-9")
        XCTAssertEqual(p["name"] as? String, "game_started")
        XCTAssertEqual(p["url"] as? String, "/")
        XCTAssertEqual(p["language"] as? String, "nb-NO")
        XCTAssertEqual(p["screen"] as? String, "1179x2556")
        let d = p["data"] as! [String: Any]
        XCTAssertEqual(d["app_version"] as? String, "1.2.0")
        XCTAssertEqual(d["build"] as? String, "42")
        XCTAssertEqual(d["os_version"] as? String, "18.5")
        XCTAssertEqual(d["device_model"] as? String, "iPhone16,2")
        XCTAssertEqual(d["difficulty"] as? String, "hard")
    }

    func testCallerPropertyOverridesMetadataOnCollision() {
        let event = Event(name: "e", data: ["app_version": "override"])
        let payload = PayloadBuilder.build(event: event, config: fixtureConfig(),
                                           device: fixtureDevice(), installId: "x")
        XCTAssertEqual(payload.payload.data["app_version"], .string("override"))
    }

    func testUserAgentFormat() {
        let ua = PayloadBuilder.userAgent(config: fixtureConfig(), device: fixtureDevice())
        XCTAssertEqual(ua, "cardgame.ios/1.2.0 (iPhone16,2; iOS 18.5)")
    }
}
