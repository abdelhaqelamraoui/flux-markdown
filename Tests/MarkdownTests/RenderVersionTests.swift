import XCTest

final class RenderVersionTests: XCTestCase {

    func testRenderVersionCounterIncrementsFromOne() {
        let counter = RenderVersionCounter()
        XCTAssertEqual(counter.next(), 1)
        XCTAssertEqual(counter.next(), 2)
        XCTAssertEqual(counter.next(), 3)
    }

    func testRenderVersionCounterIsMonotonicallyIncreasing() {
        let counter = RenderVersionCounter()
        var previous = counter.next()
        for _ in 0..<100 {
            let current = counter.next()
            XCTAssertGreaterThan(current, previous)
            previous = current
        }
    }
}

extension RenderVersionTests {
    func testOnlyLatestRequestCanCommit() {
        let counter = RenderVersionCounter()
        let old = counter.next()
        XCTAssertTrue(counter.isCurrent(old))
        let new = counter.next()
        XCTAssertFalse(counter.isCurrent(old))
        XCTAssertTrue(counter.isCurrent(new))
    }
}
