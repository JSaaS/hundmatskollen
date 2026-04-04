import Foundation
import SwiftData

// MARK: - Enums

/// Kategori för livsmedel
enum FoodCategory: String, Codable, CaseIterable {
    case meat       = "Kött"
    case fish       = "Fisk"
    case vegetables = "Grönsaker"
    case fruit      = "Frukt"
    case grains     = "Spannmål"
    case dairy      = "Mejeri"
    case eggs       = "Ägg"
    case supplements = "Tillskott"
    case other      = "Övrigt"

    var icon: String {
        switch self {
        case .meat:        return "🥩"
        case .fish:        return "🐟"
        case .vegetables:  return "🥦"
        case .fruit:       return "🍎"
        case .grains:      return "🌾"
        case .dairy:       return "🥛"
        case .eggs:        return "🥚"
        case .supplements: return "💊"
        case .other:       return "🍽️"
        }
    }
}

enum FoodMeasurementUnit: String, Codable, CaseIterable {
    case grams = "g"
    case milliliters = "ml"

    var displayName: String {
        switch self {
        case .grams:
            return "Gram"
        case .milliliters:
            return "Milliliter"
        }
    }
}

// MARK: - Food Model

/// Ett livsmedel med näringsvärden per 100g.
/// Kan vara från den inbyggda databasen (isCustom = false) eller
/// skapad av användaren (isCustom = true).
@Model
final class Food {

    var name: String
    var category: FoodCategory

    // Näringsvärden per 100g
    var caloriesPer100g: Double      // kcal
    var proteinPer100g: Double       // gram
    var fatPer100g: Double           // gram
    var carbsPer100g: Double         // gram
    var fiberPer100g: Double         // gram

    // Flaggor
    var isCustom: Bool               // Skapad av användaren
    var isDangerousForDogs: Bool     // T.ex. lök, druvor, choklad
    var dangerNote: String           // Förklaring om livsmedlet är farligt
    var preferredUnitRawValue: String?

    init(
        name: String,
        category: FoodCategory,
        caloriesPer100g: Double,
        proteinPer100g: Double,
        fatPer100g: Double,
        carbsPer100g: Double,
        fiberPer100g: Double,
        isCustom: Bool = false,
        isDangerousForDogs: Bool = false,
        dangerNote: String = "",
        preferredUnit: FoodMeasurementUnit = .grams
    ) {
        self.name = name
        self.category = category
        self.caloriesPer100g = caloriesPer100g
        self.proteinPer100g = proteinPer100g
        self.fatPer100g = fatPer100g
        self.carbsPer100g = carbsPer100g
        self.fiberPer100g = fiberPer100g
        self.isCustom = isCustom
        self.isDangerousForDogs = isDangerousForDogs
        self.dangerNote = dangerNote
        self.preferredUnitRawValue = preferredUnit.rawValue
    }

    /// Beräknar näringsvärden för en given mängd (gram)
    func calories(forGrams grams: Double) -> Double { caloriesPer100g * grams / 100 }
    func protein(forGrams grams: Double) -> Double  { proteinPer100g  * grams / 100 }
    func fat(forGrams grams: Double) -> Double      { fatPer100g      * grams / 100 }
    func carbs(forGrams grams: Double) -> Double    { carbsPer100g    * grams / 100 }
    func fiber(forGrams grams: Double) -> Double    { fiberPer100g    * grams / 100 }

    var preferredUnit: FoodMeasurementUnit {
        get { FoodMeasurementUnit(rawValue: preferredUnitRawValue ?? "") ?? .grams }
        set { preferredUnitRawValue = newValue.rawValue }
    }

    var quantityLabel: String {
        preferredUnit.rawValue
    }

    var quantityFieldLabel: String {
        "Mängd (\(quantityLabel))"
    }

    var nutritionBasisLabel: String {
        "100 \(quantityLabel)"
    }
}

// MARK: - Startdatabas med vanliga ingredienser

