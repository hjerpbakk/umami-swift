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
                                           device: fixtureDevice(), visitorId: "visitor-9")
        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["type"] as? String, "event")
        let p = json["payload"] as! [String: Any]
        XCTAssertEqual(p["website"] as? String, "web-123")
        XCTAssertEqual(p["hostname"] as? String, "cardgame.ios")
        XCTAssertEqual(p["id"] as? String, "visitor-9")
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
                                           device: fixtureDevice(), visitorId: "x")
        XCTAssertEqual(payload.payload.data["app_version"], .string("override"))
    }

    func testPageviewOmitsNameAndCarriesPathAndTitle() throws {
        let event = Event(name: nil, url: "/calendar", title: "calendar", data: [:])
        let payload = PayloadBuilder.build(event: event, config: fixtureConfig(),
                                           device: fixtureDevice(), visitorId: "visitor-9")
        let data = try JSONEncoder().encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let p = json["payload"] as! [String: Any]
        XCTAssertNil(p["name"])
        XCTAssertEqual(p["url"] as? String, "/calendar")
        XCTAssertEqual(p["title"] as? String, "calendar")
    }

    // The user agent must look like a real browser: Umami's bot filter (isbot)
    // silently drops anything else with a 200, and it matches substrings, so an
    // app name like "bookscanner" flags as a scanner bot. The app never appears
    // in it; identity lives in the payload.
    func testUserAgentIsSafariStyleForIPhone() {
        let ua = PayloadBuilder.userAgent(device: fixtureDevice())
        XCTAssertEqual(ua, "Mozilla/5.0 (iPhone; CPU iPhone OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1")
    }

    func testUserAgentIsSafariStyleForIPad() {
        let device = DeviceInfo(appVersion: "1.2.0", build: "42", osName: "iOS",
                                osVersion: "18.5", deviceModel: "iPad13,1",
                                locale: "nb-NO", screen: "1640x2360")
        let ua = PayloadBuilder.userAgent(device: device)
        XCTAssertEqual(ua, "Mozilla/5.0 (iPad; CPU OS 18_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.5 Mobile/15E148 Safari/604.1")
    }

    func testUserAgentIsSafariStyleForMac() {
        let device = DeviceInfo(appVersion: "2.0", build: "7", osName: "macOS",
                                osVersion: "15.5", deviceModel: "Mac16,10",
                                locale: "en-US", screen: "3456x2234")
        let ua = PayloadBuilder.userAgent(device: device)
        XCTAssertEqual(ua, "Mozilla/5.0 (Macintosh; Intel Mac OS X 15_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.5 Safari/605.1.15")
    }

    func testUserAgentNeverContainsAppIdentity() {
        let ua = PayloadBuilder.userAgent(device: fixtureDevice())
        XCTAssertFalse(ua.contains("cardgame"))
        XCTAssertFalse(ua.contains("1.2.0"))
        XCTAssertFalse(ua.contains("iPhone16,2"))
    }
}
