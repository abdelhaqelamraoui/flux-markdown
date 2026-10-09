import Foundation

struct SearchWindowPlacement: Equatable {
    struct Screen { let id: UInt32; let visibleFrame: CGRect }
    let frame: CGRect
    let displayID: UInt32
    init?(frame: CGRect, displayID: UInt32) {
        guard displayID > 0, !frame.isNull, !frame.isInfinite,
              [frame.origin.x, frame.origin.y, frame.size.width, frame.size.height].allSatisfy({ $0.isFinite }),
              abs(frame.minX) <= 100_000, abs(frame.minY) <= 100_000,
              frame.size.width > 0, frame.size.height > 0, frame.size.width <= 20_000, frame.size.height <= 20_000 else { return nil }
        self.frame = frame; self.displayID = displayID
    }
    var queryItems: [URLQueryItem] {
        [URLQueryItem(name: "frame", value: [frame.origin.x, frame.origin.y, frame.width, frame.height].map { String(Double($0)) }.joined(separator: ",")),
         URLQueryItem(name: "screen", value: String(displayID))]
    }
    static func decode(_ items: [URLQueryItem]) -> SearchWindowPlacement? {
        let frames = items.filter { $0.name == "frame" }, screens = items.filter { $0.name == "screen" }
        guard frames.count == 1, screens.count == 1, let text = frames[0].value,
              let screen = screens[0].value, let id = UInt32(screen) else { return nil }
        let parts = text.split(separator: ",", omittingEmptySubsequences: false)
        let values = parts.compactMap { Double($0) }
        guard parts.count == 4, values.count == 4 else { return nil }
        return SearchWindowPlacement(frame: CGRect(x: values[0], y: values[1], width: values[2], height: values[3]), displayID: id)
    }
    func fittedFrame(screens: [Screen]) -> CGRect? {
        let usable = screens.filter { !$0.visibleFrame.isNull && !$0.visibleFrame.isInfinite && $0.visibleFrame.width >= 320 && $0.visibleFrame.height >= 200 }
        guard !usable.isEmpty else { return nil }
        func area(_ screen: Screen) -> CGFloat {
            let intersection = frame.intersection(screen.visibleFrame)
            return intersection.isNull ? 0 : intersection.width * intersection.height
        }
        func distance(_ screen: Screen) -> CGFloat {
            let dx = frame.midX - screen.visibleFrame.midX, dy = frame.midY - screen.visibleFrame.midY
            return dx * dx + dy * dy
        }
        let target = usable.first(where: { $0.id == displayID }) ?? usable.sorted {
            area($0) == area($1) ? distance($0) < distance($1) : area($0) > area($1)
        }[0]
        let visible = target.visibleFrame
        let width = min(max(frame.width, 320), visible.width), height = min(max(frame.height, 200), visible.height)
        return CGRect(x: min(max(frame.minX, visible.minX), visible.maxX - width),
                      y: min(max(frame.minY, visible.minY), visible.maxY - height), width: width, height: height)
    }
}

final class DocumentWindowPlacementStore {
    static let shared = DocumentWindowPlacementStore()
    private let lock = NSLock()
    private var items: [String: (UUID, SearchWindowPlacement)] = [:]
    private var order: [String] = []
    private func key(_ url: URL) -> String { url.standardizedFileURL.resolvingSymlinksInPath().path }
    @discardableResult func set(_ placement: SearchWindowPlacement, for url: URL) -> UUID {
        lock.lock(); defer { lock.unlock() }
        let path = key(url), id = UUID()
        items[path] = (id, placement); order.removeAll { $0 == path }; order.append(path)
        while order.count > 100 { items.removeValue(forKey: order.removeFirst()) }
        return id
    }
    func consume(for url: URL) -> SearchWindowPlacement? {
        lock.lock(); defer { lock.unlock() }
        let path = key(url); order.removeAll { $0 == path }
        return items.removeValue(forKey: path)?.1
    }
    func discard(for url: URL, id: UUID) {
        lock.lock(); defer { lock.unlock() }
        let path = key(url)
        guard items[path]?.0 == id else { return }
        items.removeValue(forKey: path); order.removeAll { $0 == path }
    }
}
