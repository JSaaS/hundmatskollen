import SwiftUI
import SwiftData

struct WeekView: View {
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @Query(sort: \Meal.date, order: .reverse) private var meals: [Meal]

    @State private var selectedDogID: PersistentIdentifier?
    @State private var selectedRegistrationDate: Date?
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

                        Section {
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
                        }

                        Section("Veckoöversikt") {
                            LabeledContent("Mål per dag", value: "\(Int(selectedDog.dailyCalories)) kcal")
                            LabeledContent("Mål protein", value: "\(Int(selectedDog.dailyProteinGrams)) g")
                            LabeledContent("Mål fett", value: "\(Int(selectedDog.dailyFatGrams)) g")
                            LabeledContent("Mål fiber", value: "\(Int(selectedDog.dailyFiberGrams)) g")
                            LabeledContent("Mål vätska", value: "\(Int(selectedDog.dailyWaterMl)) ml")
                        }

                        Section("Veckodagar") {
                            ForEach(weekEntries) { entry in
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(entry.date, format: .dateTime.weekday(.wide))
                                                .font(.headline)
                                            Text(entry.date, format: .dateTime.day().month(.abbreviated))
                                                .font(.subheadline)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Text("\(entry.meals.count) måltider")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Button {
                                        selectedRegistrationDate = defaultRegistrationDate(for: entry.date)
                                        isPresentingAddMeal = true
                                    } label: {
                                        Label("Registrera måltid för den här dagen", systemImage: "plus.circle")
                                            .font(.subheadline.weight(.medium))
                                    }
                                    .buttonStyle(.borderless)

                                    if entry.meals.isEmpty {
                                        Text("Ingen loggning")
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        NutritionProgressRow(
                                            title: "Kalorier",
                                            consumedText: "\(Int(entry.nutrition.calories)) / \(Int(selectedDog.dailyCalories)) kcal",
                                            progress: entry.progress.calories,
                                            tint: .orange
                                        )
                                        NutritionProgressRow(
                                            title: "Protein",
                                            consumedText: "\(Int(entry.nutrition.protein)) / \(Int(selectedDog.dailyProteinGrams)) g",
                                            progress: entry.progress.protein,
                                            tint: .red
                                        )
                                        NutritionProgressRow(
                                            title: "Fiber",
                                            consumedText: "\(Int(entry.nutrition.fiber)) / \(Int(selectedDog.dailyFiberGrams)) g",
                                            progress: entry.progress.fiber,
                                            tint: .mint
                                        )
                                        NutritionProgressRow(
                                            title: "Vätska",
                                            consumedText: "\(Int(entry.nutrition.waterMl)) / \(Int(selectedDog.dailyWaterMl)) ml",
                                            progress: entry.progress.water,
                                            tint: .blue
                                        )

                                        HStack {
                                            Text("Fett \(Int(entry.nutrition.fat)) g")
                                            Spacer()
                                            Text("Kolhydrater \(Int(entry.nutrition.carbs)) g")
                                        }
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.vertical, 4)
                            }
                        }
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
    }

    private func defaultRegistrationDate(for day: Date) -> Date {
        if isoCalendar.isDateInToday(day) {
            return Date()
        }

        return isoCalendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
    }
}
