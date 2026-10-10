import Foundation

final class RenderVersionCounter {
    private var version: Int = 0

    func isCurrent(_ candidate: Int) -> Bool { candidate == version }

    @discardableResult
    func next() -> Int {
        version += 1
        return version
    }
}
