import AppKit

let applicationLanguagesBeforeBootstrap = DiagnosticEnvironment.applicationLanguages()

// Install the runtime localization swizzle and apply the persisted language
// preference before any view, menu or scene is built.
LocalizationManager.bootstrap(initialPreference: AppearancePreference.shared.uiLanguage)

if CommandLine.arguments.contains("--export-pdf") {
    let delegate = CLIAppDelegate()
    let app = NSApplication.shared
    app.delegate = delegate
    app.setActivationPolicy(.accessory)
    app.run()
} else {
    let preference = AppearancePreference.shared
    var environment = DiagnosticEnvironment.current()
    environment["applicationLanguagesBeforeBootstrap"] = applicationLanguagesBeforeBootstrap
    preference.history?.startSession(settings: preference.diagnosticSettings, environment: environment)
    MarkdownApp.main()
}
