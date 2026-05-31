import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @AppStorage("weightUnit")              private var weightUnit = "kg"
    @AppStorage("distanceUnit")            private var distanceUnit = "km"
    @AppStorage("healthKitSyncEnabled")    private var healthKitSyncEnabled = true
    @AppStorage("healthKitWeightEnabled")  private var healthKitWeightEnabled = true
    @AppStorage("lockEnabled")             private var lockEnabled = true

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Träning") {
                    HStack {
                        Image(systemName: "square.grid.2x2")
                            .foregroundStyle(Color.homeAccent)
                            .frame(width: 28)
                        Text("Program")
                            .font(.jost(.regular, size: 16))
                        Spacer()
                        Text("Kommer snart")
                            .font(.jost(.regular, size: 14))
                            .foregroundStyle(Color(.tertiaryLabel))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                }

                Section("Enheter") {
                    HStack {
                        Image(systemName: "scalemass")
                            .foregroundStyle(Color(.secondaryLabel))
                            .frame(width: 28)
                        Text("Vikt")
                            .font(.jost(.regular, size: 16))
                        Spacer()
                        Picker("", selection: $weightUnit) {
                            Text("kg").tag("kg")
                            Text("lbs").tag("lbs")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 100)
                    }

                    HStack {
                        Image(systemName: "figure.walk")
                            .foregroundStyle(Color(.secondaryLabel))
                            .frame(width: 28)
                        Text("Distans")
                            .font(.jost(.regular, size: 16))
                        Spacer()
                        Picker("", selection: $distanceUnit) {
                            Text("km").tag("km")
                            Text("miles").tag("miles")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 120)
                    }
                }

                Section {
                    Toggle(isOn: $healthKitSyncEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(.red)
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Spara pass till Hälsa")
                                    .font(.jost(.regular, size: 16))
                                Text("Dina pass sparas i Apple Hälsa så att de visas i Aktivitet och Fitness.")
                                    .font(.jost(.regular, size: 12))
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                        }
                    }
                    .tint(Color.homeAccent)

                    Toggle(isOn: $healthKitWeightEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "scalemass.fill")
                                .foregroundStyle(Color(.secondaryLabel))
                                .frame(width: 28)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hämta kroppsvikt från Hälsa")
                                    .font(.jost(.regular, size: 16))
                                Text("Appen läser ditt senaste registrerade värde och använder det enbart för att beräkna kaloriförbrukning.")
                                    .font(.jost(.regular, size: 12))
                                    .foregroundStyle(Color(.secondaryLabel))
                            }
                        }
                    }
                    .tint(Color.homeAccent)
                    .disabled(!healthKitSyncEnabled)
                } header: {
                    Text("Hälsa")
                }

                Section("Sekretess") {
                    Toggle(isOn: $lockEnabled) {
                        HStack(spacing: 12) {
                            Image(systemName: "faceid")
                                .foregroundStyle(Color(.secondaryLabel))
                                .frame(width: 28)
                            Text("Face ID-lås")
                                .font(.jost(.regular, size: 16))
                        }
                    }
                    .tint(Color.homeAccent)
                }

                Section("Om") {
                    HStack {
                        Text("Version")
                            .font(.jost(.regular, size: 16))
                        Spacer()
                        Text(appVersion)
                            .font(.jost(.regular, size: 16))
                            .foregroundStyle(Color(.secondaryLabel))
                    }
                }
            }
            .navigationTitle("Inställningar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Klar") { dismiss() }
                        .font(.jost(.semibold, size: 16))
                        .foregroundStyle(Color.historyAccent)
                }
            }
        }
    }
}
