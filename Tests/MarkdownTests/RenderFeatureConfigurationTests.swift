import XCTest

final class RenderFeatureConfigurationTests: XCTestCase {
    func testEachFeatureInvalidatesTheThemeOnlyFastPath() {
        let original = RenderFeatureConfiguration(fontSize: 14, mermaid: true, katex: true, emoji: true, typst: true, codeTheme: "default")
        let mutations: [(inout RenderFeatureConfiguration) -> Void] = [
            { $0.fontSize = 16 }, { $0.mermaid = false }, { $0.katex = false },
            { $0.emoji = false }, { $0.typst = false }, { $0.codeTheme = "dark" }
        ]
        for mutate in mutations {
            var changed = original
            mutate(&changed)
            XCTAssertNotEqual(changed, original)
        }
        XCTAssertEqual(original, original)
    }
}
