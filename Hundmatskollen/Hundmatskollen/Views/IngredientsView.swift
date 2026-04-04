import SwiftUI
import SwiftData

struct IngredientsView: View {
    @Query(sort: \Food.name) private var foods: [Food]

    @State private var searchText = ""
    @State private var isPresentingAddFood = false

    var body: some View {
        List {
            if filteredFoods.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "Inga ingredienser" : "Inga träffar",
                    systemImage: "carrot",
                    description: Text(searchText.isEmpty ? "Lägg till en ingrediens för att börja bygga din databas." : "Prova ett annat sökord.")
                )
            } else {
                ForEach(sectionedFoods) { section in
                    Section(section.category.rawValue) {
                        ForEach(section.foods) { food in
                            NavigationLink {
                                FoodDetailView(food: food)
                            } label: {
                                IngredientRowView(food: food)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Ingredienser")
        .searchable(text: $searchText, prompt: "Sök ingrediens")
        .searchSuggestions {
            ForEach(searchSuggestions) { food in
                Text(food.name)
                    .searchCompletion(food.name)
            }
        }
        .toolbar {
            Button {
                isPresentingAddFood = true
            } label: {
                Label("Ny ingrediens", systemImage: "plus")
            }
        }
        .sheet(isPresented: $isPresentingAddFood) {
            AddFoodView()
        }
    }

    private var filteredFoods: [Food] {
        guard !searchText.isEmpty else { return foods }

        return foods.filter { food in
            food.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    private var searchSuggestions: [Food] {
        guard !searchText.isEmpty else { return [] }

        return foods.filter { food in
            food.name.localizedCaseInsensitiveContains(searchText) &&
            food.name.localizedCaseInsensitiveCompare(searchText) != .orderedSame
        }
        .prefix(5)
        .map { $0 }
    }

    private var sectionedFoods: [IngredientSection] {
        FoodCategory.allCases.compactMap { category in
            let foodsInCategory = filteredFoods.filter { $0.category == category }
            guard !foodsInCategory.isEmpty else { return nil }
            return IngredientSection(category: category, foods: foodsInCategory)
        }
    }
}

private struct IngredientSection: Identifiable {
    let category: FoodCategory
    let foods: [Food]

    var id: FoodCategory { category }
}

private struct IngredientRowView: View {
    let food: Food

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Text(food.category.icon)
                Text(food.name)
                    .font(.headline)

                if food.isCustom {
                    Label("Egen", systemImage: "person.crop.circle.badge.plus")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Text(food.quantityLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                if food.isDangerousForDogs {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            }

            Text("\(Int(food.caloriesPer100g)) kcal · P \(format(food.proteinPer100g)) g · F \(format(food.fatPer100g)) g · K \(format(food.carbsPer100g)) g / \(food.nutritionBasisLabel)")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if food.isDangerousForDogs, !food.dangerNote.isEmpty {
                Text(food.dangerNote)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }

    private func format(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value)
    }
}
