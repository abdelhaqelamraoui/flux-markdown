import XCTest

final class ReadingToolbarLayoutTests: XCTestCase {
    func testDirectoryReservationAndScaling() {
        XCTAssertEqual(ReadingToolbarLayout.trailingInset(body: ["rightInset": 68.0], zoom: 1), 80)
        XCTAssertEqual(ReadingToolbarLayout.trailingInset(body: ["rightInset": 68.0], zoom: 2), 148)
    }
    func testNoRightDirectoryRestoresNativeMargin() {
        XCTAssertEqual(ReadingToolbarLayout.trailingInset(body: ["rightInset": 0.0], zoom: 1), 10)
    }
    func testMalformedMetricsCannotMoveNativeControlsOffscreen() {
        for value in [-1.0, Double.nan, Double.infinity, 9999.0] {
            XCTAssertEqual(ReadingToolbarLayout.trailingInset(body: ["rightInset": value], zoom: 1), 10)
        }
        XCTAssertEqual(ReadingToolbarLayout.trailingInset(body: ["rightInset": true], zoom: 1), 10)
    }
}
