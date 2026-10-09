import AppKit
import ApplicationServices
import Foundation
import Security

// Development-only, read-only probe. Never creates an event tap, requests trust,
// performs an AX action, or registers persistence. It is not embedded in the app.
func report(_ values: [String: Any], exitCode: Int32) -> Never {
    var output = values
    output["mode"] = "read-only-probe"
    output["interceptionEnabled"] = false
    if let data = try? JSONSerialization.data(withJSONObject: output, options: [.sortedKeys]) {
        FileHandle.standardOutput.write(data)
        FileHandle.standardOutput.write(Data("\n".utf8))
    }
    exit(exitCode)
}

let trusted = AXIsProcessTrusted()
let args = CommandLine.arguments
if !args.contains("--probe") {
    report(["permissionGranted": trusted, "status": "permission-status"], exitCode: 0)
}
guard trusted else {
    report(["permissionGranted": false, "status": "permission-required"], exitCode: 3)
}
guard let appIndex = args.firstIndex(of: "--app"), args.indices.contains(appIndex + 1),
      args[appIndex + 1].hasPrefix("/") else {
    report(["status": "absolute-app-path-required"], exitCode: 2)
}
let appURL = URL(fileURLWithPath: args[appIndex + 1]).standardizedFileURL.resolvingSymlinksInPath()
guard Bundle(url: appURL)?.bundleIdentifier == "com.xykong.Markdown" else {
    report(["status": "invalid-app"], exitCode: 2)
}
let expectedExecutable = appURL.appendingPathComponent("Contents/PlugIns/MarkdownPreview.appex/Contents/MacOS/MarkdownPreview")
    .standardizedFileURL.resolvingSymlinksInPath()

func attribute(_ element: AXUIElement, _ name: CFString) -> CFTypeRef? {
    var result: CFTypeRef?
    return AXUIElementCopyAttributeValue(element, name, &result) == .success ? result : nil
}

func authenticatedProcess(_ pid: pid_t) -> (valid: Bool, identifier: String, expected: Bool) {
    var code: SecCode?
    let attributes = [kSecGuestAttributePid as String: NSNumber(value: pid)] as CFDictionary
    guard SecCodeCopyGuestWithAttributes(nil, attributes, SecCSFlags(rawValue: 0), &code) == errSecSuccess,
          let code,
          SecCodeCheckValidity(code, SecCSFlags(rawValue: kSecCSStrictValidate), nil) == errSecSuccess else {
        return (false, "", false)
    }
    var staticCode: SecStaticCode?
    guard SecCodeCopyStaticCode(code, SecCSFlags(rawValue: 0), &staticCode) == errSecSuccess,
          let staticCode else { return (false, "", false) }
    var info: CFDictionary?
    guard SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
          let dictionary = info as? [String: Any] else { return (false, "", false) }
    let identifier = dictionary[kSecCodeInfoIdentifier as String] as? String ?? ""
    let executable = (dictionary[kSecCodeInfoMainExecutable as String] as? URL)?
        .standardizedFileURL.resolvingSymlinksInPath()
    return (true, identifier, executable == expectedExecutable)
}

// Allow a developer to switch back to Finder after starting the command. No
// window is activated by this probe, and waiting is explicitly bounded.
var waitSeconds = 0.0
if let index = args.firstIndex(of: "--wait-seconds"), args.indices.contains(index + 1),
   let value = Double(args[index + 1]), value.isFinite {
    waitSeconds = min(15, max(0, value))
}
let waitDeadline = Date().addingTimeInterval(waitSeconds)
while NSWorkspace.shared.frontmostApplication?.bundleIdentifier != "com.apple.finder", Date() < waitDeadline {
    RunLoop.current.run(until: Date().addingTimeInterval(0.05))
}
guard let finder = NSWorkspace.shared.frontmostApplication, finder.bundleIdentifier == "com.apple.finder" else {
    report(["permissionGranted": true, "finderFrontmost": false, "status": "finder-not-frontmost"], exitCode: 4)
}
let finderAX = AXUIElementCreateApplication(finder.processIdentifier)
AXUIElementSetMessagingTimeout(finderAX, 0.1)
guard let rawWindow = attribute(finderAX, kAXFocusedWindowAttribute as CFString),
      CFGetTypeID(rawWindow) == AXUIElementGetTypeID() else {
    report(["permissionGranted": true, "finderFrontmost": true, "focusedWindow": false,
            "status": "no-focused-window"], exitCode: 4)
}
let window = unsafeBitCast(rawWindow, to: AXUIElement.self)
var queue: [(AXUIElement, Int)] = [(window, 0)]
var visited = 0, candidates = 0, authenticated = 0, hostOwned = 0
let deadline = Date().addingTimeInterval(1)
while visited < queue.count, visited < 256, Date() < deadline {
    let (element, depth) = queue[visited]
    visited += 1
    AXUIElementSetMessagingTimeout(element, 0.1)
    let role = attribute(element, kAXRoleAttribute as CFString) as? String ?? ""
    let identifier = attribute(element, kAXIdentifierAttribute as CFString) as? String ?? ""
    if QuickLookShortcutIdentity.viewID(from: identifier) != nil {
        candidates += 1
        var actions: CFArray?
        let hasPress = AXUIElementCopyActionNames(element, &actions) == .success
            && (actions as? [String] ?? []).contains(kAXPressAction as String)
        var pid: pid_t = 0
        if AXUIElementGetPid(element, &pid) == .success {
            if pid == finder.processIdentifier { hostOwned += 1 }
            let signature = authenticatedProcess(pid)
            let evidence = QuickLookShortcutEvidence(permissionGranted: trusted,
                finderFrontmost: true, focusedWindow: true, identifier: identifier,
                buttonRole: role == (kAXButtonRole as String), pressAction: hasPress,
                extensionSignatureValid: signature.valid, extensionIdentifier: signature.identifier,
                expectedExecutable: signature.expected)
            if QuickLookShortcutIdentity.isEligible(evidence) { authenticated += 1 }
        }
    }
    if depth < 10, let children = attribute(element, kAXChildrenAttribute as CFString) as? [AXUIElement] {
        queue.append(contentsOf: children.prefix(max(0, 256 - queue.count)).map { ($0, depth + 1) })
    }
}
report(["permissionGranted": true, "finderFrontmost": true, "focusedWindow": true,
        "visitedNodes": visited, "candidateCount": candidates, "hostOwnedCandidateCount": hostOwned,
        "authenticatedCandidateCount": authenticated,
        "status": authenticated == 1 ? "verified-target" : "target-not-verified"],
       exitCode: authenticated == 1 ? 0 : 4)
