import SwiftUI
import SwiftData

extension Food {
    var pickerTitle: String {
        if isCustom {
            return "\(category.icon) \(name) • Egen"
        }

        return "\(category.icon) \(name)"
    }
}

struct FoodRowLabel: View {
    let food: Food

    var body: some View {
        HStack(spacing: 8) {
            Text(food.category.icon)
            Text(food.name)

            if food.isCustom {
                Image(systemName: "person.crop.circle.badge.plus")
                    .foregroundStyle(.orange)
            }
        }
    }
}

struct NutritionProgressRow: View {
    let title: String
    let consumedText: String
    let progress: Double
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                Text(consumedText)
                    .foregroundStyle(.secondary)
            }
            ProgressView(value: progress)
                .tint(tint)
        }
        .padding(.vertical, 4)
    }
}

struct FoodDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    let food: Food
    @State private var isPresentingEditFood = false
    @State private var mealDog: Dog?
    @State private var recipeDog: Dog?

    var body: some View {
        List {
            Section("Översikt") {
                LabeledContent("Kategori", value: food.category.rawValue)
                LabeledContent("Enhet", value: food.quantityLabel)
                if food.isCustom {
                    Label("Egen ingrediens", systemImage: "person.crop.circle.badge.plus")
                        .foregroundStyle(.orange)
                }
                LabeledContent("Kalorier", value: "\(Int(food.caloriesPer100g)) kcal / \(food.nutritionBasisLabel)")
                LabeledContent("Protein", value: "\(format(food.proteinPer100g)) g / \(food.nutritionBasisLabel)")
                LabeledContent("Fett", value: "\(format(food.fatPer100g)) g / \(food.nutritionBasisLabel)")
                LabeledContent("Kolhydrater", value: "\(format(food.carbsPer100g)) g / \(food.nutritionBasisLabel)")
                LabeledContent("Fiber", value: "\(format(food.fiberPer100g)) g / \(food.nutritionBasisLabel)")
            }

            if food.isDangerousForDogs {
                Section("Varning") {
                    Label(food.dangerNote, systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.red)
                }
            } else {
                Section("Bedömning") {
                    Label("Livsmedlet är inte markerat som farligt för hundar.", systemImage: "checkmark.shield")
                        .foregroundStyle(.green)
                }
            }

            Section("Använd ingrediens") {
                if dogs.isEmpty {
                    Text("Skapa en hundprofil innan du lägger till ingrediensen i måltid eller recept.")
                        .foregroundStyle(.secondary)
                } else if dogs.count == 1, let dog = dogs.first {
                    Button {
                        mealDog = dog
                    } label: {
                        Label("Lägg till i måltid", systemImage: "plus.circle")
                    }

                    Button {
                        recipeDog = dog
                    } label: {
                        Label("Lägg till i recept", systemImage: "book.closed")
                    }
                } else {
                    Menu {
                        ForEach(dogs) { dog in
                            Button(dog.name) {
                                mealDog = dog
                            }
                        }
                    } label: {
                        Label("Lägg till i måltid", systemImage: "plus.circle")
                    }

                    Menu {
                        ForEach(dogs) { dog in
                            Button(dog.name) {
                                recipeDog = dog
                            }
                        }
                    } label: {
                        Label("Lägg till i recept", systemImage: "book.closed")
                    }
                }
            }
        }
        .navigationTitle(food.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if food.isCustom {
                Button("Redigera") {
                    isPresentingEditFood = true
                }
            }
        }
        .sheet(isPresented: $isPresentingEditFood) {
            EditFoodView(food: food) {
                isPresentingEditFood = false
                dismiss()
            }
        }
        .sheet(item: $mealDog) { dog in
            AddMealView(dog: dog, initialFood: food)
        }
        .sheet(item: $recipeDog) { dog in
            AddRecipeView(dog: dog, initialFood: food)
        }
    }

    private func format(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value)
    }
}

struct WeekEntry: Identifiable {
    let date: Date
    let meals: [Meal]
    let plannedMeals: [PlannedMeal]
    let nutrition: DailyNutrition
    let progress: NutritionProgress

    var id: Date { date }
    var totalEntryCount: Int { meals.count + plannedMeals.count }
    var hasEntries: Bool { totalEntryCount > 0 }
}
