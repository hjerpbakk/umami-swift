import XCTest
@testable import Umami

final class EnabledFlagTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        UserDefaults(suiteName: "umami.enabledflag.\(UUID().uuidString)")!
    }

    func testDefaultsToTrueWhenUnset() {
        let defaults = makeDefaults()
        XCTAssertTrue(EnabledFlag.get(defaults))
    }

    func testSetFalseThenGetReturnsFalse() {
        let defaults = makeDefaults()
        EnabledFlag.set(false, defaults)
        XCTAssertFalse(EnabledFlag.get(defaults))
    }

    func testSetTrueThenGetReturnsTrue() {
        let defaults = makeDefaults()
        EnabledFlag.set(false, defaults)
        EnabledFlag.set(true, defaults)
        XCTAssertTrue(EnabledFlag.get(defaults))
    }
}
