import XCTest
@testable import Exercis

final class LiveActivityColorTests: XCTestCase {

    func testAllProgramColorNamesResolve() {
        for pc in ProgramColor.allCases {
            let hex = pc.darkHex
            XCTAssertFalse(hex.isEmpty, "\(pc.rawValue) returned empty hex")
            XCTAssertEqual(hex.count, 6, "\(pc.rawValue) hex should be 6 chars, got \(hex)")
        }
    }

    func testKnownColorHexValues() {
        XCTAssertEqual(ProgramColor.intenseRed.darkHex, "F97775")
        XCTAssertEqual(ProgramColor.green.darkHex,      "63BD5C")
        XCTAssertEqual(ProgramColor.lightBlue.darkHex,  "00B3F7")
    }

    func testUnknownColorNameReturnsFallback() {
        // hexForColorName is private; test via ProgramColor init
        let result = ProgramColor(rawValue: "nonexistent")
        XCTAssertNil(result, "Unknown color name should not produce a ProgramColor")
    }

    func testAllSeederColorNamesAreValidProgramColors() {
        let seederColors = [
            "paletteIntenseRed", "paletteOrange", "paletteYellow",
            "paletteLime", "paletteGreen", "paletteTeal", "paletteCyan"
        ]
        for name in seederColors {
            XCTAssertNotNil(ProgramColor(rawValue: name), "\(name) used in seeder is not a valid ProgramColor")
        }
    }
}
