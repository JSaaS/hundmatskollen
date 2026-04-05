import SwiftUI

enum SettingsKeys {
    static let weightUnit = "settings.weightUnit"
    static let volumeUnit = "settings.volumeUnit"
}

enum WeightDisplayUnit: String, CaseIterable, Identifiable {
    case kilograms = "kg"
    case pounds = "lb"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .kilograms:
            return "Kilogram"
        case .pounds:
            return "Pounds"
        }
    }
}

enum VolumeDisplayUnit: String, CaseIterable, Identifiable {
    case milliliters = "ml"
    case fluidOunces = "fl oz"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .milliliters:
            return "Milliliter"
        case .fluidOunces:
            return "Fluid ounces"
        }
    }
}

enum DisplayFormatter {
    static func massText(fromGrams grams: Double, unit: WeightDisplayUnit) -> String {
        switch unit {
        case .kilograms:
            return "\(formatted(grams)) g"
        case .pounds:
            return "\(formatted(grams / 28.3495)) oz"
        }
    }

    static func displayWeightValue(fromKilograms kilograms: Double, unit: WeightDisplayUnit) -> Double {
        switch unit {
        case .kilograms:
            return kilograms
        case .pounds:
            return kilograms * 2.20462
        }
    }

    static func metricWeight(fromDisplayValue value: Double, unit: WeightDisplayUnit) -> Double {
        switch unit {
        case .kilograms:
            return value
        case .pounds:
            return value / 2.20462
        }
    }

    static func weightText(fromKilograms kilograms: Double, unit: WeightDisplayUnit) -> String {
        "\(formatted(displayWeightValue(fromKilograms: kilograms, unit: unit))) \(unit.rawValue)"
    }

    static func volumeText(fromMilliliters milliliters: Double, unit: VolumeDisplayUnit) -> String {
        switch unit {
        case .milliliters:
            return "\(formatted(milliliters)) ml"
        case .fluidOunces:
            return "\(formatted(milliliters / 29.5735)) fl oz"
        }
    }

    static func displayFoodAmount(
        fromMetricAmount amount: Double,
        foodUnit: FoodMeasurementUnit,
        weightUnit: WeightDisplayUnit,
        volumeUnit: VolumeDisplayUnit
    ) -> String {
        formatted(
            displayFoodAmountValue(
                fromMetricAmount: amount,
                foodUnit: foodUnit,
                weightUnit: weightUnit,
                volumeUnit: volumeUnit
            )
        )
    }

    static func displayFoodAmountValue(
        fromMetricAmount amount: Double,
        foodUnit: FoodMeasurementUnit,
        weightUnit: WeightDisplayUnit,
        volumeUnit: VolumeDisplayUnit
    ) -> Double {
        switch foodUnit {
        case .grams:
            return weightUnit == .kilograms ? amount : amount / 28.3495
        case .milliliters:
            return volumeUnit == .milliliters ? amount : amount / 29.5735
        }
    }

    static func metricFoodAmount(
        fromDisplayValue value: Double,
        foodUnit: FoodMeasurementUnit,
        weightUnit: WeightDisplayUnit,
        volumeUnit: VolumeDisplayUnit
    ) -> Double {
        switch foodUnit {
        case .grams:
            return weightUnit == .kilograms ? value : value * 28.3495
        case .milliliters:
            return volumeUnit == .milliliters ? value : value * 29.5735
        }
    }

    static func foodAmountUnitLabel(
        for foodUnit: FoodMeasurementUnit,
        weightUnit: WeightDisplayUnit,
        volumeUnit: VolumeDisplayUnit
    ) -> String {
        switch foodUnit {
        case .grams:
            return weightUnit == .kilograms ? "g" : "oz"
        case .milliliters:
            return volumeUnit.rawValue
        }
    }

    private static func formatted(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }

        return String(format: "%.1f", value)
    }
}
