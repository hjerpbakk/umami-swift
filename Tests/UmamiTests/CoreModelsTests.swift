import XCTest
@testable import Umami

final class CoreModelsTests: XCTestCase {
    func testEventRoundTripsThroughJSON() throws {
        let event = Event(name: "level_completed", data: ["level": 3, "won": true])
        let data = try JSONEncoder().encode(event)
        let decoded = try JSONDecoder().decode(Event.self, from: data)
        XCTAssertEqual(event, decoded)
    }

    func testDeviceInfoIsValueEquatable() {
        let a = DeviceInfo(appVersion: "1.0", build: "1", osName: "iOS",
                           osVersion: "18.0", deviceModel: "iPhone16,2",
                           locale: "nb-NO", screen: "1179x2556")
        let b = a
        XCTAssertEqual(a, b)
    }
}
