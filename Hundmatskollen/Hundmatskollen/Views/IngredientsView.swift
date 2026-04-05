import SwiftUI
import SwiftData

struct IngredientsView: View {
    @Query(sort: \Food.name) private var foods: [Food]

    @State private var searchText = ""
    @State private var isPresentingAddFood = false
    @State private var selectedCategory: FoodCategory?

    var body: some View {
        List {
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryFilterChip(
                            title: "Alla",
                            systemImage: "square.grid.2x2",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        ForEach(FoodCategory.allCases, id: \.self) { category in
                            CategoryFilterChip(
                                title: category.rawValue,
                                iconText: category.icon,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 4, trailing: 16))
            }

            if filteredFoods.isEmpty {
                ContentUnavailableView(
                    searchText.isEmpty ? "Inga ingredienser" : "Inga träffar",
                    systemImage: "carrot",
                    description: Text(emptyStateDescription)
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
        foods.filter { food in
            let matchesCategory = selectedCategory.map { food.category == $0 } ?? true
            let matchesSearch = searchText.isEmpty || food.name.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
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

    private var emptyStateDescription: String {
        if searchText.isEmpty, let selectedCategory {
            return "Det finns inga ingredienser i kategorin \(selectedCategory.rawValue) ännu."
        }

        if !searchText.isEmpty, let selectedCategory {
            return "Prova ett annat sökord eller byt kategori från \(selectedCategory.rawValue)."
        }

        if searchText.isEmpty {
            return "Lägg till en ingrediens för att börja bygga din databas."
        }

        return "Prova ett annat sökord."
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

private struct CategoryFilterChip: View {
    let title: String
    var iconText: String?
    var systemImage: String?
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let iconText {
                    Text(iconText)
                }
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.orange : Color(.secondarySystemBackground))
            .foregroundStyle(isSelected ? Color.white : Color.primary)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
