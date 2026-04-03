import SwiftUI
import SwiftData

struct AddMealView: View {
    struct DraftMealItem: Identifiable {
        let id = UUID()
        var selectedFoodIndex = 0
        var gramsText = ""
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Food.name) private var foods: [Food]

    let dog: Dog
    private let initialDate: Date
    private let initialRecipe: Recipe?

    @State private var date: Date
    @State private var type: MealType = .dinner
    @State private var notes = ""
    @State private var draftItems: [DraftMealItem] = []

    init(dog: Dog, initialDate: Date = Date(), initialRecipe: Recipe? = nil) {
        self.dog = dog
        self.initialDate = initialDate
        self.initialRecipe = initialRecipe
        _date = State(initialValue: initialDate)
        _notes = State(initialValue: initialRecipe?.name ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Måltid") {
                    DatePicker("Tid", selection: $date, displayedComponents: [.date, .hourAndMinute])
                    Picker("Typ", selection: $type) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            Text(mealType.rawValue).tag(mealType)
                        }
                    }
                    TextField("Anteckningar", text: $notes, axis: .vertical)
                }

                Section("Ingredienser") {
                    if foods.isEmpty {
                        Text("Ingen matdatabas tillgänglig ännu.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach($draftItems) { $item in
                            VStack(alignment: .leading, spacing: 12) {
                                Picker("Livsmedel", selection: $item.selectedFoodIndex) {
                                    ForEach(Array(foods.indices), id: \.self) { index in
                                        let food = foods[index]
                                        Text("\(food.category.icon) \(food.name)").tag(index)
                                    }
                                }

                                TextField("Mängd (gram)", text: $item.gramsText)
                                    .keyboardType(.decimalPad)

                                if let food = selectedFood(for: item), food.isDangerousForDogs {
                                    Label(food.dangerNote, systemImage: "exclamationmark.triangle.fill")
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: removeItems)

                        Button {
                            addDraftItem()
                        } label: {
                            Label("Lägg till ingrediens", systemImage: "plus.circle")
                        }
                    }
                }
            }
            .navigationTitle("Ny måltid")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        saveMeal()
                    }
                    .disabled(validDraftItems.isEmpty)
                }
            }
        }
        .onAppear {
            date = initialDate

            if draftItems.isEmpty && !foods.isEmpty {
                populateDraftItems()
            }
        }
    }

    private var validDraftItems: [DraftMealItem] {
        draftItems.filter { item in
            selectedFood(for: item) != nil && parsedGrams(from: item.gramsText) > 0
        }
    }

    private func addDraftItem() {
        draftItems.append(DraftMealItem())
    }

    private func populateDraftItems() {
        if let initialRecipe {
            let recipeDraftItems = initialRecipe.items.compactMap { item -> DraftMealItem? in
                guard
                    let food = item.food,
                    let index = foods.firstIndex(where: { $0.persistentModelID == food.persistentModelID })
                else {
                    return nil
                }

                var draftItem = DraftMealItem()
                draftItem.selectedFoodIndex = index
                draftItem.gramsText = formatGrams(item.grams)
                return draftItem
            }

            if !recipeDraftItems.isEmpty {
                draftItems = recipeDraftItems
                return
            }
        }

        addDraftItem()
    }

    private func removeItems(at offsets: IndexSet) {
        draftItems.remove(atOffsets: offsets)
    }

    private func saveMeal() {
        let meal = Meal(dog: dog, date: date, type: type, notes: notes.trimmingCharacters(in: .whitespacesAndNewlines))

        for item in validDraftItems {
            guard let food = selectedFood(for: item) else { continue }

            let mealItem = MealItem(food: food, grams: parsedGrams(from: item.gramsText))
            modelContext.insert(mealItem)
            meal.items.append(mealItem)
        }

        modelContext.insert(meal)
        dismiss()
    }

    private func selectedFood(for item: DraftMealItem) -> Food? {
        guard foods.indices.contains(item.selectedFoodIndex) else { return nil }
        return foods[item.selectedFoodIndex]
    }

    private func parsedGrams(from text: String) -> Double {
        Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func formatGrams(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }
}
