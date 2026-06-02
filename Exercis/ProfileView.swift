import SwiftUI
import SwiftData
import PhotosUI

struct ProfileView: View {
    @Query(sort: \WorkoutSession.date, order: .reverse) private var workoutSessions: [WorkoutSession]
    @Query(sort: \CardioSession.date, order: .reverse) private var cardioSessions: [CardioSession]

    @AppStorage("profileName") private var name = ""
    @State private var photoItem: PhotosPickerItem? = nil
    @State private var profileImage: UIImage? = nil
    @State private var editingName = false
    @State private var showSettings = false

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            ThinDivider().padding(.top, 8)

            ScrollView {
                VStack(spacing: 32) {
                    avatarSection
                    statsRow
                }
                .padding(.top, 32)
                .padding(.bottom, 32)
            }
        }
        .onAppear { loadImage() }
        .onChange(of: photoItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    profileImage = image
                    saveImage(image)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Header

    private var headerRow: some View {
        HStack {
            Text("PROFIL")
                .font(.jost(.bold, size: 17))
                .kerning(2)
                .foregroundColor(.primary)
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(.secondaryLabel))
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Inställningar")
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
    }

    // MARK: - Avatar

    private var avatarSection: some View {
        VStack(spacing: 14) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                avatarView
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(Color.historyAccent)
                            .background(Color.appBackground.clipShape(Circle()))
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Byt profilbild")

            if editingName {
                TextField("Ditt namn", text: $name, onCommit: { editingName = false })
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .submitLabel(.done)
                    .padding(.horizontal, 48)
            } else {
                Button {
                    editingName = true
                } label: {
                    Text(name.isEmpty ? "Lägg till namn" : name)
                        .font(.title3.weight(.semibold))
                        .foregroundColor(name.isEmpty ? Color(.tertiaryLabel) : .primary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let image = profileImage {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 88, height: 88)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(.secondarySystemFill))
                .frame(width: 88, height: 88)
                .overlay {
                    if initials.isEmpty {
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(.secondaryLabel))
                    } else {
                        Text(initials)
                            .font(.jost(.semibold, size: 30))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
        }
    }

    private var initials: String {
        let parts = name.split(separator: " ")
        return parts.prefix(2).compactMap { $0.first.map(String.init) }.joined().uppercased()
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(alignment: .top, spacing: 0) {
            statBlock(label: "STYRKA", value: "\(workoutSessions.count)", alignment: .leading)
            statBlock(label: "KONDITION", value: "\(cardioSessions.count)", alignment: .center)
            statBlock(label: "VOLYM", value: volumeText.0, unit: volumeText.1, alignment: .center)
            statBlock(label: "KONDITIONSTID", value: cardioTimeText.0, unit: cardioTimeText.1, alignment: .trailing)
        }
        .padding(.horizontal, 24)
    }

    private var totalVolume: Double {
        workoutSessions.reduce(0.0) { t, s in
            t + s.exerciseLogs.reduce(0.0) { lt, l in
                lt + l.sets.reduce(0.0) { $0 + $1.weight * Double($1.reps) }
            }
        }
    }

    private var volumeText: (String, String?) {
        guard totalVolume > 0 else { return ("—", nil) }
        if totalVolume >= 1000 { return (formatWeight(totalVolume / 1000), " TON") }
        return (formatWeight(totalVolume), " KG")
    }

    private var totalCardioMinutes: Double {
        cardioSessions.reduce(0.0) { $0 + $1.durationMinutes }
    }

    private var cardioTimeText: (String, String?) {
        guard totalCardioMinutes > 0 else { return ("—", nil) }
        let hours = totalCardioMinutes / 60
        return (formatWeight(hours), " H")
    }

    @ViewBuilder
    private func statBlock(label: String, value: String, unit: String? = nil, alignment: HorizontalAlignment = .leading) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(label)
                .font(.jost(.medium, size: 10))
                .kerning(1.5)
                .foregroundColor(Color(.secondaryLabel))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.jost(.semibold, size: 22))
                    .foregroundColor(.primary)
                if let unit {
                    Text(unit)
                        .font(.jost(.semibold, size: 14))
                        .foregroundColor(Color(.secondaryLabel))
                }
            }
        }
        .fixedSize()
        .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .top))
    }

    // MARK: - Image persistence

    private func imageURL() -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("profile.jpg")
    }

    private func saveImage(_ image: UIImage) {
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: imageURL())
        }
    }

    private func loadImage() {
        if let data = try? Data(contentsOf: imageURL()),
           let image = UIImage(data: data) {
            profileImage = image
        }
    }
}
