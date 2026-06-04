import SwiftUI
import SwiftData

#Preview {
    NavigationStack {
        CardioView()
            .modelContainer(for: CardioSession.self, inMemory: true)
    }
}

private enum CardioField: Hashable {
    case durationHours(CardioType)
    case duration(CardioType)
    case distance(CardioType)
}

struct CardioView: View {
    var initialType: CardioType? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \CardioSession.date, order: .reverse) private var cardioSessions: [CardioSession]
    @AppStorage("lastCardioType") private var storedType: String = CardioType.crosstrainer.rawValue
    @AppStorage("hasCardioDraft") private var hasCardioDraft = false
    @AppStorage("selectedCardioTypes") private var selectedCardioTypesRaw = ""

    private var activeCardioTypes: [CardioType] {
        let selected = Set(selectedCardioTypesRaw.split(separator: ",").map(String.init))
        if selected.isEmpty { return CardioType.allCases }
        return CardioType.allCases.filter { selected.contains($0.rawValue) }
    }
    @State private var expandedType: CardioType? = nil
    @State private var hours: [String: String] = [:]
    @State private var durations: [String: String] = [:]
    @State private var distances: [String: String] = [:]
    @State private var increaseTypes: Set<String> = []
    @State private var longPressFired: Set<CardioType> = []
    @State private var showEffortPicker = false
    @State private var showTimePicker = false
    @State private var editedStart: Date = Date()
    @State private var editedEnd: Date = Date()
    @State private var hasCustomTime = false
    @State private var lastEffortScore = 5
    @State private var effortDragOffset: CGFloat = 0
    @State private var didCompleteSession = false
    @FocusState private var focusedField: CardioField?

    private var nextCardioField: CardioField? {
        switch focusedField {
        case .durationHours(let type): return .duration(type)
        case .duration(let type):      return .distance(type)
        default:                       return nil
        }
    }

    private func hoursBinding(for type: CardioType) -> Binding<String> {
        Binding(
            get: { hours[type.rawValue] ?? "" },
            set: { hours[type.rawValue] = $0 }
        )
    }

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
            VStack(spacing: 0) {
                headerRow
                ThinDivider().padding(.top, 8)

                ForEach(activeCardioTypes, id: \.self) { type in
                    typeRow(type)
                    ThinDivider()
                }

                Spacer()
            }

            if showEffortPicker {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        Haptics.notification(.success)
                        saveSession(effortScore: nil)
                        dismiss()
                    }
                VStack(spacing: 0) {
                    Spacer()
                    VStack(spacing: 0) {
                        Capsule()
                            .fill(Color(.tertiarySystemFill))
                            .frame(width: 36, height: 4)
                            .padding(.top, 8)
                            .padding(.bottom, 4)
                        EffortPickerSheet(accent: .workoutAccent, initialScore: lastEffortScore) { score in
                            saveSession(effortScore: score)
                            dismiss()
                        }
                    }
                    .background(Color.appBackground)
                    .clipShape(UnevenRoundedRectangle(topLeadingRadius: 16, topTrailingRadius: 16))
                }
                .offset(y: max(0, effortDragOffset))
                .animation(.interactiveSpring(), value: effortDragOffset)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            var t = Transaction()
                            t.disablesAnimations = true
                            withTransaction(t) { effortDragOffset = value.translation.height }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                Haptics.notification(.success)
                                saveSession(effortScore: nil)
                                dismiss()
                            } else {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) { effortDragOffset = 0 }
                            }
                        }
                )
                .ignoresSafeArea(edges: .bottom)
                .transition(.move(edge: .bottom))
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !showEffortPicker {
                klarBar
                    .opacity(focusedField != nil ? 0 : 1)
                    .animation(.linear(duration: 0), value: focusedField)
            }
        }
        .sheet(isPresented: $showTimePicker, onDismiss: { hasCustomTime = true }) {
            SessionTimePicker(start: $editedStart, end: $editedEnd, accent: .workoutAccent)
        }
        .animation(.easeInOut(duration: 0.22), value: showEffortPicker)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("NÄSTA") {
                    Haptics.selection()
                    focusedField = nextCardioField
                }
                .font(.jost(.semibold, size: 13))
                .foregroundColor(nextCardioField != nil ? Color.workoutAccent : Color(.tertiaryLabel))
                .disabled(nextCardioField == nil)
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
                        if type == .hiking, let totalMins = parseWeight(saved) {
                            let h = Int(totalMins) / 60
                            let m = Int(totalMins) % 60
                            hours[type.rawValue] = h > 0 ? "\(h)" : ""
                            durations[type.rawValue] = m > 0 ? "\(m)" : ""
                        } else {
                            durations[type.rawValue] = saved
                        }
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
                    if type == .hiking, let draftHours = UserDefaults.standard.string(forKey: "cardioDraftHours") {
                        hours[savedType] = draftHours
                    }
                    if let draftDistance = UserDefaults.standard.string(forKey: "cardioDraftDistance") {
                        distances[savedType] = draftDistance
                    }
                } else {
                    expandedType = initialType ?? CardioType(rawValue: storedType)
                }
            }
            editedEnd = Date()
            editedStart = Date()
            Task { await HealthKitManager.shared.requestAuthorization() }
        }
        .onDisappear {
            saveDraftIfNeeded()
        }
    }

    // MARK: Sub-views

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("KONDITION")
                .font(.jost(.bold, size: 17))
                .kerning(2)
                .foregroundColor(.primary)

            Button {
                showTimePicker = true
            } label: {
                Text(editedEnd.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "sv_SE"))).uppercased())
                    .font(.jost(.regular, size: 13))
                    .foregroundColor(Color(.secondaryLabel))
            }
            .buttonStyle(.plain)

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    @ViewBuilder
    private func typeRow(_ type: CardioType) -> some View {
        let isExpanded = expandedType == type
        let summary = lastSessionSummary(for: type)

        VStack(spacing: 0) {
            Button {
                if longPressFired.contains(type) {
                    longPressFired.remove(type)
                    return
                }
                Haptics.selection()
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
                HStack(alignment: .firstTextBaseline) {
                    Text(type.displayName.uppercased())
                        .font(.jost(.semibold, size: 12))
                        .kerning(1.5)
                        .foregroundColor(isExpanded ? Color.workoutAccent : Color(.secondaryLabel))
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
                        if let summary {
                            Text(summary)
                                .font(.jost(.regular, size: 12))
                                .foregroundColor(Color(.secondaryLabel))
                        }
                        Image(systemName: "chevron.right")
                            .font(.jost(.medium, size: 10))
                            .foregroundColor(Color(.secondaryLabel))
                            .padding(.leading, 6)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, isExpanded ? 10 : 20)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                // Column headers
                HStack(spacing: 0) {
                    if type == .hiking {
                        Text("H")
                            .frame(width: 60, alignment: .leading)
                        Text("MIN")
                            .frame(width: 60, alignment: .leading)
                    } else {
                        Text("MIN")
                            .frame(width: 80, alignment: .leading)
                    }
                    Spacer()
                    Text("KM")
                        .frame(width: 80, alignment: .trailing)
                }
                .font(.jost(.medium, size: 10))
                .kerning(1.5)
                .foregroundColor(Color(.secondaryLabel))
                .padding(.horizontal, 24)
                .padding(.bottom, 6)

                // Number fields
                HStack(alignment: .firstTextBaseline, spacing: 0) {
                    if type == .hiking {
                        durationField(
                            text: hoursBinding(for: type),
                            focus: .durationHours(type),
                            keyboard: .numberPad,
                            width: 60
                        )
                        durationField(
                            text: durationBinding(for: type),
                            focus: .duration(type),
                            keyboard: .numberPad,
                            width: 60
                        )
                    } else {
                        durationField(
                            text: durationBinding(for: type),
                            focus: .duration(type),
                            keyboard: .decimalPad,
                            width: 80
                        )
                    }

                    Spacer()

                    distanceField(text: distanceBinding(for: type), focus: .distance(type))
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 14)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.22), value: isExpanded)
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                Haptics.impact(.medium)
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

    private func durationField(text: Binding<String>, focus: CardioField, keyboard: UIKeyboardType, width: CGFloat) -> some View {
        TextField("", text: text)
            .font(.jost(.semibold, size: 34))
            .foregroundColor(.primary)
            .keyboardType(keyboard)
            .multilineTextAlignment(.leading)
            .focused($focusedField, equals: focus)
            .frame(width: width, alignment: .leading)
            .overlay(alignment: .leading) {
                if text.wrappedValue.isEmpty && focusedField != focus {
                    Text("–")
                        .font(.jost(.semibold, size: 34))
                        .foregroundColor(Color(.tertiaryLabel))
                        .allowsHitTesting(false)
                }
            }
    }

    private func distanceField(text: Binding<String>, focus: CardioField) -> some View {
        TextField("", text: text)
            .font(.jost(.semibold, size: 34))
            .foregroundColor(.primary)
            .keyboardType(.decimalPad)
            .multilineTextAlignment(.trailing)
            .focused($focusedField, equals: focus)
            .frame(width: 80, alignment: .trailing)
            .overlay(alignment: .trailing) {
                if text.wrappedValue.isEmpty && focusedField != focus {
                    Text("–")
                        .font(.jost(.semibold, size: 34))
                        .foregroundColor(Color(.tertiaryLabel))
                        .allowsHitTesting(false)
                }
            }
    }

    private func lastSessionSummary(for type: CardioType) -> String? {
        guard let dStr = UserDefaults.standard.string(forKey: "cardioSavedDuration_\(type.rawValue)"),
              let duration = Double(dStr.replacingOccurrences(of: ",", with: ".")),
              duration > 0 else { return nil }
        let mins = Int(duration)
        var text: String
        if type == .hiking && duration >= 60 {
            let h = mins / 60; let m = mins % 60
            text = m > 0 ? "\(h) H \(m) MIN" : "\(h) H"
        } else {
            text = "\(mins) MIN"
        }
        if let kStr = UserDefaults.standard.string(forKey: "cardioSavedDistance_\(type.rawValue)"),
           let km = Double(kStr.replacingOccurrences(of: ",", with: ".")), km > 0 {
            text += " · \(formatWeight(km)) KM"
        }
        return text
    }

    private func totalMinutes(for type: CardioType) -> Double {
        if type == .hiking {
            let h = Double(hours[type.rawValue]?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
            let m = Double((durations[type.rawValue] ?? "").replacingOccurrences(of: ",", with: ".")) ?? 0
            return h * 60 + m
        }
        return Double((durations[type.rawValue] ?? "").replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func handleKlar() {
        guard let type = expandedType, totalMinutes(for: type) > 0 else { dismiss(); return }
        focusedField = nil
        let saved = UserDefaults.standard.integer(forKey: "cardioEffortScore_\(type.rawValue)")
        lastEffortScore = saved > 0 ? saved : 5
        showEffortPicker = true
    }

    private var klarBar: some View {
        Button("KLAR", action: handleKlar)
            .buttonStyle(FilledButtonStyle(accent: Color.workoutAccent))
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
    }

    // MARK: Logic

    private func saveDraftIfNeeded() {
        guard !didCompleteSession else { return }
        guard let type = expandedType else { return }
        let hasData: Bool
        if type == .hiking {
            hasData = !(hours[type.rawValue] ?? "").isEmpty || !(durations[type.rawValue] ?? "").isEmpty
        } else {
            hasData = !(durations[type.rawValue] ?? "").isEmpty
        }
        guard hasData else { return }
        UserDefaults.standard.set(type.rawValue, forKey: "cardioDraftType")
        UserDefaults.standard.set(durations[type.rawValue] ?? "", forKey: "cardioDraftMinutes")
        if type == .hiking {
            UserDefaults.standard.set(hours[type.rawValue] ?? "", forKey: "cardioDraftHours")
        }
        let distStr = distances[type.rawValue] ?? ""
        if !distStr.isEmpty {
            UserDefaults.standard.set(distStr, forKey: "cardioDraftDistance")
        } else {
            UserDefaults.standard.removeObject(forKey: "cardioDraftDistance")
        }
        hasCardioDraft = true
    }

    private func saveSession(effortScore: Int? = nil) {
        guard let type = expandedType else { return }
        let minutes = totalMinutes(for: type)
        guard minutes > 0 else { return }
        didCompleteSession = true

        let distanceStr = distances[type.rawValue] ?? ""
        let distanceKm = distanceStr.isEmpty ? nil : Double(distanceStr.replacingOccurrences(of: ",", with: "."))

        UserDefaults.standard.removeObject(forKey: "cardioDraftType")
        UserDefaults.standard.removeObject(forKey: "cardioDraftMinutes")
        UserDefaults.standard.removeObject(forKey: "cardioDraftHours")
        UserDefaults.standard.removeObject(forKey: "cardioDraftDistance")
        hasCardioDraft = false

        let previousDuration = Double(UserDefaults.standard.string(forKey: "cardioSavedDuration_\(type.rawValue)")?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
        UserDefaults.standard.set(formatWeight(minutes), forKey: "cardioSavedDuration_\(type.rawValue)")
        if !distanceStr.isEmpty {
            UserDefaults.standard.set(distanceStr, forKey: "cardioSavedDistance_\(type.rawValue)")
        } else {
            UserDefaults.standard.removeObject(forKey: "cardioSavedDistance_\(type.rawValue)")
        }

        if let score = effortScore {
            UserDefaults.standard.set(score, forKey: "cardioEffortScore_\(type.rawValue)")
        }

        if minutes > previousDuration && increaseTypes.contains(type.rawValue) {
            increaseTypes.remove(type.rawValue)
            UserDefaults.standard.setCardioIncrease(type, false)
        }

        let end = hasCustomTime && editedEnd > editedStart ? editedEnd : Date()
        let start = hasCustomTime ? (editedStart < end ? editedStart : end.addingTimeInterval(-minutes * 60))
                                  : end.addingTimeInterval(-minutes * 60)
        let session = CardioSession(date: end, startDate: start, durationMinutes: minutes, cardioType: type.rawValue, distanceKm: distanceKm)
        session.effortScore = effortScore
        context.insert(session)
        try? context.save()

        if UserDefaults.standard.bool(forKey: "healthKitSyncEnabled") {
            Task { @MainActor in
                let uuid = await HealthKitManager.shared.saveCardioWorkout(start: start, end: end, type: type, distanceKm: distanceKm, effortScore: effortScore)
                session.healthKitID = uuid
                try? context.save()
            }
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
