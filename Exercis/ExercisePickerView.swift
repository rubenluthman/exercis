import SwiftUI
import Fuse

struct ExercisePickerView: View {
    let onSelect: (ExerciseDef) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private let fuse = Fuse(threshold: 0.4)

    private var filtered: [ExerciseDef] {
        if searchText.isEmpty { return ExerciseDef.all }
        let searchStrings = ExerciseDef.all.map { "\($0.displayName) \($0.primaryMuscles.joined(separator: " "))" }
        let results = fuse.search(searchText, in: searchStrings)
        return results
            .sorted { $0.score < $1.score }
            .map { ExerciseDef.all[$0.index] }
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
                                .font(.jost(.regular, size: 12))
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
                        .font(.jost(.regular, size: 16))
                }
            }
        }
    }
}
