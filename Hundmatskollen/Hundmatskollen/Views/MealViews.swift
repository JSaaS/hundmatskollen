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
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    let dog: Dog
    private let initialDate: Date
    private let initialRecipe: Recipe?

    @State private var date: Date
    @State private var type: MealType = .dinner
    @State private var notes = ""
    @State private var waterText = ""
    @State private var draftItems: [DraftMealItem] = []
    @State private var isPresentingAddFood = false
    @State private var hasCustomizedTime = false
    @State private var isApplyingSuggestedTime = false

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
                    DatePicker("Tid", selection: dateBinding, displayedComponents: [.date, .hourAndMinute])
                    Picker("Typ", selection: $type) {
                        ForEach(MealType.allCases, id: \.self) { mealType in
                            Text(mealType.displayTitle).tag(mealType)
                        }
                    }
                    TextField("Vätska (ml)", text: $waterText)
                        .keyboardType(.decimalPad)
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
                                        Text(food.pickerTitle).tag(index)
                                    }
                                }

                                TextField(quantityFieldLabel(for: item), text: $item.gramsText)
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

                        Button {
                            isPresentingAddFood = true
                        } label: {
                            Label("Skapa egen ingrediens", systemImage: "person.crop.circle.badge.plus")
                        }
                    }

                    if parsedAmount(from: waterText) > 0 {
                        Text("Du kan spara en registrering med bara vätska även utan ingredienser.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                if !availableRecipes.isEmpty {
                    Section("Recept") {
                        Text("Välj ett recept för att fylla i ingredienserna automatiskt.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)

                        ForEach(availableRecipes) { recipe in
                            Button {
                                applyRecipe(recipe)
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(recipe.name)
                                            .foregroundStyle(.primary)
                                        Text("\(recipe.items.count) ingredienser · \(Int(recipe.totalCalories)) kcal")
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "arrow.down.circle")
                                        .foregroundStyle(.orange)
                                }
                            }
                            .buttonStyle(.plain)
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
                    .disabled(validDraftItems.isEmpty && parsedAmount(from: waterText) <= 0)
                }
            }
        }
        .sheet(isPresented: $isPresentingAddFood) {
            AddFoodView()
        }
        .onAppear {
            applySuggestedTime(for: type, on: initialDate)

            if draftItems.isEmpty && !foods.isEmpty {
                populateDraftItems()
            }
        }
        .onChange(of: type) { _, newType in
            guard !hasCustomizedTime else { return }
            applySuggestedTime(for: newType, on: date)
        }
    }

    private var validDraftItems: [DraftMealItem] {
        draftItems.filter { item in
            selectedFood(for: item) != nil && parsedGrams(from: item.gramsText) > 0
        }
    }

    private var availableRecipes: [Recipe] {
        recipes.filter { recipe in
            guard let recipeDog = recipe.dog else { return false }
            return recipeDog.persistentModelID == dog.persistentModelID
        }
    }

    private func addDraftItem() {
        draftItems.append(DraftMealItem())
    }

    private func applyRecipe(_ recipe: Recipe) {
        let recipeDraftItems = recipe.items.compactMap { item -> DraftMealItem? in
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

        guard !recipeDraftItems.isEmpty else { return }

        draftItems = recipeDraftItems
        if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            notes = recipe.name
        }
    }

    private func populateDraftItems() {
        if let initialRecipe {
            applyRecipe(initialRecipe)

            if !draftItems.isEmpty {
                return
            }
        }

        addDraftItem()
    }

    private func removeItems(at offsets: IndexSet) {
        draftItems.remove(atOffsets: offsets)
    }

    private func saveMeal() {
        let meal = Meal(
            dog: dog,
            date: date,
            type: type,
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
            waterMl: parsedAmount(from: waterText)
        )

        for item in validDraftItems {
            guard let food = selectedFood(for: item) else { continue }

            let mealItem = MealItem(food: food, grams: parsedGrams(from: item.gramsText))
            modelContext.insert(mealItem)
            meal.items.append(mealItem)
        }

        modelContext.insert(meal)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not save meal: \(error)")
        }

        dismiss()
    }

    private func selectedFood(for item: DraftMealItem) -> Food? {
        guard foods.indices.contains(item.selectedFoodIndex) else { return nil }
        return foods[item.selectedFoodIndex]
    }

    private func quantityFieldLabel(for item: DraftMealItem) -> String {
        selectedFood(for: item)?.quantityFieldLabel ?? "Mängd"
    }

    private func parsedGrams(from text: String) -> Double {
        parsedAmount(from: text)
    }

    private func parsedAmount(from text: String) -> Double {
        Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func formatGrams(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }

    private func applySuggestedTime(for mealType: MealType, on baseDate: Date) {
        isApplyingSuggestedTime = true
        date = mealType.suggestedDate(on: baseDate)
        isApplyingSuggestedTime = false
    }

    private var dateBinding: Binding<Date> {
        Binding(
            get: { date },
            set: { newValue in
                date = newValue

                if !isApplyingSuggestedTime {
                    hasCustomizedTime = true
                }
            }
        )
    }
}
