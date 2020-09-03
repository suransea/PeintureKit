import XCTest
@testable import PeintureKit

final class PeintureKitTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(PeintureKit().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