extension Food {
    /// Returnerar en lista med vanliga ingredienser att seeda databasen med
    static func seedData() -> [Food] {
        [
            // Kött
            Food(name: "Kycklingfilé",    category: .meat, caloriesPer100g: 110, proteinPer100g: 23,  fatPer100g: 2,   carbsPer100g: 0,   fiberPer100g: 0),
            Food(name: "Nötfärs (10%)",   category: .meat, caloriesPer100g: 152, proteinPer100g: 20,  fatPer100g: 8,   carbsPer100g: 0,   fiberPer100g: 0),
            Food(name: "Lammlår",         category: .meat, caloriesPer100g: 162, proteinPer100g: 18,  fatPer100g: 10,  carbsPer100g: 0,   fiberPer100g: 0),
            Food(name: "Fläskfilé",       category: .meat, caloriesPer100g: 121, proteinPer100g: 22,  fatPer100g: 4,   carbsPer100g: 0,   fiberPer100g: 0),
            Food(name: "Kalvlever",       category: .meat, caloriesPer100g: 130, proteinPer100g: 20,  fatPer100g: 4,   carbsPer100g: 3,   fiberPer100g: 0),
            Food(name: "Kycklinglever",   category: .meat, caloriesPer100g: 119, proteinPer100g: 17,  fatPer100g: 5,   carbsPer100g: 1,   fiberPer100g: 0),

            // Fisk
            Food(name: "Lax",             category: .fish, caloriesPer100g: 206, proteinPer100g: 20,  fatPer100g: 14,  carbsPer100g: 0,   fiberPer100g: 0),
            Food(name: "Torsk",           category: .fish, caloriesPer100g: 82,  proteinPer100g: 18,  fatPer100g: 1,   carbsPer100g: 0,   fiberPer100g: 0),
            Food(name: "Makrill",         category: .fish, caloriesPer100g: 205, proteinPer100g: 19,  fatPer100g: 14,  carbsPer100g: 0,   fiberPer100g: 0),
            Food(name: "Sardiner (vatten)",category: .fish,caloriesPer100g: 135, proteinPer100g: 24,  fatPer100g: 4,   carbsPer100g: 0,   fiberPer100g: 0),

            // Grönsaker
            Food(name: "Morot",           category: .vegetables, caloriesPer100g: 41,  proteinPer100g: 1,   fatPer100g: 0.2, carbsPer100g: 10,  fiberPer100g: 3),
            Food(name: "Broccoli",        category: .vegetables, caloriesPer100g: 34,  proteinPer100g: 3,   fatPer100g: 0.4, carbsPer100g: 7,   fiberPer100g: 3),
            Food(name: "Pumpa",           category: .vegetables, caloriesPer100g: 26,  proteinPer100g: 1,   fatPer100g: 0.1, carbsPer100g: 6,   fiberPer100g: 0.5),
            Food(name: "Spenat",          category: .vegetables, caloriesPer100g: 23,  proteinPer100g: 3,   fatPer100g: 0.4, carbsPer100g: 4,   fiberPer100g: 2),
            Food(name: "Zucchini",        category: .vegetables, caloriesPer100g: 17,  proteinPer100g: 1,   fatPer100g: 0.3, carbsPer100g: 3,   fiberPer100g: 1),
            Food(name: "Sötpotatis",      category: .vegetables, caloriesPer100g: 86,  proteinPer100g: 2,   fatPer100g: 0.1, carbsPer100g: 20,  fiberPer100g: 3),

            // Farliga – visas med varning
            Food(name: "Lök",             category: .vegetables, caloriesPer100g: 40,  proteinPer100g: 1, fatPer100g: 0.1, carbsPer100g: 9, fiberPer100g: 2,
                 isDangerousForDogs: true, dangerNote: "Giftigt för hundar – kan orsaka blodbrist."),
            Food(name: "Vitlök",          category: .vegetables, caloriesPer100g: 149, proteinPer100g: 6, fatPer100g: 0.5, carbsPer100g: 33, fiberPer100g: 2,
                 isDangerousForDogs: true, dangerNote: "Giftigt för hundar även i små mängder."),
            Food(name: "Vindruvor",       category: .fruit,      caloriesPer100g: 67,  proteinPer100g: 1, fatPer100g: 0.4, carbsPer100g: 17, fiberPer100g: 1,
                 isDangerousForDogs: true, dangerNote: "Kan orsaka njursvikt hos hundar."),
            Food(name: "Russin",          category: .fruit,      caloriesPer100g: 299, proteinPer100g: 3, fatPer100g: 0.5, carbsPer100g: 79, fiberPer100g: 4,
                 isDangerousForDogs: true, dangerNote: "Kan orsaka allvarlig njurpåverkan hos hundar."),
            Food(name: "Choklad",         category: .other,      caloriesPer100g: 546, proteinPer100g: 5, fatPer100g: 31, carbsPer100g: 61, fiberPer100g: 7,
                 isDangerousForDogs: true, dangerNote: "Innehåller teobromin och är giftigt för hundar."),

            // Frukt
            Food(name: "Äpple (utan kärnhus)", category: .fruit, caloriesPer100g: 52, proteinPer100g: 0.3, fatPer100g: 0.2, carbsPer100g: 14, fiberPer100g: 2),
            Food(name: "Blåbär",          category: .fruit,      caloriesPer100g: 57,  proteinPer100g: 1,   fatPer100g: 0.3, carbsPer100g: 14,  fiberPer100g: 2),
            Food(name: "Banan",           category: .fruit,      caloriesPer100g: 89,  proteinPer100g: 1,   fatPer100g: 0.3, carbsPer100g: 23,  fiberPer100g: 3),
            Food(name: "Vattenmelon (utan frön)", category: .fruit, caloriesPer100g: 30, proteinPer100g: 1, fatPer100g: 0.2, carbsPer100g: 8,  fiberPer100g: 0.4),

            // Spannmål
            Food(name: "Brunt ris (kokt)",category: .grains,     caloriesPer100g: 112, proteinPer100g: 2,   fatPer100g: 0.9, carbsPer100g: 23,  fiberPer100g: 2),
            Food(name: "Havregryn",       category: .grains,     caloriesPer100g: 389, proteinPer100g: 17,  fatPer100g: 7,   carbsPer100g: 66,  fiberPer100g: 11),
            Food(name: "Quinoa (kokt)",   category: .grains,     caloriesPer100g: 120, proteinPer100g: 4,   fatPer100g: 2,   carbsPer100g: 21,  fiberPer100g: 3),

            // Mejeri & Ägg
            Food(name: "Ägg",             category: .eggs,       caloriesPer100g: 155, proteinPer100g: 13,  fatPer100g: 11,  carbsPer100g: 1,   fiberPer100g: 0),
            Food(name: "Keso",            category: .dairy,      caloriesPer100g: 98,  proteinPer100g: 11,  fatPer100g: 4,   carbsPer100g: 4,   fiberPer100g: 0),
            Food(name: "Naturell yoghurt",category: .dairy,      caloriesPer100g: 61,  proteinPer100g: 4,   fatPer100g: 3,   carbsPer100g: 5,   fiberPer100g: 0),

            // Tillskott
            Food(name: "Fiskolja",        category: .supplements, caloriesPer100g: 902, proteinPer100g: 0, fatPer100g: 100, carbsPer100g: 0,  fiberPer100g: 0),
        ]
    }
}
