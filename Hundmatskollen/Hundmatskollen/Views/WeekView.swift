import SwiftUI
import SwiftData

struct WeekView: View {
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @Query(sort: \Meal.date, order: .reverse) private var meals: [Meal]
    @Query(sort: \PlannedMeal.scheduledDate, order: .forward) private var plannedMeals: [PlannedMeal]

    @State private var selectedDogID: PersistentIdentifier?
    @State private var selectedRegistrationDate: Date?
    @State private var selectedDay = Date()
    @State private var isPresentingAddMeal = false
    @State private var isPresentingPlannedMealEditor = false
    @State private var displayedWeekAnchor = Date()
    @State private var plannedMealToEdit: PlannedMeal?

    private var selectedDog: Dog? {
        if let selectedDogID {
            return dogs.first { $0.persistentModelID == selectedDogID } ?? dogs.first
        }

        return dogs.first
    }

    var body: some View {
        NavigationStack {
            Group {
                if selectedDog != nil {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if dogs.count > 1 {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Hund")
                                        .font(.headline)
                                    Picker("Aktiv hund", selection: selectedDogBinding) {
                                        ForEach(dogs) { dog in
                                            Text(dog.name).tag(dog.persistentModelID)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                }
                            }

                            VStack(spacing: 12) {
                                HStack {
                                    Button {
                                        moveWeek(by: -1)
                                    } label: {
                                        Image(systemName: "chevron.left")
                                    }

                                    Spacer()

                                    VStack(spacing: 4) {
                                        Text("Vecka \(displayedWeekNumber)")
                                            .font(.headline)
                                        Text(displayedWeekRangeText)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button {
                                        moveWeek(by: 1)
                                    } label: {
                                        Image(systemName: "chevron.right")
                                    }
                                }
                                .buttonStyle(.plain)
                                LazyVGrid(columns: weekColumns, spacing: 8) {
                                    ForEach(weekEntries) { entry in
                                        Button {
                                            selectedDay = entry.date
                                        } label: {
                                            WeekCalendarDayCell(
                                                entry: entry,
                                                isSelected: isoCalendar.isDate(entry.date, inSameDayAs: selectedDay),
                                                isToday: isoCalendar.isDateInToday(entry.date),
                                                isFuture: entry.date > todayStartOfDay
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(selectedEntry?.date.formatted(.dateTime.weekday(.wide)) ?? "")
                                            .font(.headline)
                                        if let selectedEntry {
                                            Text(selectedEntry.date, format: .dateTime.day().month(.abbreviated))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    Spacer()
                                    Text(dayStatusText)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(dayStatusColor)
                                }

                                Button {
                                    plannedMealToEdit = nil
                                    isPresentingPlannedMealEditor = true
                                } label: {
                                    Label("Planera mål för vald dag", systemImage: "calendar.badge.plus")
                                        .font(.subheadline.weight(.medium))
                                }
                                .buttonStyle(.borderless)

                                Button {
                                    selectedRegistrationDate = defaultRegistrationDate(for: selectedDay)
                                    isPresentingAddMeal = true
                                } label: {
                                    Label("Registrera måltid för vald dag", systemImage: "plus.circle")
                                        .font(.subheadline.weight(.medium))
                                }
                                .buttonStyle(.borderless)

                                if let selectedEntry {
                                    if !selectedEntry.plannedMeals.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Planerade mål")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.secondary)

                                            ForEach(selectedEntry.plannedMeals) { plannedMeal in
                                                Button {
                                                    plannedMealToEdit = plannedMeal
                                                    isPresentingPlannedMealEditor = true
                                                } label: {
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
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }

                                    if !selectedEntry.meals.isEmpty {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Loggade mål")
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.secondary)

                                            ForEach(selectedEntry.meals) { meal in
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(mealTitle(for: meal))
                                                        .font(.subheadline.weight(.medium))
                                                        .foregroundStyle(.primary)
                                                    Text(meal.date.formatted(date: .omitted, time: .shortened))
                                                        .font(.footnote)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                        }
                                    }

                                    if !selectedEntry.hasEntries {
                                        Text(selectedEntry.date > todayStartOfDay ? "Ingen planering ännu" : "Ingen loggning")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(.secondarySystemBackground))
                            )
                        }
                        .padding()
                    }
                } else {
                    ContentUnavailableView(
                        "Ingen hund hittades",
                        systemImage: "calendar",
                        description: Text("Skapa en hundprofil för att se veckosummeringar.")
                    )
                }
            }
            .navigationTitle("Vecka")
            .sheet(isPresented: $isPresentingAddMeal) {
                if let selectedDog {
                    AddMealView(
                        dog: selectedDog,
                        initialDate: selectedRegistrationDate ?? Date()
                    )
                }
            }
            .sheet(isPresented: $isPresentingPlannedMealEditor) {
                if let selectedDog {
                    PlannedMealEditorView(
                        dog: selectedDog,
                        initialDate: defaultRegistrationDate(for: selectedDay),
                        plannedMeal: plannedMealToEdit
                    )
                }
            }
            .gesture(
                DragGesture(minimumDistance: 30)
                    .onEnded { value in
                        if value.translation.width < -60 {
                            moveWeek(by: 1)
                        } else if value.translation.width > 60 {
                            moveWeek(by: -1)
                        }
                    }
            )
        }
        .onAppear {
            if selectedDogID == nil {
                selectedDogID = dogs.first?.persistentModelID
            }

            displayedWeekAnchor = Date()
            syncSelectedDay()
        }
    }

    private var selectedDogBinding: Binding<PersistentIdentifier> {
        Binding(
            get: { selectedDogID ?? dogs.first!.persistentModelID },
            set: { selectedDogID = $0 }
        )
    }

    private var weekEntries: [WeekEntry] {
        guard let selectedDog else { return [] }

        return weekDates.map { date in
            let dayMeals = meals.filter { meal in
                guard let mealDog = meal.dog else { return false }

                return mealDog.persistentModelID == selectedDog.persistentModelID &&
                    isoCalendar.isDate(meal.date, inSameDayAs: date)
            }
            let dayPlannedMeals = plannedMeals.filter { plannedMeal in
                guard let plannedDog = plannedMeal.dog else { return false }

                return plannedDog.persistentModelID == selectedDog.persistentModelID &&
                    isoCalendar.isDate(plannedMeal.scheduledDate, inSameDayAs: date)
            }
            let nutrition = dayMeals.dailyNutrition()

            return WeekEntry(
                date: date,
                meals: dayMeals,
                plannedMeals: dayPlannedMeals,
                nutrition: nutrition,
                progress: nutrition.progress(for: selectedDog)
            )
        }
    }

    private var isoCalendar: Calendar {
        var calendar = Calendar(identifier: .iso8601)
        calendar.locale = Locale(identifier: "sv_SE")
        calendar.timeZone = .current
        return calendar
    }

    private var weekColumns: [GridItem] {
        Array(repeating: GridItem(.flexible(), spacing: 8), count: 7)
    }

    private var todayStartOfDay: Date {
        isoCalendar.startOfDay(for: Date())
    }

    private var displayedWeekInterval: DateInterval {
        isoCalendar.dateInterval(of: .weekOfYear, for: displayedWeekAnchor) ?? DateInterval(start: isoCalendar.startOfDay(for: displayedWeekAnchor), duration: 60 * 60 * 24 * 7)
    }

    private var weekDates: [Date] {
        let start = displayedWeekInterval.start
        return (0..<7).compactMap { offset in
            isoCalendar.date(byAdding: .day, value: offset, to: start)
        }
    }

    private var displayedWeekNumber: Int {
        isoCalendar.component(.weekOfYear, from: displayedWeekInterval.start)
    }

    private var selectedEntry: WeekEntry? {
        weekEntries.first { isoCalendar.isDate($0.date, inSameDayAs: selectedDay) }
    }

    private var dayStatusText: String {
        guard let selectedEntry else { return "" }
        if isoCalendar.isDateInToday(selectedEntry.date) {
            return "Idag"
        }
        if selectedEntry.date > todayStartOfDay {
            return selectedEntry.hasEntries ? "Planerad/loggad" : "Kommande dag"
        }
        if !selectedEntry.meals.isEmpty {
            return "Loggad dag"
        }
        if !selectedEntry.plannedMeals.isEmpty {
            return "Planerad dag"
        }
        return "Ingen loggning"
    }

    private var dayStatusColor: Color {
        guard let selectedEntry else { return .secondary }
        if isoCalendar.isDateInToday(selectedEntry.date) {
            return .orange
        }
        if selectedEntry.date > todayStartOfDay {
            return selectedEntry.hasEntries ? .blue : .secondary
        }
        if !selectedEntry.meals.isEmpty {
            return .green
        }
        if !selectedEntry.plannedMeals.isEmpty {
            return .blue
        }
        return .secondary
    }

    private var displayedWeekRangeText: String {
        let formatter = DateIntervalFormatter()
        formatter.locale = Locale(identifier: "sv_SE")
        formatter.calendar = isoCalendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        let endDate = isoCalendar.date(byAdding: .day, value: 6, to: displayedWeekInterval.start) ?? displayedWeekInterval.end
        return formatter.string(from: displayedWeekInterval.start, to: endDate)
    }

    private func moveWeek(by value: Int) {
        displayedWeekAnchor = isoCalendar.date(byAdding: .weekOfYear, value: value, to: displayedWeekAnchor) ?? displayedWeekAnchor
        syncSelectedDay()
    }

    private func syncSelectedDay() {
        if isoCalendar.isDate(selectedDay, equalTo: displayedWeekAnchor, toGranularity: .weekOfYear) {
            return
        }

        if weekDates.contains(where: { isoCalendar.isDateInToday($0) }) {
            selectedDay = Date()
        } else {
            selectedDay = displayedWeekInterval.start
        }
    }

    private func defaultRegistrationDate(for day: Date) -> Date {
        if isoCalendar.isDateInToday(day) {
            return Date()
        }

        return isoCalendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
    }

    private func mealTitle(for meal: Meal) -> String {
        let trimmedNotes = meal.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedNotes.isEmpty {
            return trimmedNotes
        }
        return meal.type.rawValue
    }
}

private struct WeekCalendarDayCell: View {
    let entry: WeekEntry
    let isSelected: Bool
    let isToday: Bool
    let isFuture: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(entry.date, format: .dateTime.weekday(.narrow))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(entry.date, format: .dateTime.day())
                .font(.headline)
                .foregroundStyle(isSelected ? .white : .primary)

            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)

            Text("\(entry.totalEntryCount)")
                .font(.caption2.weight(.medium))
                .foregroundStyle(isSelected ? .white.opacity(0.9) : .secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 92)
        .padding(.vertical, 10)
        .background(backgroundStyle)
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(borderColor, lineWidth: isSelected ? 0 : 1)
        )
    }

    private var statusColor: Color {
        if isToday {
            return .orange
        }
        if !entry.meals.isEmpty {
            return .green
        }
        if !entry.plannedMeals.isEmpty {
            return .blue
        }
        if entry.meals.isEmpty {
            return isFuture ? .blue : .secondary.opacity(0.5)
        }
        return .secondary.opacity(0.5)
    }

    private var backgroundStyle: some ShapeStyle {
        if isSelected {
            return AnyShapeStyle(.orange)
        }
        if isToday {
            return AnyShapeStyle(Color.orange.opacity(0.12))
        }
        if isFuture {
            return AnyShapeStyle(Color.blue.opacity(0.08))
        }
        return AnyShapeStyle(Color(.secondarySystemBackground))
    }

    private var borderColor: Color {
        if isToday {
            return .orange.opacity(0.4)
        }
        return Color(.separator)
    }
}

private struct PlannedMealEditorView: View {
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
                            Text(type.rawValue).tag(type)
                        }
                    }
                }

                Section("Innehåll") {
                    Picker("Recept", selection: $selectedRecipeID) {
                        Text("Fri måltid").tag(Optional<PersistentIdentifier>.none)
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
