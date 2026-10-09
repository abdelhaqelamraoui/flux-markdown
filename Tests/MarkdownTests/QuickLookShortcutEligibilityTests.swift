import Foundation
import XCTest

final class QuickLookShortcutEligibilityTests: XCTestCase {
    private func valid() -> QuickLookShortcutEvidence {
        QuickLookShortcutEvidence(permissionGranted: true, finderFrontmost: true,
            focusedWindow: true, identifier: QuickLookShortcutIdentity.identifier(for: UUID()),
            buttonRole: true, pressAction: true, extensionSignatureValid: true,
            extensionIdentifier: "com.xykong.Markdown.QuickLook", expectedExecutable: true)
    }

    func testVerifiedPreviewIsEligible() {
        XCTAssertTrue(QuickLookShortcutIdentity.isEligible(valid()))
    }

    func testMarkerAloneDoesNotAuthenticateARecipient() {
        var evidence = valid()
        evidence.expectedExecutable = false
        XCTAssertFalse(QuickLookShortcutIdentity.isEligible(evidence))
        evidence = valid(); evidence.extensionSignatureValid = false
        XCTAssertFalse(QuickLookShortcutIdentity.isEligible(evidence))
        evidence = valid(); evidence.extensionIdentifier = "com.apple.finder"
        XCTAssertFalse(QuickLookShortcutIdentity.isEligible(evidence))
    }

    func testPermissionsAndRecipientMustBothMatch() {
        var evidence = valid(); evidence.permissionGranted = false
        XCTAssertFalse(QuickLookShortcutIdentity.isEligible(evidence))
        evidence = valid(); evidence.finderFrontmost = false
        XCTAssertFalse(QuickLookShortcutIdentity.isEligible(evidence))
        evidence = valid(); evidence.focusedWindow = false
        XCTAssertFalse(QuickLookShortcutIdentity.isEligible(evidence))
    }

    func testControlMustHaveAValidIdentityAndPressAction() {
        var evidence = valid(); evidence.identifier = "Markdown Preview"
        XCTAssertFalse(QuickLookShortcutIdentity.isEligible(evidence))
        evidence = valid(); evidence.identifier = QuickLookShortcutIdentity.prefix + "not-a-uuid"
        XCTAssertFalse(QuickLookShortcutIdentity.isEligible(evidence))
        evidence = valid(); evidence.buttonRole = false
        XCTAssertFalse(QuickLookShortcutIdentity.isEligible(evidence))
        evidence = valid(); evidence.pressAction = false
        XCTAssertFalse(QuickLookShortcutIdentity.isEligible(evidence))
    }
}
