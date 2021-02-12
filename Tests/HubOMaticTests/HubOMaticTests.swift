import XCTest
@testable import HubOMatic
import MiscKit

final class HubOMaticTests: XCTestCase {
    func testExample() {
        XCTAssertEqual(HubOMatic().text, "Hello, World!")

        dbg("sample log")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
