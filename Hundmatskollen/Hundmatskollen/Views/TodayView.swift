import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @Query(sort: \Meal.date, order: .reverse) private var meals: [Meal]
    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]
    @AppStorage(SettingsKeys.weightUnit) private var weightUnitRawValue = WeightDisplayUnit.kilograms.rawValue
    @AppStorage(SettingsKeys.volumeUnit) private var volumeUnitRawValue = VolumeDisplayUnit.milliliters.rawValue

    @State private var selectedDogID: PersistentIdentifier?
    @State private var isPresentingAddMeal = false
    @State private var selectedRecipe: Recipe?

    private var selectedDog: Dog? {
        if let selectedDogID {
            return dogs.first { $0.persistentModelID == selectedDogID } ?? dogs.first
        }

        return dogs.first
    }

    private var todayMeals: [Meal] {
        guard let selectedDog else { return [] }

        return meals.filter { meal in
            guard let mealDog = meal.dog else { return false }

            return mealDog.persistentModelID == selectedDog.persistentModelID &&
                Calendar.current.isDate(meal.date, inSameDayAs: Date())
        }
    }

    private var selectedDogRecipes: [Recipe] {
        guard let selectedDog else { return [] }

        return recipes.filter { recipe in
            guard let dog = recipe.dog else { return false }
            return dog.persistentModelID == selectedDog.persistentModelID
        }
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

                        Section("Summering idag") {
                            NutritionProgressRow(
                                title: "Kalorier",
                                consumedText: "\(Int(todayNutrition.calories)) / \(Int(selectedDog.dailyCalories)) kcal",
                                progress: todayProgress.calories,
                                tint: .orange
                            )
                            NutritionProgressRow(
                                title: "Protein",
                                consumedText: "\(DisplayFormatter.massText(fromGrams: todayNutrition.protein, unit: weightDisplayUnit)) / \(DisplayFormatter.massText(fromGrams: selectedDog.dailyProteinGrams, unit: weightDisplayUnit))",
                                progress: todayProgress.protein,
                                tint: .red
                            )
                            NutritionProgressRow(
                                title: "Fett",
                                consumedText: "\(DisplayFormatter.massText(fromGrams: todayNutrition.fat, unit: weightDisplayUnit)) / \(DisplayFormatter.massText(fromGrams: selectedDog.dailyFatGrams, unit: weightDisplayUnit))",
                                progress: todayProgress.fat,
                                tint: .yellow
                            )
                            NutritionProgressRow(
                                title: "Kolhydrater",
                                consumedText: "\(DisplayFormatter.massText(fromGrams: todayNutrition.carbs, unit: weightDisplayUnit)) / \(DisplayFormatter.massText(fromGrams: selectedDog.dailyCarbGrams, unit: weightDisplayUnit))",
                                progress: todayProgress.carbs,
                                tint: .green
                            )
                            NutritionProgressRow(
                                title: "Fiber",
                                consumedText: "\(DisplayFormatter.massText(fromGrams: todayNutrition.fiber, unit: weightDisplayUnit)) / \(DisplayFormatter.massText(fromGrams: selectedDog.dailyFiberGrams, unit: weightDisplayUnit))",
                                progress: todayProgress.fiber,
                                tint: .mint
                            )
                            NutritionProgressRow(
                                title: "Vätska",
                                consumedText: "\(DisplayFormatter.volumeText(fromMilliliters: todayNutrition.waterMl, unit: volumeDisplayUnit)) / \(DisplayFormatter.volumeText(fromMilliliters: selectedDog.dailyWaterMl, unit: volumeDisplayUnit))",
                                progress: todayProgress.water,
                                tint: .blue
                            )
                        }

                        if !selectedDogRecipes.isEmpty {
                            Section("Standardrecept") {
                                ForEach(selectedDogRecipes) { recipe in
                                    Button {
                                        selectedRecipe = recipe
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(recipe.name)
                                                    .font(.headline)
                                                    .foregroundStyle(.primary)
                                                Text("\(recipe.items.count) ingredienser · \(Int(recipe.totalCalories)) kcal")
                                                    .font(.subheadline)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Image(systemName: "plus.circle.fill")
                                                .foregroundStyle(.orange)
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        Section("Dagens måltider") {
                            if todayMeals.isEmpty {
                                ContentUnavailableView(
                                    "Inga måltider idag",
                                    systemImage: "fork.knife.circle",
                                    description: Text("Lägg till dagens första måltid för att börja följa näringsintaget.")
                                )
                            } else {
                                ForEach(todayMeals) { meal in
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text(meal.type.displayTitle)
                                                .font(.headline)
                                            Spacer()
                                            Text(meal.date.formatted(date: .omitted, time: .shortened))
                                                .foregroundStyle(.secondary)
                                        }

                                        ForEach(meal.items) { item in
                                            if let food = item.food {
                                                HStack {
                                                    Text(food.name)
                                                    Spacer()
                                                    Text("\(Int(item.grams)) \(food.quantityLabel)")
                                                        .foregroundStyle(.secondary)
                                                }
                                                .font(.subheadline)
                                            }
                                        }

                                        Text("\(Int(meal.totalCalories)) kcal")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)

                                        if meal.totalWaterMl > 0 {
                                            Text("\(DisplayFormatter.volumeText(fromMilliliters: meal.totalWaterMl, unit: volumeDisplayUnit)) vätska")
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }

                                        if !meal.notes.isEmpty {
                                            Text(meal.notes)
                                                .font(.footnote)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Ingen hund hittades",
                        systemImage: "pawprint",
                        description: Text("Skapa en hundprofil innan du loggar måltider.")
                    )
                }
            }
            .navigationTitle("Idag")
            .toolbar {
                if selectedDog != nil {
                    Button {
                        isPresentingAddMeal = true
                    } label: {
                        Label("Lägg till måltid", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isPresentingAddMeal) {
                if let selectedDog {
                    AddMealView(dog: selectedDog)
                }
            }
            .sheet(item: $selectedRecipe) { recipe in
                if let dog = recipe.dog {
                    AddMealView(dog: dog, initialRecipe: recipe)
                }
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

    private var todayNutrition: DailyNutrition {
        todayMeals.dailyNutrition()
    }

    private var todayProgress: NutritionProgress {
        guard let selectedDog else {
            return NutritionProgress(calories: 0, protein: 0, fat: 0, carbs: 0, fiber: 0, water: 0)
        }

        return todayNutrition.progress(for: selectedDog)
    }

    private var volumeDisplayUnit: VolumeDisplayUnit {
        VolumeDisplayUnit(rawValue: volumeUnitRawValue) ?? .milliliters
    }

    private var weightDisplayUnit: WeightDisplayUnit {
        WeightDisplayUnit(rawValue: weightUnitRawValue) ?? .kilograms
    }
}
