import Foundation
import SwiftData

// MARK: - Enums

/// Hundens kön
enum DogGender: String, Codable, CaseIterable {
    case male   = "Hane"
    case female = "Tik"
}

/// Hundens aktivitetsnivå – påverkar kaloribehovet
enum ActivityLevel: String, Codable, CaseIterable {
    case low      = "Låg"
    case moderate = "Medel"
    case high     = "Hög"
    case athlete  = "Träningshund"

    /// Multiplikator mot RER (Resting Energy Requirement)
    var factor: Double {
        switch self {
        case .low:      return 1.2
        case .moderate: return 1.6
        case .high:     return 2.0
        case .athlete:  return 3.0
        }
    }
}

/// Hundens hälsostatus – kan påverka rekommenderade näringsvärden
enum HealthStatus: String, Codable, CaseIterable {
    case healthy  = "Frisk"
    case puppy    = "Valp"
    case senior   = "Senior"
    case pregnant = "Dräktig/Digivande"
    case sick     = "Sjuk"
    case weightLoss = "Viktnedgång"
    case weightGain = "Viktuppgång"
}

// MARK: - Dog Model

/// Representerar en hund med profil och hälsoinformation.
/// Lagras persistent med SwiftData.
@Model
final class Dog {

    // Grundinfo
    var name: String
    var breed: String
    var weightKg: Double
    var birthDate: Date
    var gender: DogGender

    // Hälsa & mål
    var healthStatus: HealthStatus
    var activityLevel: ActivityLevel

    // Metadata
    var createdAt: Date

    // Relationer
    @Relationship(deleteRule: .cascade) var meals: [Meal] = []
    @Relationship(deleteRule: .cascade) var recipes: [Recipe] = []

    init(
        name: String,
        breed: String = "",
        weightKg: Double,
        birthDate: Date = Date(),
        gender: DogGender = .male,
        healthStatus: HealthStatus = .healthy,
        activityLevel: ActivityLevel = .moderate
    ) {
        self.name = name
        self.breed = breed
        self.weightKg = weightKg
        self.birthDate = birthDate
        self.gender = gender
        self.healthStatus = healthStatus
        self.activityLevel = activityLevel
        self.createdAt = Date()
    }

    // MARK: - Beräknade näringsvärden

    /// Ålder i år (beräknad från birthDate)
    var ageInYears: Int {
        Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
    }

    /// RER = Resting Energy Requirement (kcal/dag)
    /// Formel: 70 × vikt_kg^0.75
    var rer: Double {
        70 * pow(weightKg, 0.75)
    }

    /// MER = Maintenance Energy Requirement (kcal/dag)
    /// RER × aktivitetsfaktor
    var dailyCalories: Double {
        rer * activityLevel.factor
    }

    /// Rekommenderat dagligt proteinintag (gram)
    /// Grundregel: ~25% av kalorier från protein (1g protein = 4 kcal)
    var dailyProteinGrams: Double {
        (dailyCalories * 0.25) / 4
    }

    /// Rekommenderat dagligt fettintag (gram)
    /// Grundregel: ~30% av kalorier från fett (1g fett = 9 kcal)
    var dailyFatGrams: Double {
        (dailyCalories * 0.30) / 9
    }

    /// Rekommenderat dagligt kolhydratintag (gram)
    /// Grundregel: ~45% av kalorier från kolhydrater (1g = 4 kcal)
    var dailyCarbGrams: Double {
        (dailyCalories * 0.45) / 4
    }

    /// Rekommenderat dagligt vattenintag (ml)
    /// Grundregel: ~50ml per kg kroppsvikt
    var dailyWaterMl: Double {
        weightKg * 50
    }
}
