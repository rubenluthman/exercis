import XCTest
@testable import Exercis

final class SkippedTests: XCTestCase {

    func testStrengthCSVRowStructureAndE1RM() throws {
        throw XCTSkip("strengthCSV traverses SwiftData relationships via .sorted(by:) which does not fault-load in test contexts — e1RM formula is covered by EpleyFormulaTests")
    }

    func testSwiftUIRenderingAndNavigation() throws {
        throw XCTSkip("SwiftUI rendering, animations and navigation flow require UI testing (XCUITest) — out of scope for unit tests")
    }

    func testLiveActivityUpdates() throws {
        throw XCTSkip("ActivityKit requires a physical device and an active workout session — not testable in unit tests")
    }

    func testHealthKitAuthorization() throws {
        throw XCTSkip("HealthKit authorization requires a physical device and user interaction — not testable in unit tests")
    }

    func testWidgetData() throws {
        throw XCTSkip("Widget rendering and WidgetKit timeline require a physical device context — not testable in unit tests")
    }
}
