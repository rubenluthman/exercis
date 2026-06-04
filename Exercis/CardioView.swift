import SwiftUI
import SwiftData

struct CardioView: View {
    let type: CardioType

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @AppStorage("hasCardioDraft") private var hasCardioDraft = false

    @State private var distance = ""
    @State private var increaseActive = false
    @State private var showEffortPicker = false
    @State private var showTimePicker = false
    @State private var editedStart: Date = Date()
    @State private var editedEnd: Date = Date()
    @State private var hasCustomTime = false
    @State private var lastEffortScore = 5
    @State private var effortDragOffset: CGFloat = 0
    @State private var didCompleteSession = false
    @State private var longPressFired = false
    @FocusState private var distanceFocused: Bool

    private var draftStartKey: String { "cardioDraftStartTime_\(type.rawValue)" }
    private var draftDistanceKey: String { "cardioDraftDistance_\(type.rawValue)" }
    private var draftActiveKey: String { "cardioDraftActive_\(type.rawValue)" }

    private var lastSummary: String? {
        guard let dStr = UserDefaults.standard.string(forKey: "cardioSavedDuration_\(type.rawValue)"),
              let duration = Double(dStr.replacingOccurrences(of: ",", with: ".")),
              duration > 0 else { return nil }
        let mins = Int(duration)
        var text = mins >= 60 ? "\(mins/60) H \(mins%60 > 0 ? "\(mins%60) MIN" : "")" : "\(mins) MIN"
        text = text.trimmingCharacters(in: .whitespaces)
        if let kStr = UserDefaults.standard.string(forKey: "cardioSavedDistance_\(type.rawValue)"),
           let km = Double(kStr.replacingOccurrences(of: ",", with: ".")), km > 0 {
            text += " · \(formatWeight(km)) KM"
        }
        return text
    }

