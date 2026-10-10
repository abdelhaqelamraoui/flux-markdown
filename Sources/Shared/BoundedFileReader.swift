import Foundation

/// Read at most maxBytes + 1, so a changed file cannot bypass a prior stat limit.
enum BoundedFileReader {
    static let documentLimit = 32 * 1024 * 1024
    static func read(_ url: URL, maxBytes: Int) throws -> Data {
        let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
        guard values.isRegularFile == true, (values.fileSize ?? 0) <= maxBytes else {
            throw CocoaError(.fileReadTooLarge)
        }
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        let data = try file.read(upToCount: maxBytes + 1) ?? Data()
        guard data.count <= maxBytes else { throw CocoaError(.fileReadTooLarge) }
        return data
    }
}

enum PreviewFileReader {
    struct Snapshot {
        let content: String
        let size: UInt64
        let modificationDate: Date?
    }
    static let previewLimit = 500 * 1024

    static func read(_ url: URL, limit: Int = previewLimit) throws -> Snapshot {
        let values = try url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey, .isRegularFileKey])
        guard values.isRegularFile == true else { throw CocoaError(.fileReadUnsupportedScheme) }
        let file = try FileHandle(forReadingFrom: url)
        defer { try? file.close() }
        var data = try file.read(upToCount: limit + 1) ?? Data()
        let truncated = data.count > limit
        if truncated { data = data.prefix(limit) }
        var decoded = String(data: data, encoding: .utf8)
        // A valid UTF8 character has at most four bytes. Never conceal malformed
        // bytes in the body; only recover an incomplete final character.
        if truncated && decoded == nil {
            for removed in 1...min(3, data.count) {
                let prefix = data.dropLast(removed)
                let tail = Array(data.suffix(removed))
                let lead = tail.first ?? 0
                let expected = lead >= 0xC2 && lead <= 0xDF ? 2 : lead >= 0xE0 && lead <= 0xEF ? 3 : lead >= 0xF0 && lead <= 0xF4 ? 4 : 0
                if expected > removed && tail.dropFirst().allSatisfy({ $0 >= 0x80 && $0 <= 0xBF }),
                   let text = String(data: prefix, encoding: .utf8) {
                    decoded = text
                    break
                }
            }
        }
        guard var content = decoded else { throw CocoaError(.fileReadInapplicableStringEncoding) }
        if truncated { content += "\n\n> **Preview truncated.**" }
        if url.pathExtension.lowercased() == "mmd" { content = "```mermaid\n\(content)\n```" }
        return Snapshot(content: content, size: UInt64(values.fileSize ?? data.count), modificationDate: values.contentModificationDate)
    }
}
