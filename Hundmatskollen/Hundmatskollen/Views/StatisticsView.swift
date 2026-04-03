import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @Query(sort: \Meal.date, order: .reverse) private var meals: [Meal]

    @State private var selectedDogID: PersistentIdentifier?
    @State private var selectedRange: StatisticsRange = .thirtyDays
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -29, to: Date()) ?? Date()
    @State private var customEndDate = Date()

    private var selectedDog: Dog? {
        if let selectedDogID {
            return dogs.first { $0.persistentModelID == selectedDogID }
        }

        return dogs.first
    }

    private var dateInterval: DateInterval {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: customEndDate)

        switch selectedRange {
        case .sevenDays:
            let startDate = calendar.date(byAdding: .day, value: -6, to: endDate) ?? endDate
            return DateInterval(start: startDate, end: endDate)
        case .fourteenDays:
            let startDate = calendar.date(byAdding: .day, value: -13, to: endDate) ?? endDate
            return DateInterval(start: startDate, end: endDate)
        case .thirtyDays:
            let startDate = calendar.date(byAdding: .day, value: -29, to: endDate) ?? endDate
            return DateInterval(start: startDate, end: endDate)
        case .ninetyDays:
            let startDate = calendar.date(byAdding: .day, value: -89, to: endDate) ?? endDate
            return DateInterval(start: startDate, end: endDate)
        case .custom:
            let startDate = min(calendar.startOfDay(for: customStartDate), endDate)
            return DateInterval(start: startDate, end: endDate)
        }
    }

    private var filteredMeals: [Meal] {
        guard let selectedDog else { return [] }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: dateInterval.start)
        let endDate = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: dateInterval.end)) ?? dateInterval.end

        return meals.filter { meal in
            guard let mealDog = meal.dog else { return false }

            return mealDog.persistentModelID == selectedDog.persistentModelID &&
                meal.date >= startDate &&
                meal.date < endDate
        }
    }

    private var dailyEntries: [StatisticsDayEntry] {
        guard selectedDog != nil else { return [] }

        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: dateInterval.start)
        let endDate = calendar.startOfDay(for: dateInterval.end)
        let groupedMeals = Dictionary(grouping: filteredMeals) { meal in
            calendar.startOfDay(for: meal.date)
        }

        return calendar.days(from: startDate, through: endDate).map { date in
            let mealsForDay = groupedMeals[date] ?? []
            let nutrition = mealsForDay.dailyNutrition()

            return StatisticsDayEntry(
                date: date,
                mealCount: mealsForDay.count,
                calories: nutrition.calories,
                protein: nutrition.protein,
                fat: nutrition.fat,
                carbs: nutrition.carbs
            )
        }
    }

    private var macroPoints: [MacroChartPoint] {
        dailyEntries.flatMap { entry -> [MacroChartPoint] in
            let totalMacroCalories = (entry.protein * 4) + (entry.fat * 9) + (entry.carbs * 4)

            guard totalMacroCalories > 0 else { return [] }

            return [
                MacroChartPoint(date: entry.date, nutrient: "Protein", share: (entry.protein * 4 / totalMacroCalories) * 100),
                MacroChartPoint(date: entry.date, nutrient: "Fett", share: (entry.fat * 9 / totalMacroCalories) * 100),
                MacroChartPoint(date: entry.date, nutrient: "Kolhydrater", share: (entry.carbs * 4 / totalMacroCalories) * 100)
            ]
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if selectedDog != nil {
                    List {
                        Section("Urval") {
                            if dogs.count > 1 {
                                Picker("Hund", selection: selectedDogBinding) {
                                    ForEach(dogs) { dog in
                                        Text(dog.name).tag(dog.persistentModelID)
                                    }
                                }
                            }

                            Picker("Period", selection: $selectedRange) {
                                ForEach(StatisticsRange.allCases) { range in
                                    Text(range.title).tag(range)
                                }
                            }
                            .pickerStyle(.segmented)

                            if selectedRange == .custom {
                                DatePicker("Från", selection: $customStartDate, displayedComponents: .date)
                                DatePicker("Till", selection: $customEndDate, displayedComponents: .date)
                            }
                        }

                        Section("Översikt") {
                            LabeledContent("Period", value: periodLabel)
                            LabeledContent("Loggade måltider", value: "\(filteredMeals.count)")
                            LabeledContent("Dagar med loggning", value: "\(dailyEntries.filter { $0.mealCount > 0 }.count)")
                            LabeledContent("Snitt kcal / dag", value: "\(averageCaloriesPerDay) kcal")
                        }

                        Section("Kalorier över tid") {
                            if hasLoggedData {
                                Chart(dailyEntries) { entry in
                                    LineMark(
                                        x: .value("Datum", entry.date),
                                        y: .value("Kalorier", entry.calories)
                                    )
                                    .foregroundStyle(.orange)
                                    .interpolationMethod(.catmullRom)

                                    AreaMark(
                                        x: .value("Datum", entry.date),
                                        y: .value("Kalorier", entry.calories)
                                    )
                                    .foregroundStyle(.orange.opacity(0.12))
                                    .interpolationMethod(.catmullRom)
                                }
                                .frame(height: 220)
                                .chartYAxis {
                                    AxisMarks(position: .leading)
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: xAxisStrideComponent)) { value in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel(format: xAxisLabelFormat)
                                    }
                                }
                            } else {
                                statisticsEmptyState
                            }
                        }

                        Section("Makrofördelning över tid") {
                            if !macroPoints.isEmpty {
                                Chart(macroPoints) { point in
                                    LineMark(
                                        x: .value("Datum", point.date),
                                        y: .value("Andel", point.share),
                                        series: .value("Makro", point.nutrient)
                                    )
                                    .foregroundStyle(by: .value("Makro", point.nutrient))
                                    .interpolationMethod(.catmullRom)
                                }
                                .frame(height: 240)
                                .chartForegroundStyleScale([
                                    "Protein": .red,
                                    "Fett": .yellow,
                                    "Kolhydrater": .green
                                ])
                                .chartYAxis {
                                    AxisMarks(position: .leading, values: [0, 25, 50, 75, 100]) { value in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel {
                                            if let share = value.as(Int.self) {
                                                Text("\(share) %")
                                            }
                                        }
                                    }
                                }
                                .chartXAxis {
                                    AxisMarks(values: .stride(by: xAxisStrideComponent)) { value in
                                        AxisGridLine()
                                        AxisTick()
                                        AxisValueLabel(format: xAxisLabelFormat)
                                    }
                                }
                                .chartLegend(position: .bottom)
                            } else {
                                statisticsEmptyState
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Ingen hund hittades",
                        systemImage: "chart.xyaxis.line",
                        description: Text("Skapa en hundprofil och logga måltider för att se statistik.")
                    )
                }
            }
            .navigationTitle("Statistik")
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

    private var periodLabel: String {
        let start = dateInterval.start.formatted(date: .abbreviated, time: .omitted)
        let end = dateInterval.end.formatted(date: .abbreviated, time: .omitted)
        return "\(start) – \(end)"
    }

    private var averageCaloriesPerDay: Int {
        guard !dailyEntries.isEmpty else { return 0 }
        let average = dailyEntries.reduce(0) { $0 + $1.calories } / Double(dailyEntries.count)
        return Int(average.rounded())
    }

    private var hasLoggedData: Bool {
        dailyEntries.contains { $0.calories > 0 }
    }

    private var xAxisStrideComponent: Calendar.Component {
        switch selectedRange {
        case .sevenDays, .fourteenDays:
            return .day
        case .thirtyDays, .ninetyDays, .custom:
            return .weekOfYear
        }
    }

    private var xAxisLabelFormat: Date.FormatStyle {
        switch selectedRange {
        case .sevenDays, .fourteenDays:
            return .dateTime.day().month(.abbreviated)
        case .thirtyDays, .ninetyDays, .custom:
            return .dateTime.day().month(.abbreviated)
        }
    }

    private var statisticsEmptyState: some View {
        ContentUnavailableView(
            "Ingen statistik ännu",
            systemImage: "waveform.path.ecg",
            description: Text("Logga måltider under den valda perioden för att se trender.")
        )
    }
}

enum StatisticsRange: String, CaseIterable, Identifiable {
    case sevenDays
    case fourteenDays
    case thirtyDays
    case ninetyDays
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .sevenDays: return "7 d"
        case .fourteenDays: return "14 d"
        case .thirtyDays: return "30 d"
        case .ninetyDays: return "90 d"
        case .custom: return "Valfri"
        }
    }
}

struct StatisticsDayEntry: Identifiable {
    let date: Date
    let mealCount: Int
    let calories: Double
    let protein: Double
    let fat: Double
    let carbs: Double

    var id: Date { date }
}

struct MacroChartPoint: Identifiable {
    let date: Date
    let nutrient: String
    let share: Double

    var id: String { "\(date.timeIntervalSince1970)-\(nutrient)" }
}

private extension Calendar {
    func days(from startDate: Date, through endDate: Date) -> [Date] {
        guard startDate <= endDate else { return [] }

        var dates: [Date] = []
        var currentDate = startDate

        while currentDate <= endDate {
            dates.append(currentDate)
            currentDate = date(byAdding: .day, value: 1, to: currentDate) ?? endDate.addingTimeInterval(1)
        }

        return dates
    }
}
