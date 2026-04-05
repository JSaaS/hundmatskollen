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

    // Mikronäringsvärden per 100g
    var calcium: Double?             // mg
    var phosphorus: Double?          // mg
    var magnesium: Double?           // mg
    var iron: Double?                // mg
    var zinc: Double?                // mg
    var sodium: Double?              // mg
    var vitaminA: Double?            // µg RE
    var vitaminD: Double?            // µg
    var vitaminE: Double?            // mg
    var vitaminB12: Double?          // µg

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
        calcium: Double? = nil,
        phosphorus: Double? = nil,
        magnesium: Double? = nil,
        iron: Double? = nil,
        zinc: Double? = nil,
        sodium: Double? = nil,
        vitaminA: Double? = nil,
        vitaminD: Double? = nil,
        vitaminE: Double? = nil,
        vitaminB12: Double? = nil,
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
        self.calcium = calcium
        self.phosphorus = phosphorus
        self.magnesium = magnesium
        self.iron = iron
        self.zinc = zinc
        self.sodium = sodium
        self.vitaminA = vitaminA
        self.vitaminD = vitaminD
        self.vitaminE = vitaminE
        self.vitaminB12 = vitaminB12
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
    func calcium(forGrams grams: Double) -> Double? { calcium.map { $0 * grams / 100 } }
    func phosphorus(forGrams grams: Double) -> Double? { phosphorus.map { $0 * grams / 100 } }
    func magnesium(forGrams grams: Double) -> Double? { magnesium.map { $0 * grams / 100 } }
    func iron(forGrams grams: Double) -> Double? { iron.map { $0 * grams / 100 } }
    func zinc(forGrams grams: Double) -> Double? { zinc.map { $0 * grams / 100 } }
    func sodium(forGrams grams: Double) -> Double? { sodium.map { $0 * grams / 100 } }
    func vitaminA(forGrams grams: Double) -> Double? { vitaminA.map { $0 * grams / 100 } }
    func vitaminD(forGrams grams: Double) -> Double? { vitaminD.map { $0 * grams / 100 } }
    func vitaminE(forGrams grams: Double) -> Double? { vitaminE.map { $0 * grams / 100 } }
    func vitaminB12(forGrams grams: Double) -> Double? { vitaminB12.map { $0 * grams / 100 } }

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
    static func hasDuplicateName(_ candidate: String, in foods: [Food]) -> Bool {
        let trimmedCandidate = candidate.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCandidate.isEmpty else { return false }

        return foods.contains { food in
            food.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .localizedCaseInsensitiveCompare(trimmedCandidate) == .orderedSame
        }
    }

    /// Returnerar en lista med vanliga ingredienser att seeda databasen med
    ///
    /// Datakälla: Livsmedelsverket, Livsmedelsdatabasen (CC BY 4.0)
    /// https://www.livsmedelsverket.se/en/about-us/open-data/food-composition-data/
    /// Hämtad: 2026-04-05
    ///
    /// Kommentarerna i seed-listan anger Livsmedelsverkets livsmedels-ID för vald match.
    /// För kött och fisk är prioriterade mikronäringsvärden ifyllda från samma källa.
    static func seedData() -> [Food] {
        [
            // Kött
            // SLV 1173: Kyckling bröstfilé rå u. skinn
            Food(name: "Kycklingfilé",    category: .meat, caloriesPer100g: 110, proteinPer100g: 23,  fatPer100g: 2,   carbsPer100g: 0,   fiberPer100g: 0, calcium: 11, phosphorus: 196, iron: 0.7, zinc: 0.8, vitaminA: 7.0, vitaminD: 0.4, vitaminE: 1.1),
            // SLV 951: Nöt färs rå fett 10%
            Food(name: "Nötfärs (10%)",   category: .meat, caloriesPer100g: 152, proteinPer100g: 20,  fatPer100g: 8,   carbsPer100g: 0,   fiberPer100g: 0, calcium: 8, phosphorus: 162, iron: 2.0, zinc: 5.0, vitaminA: 12.5, vitaminD: 0.09, vitaminE: 0.6),
            // SLV 924: Lamm stek rå
            Food(name: "Lammlår",         category: .meat, caloriesPer100g: 162, proteinPer100g: 18,  fatPer100g: 10,  carbsPer100g: 0,   fiberPer100g: 0, calcium: 4, phosphorus: 220, iron: 2.1, zinc: 3.5, vitaminA: 3.9, vitaminD: 0.0, vitaminE: 0.3),
            // SLV 970: Gris fläskfilé rå
            Food(name: "Fläskfilé",       category: .meat, caloriesPer100g: 121, proteinPer100g: 22,  fatPer100g: 4,   carbsPer100g: 0,   fiberPer100g: 0, calcium: 5, phosphorus: 204, iron: 1.4, zinc: 1.7, vitaminA: 9.0, vitaminD: 0.57, vitaminE: 0.3),
            // SLV 1441: Kalv lever rå
            Food(name: "Kalvlever",       category: .meat, caloriesPer100g: 130, proteinPer100g: 20,  fatPer100g: 4,   carbsPer100g: 3,   fiberPer100g: 0, calcium: 10, phosphorus: 340, iron: 8.7, zinc: 3.2, vitaminA: 6602.7, vitaminD: 0.25, vitaminE: 0.7),
            // SLV 1453: Kyckling lever rå
            Food(name: "Kycklinglever",   category: .meat, caloriesPer100g: 119, proteinPer100g: 17,  fatPer100g: 5,   carbsPer100g: 1,   fiberPer100g: 0, calcium: 7, phosphorus: 333, iron: 7.3, zinc: 2.4, vitaminA: 9500.0, vitaminD: 0.4, vitaminE: 2.6),

            // Fisk
            // SLV 1255: Lax odlad Norge fjordlax rå
            Food(name: "Lax",             category: .fish, caloriesPer100g: 206, proteinPer100g: 20,  fatPer100g: 14,  carbsPer100g: 0,   fiberPer100g: 0, calcium: 5, phosphorus: 234, iron: 0.2, zinc: 0.3, vitaminA: 3.7, vitaminD: 7.37, vitaminE: 4.6),
            // SLV 1246: Torsk rå
            Food(name: "Torsk",           category: .fish, caloriesPer100g: 82,  proteinPer100g: 18,  fatPer100g: 1,   carbsPer100g: 0,   fiberPer100g: 0, calcium: 12, phosphorus: 217, iron: 0.1, zinc: 0.6, vitaminA: 2.3, vitaminD: 1.84, vitaminE: 0.7),
            // SLV 1260: Makrill rå
            Food(name: "Makrill",         category: .fish, caloriesPer100g: 205, proteinPer100g: 19,  fatPer100g: 14,  carbsPer100g: 0,   fiberPer100g: 0, calcium: 15, phosphorus: 194, iron: 0.8, zinc: 0.6, vitaminA: 15.0, vitaminD: 5.4, vitaminE: 0.4),
            // SLV 1271: Sardiner i olja konserv. (närmsta tillgängliga match till sardiner i vatten)
            Food(name: "Sardiner (vatten)",category: .fish,caloriesPer100g: 135, proteinPer100g: 24,  fatPer100g: 4,   carbsPer100g: 0,   fiberPer100g: 0, calcium: 191, phosphorus: 300, iron: 2.8, zinc: 2.0, vitaminA: 114.3, vitaminD: 15.0, vitaminE: 1.7),

            // Grönsaker
            // SLV 289: Morot
            Food(name: "Morot",           category: .vegetables, caloriesPer100g: 41,  proteinPer100g: 1,   fatPer100g: 0.2, carbsPer100g: 10,  fiberPer100g: 3),
            // SLV 325: Broccoli
            Food(name: "Broccoli",        category: .vegetables, caloriesPer100g: 34,  proteinPer100g: 3,   fatPer100g: 0.4, carbsPer100g: 7,   fiberPer100g: 3),
            // SLV 353: Pumpa
            Food(name: "Pumpa",           category: .vegetables, caloriesPer100g: 26,  proteinPer100g: 1,   fatPer100g: 0.1, carbsPer100g: 6,   fiberPer100g: 0.5),
            // SLV 4941: Spenat färsk
            Food(name: "Spenat",          category: .vegetables, caloriesPer100g: 23,  proteinPer100g: 3,   fatPer100g: 0.4, carbsPer100g: 4,   fiberPer100g: 2),
            // SLV 362: Squash (närmsta match till zucchini)
            Food(name: "Zucchini",        category: .vegetables, caloriesPer100g: 17,  proteinPer100g: 1,   fatPer100g: 0.3, carbsPer100g: 3,   fiberPer100g: 1),
            // SLV 3765: Sötpotatis rå
            Food(name: "Sötpotatis",      category: .vegetables, caloriesPer100g: 86,  proteinPer100g: 2,   fatPer100g: 0.1, carbsPer100g: 20,  fiberPer100g: 3),

            // Farliga – visas med varning
            // SLV 344: Lök gul
            Food(name: "Lök",             category: .vegetables, caloriesPer100g: 40,  proteinPer100g: 1, fatPer100g: 0.1, carbsPer100g: 9, fiberPer100g: 2,
                 isDangerousForDogs: true, dangerNote: "Giftigt för hundar – kan orsaka blodbrist."),
            // SLV 371: Vitlök
            Food(name: "Vitlök",          category: .vegetables, caloriesPer100g: 149, proteinPer100g: 6, fatPer100g: 0.5, carbsPer100g: 33, fiberPer100g: 2,
                 isDangerousForDogs: true, dangerNote: "Giftigt för hundar även i små mängder."),
            // SLV 587: Vindruvor
            Food(name: "Vindruvor",       category: .fruit,      caloriesPer100g: 67,  proteinPer100g: 1, fatPer100g: 0.4, carbsPer100g: 17, fiberPer100g: 1,
                 isDangerousForDogs: true, dangerNote: "Kan orsaka njursvikt hos hundar."),
            // SLV 610: Russin
            Food(name: "Russin",          category: .fruit,      caloriesPer100g: 299, proteinPer100g: 3, fatPer100g: 0.5, carbsPer100g: 79, fiberPer100g: 4,
                 isDangerousForDogs: true, dangerNote: "Kan orsaka allvarlig njurpåverkan hos hundar."),
            // SLV 2052: Mörk choklad kakao ≥ 70% (närmsta match till generell choklad)
            Food(name: "Choklad",         category: .other,      caloriesPer100g: 546, proteinPer100g: 5, fatPer100g: 31, carbsPer100g: 61, fiberPer100g: 7,
                 isDangerousForDogs: true, dangerNote: "Innehåller teobromin och är giftigt för hundar."),

            // Frukt
            // SLV 588: Äpple m. skal
            Food(name: "Äpple (utan kärnhus)", category: .fruit, caloriesPer100g: 52, proteinPer100g: 0.3, fatPer100g: 0.2, carbsPer100g: 14, fiberPer100g: 2),
            // SLV 555: Blåbär
            Food(name: "Blåbär",          category: .fruit,      caloriesPer100g: 57,  proteinPer100g: 1,   fatPer100g: 0.3, carbsPer100g: 14,  fiberPer100g: 2),
            // SLV 553: Banan
            Food(name: "Banan",           category: .fruit,      caloriesPer100g: 89,  proteinPer100g: 1,   fatPer100g: 0.3, carbsPer100g: 23,  fiberPer100g: 3),
            // SLV 549: Vattenmelon
            Food(name: "Vattenmelon (utan frön)", category: .fruit, caloriesPer100g: 30, proteinPer100g: 1, fatPer100g: 0.2, carbsPer100g: 8,  fiberPer100g: 0.4),

            // Spannmål
            // SLV 2517: Ris råris långkornigt kokt m. salt fullkorn
            Food(name: "Brunt ris (kokt)",category: .grains,     caloriesPer100g: 112, proteinPer100g: 2,   fatPer100g: 0.9, carbsPer100g: 23,  fiberPer100g: 2),
            // SLV 702: Havregryn fullkorn
            Food(name: "Havregryn",       category: .grains,     caloriesPer100g: 389, proteinPer100g: 17,  fatPer100g: 7,   carbsPer100g: 66,  fiberPer100g: 11),
            // SLV 3518: Quinoa röd kokt m. salt (närmsta kokta quinoa-match)
            Food(name: "Quinoa (kokt)",   category: .grains,     caloriesPer100g: 120, proteinPer100g: 4,   fatPer100g: 2,   carbsPer100g: 21,  fiberPer100g: 3),

            // Mejeri & Ägg
            // SLV 1225: Ägg rått
            Food(name: "Ägg",             category: .eggs,       caloriesPer100g: 155, proteinPer100g: 13,  fatPer100g: 11,  carbsPer100g: 1,   fiberPer100g: 0),
            // SLV 70: Färskost cottage cheese naturell fett 4%
            Food(name: "Keso",            category: .dairy,      caloriesPer100g: 98,  proteinPer100g: 11,  fatPer100g: 4,   carbsPer100g: 4,   fiberPer100g: 0),
            // SLV 124: Yoghurt naturell fett 3% berikad
            Food(name: "Naturell yoghurt",category: .dairy,      caloriesPer100g: 61,  proteinPer100g: 4,   fatPer100g: 3,   carbsPer100g: 5,   fiberPer100g: 0),

            // Tillskott
            // Ingen direkt SLV-match för fiskolja hittades i öppna livsmedelsdatabasen 2026-04-05.
            Food(name: "Fiskolja",        category: .supplements, caloriesPer100g: 902, proteinPer100g: 0, fatPer100g: 100, carbsPer100g: 0,  fiberPer100g: 0),
        ]
    }
}
