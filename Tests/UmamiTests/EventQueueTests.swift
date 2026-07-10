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

    func testRemoveFirst() {
        let q = EventQueue(fileURL: tempFile(), maxSize: 10)
        q.append(Event(name: "a", data: [:]))
        q.append(Event(name: "b", data: [:]))
        q.removeFirst(1)
        XCTAssertEqual(q.peekBatch(10).map(\.name), ["b"])
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
