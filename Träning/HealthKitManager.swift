import HealthKit

struct HealthKitManager {
    static let shared = HealthKitManager()
    private let store = HKHealthStore()

    private var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestAuthorization() async {
        guard isAvailable else { return }
        var shareTypes: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType(.activeEnergyBurned),
            HKQuantityType(.distanceCycling),
            HKQuantityType(.distanceWalkingRunning)
        ]
        if #available(iOS 18.0, *) {
            shareTypes.insert(HKQuantityType(.workoutEffortScore))
        }
        let readTypes: Set<HKObjectType> = [HKQuantityType(.bodyMass)]
        try? await store.requestAuthorization(toShare: shareTypes, read: readTypes)
    }

    func saveCardioWorkout(start: Date, end: Date, type: CardioType, distanceKm: Double?) async -> UUID? {
        guard isAvailable else { return nil }
        let config = HKWorkoutConfiguration()
        var met = 0.0
        switch type {
        case .crosstrainer: config.activityType = .elliptical; met = 7.0
        case .cykel:        config.activityType = .cycling;    met = 8.0
        case .roddmaskin:   config.activityType = .rowing;     met = 7.5
        }
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        try? await builder.beginCollection(at: start)
        await addCalories(to: builder, met: met, start: start, end: end)
        if let km = distanceKm, km > 0 {
            await addDistance(to: builder, km: km, cardioType: type, start: start, end: end)
        }
        try? await builder.endCollection(at: end)
        guard let workout = try? await builder.finishWorkout() else { return nil }
        return workout.uuid
    }

    func saveWorkout(start: Date, end: Date, effortScore: Int? = nil) async -> UUID? {
        guard isAvailable else { return nil }
        let config = HKWorkoutConfiguration()
        config.activityType = .traditionalStrengthTraining
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        try? await builder.beginCollection(at: start)
        await addCalories(to: builder, met: 5.5, start: start, end: end)
        try? await builder.endCollection(at: end)
        guard let workout = try? await builder.finishWorkout() else { return nil }
        if #available(iOS 18.0, *), let score = effortScore {
            await attachEffortScore(score, to: workout, start: start, end: end)
        }
        return workout.uuid
    }

    func deleteWorkout(uuid: UUID) async {
        guard isAvailable else { return }
        let predicate = HKQuery.predicateForObject(with: uuid)
        _ = try? await store.deleteObjects(of: .workoutType(), predicate: predicate)
    }

    private func fetchBodyMass() async -> Double? {
        guard isAvailable else { return nil }
        let type = HKQuantityType(.bodyMass)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                let kg = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: .gramUnit(with: .kilo))
                continuation.resume(returning: kg)
            }
            store.execute(query)
        }
    }

    private func addCalories(to builder: HKWorkoutBuilder, met: Double, start: Date, end: Date) async {
        let bodyMass = await fetchBodyMass() ?? 75.0
        let hours = end.timeIntervalSince(start) / 3600
        let kcal = met * bodyMass * hours
        guard kcal > 0 else { return }
        let type = HKQuantityType(.activeEnergyBurned)
        let quantity = HKQuantity(unit: .kilocalorie(), doubleValue: kcal)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: start, end: end)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            builder.add([sample]) { _, _ in cont.resume() }
        }
    }

    private func addDistance(to builder: HKWorkoutBuilder, km: Double, cardioType: CardioType, start: Date, end: Date) async {
        let identifier: HKQuantityTypeIdentifier
        switch cardioType {
        case .cykel:        identifier = .distanceCycling
        case .crosstrainer: identifier = .distanceWalkingRunning
        case .roddmaskin:   return
        }
        let type = HKQuantityType(identifier)
        let quantity = HKQuantity(unit: .meter(), doubleValue: km * 1000)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: start, end: end)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            builder.add([sample]) { _, _ in cont.resume() }
        }
    }

    @available(iOS 18.0, *)
    private func attachEffortScore(_ score: Int, to workout: HKWorkout, start: Date, end: Date) async {
        let type = HKQuantityType(.workoutEffortScore)
        let quantity = HKQuantity(unit: .appleEffortScore(), doubleValue: Double(score))
        let sample = HKQuantitySample(type: type, quantity: quantity, start: start, end: end)
        _ = try? await store.relateWorkoutEffortSample(sample, with: workout, activity: nil)
    }
}
