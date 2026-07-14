import XCTest
@testable import Umami

final class VisitorIDTests: XCTestCase {
    // Noon avoids flakiness around midnight and DST transitions.
    private var noon: Date {
        Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: Date())!
    }

    func testIsAUUID() {
        let visitor = VisitorID(now: noon)
        XCTAssertNotNil(UUID(uuidString: visitor.current(now: noon)))
    }

    func testStableWithinTheSameDay() {
        let visitor = VisitorID(now: noon)
        let first = visitor.current(now: noon)
        let second = visitor.current(now: noon.addingTimeInterval(1800))
        XCTAssertEqual(first, second)
    }

    func testRotatesWhenTheDayChanges() {
        let visitor = VisitorID(now: noon)
        let today = visitor.current(now: noon)
        // 26 hours is on the next calendar day even across a 25-hour DST day.
        let nextDay = noon.addingTimeInterval(26 * 3600)
        let tomorrow = visitor.current(now: nextDay)
        XCTAssertNotEqual(today, tomorrow)
        XCTAssertEqual(tomorrow, visitor.current(now: nextDay.addingTimeInterval(60)))
    }

    func testFreshInstancesGetDistinctIds() {
        XCTAssertNotEqual(VisitorID(now: noon).current(now: noon),
                          VisitorID(now: noon).current(now: noon))
    }

    func testRemoveLegacyInstallIdDeletesTheStoredKey() {
        let defaults = UserDefaults(suiteName: "umami.visitor.\(UUID().uuidString)")!
        defaults.set("ABC-123", forKey: VisitorID.legacyInstallIdKey)
        VisitorID.removeLegacyInstallId(from: defaults)
        XCTAssertNil(defaults.string(forKey: VisitorID.legacyInstallIdKey))
    }
}
