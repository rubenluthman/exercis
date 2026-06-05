import SwiftData
import Foundation
@testable import Exercis

func makeTestContainer() throws -> ModelContainer {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    return try ModelContainer(
        for: WorkoutSession.self, CardioSession.self, WorkoutProgram.self,
        configurations: config
    )
}
