import XCTest
@testable import Exercis

final class WeightFormattingTests: XCTestCase {

    // MARK: parseWeight

    func testParseWeightWithDot() {
        XCTAssertEqual(parseWeight("1.5"), 1.5)
    }

    func testParseWeightWithComma() {
        XCTAssertEqual(parseWeight("1,5"), 1.5)
    }

    func testParseWeightWholeNumber() {
        XCTAssertEqual(parseWeight("100"), 100.0)
    }

    func testParseWeightEmptyString() {
        XCTAssertNil(parseWeight(""))
    }

    func testParseWeightNonNumeric() {
        XCTAssertNil(parseWeight("abc"))
    }

    func testParseWeightNegative() {
        XCTAssertEqual(parseWeight("-5"), -5.0)
    }

    // MARK: formatWeight

    func testFormatWeightInteger() {
        let result = formatWeight(100.0)
        XCTAssertFalse(result.contains("."), "Should not show decimal for whole numbers")
        XCTAssertFalse(result.contains(","), "Should not show decimal for whole numbers")
    }

    func testFormatWeightDecimal() {
        let result = formatWeight(1.5)
        XCTAssertTrue(result.contains("1"), "Should contain the integer part")
        XCTAssertTrue(result.contains("5"), "Should contain the decimal part")
    }

    func testFormatWeightRoundTrip() {
        let value = 82.5
        let formatted = formatWeight(value)
        let parsed = try XCTUnwrap(parseWeight(formatted))
        XCTAssertEqual(parsed, value, accuracy: 0.001)
    }
}
