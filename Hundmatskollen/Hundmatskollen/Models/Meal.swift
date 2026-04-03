import Foundation
import SwiftData

// MARK: - MealType

/// Typ av måltid
enum MealType: String, Codable, CaseIterable {
    case breakfast = "Frukost"
    case lunch     = "Lunch"
    case dinner    = "Middag"
    case snack     = "Snacks/Belöning"
}

// MARK: - MealItem

/// En ingrediens i en måltid med specifik gram-mängd.
/// Är en "join" mellan Meal och Food.
@Model
final class MealItem {
    var food: Food?
    var grams: Double

    init(food: Food, grams: Double) {
        self.food = food
        self.grams = grams
    }

    // Beräknade näringsvärden för den specifika mängden
    var calories: Double { food?.calories(forGrams: grams) ?? 0 }
    var protein: Double  { food?.protein(forGrams: grams)  ?? 0 }
    var fat: Double      { food?.fat(forGrams: grams)      ?? 0 }
    var carbs: Double    { food?.carbs(forGrams: grams)    ?? 0 }
    var fiber: Double    { food?.fiber(forGrams: grams)    ?? 0 }
}

// MARK: - Meal

/// En loggad måltid för en specifik hund vid ett specifikt tillfälle.
@Model
final class Meal {
    var dog: Dog?
    var date: Date
    var type: MealType
    var notes: String

    @Relationship(deleteRule: .cascade) var items: [MealItem] = []

    init(
        dog: Dog? = nil,
        date: Date = Date(),
        type: MealType = .dinner,
        notes: String = ""
    ) {
        self.dog   = dog
        self.date  = date
        self.type  = type
        self.notes = notes
    }

    // MARK: - Summerade näringsvärden för hela måltiden

    var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double  { items.reduce(0) { $0 + $1.protein  } }
    var totalFat: Double      { items.reduce(0) { $0 + $1.fat      } }
    var totalCarbs: Double    { items.reduce(0) { $0 + $1.carbs    } }
    var totalFiber: Double    { items.reduce(0) { $0 + $1.fiber    } }
    var totalGrams: Double    { items.reduce(0) { $0 + $1.grams    } }
}

// MARK: - DailyNutrition

/// Hjälpstruktur för att summera ett helt dags näringsvärden
struct DailyNutrition {
    var calories: Double = 0
    var protein: Double  = 0
    var fat: Double      = 0
    var carbs: Double    = 0
    var fiber: Double    = 0

    /// Beräknar hur stor andel av hundens dagsbehov som är uppfyllt (0–1)
    func progress(for dog: Dog) -> NutritionProgress {
        NutritionProgress(
            calories: min(calories / dog.dailyCalories, 1.0),
            protein:  min(protein  / dog.dailyProteinGrams, 1.0),
            fat:      min(fat      / dog.dailyFatGrams, 1.0),
            carbs:    min(carbs    / dog.dailyCarbGrams, 1.0)
        )
    }
}

/// Progressvärden (0.0 – 1.0) för varje makronäringsämne
struct NutritionProgress {
    var calories: Double
    var protein: Double
    var fat: Double
    var carbs: Double
}

// MARK: - Hjälpfunktion: summera måltider för en dag

extension [Meal] {
    /// Summerar näringsvärden för alla måltider i listan
    func dailyNutrition() -> DailyNutrition {
        reduce(into: DailyNutrition()) { result, meal in
            result.calories += meal.totalCalories
            result.protein  += meal.totalProtein
            result.fat      += meal.totalFat
            result.carbs    += meal.totalCarbs
            result.fiber    += meal.totalFiber
        }
    }
}
