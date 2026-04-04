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

    var description: String {
        switch self {
        case .low:
            return "Passar hundar som mest tar lugna promenader och vilar mycket."
        case .moderate:
            return "För normal vardagsaktivitet med regelbundna promenader och lek."
        case .high:
            return "För aktiva hundar som tränar ofta eller rör sig mycket varje dag."
        case .athlete:
            return "För arbetande eller hårt tränande hundar med högt energibehov."
        }
    }
}

/// Hundens hälsostatus – kan påverka rekommenderade näringsvärden
enum HealthStatus: String, Codable, CaseIterable {
    case healthy    = "Frisk"
    case puppy      = "Valp"
    case senior     = "Senior"
    case pregnant   = "Dräktig/Digivande"
    case sick       = "Sjuk"
    case weightLoss = "Viktnedgång"
    case weightGain = "Viktuppgång"

    static var profileOptions: [HealthStatus] {
        [.healthy, .puppy, .senior, .pregnant, .sick]
    }

    var description: String {
        switch self {
        case .healthy:
            return "Standardläge för en frisk vuxen hund."
        case .puppy:
            return "Valpar behöver mer energi och protein för tillväxt."
        case .senior:
            return "Seniorhundar behöver ofta lite mindre energi men fortsatt bra proteinkvalitet."
        case .pregnant:
            return "Dräktiga eller digivande tikar behöver extra energi och näring."
        case .sick:
            return "Vid sjukdom bör rekommendationerna ses som vägledande och veterinär rådfrågas."
        case .weightLoss:
            return "Äldre alternativ för viktnedgångsmål."
        case .weightGain:
            return "Äldre alternativ för viktuppgångsmål."
        }
    }

    var calorieFactor: Double {
        switch self {
        case .healthy:
            return 1.0
        case .puppy:
            return 1.8
        case .senior:
            return 0.9
        case .pregnant:
            return 1.4
        case .sick:
            return 1.0
        case .weightLoss:
            return 0.9
        case .weightGain:
            return 1.1
        }
    }

    var proteinShare: Double {
        switch self {
        case .healthy, .senior:
            return 0.25
        case .puppy, .pregnant, .sick:
            return 0.28
        case .weightLoss:
            return 0.32
        case .weightGain:
            return 0.27
        }
    }

    var fatShare: Double {
        switch self {
        case .healthy, .senior, .sick:
            return 0.30
        case .puppy, .pregnant:
            return 0.32
        case .weightLoss:
            return 0.28
        case .weightGain:
            return 0.31
        }
    }

    var waterFactor: Double {
        switch self {
        case .healthy, .senior, .weightLoss, .weightGain:
            return 50
        case .puppy:
            return 60
        case .pregnant:
            return 65
        case .sick:
            return 70
        }
    }
}

enum FeedingGoal: String, Codable, CaseIterable {
    case maintain   = "Underhåll"
    case loseWeight = "Viktnedgång"
    case gainWeight = "Viktuppgång"

    var description: String {
        switch self {
        case .maintain:
            return "Behåll nuvarande vikt med balanserat energiintag."
        case .loseWeight:
            return "Sänk energin något men håll proteinintaget uppe för att bevara muskelmassa."
        case .gainWeight:
            return "Öka energin stegvis för att stödja viktuppgång."
        }
    }

    var calorieFactor: Double {
        switch self {
        case .maintain:
            return 1.0
        case .loseWeight:
            return 0.85
        case .gainWeight:
            return 1.15
        }
    }

    var proteinShareAdjustment: Double {
        switch self {
        case .maintain:
            return 0
        case .loseWeight:
            return 0.03
        case .gainWeight:
            return 0.01
        }
    }
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
    var feedingGoalRawValue: String?

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
        activityLevel: ActivityLevel = .moderate,
        feedingGoal: FeedingGoal = .maintain
    ) {
        self.name = name
        self.breed = breed
        self.weightKg = weightKg
        self.birthDate = birthDate
        self.gender = gender
        self.healthStatus = healthStatus
        self.activityLevel = activityLevel
        self.feedingGoalRawValue = feedingGoal.rawValue
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

    /// Dagsbehov i kcal utifrån aktivitet, hälsostatus och mål
    var dailyCalories: Double {
        rer * activityLevel.factor * healthStatus.calorieFactor * feedingGoal.calorieFactor
    }

    /// Rekommenderat dagligt proteinintag (gram)
    var dailyProteinGrams: Double {
        let proteinShare = min(healthStatus.proteinShare + feedingGoal.proteinShareAdjustment, 0.4)
        return (dailyCalories * proteinShare) / 4
    }

    /// Rekommenderat dagligt fettintag (gram)
    var dailyFatGrams: Double {
        (dailyCalories * healthStatus.fatShare) / 9
    }

    /// Rekommenderat dagligt kolhydratintag (gram)
    var dailyCarbGrams: Double {
        let proteinCalories = dailyProteinGrams * 4
        let fatCalories = dailyFatGrams * 9
        let remainingCalories = max(dailyCalories - proteinCalories - fatCalories, 0)
        return remainingCalories / 4
    }

    /// Rekommenderat dagligt fiberintag (gram)
    var dailyFiberGrams: Double {
        let baseFiber = weightKg * 1.0
        let healthAdjustment: Double
        switch healthStatus {
        case .healthy, .senior:
            healthAdjustment = 1.0
        case .puppy:
            healthAdjustment = 0.8
        case .pregnant:
            healthAdjustment = 1.1
        case .sick:
            healthAdjustment = 0.9
        case .weightLoss:
            healthAdjustment = 1.1
        case .weightGain:
            healthAdjustment = 0.95
        }

        let goalAdjustment: Double
        switch feedingGoal {
        case .maintain:
            goalAdjustment = 1.0
        case .loseWeight:
            goalAdjustment = 1.1
        case .gainWeight:
            goalAdjustment = 0.95
        }

        return max(baseFiber * healthAdjustment * goalAdjustment, 1)
    }

    /// Rekommenderat dagligt vattenintag (ml)
    var dailyWaterMl: Double {
        weightKg * healthStatus.waterFactor
    }

    var feedingGoal: FeedingGoal {
        get { FeedingGoal(rawValue: feedingGoalRawValue ?? "") ?? .maintain }
        set { feedingGoalRawValue = newValue.rawValue }
    }
}
