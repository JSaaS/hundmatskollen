import SwiftUI
import SwiftData

struct RecipesView: View {
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    @State private var selectedDogID: PersistentIdentifier?
    @State private var searchText = ""
    @State private var isPresentingAddRecipe = false
    @State private var isPresentingAddFood = false

    private var selectedDog: Dog? {
        if let selectedDogID {
            return dogs.first { $0.persistentModelID == selectedDogID } ?? dogs.first
        }

        return dogs.first
    }

    var body: some View {
        NavigationStack {
            Group {
                if let selectedDog {
                    List {
                        if dogs.count > 1 {
                            Section("Hund") {
                                Picker("Aktiv hund", selection: selectedDogBinding) {
                                    ForEach(dogs) { dog in
                                        Text(dog.name).tag(dog.persistentModelID)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                        }

                        Section("Databas") {
                            NavigationLink {
                                IngredientsView()
                            } label: {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ingrediensdatabas")
                                        .font(.headline)
                                    Text("Sök, bläddra och jämför ingredienser per kategori.")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }

                        Section("Standardrecept") {
                            if filteredRecipes.isEmpty {
                                ContentUnavailableView(
                                    searchText.isEmpty ? "Inga recept ännu" : "Inga träffar",
                                    systemImage: "book.closed",
                                    description: Text(searchText.isEmpty ? "Skapa ett standardrecept för \(selectedDog.name)." : "Prova ett annat sökord.")
                                )
                            } else {
                                ForEach(filteredRecipes) { recipe in
                                    NavigationLink {
                                        RecipeDetailView(recipe: recipe)
                                    } label: {
                                        RecipeRowView(recipe: recipe)
                                    }
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Ingen hund hittades",
                        systemImage: "book.closed",
                        description: Text("Skapa en hundprofil innan du bygger recept.")
                    )
                }
            }
            .navigationTitle("Recept")
            .searchable(text: $searchText, prompt: "Sök recept")
            .toolbar {
                if selectedDog != nil {
                    Menu {
                        Button {
                            isPresentingAddRecipe = true
                        } label: {
                            Label("Nytt recept", systemImage: "fork.knife")
                        }

                        Button {
                            isPresentingAddFood = true
                        } label: {
                            Label("Ny ingrediens", systemImage: "person.crop.circle.badge.plus")
                        }
                    } label: {
                        Label("Skapa", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddRecipe) {
                if let selectedDog {
                    AddRecipeView(dog: selectedDog)
                }
            }
            .sheet(isPresented: $isPresentingAddFood) {
                AddFoodView()
            }
        }
        .onAppear {
            if selectedDogID == nil {
                selectedDogID = dogs.first?.persistentModelID
            }
        }
    }

    private var selectedDogBinding: Binding<PersistentIdentifier> {
        Binding(
            get: { selectedDogID ?? dogs.first!.persistentModelID },
            set: { selectedDogID = $0 }
        )
    }

    private var filteredRecipes: [Recipe] {
        guard let selectedDog else { return [] }

        return recipes.filter { recipe in
            guard let dog = recipe.dog else { return false }

            return dog.persistentModelID == selectedDog.persistentModelID &&
                (searchText.isEmpty || recipe.name.localizedCaseInsensitiveContains(searchText))
        }
    }
}

struct RecipeRowView: View {
    let recipe: Recipe

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(recipe.name)
                    .font(.headline)
                Spacer()
                if recipe.dangerousItemCount > 0 {
                    Label("\(recipe.dangerousItemCount)", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Text("\(recipe.items.count) ingredienser · \(Int(recipe.totalGrams)) g · \(Int(recipe.totalCalories)) kcal")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if !recipe.notes.isEmpty {
                Text(recipe.notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecipeDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let recipe: Recipe
    @State private var isPresentingAddMeal = false

    var body: some View {
        List {
            Section("Översikt") {
                LabeledContent("Totalt", value: "\(Int(recipe.totalGrams)) g")
                LabeledContent("Kalorier", value: "\(Int(recipe.totalCalories)) kcal")
                LabeledContent("Protein", value: "\(format(recipe.totalProtein)) g")
                LabeledContent("Fett", value: "\(format(recipe.totalFat)) g")
                LabeledContent("Kolhydrater", value: "\(format(recipe.totalCarbs)) g")
            }

            if recipe.dog != nil {
                Section("Använd recept") {
                    Button {
                        isPresentingAddMeal = true
                    } label: {
                        Label("Skapa måltid från recept", systemImage: "plus.circle.fill")
                    }
                }
            }

            Section("Ingredienser") {
                ForEach(recipe.items) { item in
                    if let food = item.food {
                        NavigationLink {
                            FoodDetailView(food: food)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("\(food.category.icon) \(food.name)")
                                    Spacer()
                                    Text("\(Int(item.grams)) g")
                                        .foregroundStyle(.secondary)
                                }

                                Text("\(Int(item.calories)) kcal · Protein \(format(item.protein)) g · Fett \(format(item.fat)) g")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)

                                if food.isDangerousForDogs {
                                    Label(food.dangerNote, systemImage: "exclamationmark.triangle.fill")
                                        .font(.footnote)
                                        .foregroundStyle(.red)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .onDelete(perform: deleteItems)
            }

            if !recipe.notes.isEmpty {
                Section("Anteckningar") {
                    Text(recipe.notes)
                }
            }
        }
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingAddMeal) {
            if let dog = recipe.dog {
                AddMealView(dog: dog, initialRecipe: recipe)
            }
        }
    }

    private func format(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value)
    }

    private func deleteItems(at offsets: IndexSet) {
        let itemsToDelete = offsets.map { recipe.items[$0] }

        for item in itemsToDelete {
            recipe.items.removeAll { $0.persistentModelID == item.persistentModelID }
            modelContext.delete(item)
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not delete recipe item: \(error)")
        }
    }
}

struct AddRecipeView: View {
    struct DraftRecipeItem: Identifiable {
        let id = UUID()
        var selectedFoodIndex = 0
        var gramsText = ""
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Food.name) private var foods: [Food]

    let dog: Dog

    @State private var name = ""
    @State private var notes = ""
    @State private var draftItems: [DraftRecipeItem] = []
    @State private var isPresentingAddFood = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Recept") {
                    TextField("Namn på recept", text: $name)
                    TextField("Anteckningar", text: $notes, axis: .vertical)
                }

                Section("Ingredienser") {
                    if foods.isEmpty {
                        Text("Ingen ingrediensdatabas tillgänglig ännu.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach($draftItems) { $item in
                            VStack(alignment: .leading, spacing: 12) {
                                Picker("Ingrediens", selection: $item.selectedFoodIndex) {
                                    ForEach(Array(foods.indices), id: \.self) { index in
                                        let food = foods[index]
                                        Text(food.pickerTitle).tag(index)
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

                        Button {
                            isPresentingAddFood = true
                        } label: {
                            Label("Skapa egen ingrediens", systemImage: "person.crop.circle.badge.plus")
                        }
                    }
                }

                Section("Sammanfattning") {
                    if validDraftItems.isEmpty {
                        Text("Lägg till ingredienser för att se receptets näringsvärden.")
                            .foregroundStyle(.secondary)
                    } else {
                        LabeledContent("Totalt", value: "\(Int(totalGrams)) g")
                        LabeledContent("Kalorier", value: "\(Int(totalCalories)) kcal")
                        LabeledContent("Protein", value: "\(format(totalProtein)) g")
                        LabeledContent("Fett", value: "\(format(totalFat)) g")
                        LabeledContent("Kolhydrater", value: "\(format(totalCarbs)) g")
                    }
                }
            }
            .navigationTitle("Nytt recept")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        saveRecipe()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || validDraftItems.isEmpty)
                }
            }
        }
        .sheet(isPresented: $isPresentingAddFood) {
            AddFoodView()
        }
        .onAppear {
            if draftItems.isEmpty && !foods.isEmpty {
                addDraftItem()
            }
        }
    }

    private var validDraftItems: [DraftRecipeItem] {
        draftItems.filter { item in
            selectedFood(for: item) != nil && parsedGrams(from: item.gramsText) > 0
        }
    }

    private var totalCalories: Double {
        validDraftItems.reduce(0) { partialResult, item in
            guard let food = selectedFood(for: item) else { return partialResult }
            return partialResult + food.calories(forGrams: parsedGrams(from: item.gramsText))
        }
    }

    private var totalProtein: Double {
        validDraftItems.reduce(0) { partialResult, item in
            guard let food = selectedFood(for: item) else { return partialResult }
            return partialResult + food.protein(forGrams: parsedGrams(from: item.gramsText))
        }
    }

    private var totalFat: Double {
        validDraftItems.reduce(0) { partialResult, item in
            guard let food = selectedFood(for: item) else { return partialResult }
            return partialResult + food.fat(forGrams: parsedGrams(from: item.gramsText))
        }
    }

    private var totalCarbs: Double {
        validDraftItems.reduce(0) { partialResult, item in
            guard let food = selectedFood(for: item) else { return partialResult }
            return partialResult + food.carbs(forGrams: parsedGrams(from: item.gramsText))
        }
    }

    private var totalGrams: Double {
        validDraftItems.reduce(0) { $0 + parsedGrams(from: $1.gramsText) }
    }

    private func addDraftItem() {
        draftItems.append(DraftRecipeItem())
    }

    private func removeItems(at offsets: IndexSet) {
        draftItems.remove(atOffsets: offsets)
    }

    private func saveRecipe() {
        let recipe = Recipe(
            dog: dog,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            notes: notes.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        for item in validDraftItems {
            guard let food = selectedFood(for: item) else { continue }

            let recipeItem = RecipeItem(food: food, grams: parsedGrams(from: item.gramsText))
            modelContext.insert(recipeItem)
            recipe.items.append(recipeItem)
        }

        modelContext.insert(recipe)

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not save recipe: \(error)")
        }

        dismiss()
    }

    private func selectedFood(for item: DraftRecipeItem) -> Food? {
        guard foods.indices.contains(item.selectedFoodIndex) else { return nil }
        return foods[item.selectedFoodIndex]
    }

    private func parsedGrams(from text: String) -> Double {
        Double(text.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private func format(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value)
    }
}
