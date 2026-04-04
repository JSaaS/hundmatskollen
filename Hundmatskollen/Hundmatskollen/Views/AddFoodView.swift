import SwiftUI
import SwiftData

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var category: FoodCategory = .other
    @State private var preferredUnit: FoodMeasurementUnit = .grams
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var fatText = ""
    @State private var carbsText = ""
    @State private var fiberText = ""
    @State private var isDangerousForDogs = false
    @State private var dangerNote = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingrediens") {
                    TextField("Namn", text: $name)
                    Picker("Kategori", selection: $category) {
                        ForEach(FoodCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    Picker("Föredragen enhet", selection: $preferredUnit) {
                        ForEach(FoodMeasurementUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName + " (\(unit.rawValue))").tag(unit)
                        }
                    }
                }

                Section("Näringsvärden per \(preferredUnit.rawValue)") {
                    TextField("Kalorier (kcal)", text: $caloriesText)
                        .keyboardType(.decimalPad)
                    TextField("Protein (g)", text: $proteinText)
                        .keyboardType(.decimalPad)
                    TextField("Fett (g)", text: $fatText)
                        .keyboardType(.decimalPad)
                    TextField("Kolhydrater (g)", text: $carbsText)
                        .keyboardType(.decimalPad)
                    TextField("Fiber (g)", text: $fiberText)
                        .keyboardType(.decimalPad)
                }

                Section("Säkerhet") {
                    Toggle("Markera som farlig för hund", isOn: $isDangerousForDogs)

                    if isDangerousForDogs {
                        TextField("Varningstext", text: $dangerNote, axis: .vertical)
                    }
                }
            }
            .navigationTitle("Ny ingrediens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        saveFood()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }

    private var isFormValid: Bool {
        !trimmedName.isEmpty &&
        parsedValue(from: caloriesText) != nil &&
        parsedValue(from: proteinText) != nil &&
        parsedValue(from: fatText) != nil &&
        parsedValue(from: carbsText) != nil &&
        parsedValue(from: fiberText) != nil &&
        (!isDangerousForDogs || !trimmedDangerNote.isEmpty)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDangerNote: String {
        dangerNote.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveFood() {
        guard
            let calories = parsedValue(from: caloriesText),
            let protein = parsedValue(from: proteinText),
            let fat = parsedValue(from: fatText),
            let carbs = parsedValue(from: carbsText),
            let fiber = parsedValue(from: fiberText),
            !trimmedName.isEmpty,
            !isDangerousForDogs || !trimmedDangerNote.isEmpty
        else {
            return
        }

        let food = Food(
            name: trimmedName,
            category: category,
            caloriesPer100g: calories,
            proteinPer100g: protein,
            fatPer100g: fat,
            carbsPer100g: carbs,
            fiberPer100g: fiber,
            isCustom: true,
            isDangerousForDogs: isDangerousForDogs,
            dangerNote: trimmedDangerNote,
            preferredUnit: preferredUnit
        )
        modelContext.insert(food)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not save food: \(error)")
        }

        dismiss()
    }

    private func parsedValue(from text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0 else {
            return nil
        }
        return value
    }
}

struct EditFoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var meals: [Meal]
    @Query private var recipes: [Recipe]

    let food: Food
    let onDelete: (() -> Void)?

    @State private var name: String
    @State private var category: FoodCategory
    @State private var preferredUnit: FoodMeasurementUnit
    @State private var caloriesText: String
    @State private var proteinText: String
    @State private var fatText: String
    @State private var carbsText: String
    @State private var fiberText: String
    @State private var isDangerousForDogs: Bool
    @State private var dangerNote: String
    @State private var isShowingDeleteAlert = false

    init(food: Food, onDelete: (() -> Void)? = nil) {
        self.food = food
        self.onDelete = onDelete
        _name = State(initialValue: food.name)
        _category = State(initialValue: food.category)
        _preferredUnit = State(initialValue: food.preferredUnit)
        _caloriesText = State(initialValue: Self.format(food.caloriesPer100g))
        _proteinText = State(initialValue: Self.format(food.proteinPer100g))
        _fatText = State(initialValue: Self.format(food.fatPer100g))
        _carbsText = State(initialValue: Self.format(food.carbsPer100g))
        _fiberText = State(initialValue: Self.format(food.fiberPer100g))
        _isDangerousForDogs = State(initialValue: food.isDangerousForDogs)
        _dangerNote = State(initialValue: food.dangerNote)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Ingrediens") {
                    TextField("Namn", text: $name)
                    Picker("Kategori", selection: $category) {
                        ForEach(FoodCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    Picker("Föredragen enhet", selection: $preferredUnit) {
                        ForEach(FoodMeasurementUnit.allCases, id: \.self) { unit in
                            Text(unit.displayName + " (\(unit.rawValue))").tag(unit)
                        }
                    }
                }

                Section("Näringsvärden per \(preferredUnit.rawValue)") {
                    LabeledContent("Kalorier (kcal)") {
                        TextField("Kalorier (kcal)", text: $caloriesText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Protein (g)") {
                        TextField("Protein (g)", text: $proteinText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Fett (g)") {
                        TextField("Fett (g)", text: $fatText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Kolhydrater (g)") {
                        TextField("Kolhydrater (g)", text: $carbsText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    LabeledContent("Fiber (g)") {
                        TextField("Fiber (g)", text: $fiberText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section("Säkerhet") {
                    Toggle("Markera som farlig för hund", isOn: $isDangerousForDogs)

                    if isDangerousForDogs {
                        TextField("Varningstext", text: $dangerNote, axis: .vertical)
                    }
                }

                if food.isCustom {
                    Section("Hantera") {
                        if canDeleteFood {
                            Button(role: .destructive) {
                                isShowingDeleteAlert = true
                            } label: {
                                Label("Ta bort ingrediens", systemImage: "trash")
                            }
                        } else {
                            Label("Ingrediensen används i recept eller måltider och kan inte tas bort ännu.", systemImage: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                        }
                    }
                }
            }
            .navigationTitle("Redigera ingrediens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        saveChanges()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Ta bort ingrediens?", isPresented: $isShowingDeleteAlert) {
                Button("Ta bort", role: .destructive) {
                    deleteFood()
                }
                Button("Avbryt", role: .cancel) {}
            } message: {
                Text("Ingrediensen tas bort från databasen. Recept och måltider som använder den kan förlora sin koppling.")
            }
        }
    }

    private var isFormValid: Bool {
        food.isCustom &&
        !trimmedName.isEmpty &&
        parsedValue(from: caloriesText) != nil &&
        parsedValue(from: proteinText) != nil &&
        parsedValue(from: fatText) != nil &&
        parsedValue(from: carbsText) != nil &&
        parsedValue(from: fiberText) != nil &&
        (!isDangerousForDogs || !trimmedDangerNote.isEmpty)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedDangerNote: String {
        dangerNote.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var recipeUsageCount: Int {
        recipes.reduce(0) { count, recipe in
            count + recipe.items.filter { $0.food?.persistentModelID == food.persistentModelID }.count
        }
    }

    private var mealUsageCount: Int {
        meals.reduce(0) { count, meal in
            count + meal.items.filter { $0.food?.persistentModelID == food.persistentModelID }.count
        }
    }

    private var canDeleteFood: Bool {
        recipeUsageCount == 0 && mealUsageCount == 0
    }

    private func saveChanges() {
        guard
            food.isCustom,
            let calories = parsedValue(from: caloriesText),
            let protein = parsedValue(from: proteinText),
            let fat = parsedValue(from: fatText),
            let carbs = parsedValue(from: carbsText),
            let fiber = parsedValue(from: fiberText),
            !trimmedName.isEmpty,
            !isDangerousForDogs || !trimmedDangerNote.isEmpty
        else {
            return
        }

        food.name = trimmedName
        food.category = category
        food.preferredUnit = preferredUnit
        food.caloriesPer100g = calories
        food.proteinPer100g = protein
        food.fatPer100g = fat
        food.carbsPer100g = carbs
        food.fiberPer100g = fiber
        food.isDangerousForDogs = isDangerousForDogs
        food.dangerNote = trimmedDangerNote

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not save food changes: \(error)")
        }

        dismiss()
    }

    private func deleteFood() {
        guard food.isCustom, canDeleteFood else { return }

        modelContext.delete(food)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not delete food: \(error)")
        }

        dismiss()
        onDelete?()
    }

    private func parsedValue(from text: String) -> Double? {
        let normalized = text.replacingOccurrences(of: ",", with: ".")
        guard let value = Double(normalized), value >= 0 else {
            return nil
        }
        return value
    }

    private static func format(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }
}
