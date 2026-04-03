import SwiftUI
import SwiftData

struct WeekView: View {
    @Query(sort: \Dog.createdAt) private var dogs: [Dog]
    @Query(sort: \Meal.date, order: .reverse) private var meals: [Meal]

    @State private var selectedDogID: PersistentIdentifier?
    @State private var selectedRegistrationDate: Date?
    @State private var isPresentingAddMeal = false

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

                        Section("Veckoöversikt") {
                            LabeledContent("Mål per dag", value: "\(Int(selectedDog.dailyCalories)) kcal")
                            LabeledContent("Mål protein", value: "\(Int(selectedDog.dailyProteinGrams)) g")
                            LabeledContent("Mål fett", value: "\(Int(selectedDog.dailyFatGrams)) g")
                        }

                        Section("Senaste 7 dagarna") {
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

    private var weekEntries: [WeekEntry] {
        guard let selectedDog else { return [] }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let dayMeals = meals.filter { meal in
                guard let mealDog = meal.dog else { return false }

                return mealDog.persistentModelID == selectedDog.persistentModelID &&
                    calendar.isDate(meal.date, inSameDayAs: date)
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

    private func defaultRegistrationDate(for day: Date) -> Date {
        let calendar = Calendar.current

        if calendar.isDateInToday(day) {
            return Date()
        }

        return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: day) ?? day
    }
}
