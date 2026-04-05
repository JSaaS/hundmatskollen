import Foundation
import SwiftData

@Model
final class RecipeItem {
    var food: Food?
    var grams: Double

    init(food: Food, grams: Double) {
        self.food = food
        self.grams = grams
    }

    var calories: Double { food?.calories(forGrams: grams) ?? 0 }
    var protein: Double { food?.protein(forGrams: grams) ?? 0 }
    var fat: Double { food?.fat(forGrams: grams) ?? 0 }
    var carbs: Double { food?.carbs(forGrams: grams) ?? 0 }
    var fiber: Double { food?.fiber(forGrams: grams) ?? 0 }
    var calcium: Double? { food?.calcium(forGrams: grams) }
    var phosphorus: Double? { food?.phosphorus(forGrams: grams) }
    var magnesium: Double? { food?.magnesium(forGrams: grams) }
    var iron: Double? { food?.iron(forGrams: grams) }
    var zinc: Double? { food?.zinc(forGrams: grams) }
    var sodium: Double? { food?.sodium(forGrams: grams) }
    var vitaminA: Double? { food?.vitaminA(forGrams: grams) }
    var vitaminD: Double? { food?.vitaminD(forGrams: grams) }
    var vitaminE: Double? { food?.vitaminE(forGrams: grams) }
    var vitaminB12: Double? { food?.vitaminB12(forGrams: grams) }
}

@Model
final class Recipe {
    var dog: Dog?
    var name: String
    var notes: String
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var items: [RecipeItem] = []

    init(
        dog: Dog? = nil,
        name: String,
        notes: String = ""
    ) {
        self.dog = dog
        self.name = name
        self.notes = notes
        self.createdAt = Date()
    }

    var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double { items.reduce(0) { $0 + $1.protein } }
    var totalFat: Double { items.reduce(0) { $0 + $1.fat } }
    var totalCarbs: Double { items.reduce(0) { $0 + $1.carbs } }
    var totalFiber: Double { items.reduce(0) { $0 + $1.fiber } }
    var totalGrams: Double { items.reduce(0) { $0 + $1.grams } }
    var totalCalcium: Double? { items.sum(of: \.calcium) }
    var totalPhosphorus: Double? { items.sum(of: \.phosphorus) }
    var totalMagnesium: Double? { items.sum(of: \.magnesium) }
    var totalIron: Double? { items.sum(of: \.iron) }
    var totalZinc: Double? { items.sum(of: \.zinc) }
    var totalSodium: Double? { items.sum(of: \.sodium) }
    var totalVitaminA: Double? { items.sum(of: \.vitaminA) }
    var totalVitaminD: Double? { items.sum(of: \.vitaminD) }
    var totalVitaminE: Double? { items.sum(of: \.vitaminE) }
    var totalVitaminB12: Double? { items.sum(of: \.vitaminB12) }
    var totalWaterMl: Double {
        items.reduce(0) { partialResult, item in
            guard item.food?.preferredUnit == .milliliters else { return partialResult }
            return partialResult + item.grams
        }
    }
    var dangerousItemCount: Int { items.filter { $0.food?.isDangerousForDogs == true }.count }
}

private extension Collection {
    func sum(of keyPath: KeyPath<Element, Double?>) -> Double? {
        let values = compactMap { $0[keyPath: keyPath] }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }
}
