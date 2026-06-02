import SwiftUI

struct ExercisePickerView: View {
    let onSelect: (ExerciseDef) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filtered: [ExerciseDef] {
        if searchText.isEmpty { return ExerciseDef.all }
        let q = searchText.lowercased()
        return ExerciseDef.all.filter {
            $0.displayName.lowercased().contains(q) ||
            $0.primaryMuscles.joined().lowercased().contains(q)
        }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { def in
                Button {
                    onSelect(def)
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(def.displayName)
                            .foregroundStyle(.primary)
                        if !def.primaryMuscles.isEmpty {
                            Text(def.primaryMuscles.map { $0.capitalized }.joined(separator: ", "))
                                .font(.caption)
                                .foregroundStyle(Color(.secondaryLabel))
                        }
                    }
                    .padding(.vertical, 2)
                }
                .buttonStyle(.plain)
            }
            .searchable(text: $searchText, prompt: "Sök övning")
            .navigationTitle("Välj övning")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Avbryt") { dismiss() }
                }
            }
        }
    }
}
