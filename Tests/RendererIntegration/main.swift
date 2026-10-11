import AppKit
import WebKit

let app = NSApplication.shared
app.setActivationPolicy(.prohibited)
final class RendererIntegration: NSObject, WKScriptMessageHandler {
    private var webView: WKWebView!
    private var started = false
    private var index = 0
    private let cases: [(String, String)] = [
        ("passive HTML", "await window.renderMarkdown('<img src=\"missing.png\" onerror=\"window.pwned=true\"><details><summary>ok</summary></details>'); return !document.querySelector('[onerror]') && !window.pwned && !!document.querySelector('details');"),
        ("new render wins", "const a=window.renderMarkdown('# OLD\\n\\n$x$'); const b=window.renderMarkdown('# NEW',{enableKatex:false}); await Promise.all([a,b]); return document.querySelector('h1').textContent==='NEW';"),
        ("math and emoji", "await window.renderMarkdown('$x$ :smile:'); await window.renderMarkdown(':smile:',{enableKatex:false}); return !document.getElementById('markdown-preview').textContent.includes(':smile:');"),
        ("native Typst offline", "const oldFetch=window.fetch; window.fetch=(url,...args)=>{if(/^https?:/.test(String(url))) throw new Error('Unexpected network font/package request'); return oldFetch(url,...args)}; await window.renderMarkdown('```typst\\nsum_(i=1)^n i\\n```',{context:'app'}); window.fetch=oldFetch; return !!document.querySelector('.typst-native svg use') && !document.querySelector('.typst-native style') && !document.querySelector('pre .typst-native');"),
        ("Mermaid", "await window.renderMarkdown('```mermaid\\ngraph TD; A-->B\\n```'); return !!document.querySelector('.mermaid svg') && !document.querySelector('.mermaid-error');"),
        ("Graphviz", "await window.renderMarkdown('```dot\\ndigraph { a -> b }\\n```'); const text=document.querySelector('.graphviz-diagram svg text');return text?.textContent==='a' && getComputedStyle(text).fill!=='none';"),
        ("Vega", "await window.renderMarkdown('```vega-lite\\n{\"data\":{\"values\":[{\"x\":1,\"y\":2}]},\"mark\":\"point\",\"encoding\":{\"x\":{\"field\":\"x\",\"type\":\"quantitative\"},\"y\":{\"field\":\"y\",\"type\":\"quantitative\"}}}\\n```'); return !!document.querySelector('.vega-diagram svg');"),
        ("slow export resource", "await window.renderMarkdown('# Slow'); const img=document.createElement('img'); document.getElementById('markdown-preview').append(img); Object.defineProperty(img,'complete',{value:false}); const start=performance.now(); setTimeout(()=>img.dispatchEvent(new Event('load')),3100); await window.waitForExportReady(5000); return performance.now()-start>=3000;"),
        ("local image", "await window.renderMarkdown('![Image](pixel.png)',{baseUrl:imageBase}); await window.waitForExportReady(); return document.querySelector('#markdown-preview img').naturalWidth===1;"),
        ("export ready", "await window.renderMarkdown('# Export\\n\\n$\\\\frac{a}{b}$'); await window.waitForExportReady(5000); return !!document.querySelector('.katex');"),
        ("search and refresh", "await window.renderMarkdown('# Search\\n\\nAlpha Alpha',{context:'app'});window.showSearch(); const input=document.querySelector('.search-input');input.value='Alpha';input.dispatchEvent(new Event('input',{bubbles:true}));if(!document.querySelector('.search-match-counter').textContent.includes('/2'))return false; await window.renderMarkdown('# Search\\n\\nAlpha Alpha Alpha',{context:'app'});const ok=input.value==='Alpha'&&document.querySelector('.search-match-counter').textContent.includes('/3');window.hideSearch();return ok;"),
        ("outline and positioned source", "await window.renderMarkdown('---\\ntitle: Test\\n---\\n# One\\n\\n## Two',{context:'app'});if(!document.querySelector('#toc-container a[href=\"#two\"]'))return false;if(!window.navigateDocumentPosition({line:6}))return false;window.renderSource('# One\\n\\n## Two','light');return document.getElementById('markdown-preview').classList.contains('source-mode') && window.navigateDocumentPosition({line:3});"),
        ("theme font zoom and RTL", "await window.renderMarkdown('# مرحبا بالعالم\\n\\nهذا نص عربي لاختبار اتجاه القراءة',{context:'app',theme:'dark'});window.setFontSize(18);window.setZoomLevel(1.25);const root=document.getElementById('markdown-preview');const ok=root.getAttribute('dir')==='rtl'&&document.documentElement.dataset.theme==='dark'&&root.style.fontSize==='18px';window.setZoomLevel(1);return ok;"),
        ("help controls", "window.showHelp();const open=!!document.querySelector('#help-overlay');window.hideHelp();return open;"),
        ("QuickLook Typst path", "await window.renderMarkdown('```typst\\na/b\\n```',{context:'quicklook'});return !!document.querySelector('.typst-transpiled .katex');"),
        ("export excludes application controls", "await window.renderMarkdown('# Export\\n\\n**Bold**',{context:'app',theme:'light'});const html=window.exportHTML();return html.includes('<strong>Bold</strong>')&&!html.includes('id=\"reading-controls\"')&&!html.includes('id=\"toc-container\"');"),
    ]
    func run() {
        let config = WKWebViewConfiguration()
        config.userContentController.add(self, name: "logger")
        config.setURLSchemeHandler(RendererBundleSchemeHandler(rootDirectory: URL(fileURLWithPath: CommandLine.arguments[1])), forURLScheme: RendererBundleSchemeHandler.scheme)
        let imageDirectory = URL(fileURLWithPath: CommandLine.arguments[2])
        let imageURL = imageDirectory.appendingPathComponent("pixel.png")
        try! Data(base64Encoded: "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLbtAAAAABJRU5ErkJggg==")!.write(to: imageURL)
        let images = LocalSchemeHandler()
        images.baseDirectory = imageDirectory
        images.allowedFileURLs = [imageURL]
        config.setURLSchemeHandler(images, forURLScheme: "local-md")
        webView = WKWebView(frame: CGRect(x: 0, y: 0, width: 800, height: 600), configuration: config)
        webView.load(URLRequest(url: RendererBundleSchemeHandler.rendererURL()))
        DispatchQueue.main.asyncAfter(deadline: .now() + 90) { fputs("FAIL integration timeout\n", stderr); exit(1) }
    }
    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard RendererBridgePolicy.accepts(message) else { print("FAIL bridge origin"); exit(1) }
        guard let text = message.body as? String else { return }
        if text.contains("Error") || text.contains("fallback") { print(text) }
        if text == "rendererReady" && !started { started = true; next() }
    }
    private func next() {
        if index == cases.count { print("PASS all \(cases.count) real WebKit cases"); exit(0) }
        let (name, js) = cases[index]
        webView.callAsyncJavaScript(js, arguments: ["imageBase": CommandLine.arguments[2]], in: nil, in: .page) { result in
            switch result {
            case .success(let value) where value as? Bool == true:
                print("PASS \(name)"); self.index += 1; self.next()
            default: print("FAIL \(name): \(result)"); exit(1)
            }
        }
    }
}
let integration = RendererIntegration()
integration.run()
app.run()
