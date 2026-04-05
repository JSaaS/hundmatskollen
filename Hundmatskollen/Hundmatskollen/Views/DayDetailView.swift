import SwiftUI
import SwiftData

struct DayDetailView: View {
    @Query(sort: \Meal.date, order: .forward) private var meals: [Meal]
    @Query(sort: \PlannedMeal.scheduledDate, order: .forward) private var plannedMeals: [PlannedMeal]

    let dog: Dog
    let date: Date

    @State private var isPresentingAddMeal = false
    @State private var isPresentingPlannedMealEditor = false
    @State private var plannedMealToEdit: PlannedMeal?

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.locale = Locale(identifier: "sv_SE")
        calendar.timeZone = .current
        return calendar
    }

    private var dayMeals: [Meal] {
        meals.filter { meal in
            guard let mealDog = meal.dog else { return false }
            return mealDog.persistentModelID == dog.persistentModelID &&
                calendar.isDate(meal.date, inSameDayAs: date)
        }
    }

    private var dayPlannedMeals: [PlannedMeal] {
        plannedMeals.filter { plannedMeal in
            guard let plannedDog = plannedMeal.dog else { return false }
            return plannedDog.persistentModelID == dog.persistentModelID &&
                calendar.isDate(plannedMeal.scheduledDate, inSameDayAs: date)
        }
    }

    private var nutrition: DailyNutrition {
        dayMeals.dailyNutrition()
    }

    private var progress: NutritionProgress {
        nutrition.progress(for: dog)
    }

    private var plannedRecipeMeals: [PlannedMeal] {
        dayPlannedMeals.filter { $0.recipe != nil }
    }

    private var uncountedPlannedMeals: [PlannedMeal] {
        dayPlannedMeals.filter { $0.recipe == nil }
    }

    private var plannedNutrition: DailyNutrition {
        plannedRecipeMeals.reduce(into: DailyNutrition()) { result, plannedMeal in
            guard let recipe = plannedMeal.recipe else { return }
            result.calories += recipe.totalCalories
            result.protein += recipe.totalProtein
            result.fat += recipe.totalFat
            result.carbs += recipe.totalCarbs
            result.fiber += recipe.totalFiber
            result.waterMl += recipe.totalWaterMl
        }
    }

    private var deltaToPlan: DailyNutrition {
        DailyNutrition(
            calories: nutrition.calories - plannedNutrition.calories,
            protein: nutrition.protein - plannedNutrition.protein,
            fat: nutrition.fat - plannedNutrition.fat,
            carbs: nutrition.carbs - plannedNutrition.carbs,
            fiber: nutrition.fiber - plannedNutrition.fiber,
            waterMl: nutrition.waterMl - plannedNutrition.waterMl
        )
    }

    var body: some View {
        List {
            Section("Översikt") {
                LabeledContent("Hund", value: dog.name)
                LabeledContent("Datum", value: date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                LabeledContent("Planerade mål", value: "\(dayPlannedMeals.count)")
                LabeledContent("Loggade mål", value: "\(dayMeals.count)")
                if !dayPlannedMeals.isEmpty {
                    LabeledContent("Återstår", value: "\(max(dayPlannedMeals.count - dayMeals.count, 0))")
                }
            }

            Section("Faktiskt idag") {
                NutritionProgressRow(
                    title: "Kalorier",
                    consumedText: "\(Int(nutrition.calories)) / \(Int(dog.dailyCalories)) kcal",
                    progress: progress.calories,
                    tint: .orange
                )
                NutritionProgressRow(
                    title: "Protein",
                    consumedText: "\(Int(nutrition.protein)) / \(Int(dog.dailyProteinGrams)) g",
                    progress: progress.protein,
                    tint: .red
                )
                NutritionProgressRow(
                    title: "Fett",
                    consumedText: "\(Int(nutrition.fat)) / \(Int(dog.dailyFatGrams)) g",
                    progress: progress.fat,
                    tint: .yellow
                )
                NutritionProgressRow(
                    title: "Kolhydrater",
                    consumedText: "\(Int(nutrition.carbs)) / \(Int(dog.dailyCarbGrams)) g",
                    progress: progress.carbs,
                    tint: .green
                )
                NutritionProgressRow(
                    title: "Fiber",
                    consumedText: "\(Int(nutrition.fiber)) / \(Int(dog.dailyFiberGrams)) g",
                    progress: progress.fiber,
                    tint: .mint
                )
                NutritionProgressRow(
                    title: "Vätska",
                    consumedText: "\(Int(nutrition.waterMl)) / \(Int(dog.dailyWaterMl)) ml",
                    progress: progress.water,
                    tint: .blue
                )
            }

            if !dayPlannedMeals.isEmpty {
                Section("Planerat idag") {
                    LabeledContent("Kalorier", value: "\(Int(plannedNutrition.calories)) kcal")
                    LabeledContent("Protein", value: "\(Int(plannedNutrition.protein)) g")
                    LabeledContent("Fett", value: "\(Int(plannedNutrition.fat)) g")
                    LabeledContent("Kolhydrater", value: "\(Int(plannedNutrition.carbs)) g")
                    LabeledContent("Fiber", value: "\(Int(plannedNutrition.fiber)) g")
                    LabeledContent("Vätska", value: "\(Int(plannedNutrition.waterMl)) ml")

                    if !uncountedPlannedMeals.isEmpty {
                        Label(
                            "\(uncountedPlannedMeals.count) fria planerade mål saknar näringsberäkning.",
                            systemImage: "info.circle"
                        )
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }

                Section("Skillnad mot plan") {
                    DifferenceRow(
                        title: "Kalorier",
                        valueText: signedText(for: deltaToPlan.calories, unit: "kcal"),
                        valueColor: differenceColor(for: deltaToPlan.calories)
                    )
                    DifferenceRow(
                        title: "Protein",
                        valueText: signedText(for: deltaToPlan.protein, unit: "g"),
                        valueColor: differenceColor(for: deltaToPlan.protein)
                    )
                    DifferenceRow(
                        title: "Fett",
                        valueText: signedText(for: deltaToPlan.fat, unit: "g"),
                        valueColor: differenceColor(for: deltaToPlan.fat)
                    )
                    DifferenceRow(
                        title: "Kolhydrater",
                        valueText: signedText(for: deltaToPlan.carbs, unit: "g"),
                        valueColor: differenceColor(for: deltaToPlan.carbs)
                    )
                    DifferenceRow(
                        title: "Fiber",
                        valueText: signedText(for: deltaToPlan.fiber, unit: "g"),
                        valueColor: differenceColor(for: deltaToPlan.fiber)
                    )
                    DifferenceRow(
                        title: "Vätska",
                        valueText: signedText(for: deltaToPlan.waterMl, unit: "ml"),
                        valueColor: differenceColor(for: deltaToPlan.waterMl)
                    )
                }
            }

            Section("Åtgärder") {
                Button {
                    plannedMealToEdit = nil
                    isPresentingPlannedMealEditor = true
                } label: {
                    Label("Planera mål", systemImage: "calendar.badge.plus")
                }

                Button {
                    isPresentingAddMeal = true
                } label: {
                    Label("Registrera måltid", systemImage: "plus.circle")
                }
            }

            Section("Planerade mål") {
                if dayPlannedMeals.isEmpty {
                    Text("Inga planerade mål för den här dagen.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dayPlannedMeals) { plannedMeal in
                        Button {
                            plannedMealToEdit = plannedMeal
                            isPresentingPlannedMealEditor = true
                        } label: {
                            PlannedMealSummaryRow(plannedMeal: plannedMeal)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Loggade måltider") {
                if dayMeals.isEmpty {
                    Text("Inga registrerade måltider för den här dagen.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(dayMeals) { meal in
                        LoggedMealSummaryView(meal: meal)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle(date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isPresentingAddMeal) {
            AddMealView(
                dog: dog,
                initialDate: defaultRegistrationDate
            )
        }
        .sheet(isPresented: $isPresentingPlannedMealEditor) {
            PlannedMealEditorView(
                dog: dog,
                initialDate: defaultRegistrationDate,
                plannedMeal: plannedMealToEdit
            )
        }
    }

    private var defaultRegistrationDate: Date {
        if calendar.isDateInToday(date) {
            return Date()
        }

        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) ?? date
    }

    private func signedText(for value: Double, unit: String) -> String {
        let roundedValue = Int(value.rounded())
        if roundedValue > 0 {
            return "+\(roundedValue) \(unit)"
        }
        return "\(roundedValue) \(unit)"
    }

    private func differenceColor(for value: Double) -> Color {
        let roundedValue = Int(value.rounded())
        if roundedValue == 0 {
            return .secondary
        }
        return roundedValue > 0 ? .green : .orange
    }
}

struct PlannedMealEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \Recipe.createdAt, order: .reverse) private var recipes: [Recipe]

    let dog: Dog
    let initialDate: Date
    let plannedMeal: PlannedMeal?

    @State private var scheduledDate: Date
    @State private var mealType: MealType
    @State private var title: String
    @State private var notes: String
    @State private var selectedRecipeID: PersistentIdentifier?
    @State private var isPresentingDeleteConfirmation = false
    @State private var hasCustomizedTime = false
    @State private var isApplyingSuggestedTime = false

    init(dog: Dog, initialDate: Date, plannedMeal: PlannedMeal?) {
        self.dog = dog
        self.initialDate = initialDate
        self.plannedMeal = plannedMeal
        let initialMealType = plannedMeal?.type ?? .dinner
        let initialScheduledDate = plannedMeal?.scheduledDate ?? initialMealType.suggestedDate(on: initialDate)
        _scheduledDate = State(initialValue: initialScheduledDate)
        _mealType = State(initialValue: initialMealType)
        _title = State(initialValue: plannedMeal?.recipe == nil ? (plannedMeal?.title ?? "") : "")
        _notes = State(initialValue: plannedMeal?.notes ?? "")
        _selectedRecipeID = State(initialValue: plannedMeal?.recipe?.persistentModelID)
    }

    private var availableRecipes: [Recipe] {
        recipes.filter { recipe in
            recipe.dog?.persistentModelID == dog.persistentModelID
        }
    }

    private var selectedRecipe: Recipe? {
        guard let selectedRecipeID else { return nil }
        return availableRecipes.first { $0.persistentModelID == selectedRecipeID }
    }

    private var canSave: Bool {
        selectedRecipe != nil || !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Planering") {
                    DatePicker("Tid", selection: scheduledDateBinding, displayedComponents: [.date, .hourAndMinute])

                    Picker("Typ", selection: $mealType) {
                        ForEach(MealType.allCases, id: \.self) { type in
                            Text(type.displayTitle).tag(type)
                        }
                    }
                }

                Section("Innehåll") {
                    Picker("Recept", selection: $selectedRecipeID) {
                        Text("Eget mål").tag(Optional<PersistentIdentifier>.none)
                        ForEach(availableRecipes) { recipe in
                            Text(recipe.name).tag(Optional(recipe.persistentModelID))
                        }
                    }

                    if selectedRecipe == nil {
                        TextField("Namn på planerat mål", text: $title)
                    } else if let selectedRecipe {
                        LabeledContent("Valt recept", value: selectedRecipe.name)
                    }

                    TextField("Anteckning", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                if plannedMeal != nil {
                    Section("Hantera") {
                        Button(role: .destructive) {
                            isPresentingDeleteConfirmation = true
                        } label: {
                            Label("Ta bort planerat mål", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle(plannedMeal == nil ? "Planera mål" : "Redigera plan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Avbryt") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Spara") {
                        savePlannedMeal()
                    }
                    .disabled(!canSave)
                }
            }
            .alert("Ta bort planerat mål?", isPresented: $isPresentingDeleteConfirmation) {
                Button("Avbryt", role: .cancel) {}
                Button("Ta bort", role: .destructive) {
                    deletePlannedMeal()
                }
            } message: {
                Text("Det planerade målet tas bort från veckovyn.")
            }
        }
        .onChange(of: mealType) { _, newType in
            guard !hasCustomizedTime else { return }
            applySuggestedTime(for: newType, on: scheduledDate)
        }
    }

    private func savePlannedMeal() {
        let meal = plannedMeal ?? PlannedMeal(dog: dog, scheduledDate: scheduledDate)
        meal.dog = dog
        meal.scheduledDate = scheduledDate
        meal.type = mealType
        meal.recipe = selectedRecipe
        meal.title = selectedRecipe == nil ? title.trimmingCharacters(in: .whitespacesAndNewlines) : ""
        meal.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        if plannedMeal == nil {
            modelContext.insert(meal)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            assertionFailure("Kunde inte spara planerat mål: \(error)")
        }
    }

    private func deletePlannedMeal() {
        guard let plannedMeal else { return }

        modelContext.delete(plannedMeal)

        do {
            try modelContext.save()
            dismiss()
        } catch {
            assertionFailure("Kunde inte ta bort planerat mål: \(error)")
        }
    }

    private func applySuggestedTime(for mealType: MealType, on baseDate: Date) {
        isApplyingSuggestedTime = true
        scheduledDate = mealType.suggestedDate(on: baseDate)
        isApplyingSuggestedTime = false
    }

    private var scheduledDateBinding: Binding<Date> {
        Binding(
            get: { scheduledDate },
            set: { newValue in
                scheduledDate = newValue

                if !isApplyingSuggestedTime {
                    hasCustomizedTime = true
                }
            }
        )
    }
}

private struct PlannedMealSummaryRow: View {
    let plannedMeal: PlannedMeal

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .foregroundStyle(.blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(plannedMeal.displayTitle)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Text(plannedMeal.scheduledDate.formatted(date: .omitted, time: .shortened))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(plannedMeal.sourceLabel)
                    .font(.caption)
                    .foregroundStyle(.blue)

                if !plannedMeal.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(plannedMeal.notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
    }
}

private struct LoggedMealSummaryView: View {
    let meal: Meal

    var body: some View {
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
                Text("\(Int(meal.totalWaterMl)) ml vätska")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if !meal.notes.isEmpty {
                Text(meal.notes)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct DifferenceRow: View {
    let title: String
    let valueText: String
    let valueColor: Color

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(valueText)
                .foregroundStyle(valueColor)
        }
    }
}
