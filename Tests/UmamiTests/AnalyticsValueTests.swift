import XCTest
@testable import Umami

final class AnalyticsValueTests: XCTestCase {
    func testLiteralsAndEncoding() throws {
        let values: [String: AnalyticsValue] = ["level": 7, "score": 1.5, "won": true, "mode": "hard"]
        let data = try JSONEncoder().encode(values)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        XCTAssertEqual(json["level"] as? Int, 7)
        XCTAssertEqual(json["score"] as? Double, 1.5)
        XCTAssertEqual(json["won"] as? Bool, true)
        XCTAssertEqual(json["mode"] as? String, "hard")
    }

    func testCodableRoundTrip() throws {
        let original: [String: AnalyticsValue] = ["a": 1, "b": "x", "c": true, "d": 2.5]
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode([String: AnalyticsValue].self, from: data)
        XCTAssertEqual(original, decoded)
    }
}
