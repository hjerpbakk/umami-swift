import XCTest
@testable import Umami

final class CoreModelsTests: XCTestCase {
    func testEventRoundTripsThroughJSON() throws {
        let event = Event(name: "level_completed", data: ["level": 3, "won": true])
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(Event.self, from: data)
        XCTAssertEqual(event, decoded)
    }

    func testDecodesLegacyQueueEntriesWithoutUrlAndTitle() throws {
        let legacy = #"[{"id":"D5A2AE44-52A5-4C21-B4B7-2F1E56A0A4A5","name":"e","data":{}}]"#
        let decoded = try JSONDecoder().decode([Event].self, from: Data(legacy.utf8))
        XCTAssertEqual(decoded[0].name, "e")
        XCTAssertNil(decoded[0].url)
        XCTAssertNil(decoded[0].title)
    }

    func testDeviceInfoIsValueEquatable() {
        let a = DeviceInfo(appVersion: "1.0", build: "1", osName: "iOS",
                           osVersion: "18.0", deviceModel: "iPhone16,2",
                           locale: "nb-NO", screen: "1179x2556")
        let b = a
        XCTAssertEqual(a, b)
    }
}
