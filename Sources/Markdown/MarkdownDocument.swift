import SwiftUI
import UniformTypeIdentifiers

struct MarkdownDocument: FileDocument {
    var text: String

    init(text: String = "") {
        self.text = text
    }

    static var readableContentTypes: [UTType] {
        var types: [UTType] = [.plainText]
        if let md = UTType(filenameExtension: "md") {
            types.insert(md, at: 0)
        }
        if let tsv = UTType(filenameExtension: "tsv") {
            types.append(tsv)
        }
        return types
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else { throw DocumentReadFailure(kind: .fileRead, error: CocoaError(.fileReadCorruptFile)) }
        guard data.count <= BoundedFileReader.documentLimit else { throw DocumentReadFailure(kind: .fileTooLarge, error: CocoaError(.fileReadTooLarge)) }
        guard
              let string = String(data: data, encoding: .utf8)
        else {
            throw DocumentReadFailure(kind: .fileRead, error: CocoaError(.fileReadCorruptFile))
        }
        text = string
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = text.data(using: .utf8)!
        return FileWrapper(regularFileWithContents: data)
    }
}
