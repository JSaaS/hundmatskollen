import SwiftUI

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
    let food: Food
    @State private var isPresentingEditFood = false

    var body: some View {
        List {
            Section("Översikt") {
                LabeledContent("Kategori", value: food.category.rawValue)
                if food.isCustom {
                    Label("Egen ingrediens", systemImage: "person.crop.circle.badge.plus")
                        .foregroundStyle(.orange)
                }
                LabeledContent("Kalorier", value: "\(Int(food.caloriesPer100g)) kcal / 100 g")
                LabeledContent("Protein", value: "\(format(food.proteinPer100g)) g")
                LabeledContent("Fett", value: "\(format(food.fatPer100g)) g")
                LabeledContent("Kolhydrater", value: "\(format(food.carbsPer100g)) g")
                LabeledContent("Fiber", value: "\(format(food.fiberPer100g)) g")
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
    let nutrition: DailyNutrition
    let progress: NutritionProgress

    var id: Date { date }
}
