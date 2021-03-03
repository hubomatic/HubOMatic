import XCTest
@testable import HubOMatic
import Sparkle

final class HubOMaticTests: XCTestCase {
    func testHubOMaticConfig() {
        XCTAssertEqual("https://github.com/hubomatic/HubOMatic/releases/latest/download/appcast.xml", HubOMatic.create(.github(org: "hubomatic", repo: "HubOMatic")).config.versionInfo.absoluteString)
        XCTAssertEqual("https://github.com/hubomatic/HubOMatic/releases/latest/download/HubOMatic.zip", HubOMatic.create(.github(org: "hubomatic", repo: "HubOMatic")).artifactURL.absoluteString)
    }

    func testSparkle() {
        XCTAssertEqual("Sparkle/1.26.0", SUUpdater.shared()?.userAgentString.split(separator: " ").last) // full agent is someting like: "xctest/17501 Sparkle/1.26.0"
    }
}
