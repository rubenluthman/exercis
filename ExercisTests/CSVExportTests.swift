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

    private func cardioCSV(_ sessions: [CardioSession]) -> String {
        var rows = ["datum,typ,minuter,km,ansträngning"]
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withFullDate]
        for session in sessions {
            let date = fmt.string(from: session.date)
            let type_ = CardioType(rawValue: session.cardioType)?.displayName ?? session.cardioType
            let km = session.distanceKm.map { formatWeight($0) } ?? ""
            let effort = session.effortScore.map { "\($0)" } ?? ""
            rows.append("\(date),\(type_),\(formatWeight(session.durationMinutes)),\(km),\(effort)")
        }
        return rows.joined(separator: "\n")
    }

    // MARK: - Headers

    func testStrengthCSVHasCorrectHeader() {
        let rows = ["datum,program,övning,set,kg,reps,e1RM"]
        XCTAssertEqual(rows.joined(separator: "\n"), "datum,program,övning,set,kg,reps,e1RM")
    }

    func testCardioCSVHasCorrectHeader() {
        let csv = cardioCSV([])
        XCTAssertEqual(csv, "datum,typ,minuter,km,ansträngning")
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
        let dataRow = String(csv.split(separator: "\n")[1])
        let fields = dataRow.split(separator: ",", omittingEmptySubsequences: false)
        XCTAssertEqual(fields[3], "")
        XCTAssertEqual(fields[4], "")
    }
}
