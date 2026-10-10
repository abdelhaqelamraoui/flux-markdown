import Foundation
import CoreFoundation

/// Bounded transient layout data; never persisted or included in diagnostics.
enum ReadingToolbarLayout {
    static let notification = Notification.Name("FluxMarkdown.readingToolbarInset")
    static func trailingInset(body: Any, zoom: CGFloat) -> CGFloat {
        guard let payload = body as? [String: Any],
              let number = payload["rightInset"] as? NSNumber,
              CFGetTypeID(number) != CFBooleanGetTypeID(),
              number.doubleValue.isFinite, (0...240).contains(number.doubleValue),
              zoom.isFinite, (0.5...3).contains(zoom), number.doubleValue > 0 else { return 10 }
        return CGFloat(number.doubleValue) * zoom + 12
    }
}
