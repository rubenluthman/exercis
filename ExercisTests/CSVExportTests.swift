import XCTest
import SwiftData
@testable import Exercis

@MainActor
final class CSVExportTests: XCTestCase {

    var container: ModelContainer!
    var context: ModelContext { container.mainContext }

    override func setUpWithError() throws {
        container = try makeTestContainer()
    }

    override func tearDownWithError() throws {
        container = nil
    }

    // MARK: - Headers

    func testStrengthCSVHasCorrectHeader() {
        XCTAssertEqual(strengthCSV([]).split(separator: "\n").first.map(String.init),
                       "datum,program,övning,set,kg,reps,e1RM")
    }

    func testCardioCSVHasCorrectHeader() {
        XCTAssertEqual(cardioCSV([]), "datum,typ,minuter,km,ansträngning")
    }

    // MARK: - Cardio CSV

    func testCardioCSVRowHasFiveColumns() throws {
        let session = CardioSession(date: Date(), durationMinutes: 30, cardioType: CardioType.running.rawValue)
        session.distanceKm = 5.0
        session.effortScore = 7
        context.insert(session)
        try context.save()

        let csv = cardioCSV(try context.fetch(FetchDescriptor<CardioSession>()))
        let dataRow = csv.split(separator: "\n")[1]
        XCTAssertEqual(dataRow.split(separator: ",").count, 5)
    }

    func testCardioCSVEmptyDistanceAndEffort() throws {
        let session = CardioSession(date: Date(), durationMinutes: 45, cardioType: CardioType.running.rawValue)
        context.insert(session)
        try context.save()

        let csv = cardioCSV(try context.fetch(FetchDescriptor<CardioSession>()))
        let fields = csv.split(separator: "\n")[1].split(separator: ",", omittingEmptySubsequences: false)
        XCTAssertEqual(fields[3], "")
        XCTAssertEqual(fields[4], "")
    }

    // MARK: - Strength CSV
    // Column structure and e1RM value tests are in SkippedTests — see explanation there.
}
