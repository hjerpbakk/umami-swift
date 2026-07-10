import XCTest
@testable import Umami

final class BackoffTests: XCTestCase {
    func testExponentialWithCap() {
        XCTAssertEqual(Backoff.delay(failures: 0, base: 2, cap: 300), 0)
        XCTAssertEqual(Backoff.delay(failures: 1, base: 2, cap: 300), 2)
        XCTAssertEqual(Backoff.delay(failures: 2, base: 2, cap: 300), 4)
        XCTAssertEqual(Backoff.delay(failures: 3, base: 2, cap: 300), 8)
        XCTAssertEqual(Backoff.delay(failures: 20, base: 2, cap: 300), 300)
    }
}
