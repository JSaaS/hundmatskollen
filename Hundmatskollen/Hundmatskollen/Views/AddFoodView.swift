import SwiftUI
import SwiftData

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var category: FoodCategory = .other
    @State private var caloriesText = ""
    @State private var proteinText = ""
    @State private var fatText = ""
    @State private var carbsText = ""
    @State private var fiberText = ""

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
                }

                Section("Näringsvärden per 100 g") {
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
        parsedValue(from: fiberText) != nil
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func saveFood() {
        guard
            let calories = parsedValue(from: caloriesText),
            let protein = parsedValue(from: proteinText),
            let fat = parsedValue(from: fatText),
            let carbs = parsedValue(from: carbsText),
            let fiber = parsedValue(from: fiberText),
            !trimmedName.isEmpty
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
            isCustom: true
        )
        modelContext.insert(food)
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
