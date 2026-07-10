import XCTest
@testable import Umami

final class InstallIDTests: XCTestCase {
    private func makeDefaults() -> UserDefaults {
        let suite = "umami.test.\(UUID().uuidString)"
        return UserDefaults(suiteName: suite)!
    }

    func testGeneratesOnceAndReuses() {
        let defaults = makeDefaults()
        let first = InstallID.get(defaults: defaults)
        let second = InstallID.get(defaults: defaults)
        XCTAssertEqual(first, second)
        XCTAssertFalse(first.isEmpty)
    }

    func testPersistsUnderExpectedKey() {
        let defaults = makeDefaults()
        let id = InstallID.get(defaults: defaults)
        XCTAssertEqual(defaults.string(forKey: "umami.installId"), id)
    }
}
