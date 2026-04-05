import Foundation
import SwiftData

// MARK: - MealType

/// Typ av måltid
enum MealType: String, Codable, CaseIterable {
    case breakfast = "Frukost"
    case lunch     = "Lunch"
    case dinner    = "Middag"
    case snack     = "Snacks/Belöning"

    var displayTitle: String {
        switch self {
        case .snack:
            return "Belöning"
        default:
            return rawValue
        }
    }

    var suggestedHour: Int {
        switch self {
        case .breakfast:
            return 8
        case .lunch:
            return 12
        case .dinner:
            return 18
        case .snack:
            return 15
        }
    }

    func suggestedDate(on date: Date, calendar: Calendar = .current) -> Date {
        calendar.date(
            bySettingHour: suggestedHour,
            minute: 0,
            second: 0,
            of: date
        ) ?? date
    }
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
    var fluidMl: Double {
        guard food?.preferredUnit == .milliliters else { return 0 }
        return grams
    }
}

// MARK: - Meal

/// En loggad måltid för en specifik hund vid ett specifikt tillfälle.
@Model
final class Meal {
    var dog: Dog?
    var date: Date
    var type: MealType
    var notes: String
    var waterMlValue: Double?

    @Relationship(deleteRule: .cascade) var items: [MealItem] = []

    init(
        dog: Dog? = nil,
        date: Date = Date(),
        type: MealType = .dinner,
        notes: String = "",
        waterMl: Double = 0
    ) {
        self.dog   = dog
        self.date  = date
        self.type  = type
        self.notes = notes
        self.waterMlValue = waterMl
    }

    // MARK: - Summerade näringsvärden för hela måltiden

    var totalCalories: Double { items.reduce(0) { $0 + $1.calories } }
    var totalProtein: Double  { items.reduce(0) { $0 + $1.protein  } }
    var totalFat: Double      { items.reduce(0) { $0 + $1.fat      } }
    var totalCarbs: Double    { items.reduce(0) { $0 + $1.carbs    } }
    var totalFiber: Double    { items.reduce(0) { $0 + $1.fiber    } }
    var totalGrams: Double    { items.reduce(0) { $0 + $1.grams    } }
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
    var totalFluidFromItemsMl: Double { items.reduce(0) { $0 + $1.fluidMl } }
    var totalWaterMl: Double { waterMl + totalFluidFromItemsMl }

    var waterMl: Double {
        get { waterMlValue ?? 0 }
        set { waterMlValue = newValue }
    }
}

// MARK: - PlannedMeal

/// En planerad måltid för en specifik hund och dag.
/// Skiljs från Meal eftersom plan och faktiskt utfall har olika livscykel.
@Model
final class PlannedMeal {
    var dog: Dog?
    var recipe: Recipe?
    var scheduledDate: Date
    var type: MealType
    var title: String
    var notes: String
    var createdAt: Date

    init(
        dog: Dog? = nil,
        recipe: Recipe? = nil,
        scheduledDate: Date,
        type: MealType = .dinner,
        title: String = "",
        notes: String = ""
    ) {
        self.dog = dog
        self.recipe = recipe
        self.scheduledDate = scheduledDate
        self.type = type
        self.title = title
        self.notes = notes
        self.createdAt = Date()
    }

    var displayTitle: String {
        if let recipe {
            return recipe.name
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedTitle.isEmpty {
            return trimmedTitle
        }

        return type.displayTitle
    }

    var sourceLabel: String {
        recipe == nil ? "Eget mål" : "Recept"
    }
}

// MARK: - DailyNutrition

/// Hjälpstruktur för att summera ett helt dags näringsvärden
struct DailyNutrition {
    var calories: Double = 0
    var protein: Double  = 0
    var fat: Double      = 0
    var carbs: Double    = 0
    var fiber: Double    = 0
    var waterMl: Double  = 0
    var calcium: Double? = nil
    var phosphorus: Double? = nil
    var magnesium: Double? = nil
    var iron: Double? = nil
    var zinc: Double? = nil
    var sodium: Double? = nil
    var vitaminA: Double? = nil
    var vitaminD: Double? = nil
    var vitaminE: Double? = nil
    var vitaminB12: Double? = nil

    /// Beräknar hur stor andel av hundens dagsbehov som är uppfyllt (0–1)
    func progress(for dog: Dog) -> NutritionProgress {
        NutritionProgress(
            calories: min(calories / dog.dailyCalories, 1.0),
            protein:  min(protein  / dog.dailyProteinGrams, 1.0),
            fat:      min(fat      / dog.dailyFatGrams, 1.0),
            carbs:    min(carbs    / dog.dailyCarbGrams, 1.0),
            fiber:    min(fiber    / dog.dailyFiberGrams, 1.0),
            water:    min(waterMl  / dog.dailyWaterMl, 1.0)
        )
    }
}

/// Progressvärden (0.0 – 1.0) för dagens mål
struct NutritionProgress {
    var calories: Double
    var protein: Double
    var fat: Double
    var carbs: Double
    var fiber: Double
    var water: Double
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
            result.waterMl  += meal.totalWaterMl
            result.calcium = DailyNutrition.accumulated(result.calcium, adding: meal.totalCalcium)
            result.phosphorus = DailyNutrition.accumulated(result.phosphorus, adding: meal.totalPhosphorus)
            result.magnesium = DailyNutrition.accumulated(result.magnesium, adding: meal.totalMagnesium)
            result.iron = DailyNutrition.accumulated(result.iron, adding: meal.totalIron)
            result.zinc = DailyNutrition.accumulated(result.zinc, adding: meal.totalZinc)
            result.sodium = DailyNutrition.accumulated(result.sodium, adding: meal.totalSodium)
            result.vitaminA = DailyNutrition.accumulated(result.vitaminA, adding: meal.totalVitaminA)
            result.vitaminD = DailyNutrition.accumulated(result.vitaminD, adding: meal.totalVitaminD)
            result.vitaminE = DailyNutrition.accumulated(result.vitaminE, adding: meal.totalVitaminE)
            result.vitaminB12 = DailyNutrition.accumulated(result.vitaminB12, adding: meal.totalVitaminB12)
        }
    }
}

private extension Collection {
    func sum(of keyPath: KeyPath<Element, Double?>) -> Double? {
        let values = compactMap { $0[keyPath: keyPath] }
        guard !values.isEmpty else { return nil }
        return values.reduce(0, +)
    }
}

private extension DailyNutrition {
    static func accumulated(_ current: Double?, adding next: Double?) -> Double? {
        switch (current, next) {
        case let (.some(current), .some(next)):
            return current + next
        case let (.some(current), .none):
            return current
        case let (.none, .some(next)):
            return next
        case (.none, .none):
            return nil
        }
    }
}
