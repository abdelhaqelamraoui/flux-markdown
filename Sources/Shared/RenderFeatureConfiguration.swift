/// The theme-only fast path is valid only when all parser/style inputs agree.
struct RenderFeatureConfiguration: Equatable {
    var fontSize: Double
    var mermaid: Bool
    var katex: Bool
    var emoji: Bool
    var typst: Bool
    var codeTheme: String
}
