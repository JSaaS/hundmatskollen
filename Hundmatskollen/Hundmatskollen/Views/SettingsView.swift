import SwiftUI

struct SettingsView: View {
    @AppStorage(SettingsKeys.weightUnit) private var weightUnitRawValue = WeightDisplayUnit.kilograms.rawValue
    @AppStorage(SettingsKeys.volumeUnit) private var volumeUnitRawValue = VolumeDisplayUnit.milliliters.rawValue

    var body: some View {
        List {
            Section("Enheter") {
                Picker("Vikt", selection: weightUnitBinding) {
                    ForEach(WeightDisplayUnit.allCases) { unit in
                        Text("\(unit.displayName) (\(unit.rawValue))")
                            .tag(unit)
                    }
                }

                Picker("Volym", selection: volumeUnitBinding) {
                    ForEach(VolumeDisplayUnit.allCases) { unit in
                        Text("\(unit.displayName) (\(unit.rawValue))")
                            .tag(unit)
                    }
                }

                Text("De här inställningarna används som grund för hur appen ska visa enheter när fler vyer byggs ut.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Om appen") {
                LabeledContent("Version", value: appVersionText)
                Text("Hundmatskollen hjälper dig att planera, logga och följa hundens mat över tid.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text("Datakälla: Livsmedelsverket livsmedelsdatabas (CC BY 4.0) används för seedad näringsdata.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Inställningar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var weightUnitBinding: Binding<WeightDisplayUnit> {
        Binding(
            get: { WeightDisplayUnit(rawValue: weightUnitRawValue) ?? .kilograms },
            set: { weightUnitRawValue = $0.rawValue }
        )
    }

    private var volumeUnitBinding: Binding<VolumeDisplayUnit> {
        Binding(
            get: { VolumeDisplayUnit(rawValue: volumeUnitRawValue) ?? .milliliters },
            set: { volumeUnitRawValue = $0.rawValue }
        )
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }
}
