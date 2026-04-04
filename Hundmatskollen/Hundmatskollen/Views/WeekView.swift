import SwiftUI
import SwiftData

struct WeekView: View {
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @Query(sort: \Meal.date, order: .reverse) private var meals: [Meal]

    @State private var selectedDogID: PersistentIdentifier?
    @State private var selectedRegistrationDate: Date?
    @State private var selectedDay = Date()
    @State private var isPresentingAddMeal = false
    @State private var displayedWeekAnchor = Date()

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
                                    selectedRegistrationDate = defaultRegistrationDate(for: selectedDay)
                                    isPresentingAddMeal = true
                                } label: {
                                    Label("Registrera måltid för vald dag", systemImage: "plus.circle")
                                        .font(.subheadline.weight(.medium))
                                }
                                .buttonStyle(.borderless)

                                if let selectedEntry {
                                    if selectedEntry.meals.isEmpty {
                                        Text(selectedEntry.date > todayStartOfDay ? "Ingen planering ännu" : "Ingen loggning")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        VStack(alignment: .leading, spacing: 8) {
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
            let nutrition = dayMeals.dailyNutrition()

            return WeekEntry(
                date: date,
                meals: dayMeals,
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
            return selectedEntry.meals.isEmpty ? "Kommande dag" : "Planerad/loggad"
        }
        return selectedEntry.meals.isEmpty ? "Ingen loggning" : "Loggad dag"
    }

    private var dayStatusColor: Color {
        guard let selectedEntry else { return .secondary }
        if isoCalendar.isDateInToday(selectedEntry.date) {
            return .orange
        }
        if selectedEntry.date > todayStartOfDay {
            return .blue
        }
        return selectedEntry.meals.isEmpty ? .secondary : .green
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

            Text("\(entry.meals.count)")
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
        if entry.meals.isEmpty {
            return isFuture ? .blue : .secondary.opacity(0.5)
        }
        return .green
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
