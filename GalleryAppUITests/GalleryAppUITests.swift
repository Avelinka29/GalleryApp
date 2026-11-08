import XCTest
import XCUIAutomation

final class GalleryAppUITests: XCTestCase {
    @MainActor
    func testTabsOpenWithoutDependingOnNetworkContent() {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let gallery = app.tabBars.buttons["Галерея"]
        let favourites = app.tabBars.buttons["Избранное"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 10))
        XCTAssertTrue(favourites.exists)
        favourites.tap()
        XCTAssertTrue(app.navigationBars["Избранное"].waitForExistence(timeout: 5))
        gallery.tap()
        XCTAssertTrue(app.navigationBars["Галерея"].waitForExistence(timeout: 5))
    }
}
