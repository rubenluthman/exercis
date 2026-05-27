import SwiftUI
import SwiftData

#Preview {
    NavigationStack {
        CardioView()
            .modelContainer(for: CardioSession.self, inMemory: true)
    }
}

private enum CardioField: Hashable {
    case duration(CardioType)
    case distance(CardioType)
}

struct CardioView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \CardioSession.date, order: .reverse) private var cardioSessions: [CardioSession]
    @AppStorage("lastCardioType") private var storedType: String = CardioType.crosstrainer.rawValue
    @AppStorage("hasCardioDraft") private var hasCardioDraft = false
    @State private var expandedType: CardioType? = nil
    @State private var durations: [String: String] = [:]
    @State private var distances: [String: String] = [:]
    @State private var increaseTypes: Set<String> = []
    @State private var longPressFired: Set<CardioType> = []
    @FocusState private var focusedField: CardioField?

    private func durationBinding(for type: CardioType) -> Binding<String> {
        Binding(
            get: { durations[type.rawValue] ?? "" },
            set: { durations[type.rawValue] = $0 }
        )
    }

    private func distanceBinding(for type: CardioType) -> Binding<String> {
        Binding(
            get: { distances[type.rawValue] ?? "" },
            set: { distances[type.rawValue] = $0 }
        )
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerRow
                ThinDivider().padding(.top, 8)

                ForEach(CardioType.allCases, id: \.self) { type in
                    typeRow(type)
                    ThinDivider()
                }

                Spacer()

                klarBar
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("KLAR") { focusedField = nil }
                    .font(.jost(.semibold, size: 13))
                    .foregroundColor(Color.workoutAccent)
            }
        }
        .onAppear {
            for type in CardioType.allCases {
                let hasSession = cardioSessions.contains { $0.cardioType == type.rawValue }
                if hasSession {
                    if let saved = UserDefaults.standard.string(forKey: "cardioSavedDuration_\(type.rawValue)") {
                        durations[type.rawValue] = saved
                    }
                    if let saved = UserDefaults.standard.string(forKey: "cardioSavedDistance_\(type.rawValue)") {
                        distances[type.rawValue] = saved
                    }
                } else {
                    UserDefaults.standard.removeObject(forKey: "cardioSavedDuration_\(type.rawValue)")
                    UserDefaults.standard.removeObject(forKey: "cardioSavedDistance_\(type.rawValue)")
                }
            }
            increaseTypes = UserDefaults.standard.increaseCardioTypes()
            var t = Transaction()
            t.disablesAnimations = true
            withTransaction(t) {
                if hasCardioDraft,
                   let savedType = UserDefaults.standard.string(forKey: "cardioDraftType"),
                   let type = CardioType(rawValue: savedType) {
                    expandedType = type
                    storedType = savedType
                    if let draftMinutes = UserDefaults.standard.string(forKey: "cardioDraftMinutes") {
                        durations[savedType] = draftMinutes
                    }
                    if let draftDistance = UserDefaults.standard.string(forKey: "cardioDraftDistance") {
                        distances[savedType] = draftDistance
                    }
                } else {
                    expandedType = CardioType(rawValue: storedType)
                }
            }
            Task { await HealthKitManager.shared.requestAuthorization() }
        }
    }

    // MARK: Sub-views

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("KONDITION")
                .font(.jost(.bold, size: 17))
                .kerning(2)
                .foregroundColor(.black)

            Text(Date().formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "sv_SE"))).uppercased())
                .font(.jost(.regular, size: 13))
                .foregroundColor(Color(white: 0.45))

            Spacer()

            Button("←") {
                if let type = expandedType {
                    let current = durations[type.rawValue] ?? ""
                    if !current.isEmpty {
                        UserDefaults.standard.set(type.rawValue, forKey: "cardioDraftType")
                        UserDefaults.standard.set(current, forKey: "cardioDraftMinutes")
                        let distStr = distances[type.rawValue] ?? ""
                        if !distStr.isEmpty {
                            UserDefaults.standard.set(distStr, forKey: "cardioDraftDistance")
                        } else {
                            UserDefaults.standard.removeObject(forKey: "cardioDraftDistance")
                        }
                        hasCardioDraft = true
                    }
                }
                dismiss()
            }
            .font(.jost(.regular, size: 22))
            .foregroundColor(Color(white: 0.5))
            .frame(width: 90, alignment: .trailing)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    @ViewBuilder
    private func typeRow(_ type: CardioType) -> some View {
        let isExpanded = expandedType == type

        VStack(spacing: 0) {
            Button {
                if longPressFired.contains(type) {
                    longPressFired.remove(type)
                    return
                }
                focusedField = nil
                withAnimation(.easeInOut(duration: 0.22)) {
                    if isExpanded {
                        expandedType = nil
                        storedType = ""
                    } else {
                        expandedType = type
                        storedType = type.rawValue
                    }
                }
            } label: {
                HStack {
                    Text(type.rawValue)
                        .font(.jost(.semibold, size: 12))
                        .kerning(1.5)
                        .foregroundColor(isExpanded ? Color.workoutAccent : Color(white: 0.45))
                    Text("ÖKA")
                        .font(.jost(.medium, size: 9))
                        .kerning(1.5)
                        .foregroundColor(Color.workoutAccent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 2)
                                .strokeBorder(Color.workoutAccent, lineWidth: 0.5)
                        )
                        .opacity(increaseTypes.contains(type.rawValue) ? 1 : 0)
                    Spacer()
                    if !isExpanded {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color(white: 0.4))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, isExpanded ? 14 : 20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    TextField("", text: durationBinding(for: type))
                        .font(.jost(.semibold, size: 34))
                        .foregroundColor(.black)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.leading)
                        .focused($focusedField, equals: .duration(type))
                        .frame(width: 80, alignment: .leading)
                        .overlay(alignment: .leading) {
                            if (durations[type.rawValue] ?? "").isEmpty && focusedField != .duration(type) {
                                Text("–")
                                    .font(.jost(.semibold, size: 34))
                                    .foregroundColor(Color(white: 0.75))
                                    .allowsHitTesting(false)
                            }
                        }

                    Text("MIN")
                        .font(.jost(.medium, size: 10))
                        .kerning(1.5)
                        .foregroundColor(Color(white: 0.5))

                    Spacer()

                    TextField("", text: distanceBinding(for: type))
                        .font(.jost(.semibold, size: 34))
                        .foregroundColor(.black)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .distance(type))
                        .frame(width: 80)
                        .overlay {
                            if (distances[type.rawValue] ?? "").isEmpty && focusedField != .distance(type) {
                                Text("–")
                                    .font(.jost(.semibold, size: 34))
                                    .foregroundColor(Color(white: 0.75))
                                    .allowsHitTesting(false)
                            }
                        }

                    Text("KM")
                        .font(.jost(.medium, size: 10))
                        .kerning(1.5)
                        .foregroundColor(Color(white: 0.5))
                        .padding(.leading, 6)

                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isExpanded)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                longPressFired.insert(type)
                var t = Transaction()
                t.disablesAnimations = true
                withTransaction(t) {
                    if increaseTypes.contains(type.rawValue) {
                        increaseTypes.remove(type.rawValue)
                    } else {
                        increaseTypes.insert(type.rawValue)
                    }
                }
                UserDefaults.standard.setCardioIncrease(type, increaseTypes.contains(type.rawValue))
            }
        )
    }

    private var klarBar: some View {
        Button("KLAR") {
            saveSession()
            dismiss()
        }
        .buttonStyle(FilledButtonStyle(accent: Color.workoutAccent))
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
    }

    // MARK: Logic

    private func saveSession() {
        guard let type = expandedType else { return }
        let currentDuration = durations[type.rawValue] ?? ""
        guard let minutes = Double(currentDuration.replacingOccurrences(of: ",", with: ".")), minutes > 0 else { return }

        let distanceStr = distances[type.rawValue] ?? ""
        let distanceKm = distanceStr.isEmpty ? nil : Double(distanceStr.replacingOccurrences(of: ",", with: "."))

        UserDefaults.standard.removeObject(forKey: "cardioDraftType")
        UserDefaults.standard.removeObject(forKey: "cardioDraftMinutes")
        UserDefaults.standard.removeObject(forKey: "cardioDraftDistance")
        hasCardioDraft = false

        let previousDuration = Double(UserDefaults.standard.string(forKey: "cardioSavedDuration_\(type.rawValue)")?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
        UserDefaults.standard.set(currentDuration, forKey: "cardioSavedDuration_\(type.rawValue)")
        if !distanceStr.isEmpty {
            UserDefaults.standard.set(distanceStr, forKey: "cardioSavedDistance_\(type.rawValue)")
        } else {
            UserDefaults.standard.removeObject(forKey: "cardioSavedDistance_\(type.rawValue)")
        }

        if minutes > previousDuration && increaseTypes.contains(type.rawValue) {
            increaseTypes.remove(type.rawValue)
            UserDefaults.standard.setCardioIncrease(type, false)
        }

        let session = CardioSession(date: Date(), durationMinutes: minutes, cardioType: type.rawValue, distanceKm: distanceKm)
        context.insert(session)
        try? context.save()

        let end = Date()
        let start = end.addingTimeInterval(-minutes * 60)
        Task { @MainActor in
            let uuid = await HealthKitManager.shared.saveCardioWorkout(start: start, end: end, type: type, distanceKm: distanceKm)
            session.healthKitID = uuid
            try? context.save()
        }
    }
}

private extension UserDefaults {
    static let increaseCardioKey = "increaseCardioTypes"

    func increaseCardioTypes() -> Set<String> {
        Set(stringArray(forKey: Self.increaseCardioKey) ?? [])
    }

    func setCardioIncrease(_ type: CardioType, _ value: Bool) {
        var types = increaseCardioTypes()
        if value { types.insert(type.rawValue) } else { types.remove(type.rawValue) }
        set(Array(types), forKey: Self.increaseCardioKey)
    }
}