    private func durationFromTime() -> Double {
        max(1, editedEnd.timeIntervalSince(editedStart) / 60)
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                headerRow
                ThinDivider().padding(.top, 8)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("KM")
                        .font(.jost(.medium, size: 10))
                        .kerning(1.5)
                        .foregroundColor(Color(.secondaryLabel))

                    TextField("", text: $distance)
                        .font(.jost(.semibold, size: 56))
                        .foregroundColor(.primary)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .focused($distanceFocused)
                        .overlay(alignment: .trailing) {
                            if distance.isEmpty && !distanceFocused {
                                Text("–")
                                    .font(.jost(.semibold, size: 56))
                                    .foregroundColor(Color(.tertiaryLabel))
                                    .allowsHitTesting(false)
                            }
                        }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)

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
                            var t = Transaction(); t.disablesAnimations = true
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
                Button("KLAR") {
                    distanceFocused = false
                    let saved = UserDefaults.standard.integer(forKey: "cardioEffortScore_\(type.rawValue)")
                    lastEffortScore = saved > 0 ? saved : 5
                    showEffortPicker = true
                }
                .buttonStyle(FilledButtonStyle(accent: .workoutAccent))
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .opacity(distanceFocused ? 0 : 1)
                .animation(.linear(duration: 0), value: distanceFocused)
            }
        }
        .sheet(isPresented: $showTimePicker, onDismiss: { hasCustomTime = true }) {
            SessionTimePicker(start: $editedStart, end: $editedEnd, accent: .workoutAccent)
        }
        .animation(.easeInOut(duration: 0.22), value: showEffortPicker)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("KLAR") { distanceFocused = false }
                    .font(.jost(.semibold, size: 13))
                    .foregroundColor(Color.workoutAccent)
            }
        }
        .onAppear {
            increaseActive = UserDefaults.standard.increaseCardioTypes().contains(type.rawValue)
            let saved = UserDefaults.standard.integer(forKey: "cardioEffortScore_\(type.rawValue)")
            lastEffortScore = saved > 0 ? saved : 5
            editedEnd = Date()

            // Återuppta pågående pass om draft finns
            if let startInterval = UserDefaults.standard.object(forKey: draftStartKey) as? Double {
                editedStart = Date(timeIntervalSince1970: startInterval)
                distance = UserDefaults.standard.string(forKey: draftDistanceKey) ?? ""
            } else {
                editedStart = Date()
                if let savedDist = UserDefaults.standard.string(forKey: "cardioSavedDistance_\(type.rawValue)") {
                    distance = savedDist
                }
            }
            Task { await HealthKitManager.shared.requestAuthorization() }
        }
        .onDisappear {
            saveDraftIfNeeded()
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5).onEnded { _ in
                guard !showEffortPicker else { return }
                Haptics.impact(.medium)
                longPressFired = true
                increaseActive.toggle()
                UserDefaults.standard.setCardioIncrease(type, increaseActive)
            }
        )
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(type.displayName.uppercased())
                        .font(.jost(.bold, size: 17))
                        .kerning(2)
                        .foregroundColor(.primary)
                    Text("ÖKA")
                        .font(.jost(.medium, size: 9))
                        .kerning(1.5)
                        .foregroundColor(Color.workoutAccent)
                        .padding(.horizontal, 5).padding(.vertical, 2)
                        .overlay(RoundedRectangle(cornerRadius: 2).strokeBorder(Color.workoutAccent, lineWidth: 0.5))
                        .opacity(increaseActive ? 1 : 0)
                }
                if let summary = lastSummary {
                    Text(summary)
                        .font(.jost(.regular, size: 12))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
            Spacer(minLength: 0)
            Button {
                showTimePicker = true
            } label: {
                Text(editedEnd.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated).locale(Locale(identifier: "sv_SE"))).uppercased())
                    .font(.jost(.regular, size: 13))
                    .foregroundColor(Color(.secondaryLabel))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Logic

    private func saveDraftIfNeeded() {
        guard !didCompleteSession else { return }
        UserDefaults.standard.set(editedStart.timeIntervalSince1970, forKey: draftStartKey)
        if !distance.isEmpty {
            UserDefaults.standard.set(distance, forKey: draftDistanceKey)
        } else {
            UserDefaults.standard.removeObject(forKey: draftDistanceKey)
        }
        UserDefaults.standard.set(type.rawValue, forKey: "cardioDraftType")
        hasCardioDraft = true
    }

    private func saveSession(effortScore: Int? = nil) {
        let end = editedEnd
        let start = editedStart
        let minutes = durationFromTime()
        didCompleteSession = true

        let distanceKm = distance.isEmpty ? nil : Double(distance.replacingOccurrences(of: ",", with: "."))

        UserDefaults.standard.removeObject(forKey: draftStartKey)
        UserDefaults.standard.removeObject(forKey: draftDistanceKey)
        UserDefaults.standard.removeObject(forKey: "cardioDraftType")
        hasCardioDraft = false

        let previousDuration = Double(UserDefaults.standard.string(forKey: "cardioSavedDuration_\(type.rawValue)")?.replacingOccurrences(of: ",", with: ".") ?? "") ?? 0
        UserDefaults.standard.set(formatWeight(minutes), forKey: "cardioSavedDuration_\(type.rawValue)")
        if let km = distanceKm {
            UserDefaults.standard.set(formatWeight(km), forKey: "cardioSavedDistance_\(type.rawValue)")
        } else {
            UserDefaults.standard.removeObject(forKey: "cardioSavedDistance_\(type.rawValue)")
        }
        if let score = effortScore {
            UserDefaults.standard.set(score, forKey: "cardioEffortScore_\(type.rawValue)")
        }
        if minutes > previousDuration && increaseActive {
            increaseActive = false
            UserDefaults.standard.setCardioIncrease(type, false)
        }

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
    func increaseCardioTypes() -> Set<String> { Set(stringArray(forKey: Self.increaseCardioKey) ?? []) }
    func setCardioIncrease(_ type: CardioType, _ value: Bool) {
        var types = increaseCardioTypes()
        if value { types.insert(type.rawValue) } else { types.remove(type.rawValue) }
        set(Array(types), forKey: Self.increaseCardioKey)
    }
}
