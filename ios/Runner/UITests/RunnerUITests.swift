import XCTest

/// Drives the app and captures App Store screenshots via `fastlane snapshot`.
///
/// The app launches directly into the viewer screen. Each `snapshot("name")`
/// call writes a PNG into fastlane/screenshots/<language>/<device>/.
final class RunnerUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    // setupSnapshot()/snapshot() are @MainActor-isolated in modern
    // SnapshotHelper, so the test runs on the main actor.
    @MainActor
    func testCaptureScreenshots() throws {
        let app = XCUIApplication()
        setupSnapshot(app)
        app.launch()

        // Flutter renders to a single canvas and does not expose native
        // accessibility identifiers to XCUITest by default, so we capture after
        // a short settle delay rather than waiting on a specific element.
        sleep(8)
        snapshot("01_viewer")
    }
}
