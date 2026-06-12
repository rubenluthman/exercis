import SwiftUI
import SwiftData

struct RotationEditorView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutProgram.sortIndex) private var allPrograms: [WorkoutProgram]

    var existing: ProgramRotation? = nil

    @State private var rotationName = ""
    @State private var selectedIds: [String] = []
    @State private var currentIndex = 0

    private let letters = ["A", "B", "C", "D", "E", "F"]

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            ThinDivider().padding(.top, 8)

            ScrollView {
                VStack(spacing: 0) {
                    nameSection
                    ThinDivider()
                    sequenceSection
                    if selectedIds.count >= 2 {
                        ThinDivider()
                        currentlyOnSection
                    }
                    ThinDivider()
                    addProgramsSection
                }
                .padding(.bottom, 40)
            }
            .softScrollEdge()
        }
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            if let r = existing {
                rotationName = r.name
                selectedIds = r.programIds
                currentIndex = r.currentIndex
            }
        }
    }

    private var headerRow: some View {
        HStack {
            Button(String(localized: "Cancel")) { dismiss() }
                .font(.jost(.regular, size: 15))
                .foregroundStyle(Color(.secondaryLabel))

            Spacer()

            Text(existing == nil ? "NEW ROTATION" : "EDIT ROTATION")
                .font(.jost(.bold, size: 17))
                .kerning(2)

            Spacer()

            Button(String(localized: "Save")) { save() }
                .font(.jost(.semibold, size: 15))
                .foregroundStyle(selectedIds.count >= 2 ? Color.homeAccent : Color(.tertiaryLabel))
                .disabled(selectedIds.count < 2)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            editorSectionLabel("NAME")
                .padding(.horizontal, 24)
            TextField(String(localized: "e.g. A/B Strength"), text: $rotationName)
                .font(.jost(.regular, size: 15))
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
        }
    }

    private var sequenceSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            editorSectionLabel("SEQUENCE")
                .padding(.horizontal, 24)

            if selectedIds.isEmpty {
                Text("Tap programs below to add them to the rotation.")
                    .font(.jost(.regular, size: 14))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
            } else {
                ForEach(Array(selectedIds.enumerated()), id: \.offset) { i, id in
                    let program = allPrograms.first { $0.id.uuidString == id }
                    let letter = i < letters.count ? letters[i] : "\(i + 1)"
                    let accent = program.map { Color($0.colorName) } ?? Color(.secondaryLabel)
                    HStack(spacing: 12) {
                        Text(letter)
                            .font(.jost(.semibold, size: 12))
                            .kerning(1)
                            .foregroundStyle(accent)
                            .frame(width: 16)
                        Text(program?.name ?? "—")
                            .font(.jost(.regular, size: 15))
                            .foregroundStyle(.primary)
                        Spacer()
                        Button {
                            removeFromSequence(at: i)
                        } label: {
                            Image(systemName: "xmark")
                                .font(.jost(.medium, size: 11))
                                .foregroundStyle(Color(.tertiaryLabel))
                                .frame(width: 44, height: 44)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.leading, 24)
                    ThinDivider().padding(.leading, 56)
                }
            }
        }
    }

    private var currentlyOnSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            editorSectionLabel("NEXT UP")
                .padding(.horizontal, 24)
            Text("Which program is up next?")
                .font(.jost(.regular, size: 14))
                .foregroundStyle(Color(.secondaryLabel))
                .padding(.horizontal, 24)
                .padding(.bottom, 12)
            HStack(spacing: 8) {
                ForEach(Array(selectedIds.enumerated()), id: \.offset) { i, id in
                    let prog = allPrograms.first { $0.id.uuidString == id }
                    let accent = prog.map { Color($0.colorName) } ?? Color(.secondaryLabel)
                    let isSelected = (currentIndex % max(1, selectedIds.count)) == i
                    let letter = i < letters.count ? letters[i] : "\(i + 1)"
                    Button {
                        currentIndex = i
                    } label: {
                        Text(letter)
                            .font(.jost(.semibold, size: 13))
                            .kerning(1)
                            .foregroundStyle(isSelected ? .white : accent)
                            .frame(width: 44, height: 36)
                            .background(isSelected ? accent : accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private var addProgramsSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            editorSectionLabel("ADD PROGRAMS")
                .padding(.horizontal, 24)

            let available = allPrograms.filter { !selectedIds.contains($0.id.uuidString) }
            if available.isEmpty {
                Text("All programs added.")
                    .font(.jost(.regular, size: 14))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
            } else {
                ForEach(available) { program in
                    Button {
                        guard selectedIds.count < 6 else { return }
                        selectedIds.append(program.id.uuidString)
                    } label: {
                        HStack {
                            Text(program.name)
                                .font(.jost(.regular, size: 15))
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "plus")
                                .font(.jost(.medium, size: 13))
                                .foregroundStyle(Color(program.colorName))
                                .frame(width: 44, height: 44)
                        }
                        .padding(.leading, 24)
                    }
                    .buttonStyle(.plain)
                    ThinDivider().padding(.leading, 24)
                }
            }
        }
    }

    private func removeFromSequence(at index: Int) {
        selectedIds.remove(at: index)
        let count = selectedIds.count
        if count == 0 {
            currentIndex = 0
        } else if currentIndex >= count {
            currentIndex = 0
        }
    }

    private func save() {
        guard selectedIds.count >= 2 else { return }
        let safeIndex = currentIndex % selectedIds.count
        let displayName = rotationName.trimmingCharacters(in: .whitespaces).isEmpty
            ? (0..<min(selectedIds.count, 3)).map { i in i < letters.count ? letters[i] : "\(i + 1)" }.joined(separator: "/")
            : rotationName.trimmingCharacters(in: .whitespaces)

        if let r = existing {
            r.name = displayName
            r.programIds = selectedIds
            r.currentIndex = safeIndex
        } else {
            let r = ProgramRotation(name: displayName, programIds: selectedIds)
            r.currentIndex = safeIndex
            context.insert(r)
        }
        try? context.save()
        dismiss()
    }

    private func editorSectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.jost(.medium, size: 12))
            .kerning(1.5)
            .foregroundStyle(Color(.secondaryLabel))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, 20)
            .padding(.bottom, 8)
    }
}
