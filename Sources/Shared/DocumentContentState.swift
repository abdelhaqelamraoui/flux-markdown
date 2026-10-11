import Foundation

/// File watching can receive new bytes before SwiftUI updates its FileDocument.
/// Keep those bytes for presentation-only updates until the model actually changes.
struct DocumentContentState {
    private var fileURL: URL?
    private var modelText: String?
    private var diskText: String?

    mutating func resolve(modelText: String, fileURL: URL?) -> String {
        if self.fileURL != fileURL || self.modelText != modelText {
            diskText = nil
        }
        self.fileURL = fileURL
        self.modelText = modelText
        return diskText ?? modelText
    }

    mutating func receivedDiskText(_ text: String, for fileURL: URL) {
        guard self.fileURL == fileURL else { return }
        diskText = text
    }
}
