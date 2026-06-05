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
            HKQuantityType(.distanceWalkingRunning),
        ]
        if #available(iOS 18.0, *) {
            shareTypes.insert(HKQuantityType(.workoutEffortScore))
        }
        let readTypes: Set<HKObjectType> = [HKQuantityType(.bodyMass)]
        try? await store.requestAuthorization(toShare: shareTypes, read: readTypes)
    }

    func saveCardioWorkout(start: Date, end: Date, type: CardioType, distanceKm: Double?, effortScore: Int? = nil, elevationGain: Double? = nil) async -> UUID? {
        guard isAvailable else { return nil }
        let config = HKWorkoutConfiguration()
        config.activityType = type.hkActivityType
        let builder = HKWorkoutBuilder(healthStore: store, configuration: config, device: .local())
        try? await builder.beginCollection(at: start)
        await addCalories(to: builder, met: type.met, start: start, end: end)
        if let km = distanceKm, km > 0 {
            await addDistance(to: builder, km: km, cardioType: type, start: start, end: end)
        }
        try? await builder.endCollection(at: end)
        if let elevation = elevationGain, elevation > 0 {
            await addElevationMetadata(to: builder, meters: elevation)
        }
        guard let workout = try? await builder.finishWorkout() else { return nil }
        if #available(iOS 18.0, *), let score = effortScore {
            await attachEffortScore(score, to: workout, start: start, end: end)
        }
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
        guard UserDefaults.standard.bool(forKey: "healthKitWeightEnabled") else { return nil }
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
        case .cyclingStationary, .roadCycling, .mountainBiking, .assaultBike:
            identifier = .distanceCycling
        case .running, .treadmillRun, .walking, .treadmillWalk,
             .hiking, .rucking, .crosstrainer, .stairClimber:
            identifier = .distanceWalkingRunning
        case .crossCountrySkiing:
            if #available(iOS 18.0, *) {
                identifier = .distanceCrossCountrySkiing
            } else {
                return
            }
        case .swimming:
            identifier = .distanceSwimming
        default:
            return
        }
        let type = HKQuantityType(identifier)
        let quantity = HKQuantity(unit: .meter(), doubleValue: km * 1000)
        let sample = HKQuantitySample(type: type, quantity: quantity, start: start, end: end)
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            builder.add([sample]) { _, _ in cont.resume() }
        }
    }

    private func addElevationMetadata(to builder: HKWorkoutBuilder, meters: Double) async {
        let metadata: [String: Any] = [
            HKMetadataKeyElevationAscended: HKQuantity(unit: .meter(), doubleValue: meters)
        ]
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            builder.addMetadata(metadata) { _, _ in cont.resume() }
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
