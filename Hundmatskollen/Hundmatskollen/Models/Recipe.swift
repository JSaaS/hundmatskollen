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
    var totalWaterMl: Double {
        items.reduce(0) { partialResult, item in
            guard item.food?.preferredUnit == .milliliters else { return partialResult }
            return partialResult + item.grams
        }
    }
    var dangerousItemCount: Int { items.filter { $0.food?.isDangerousForDogs == true }.count }
}
