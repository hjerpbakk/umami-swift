import XCTest
@testable import Umami

final class EventQueueTests: XCTestCase {
    private func tempFile() -> URL {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("umami-queue-\(UUID().uuidString).json")
    }

    func testAppendAndPeek() {
        let q = EventQueue(fileURL: tempFile(), maxSize: 10)
        q.append(Event(name: "a", data: [:]))
        q.append(Event(name: "b", data: [:]))
        XCTAssertEqual(q.count, 2)
        XCTAssertEqual(q.peekBatch(1).map(\.name), ["a"])
    }

    func testDropsOldestBeyondMax() {
        let q = EventQueue(fileURL: tempFile(), maxSize: 2)
        q.append(Event(name: "a", data: [:]))
        q.append(Event(name: "b", data: [:]))
        q.append(Event(name: "c", data: [:]))
        XCTAssertEqual(q.count, 2)
        XCTAssertEqual(q.peekBatch(2).map(\.name), ["b", "c"])
    }

    func testPersistsAcrossReload() {
        let url = tempFile()
        let q1 = EventQueue(fileURL: url, maxSize: 10)
        q1.append(Event(name: "kept", data: ["level": 1]))
        let q2 = EventQueue(fileURL: url, maxSize: 10)
        XCTAssertEqual(q2.peekBatch(10).map(\.name), ["kept"])
    }

    func testRemoveByIdentityLeavesUnsentEvents() {
        let q = EventQueue(fileURL: tempFile(), maxSize: 10)
        q.append(Event(name: "a", data: [:]))
        q.append(Event(name: "b", data: [:]))
        q.append(Event(name: "c", data: [:]))
        q.append(Event(name: "d", data: [:]))

        // Simulate an in-flight batch: capture the front two events before more appends happen.
        let sent = q.peekBatch(2)
        XCTAssertEqual(sent.map(\.name), ["a", "b"])

        // More events arrive while the upload is in flight.
        q.append(Event(name: "e", data: [:]))

        q.remove(sent)

        // The sent events are gone; everything else (including events appended
        // after the batch was captured) survives.
        XCTAssertEqual(q.peekBatch(10).map(\.name), ["c", "d", "e"])
    }

    func testRemoveByIdentitySurvivesFrontEvictionAtMaxSize() {
        let q = EventQueue(fileURL: tempFile(), maxSize: 3)
        q.append(Event(name: "a", data: [:]))
        q.append(Event(name: "b", data: [:]))
        q.append(Event(name: "c", data: [:]))

        // Capture the front batch as "in flight".
        let sent = q.peekBatch(2)
        XCTAssertEqual(sent.map(\.name), ["a", "b"])

        // While the upload is in flight, more events arrive and evict "a" from the front
        // because the queue is at maxSize.
        q.append(Event(name: "d", data: [:]))
        q.append(Event(name: "e", data: [:]))
        XCTAssertEqual(q.peekBatch(10).map(\.name), ["c", "d", "e"])

        // Removing the sent batch by identity must not resurrect or miscount:
        // "a" was already evicted (never delivered as far as the queue is concerned,
        // but it also can't be double-removed), "b" was truly sent and must go.
        q.remove(sent)
        XCTAssertEqual(q.peekBatch(10).map(\.name), ["c", "d", "e"])
    }

    func testLoadEnforcesMaxSize() {
        let url = tempFile()
        let q1 = EventQueue(fileURL: url, maxSize: 10)
        q1.append(Event(name: "1", data: [:]))
        q1.append(Event(name: "2", data: [:]))
        q1.append(Event(name: "3", data: [:]))
        q1.append(Event(name: "4", data: [:]))
        q1.append(Event(name: "5", data: [:]))

        let q2 = EventQueue(fileURL: url, maxSize: 2)
        XCTAssertEqual(q2.count, 2)
        XCTAssertEqual(q2.peekBatch(2).map(\.name), ["4", "5"])
    }
}
