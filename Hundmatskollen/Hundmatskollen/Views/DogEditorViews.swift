import SwiftUI
import SwiftData

struct AddDogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var breed = ""
    @State private var weightText = ""
    @State private var birthDate = Date()
    @State private var gender: DogGender = .male
    @State private var healthStatus: HealthStatus = .healthy
    @State private var activityLevel: ActivityLevel = .moderate
    @State private var feedingGoal: FeedingGoal = .maintain
    @State private var hasAttemptedSave = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Om hunden") {
                    TextField("Namn", text: $name)
                    if shouldShowNameError {
                        ValidationMessage(text: "Ange hundens namn.")
                    }

                    TextField("Ras", text: $breed)
                    TextField("Vikt (kg)", text: $weightText)
                        .keyboardType(.decimalPad)
                    if shouldShowWeightError {
                        ValidationMessage(text: "Ange en giltig vikt över 0 kg.")
                    }

                    DatePicker("Födelsedatum", selection: $birthDate, displayedComponents: .date)
                    Picker("Kön", selection: $gender) {
                        ForEach(DogGender.allCases, id: \.self) { Text($0.rawValue) }
                    }
                }

                Section("Hälsa & mål") {
                    Picker("Status", selection: $healthStatus) {
                        ForEach(HealthStatus.profileOptions, id: \.self) { Text($0.rawValue) }
                    }
                    ContextDescription(text: healthStatus.description)

                    Picker("Aktivitetsnivå", selection: $activityLevel) {
                        ForEach(ActivityLevel.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    ContextDescription(text: activityLevel.description)

                    Picker("Mål", selection: $feedingGoal) {
                        ForEach(FeedingGoal.allCases, id: \.self) { Text($0.rawValue) }
                    }
                    ContextDescription(text: feedingGoal.description)
                }

                Section("Beräknat dagsbehov") {
                    if let weight = parsedWeight {
                        let tempDog = Dog(
                            name: name,
                            weightKg: weight,
                            healthStatus: healthStatus,
                            activityLevel: activityLevel,
                            feedingGoal: feedingGoal
                        )
                        LabeledContent("Kalorier/dag", value: "\(Int(tempDog.dailyCalories)) kcal")
                        LabeledContent("Protein", value: "\(Int(tempDog.dailyProteinGrams)) g")
                        LabeledContent("Fett", value: "\(Int(tempDog.dailyFatGrams)) g")
                        LabeledContent("Kolhydrater", value: "\(Int(tempDog.dailyCarbGrams)) g")
                        LabeledContent("Vatten", value: "\(Int(tempDog.dailyWaterMl)) ml")
                    } else {
                        Text("Ange vikt för att se beräkning")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Lägg till hund")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        hasAttemptedSave = true
                        saveDog()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var parsedWeight: Double? {
        let normalizedText = weightText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalizedText), value > 0 else { return nil }
        return value
    }

    private var isFormValid: Bool {
        !trimmedName.isEmpty && parsedWeight != nil
    }

    private var shouldShowNameError: Bool {
        hasAttemptedSave && trimmedName.isEmpty
    }

    private var shouldShowWeightError: Bool {
        hasAttemptedSave && parsedWeight == nil
    }

    private func saveDog() {
        guard let weight = parsedWeight, !trimmedName.isEmpty else { return }

        let dog = Dog(
            name: trimmedName,
            breed: breed,
            weightKg: weight,
            birthDate: birthDate,
            gender: gender,
            healthStatus: healthStatus,
            activityLevel: activityLevel,
            feedingGoal: feedingGoal
        )
        modelContext.insert(dog)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not save dog: \(error)")
        }

        dismiss()
    }
}

struct EditDogView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let dog: Dog

    @State private var name: String
    @State private var breed: String
    @State private var weightText: String
    @State private var birthDate: Date
    @State private var gender: DogGender
    @State private var healthStatus: HealthStatus
    @State private var activityLevel: ActivityLevel
    @State private var feedingGoal: FeedingGoal
    @State private var hasAttemptedSave = false

    init(dog: Dog) {
        self.dog = dog
        _name = State(initialValue: dog.name)
        _breed = State(initialValue: dog.breed)
        _weightText = State(initialValue: String(format: "%.1f", dog.weightKg).replacingOccurrences(of: ".", with: ","))
        _birthDate = State(initialValue: dog.birthDate)
        _gender = State(initialValue: dog.gender)
        _healthStatus = State(initialValue: dog.healthStatus)
        _activityLevel = State(initialValue: dog.activityLevel)
        _feedingGoal = State(initialValue: dog.feedingGoal)
    }

    var body: some View {
        Form {
            Section("Om hunden") {
                TextField("Namn", text: $name)
                if shouldShowNameError {
                    ValidationMessage(text: "Ange hundens namn.")
                }

                TextField("Ras", text: $breed)
                TextField("Vikt (kg)", text: $weightText)
                    .keyboardType(.decimalPad)
                if shouldShowWeightError {
                    ValidationMessage(text: "Ange en giltig vikt över 0 kg.")
                }

                DatePicker("Födelsedatum", selection: $birthDate, displayedComponents: .date)
                Picker("Kön", selection: $gender) {
                    ForEach(DogGender.allCases, id: \.self) { Text($0.rawValue) }
                }
            }

            Section("Hälsa & mål") {
                Picker("Status", selection: $healthStatus) {
                    ForEach(HealthStatus.profileOptions, id: \.self) { Text($0.rawValue) }
                }
                ContextDescription(text: healthStatus.description)

                Picker("Aktivitetsnivå", selection: $activityLevel) {
                    ForEach(ActivityLevel.allCases, id: \.self) { Text($0.rawValue) }
                }
                ContextDescription(text: activityLevel.description)

                Picker("Mål", selection: $feedingGoal) {
                    ForEach(FeedingGoal.allCases, id: \.self) { Text($0.rawValue) }
                }
                ContextDescription(text: feedingGoal.description)
            }

            Section("Beräknat dagsbehov") {
                if let editedWeight {
                    let tempDog = Dog(
                        name: name,
                        breed: breed,
                        weightKg: editedWeight,
                        birthDate: birthDate,
                        gender: gender,
                        healthStatus: healthStatus,
                        activityLevel: activityLevel,
                        feedingGoal: feedingGoal
                    )
                    LabeledContent("Kalorier/dag", value: "\(Int(tempDog.dailyCalories)) kcal")
                    LabeledContent("Protein", value: "\(Int(tempDog.dailyProteinGrams)) g")
                    LabeledContent("Fett", value: "\(Int(tempDog.dailyFatGrams)) g")
                    LabeledContent("Kolhydrater", value: "\(Int(tempDog.dailyCarbGrams)) g")
                    LabeledContent("Vatten", value: "\(Int(tempDog.dailyWaterMl)) ml")
                } else {
                    Text("Ange vikt för att se beräkning")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Redigera hund")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Spara") {
                    hasAttemptedSave = true
                    saveChanges()
                }
                .disabled(!isFormValid)
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var editedWeight: Double? {
        let normalizedText = weightText.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalizedText), value > 0 else { return nil }
        return value
    }

    private var isFormValid: Bool {
        !trimmedName.isEmpty && editedWeight != nil
    }

    private var shouldShowNameError: Bool {
        hasAttemptedSave && trimmedName.isEmpty
    }

    private var shouldShowWeightError: Bool {
        hasAttemptedSave && editedWeight == nil
    }

    private func saveChanges() {
        guard let editedWeight, !trimmedName.isEmpty else { return }

        dog.name = trimmedName
        dog.breed = breed
        dog.weightKg = editedWeight
        dog.birthDate = birthDate
        dog.gender = gender
        dog.healthStatus = healthStatus
        dog.activityLevel = activityLevel
        dog.feedingGoal = feedingGoal

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not save dog changes: \(error)")
        }

        dismiss()
    }
}

private struct ValidationMessage: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.red)
    }
}

private struct ContextDescription: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.footnote)
            .foregroundStyle(.secondary)
    }
}
