//
//  HundmatskollenTests.swift
//  Hundmatskollen
//
//  Created by Joakim Schütt on 2026-04-03.
//
import XCTest
@testable import Hundmatskollen

// MARK: - Dog Tests

final class DogTests: XCTestCase {

    // MARK: RER (Resting Energy Requirement)

    func test_rer_standardWeight() {
        let dog = Dog(name: "Fido", weightKg: 10)
        let expected = 70 * pow(10.0, 0.75)
        XCTAssertEqual(dog.rer, expected, accuracy: 0.01)
    }

    func test_rer_smallDog() {
        let dog = Dog(name: "Tiny", weightKg: 2)
        let expected = 70 * pow(2.0, 0.75)
        XCTAssertEqual(dog.rer, expected, accuracy: 0.01)
    }

    func test_rer_largeDog() {
        let dog = Dog(name: "Rex", weightKg: 40)
        let expected = 70 * pow(40.0, 0.75)
        XCTAssertEqual(dog.rer, expected, accuracy: 0.01)
    }

    // MARK: Aktivitetsfaktorer

    func test_activityFactor_low()      { XCTAssertEqual(ActivityLevel.low.factor,      1.2) }
    func test_activityFactor_moderate() { XCTAssertEqual(ActivityLevel.moderate.factor,  1.6) }
    func test_activityFactor_high()     { XCTAssertEqual(ActivityLevel.high.factor,      2.0) }
    func test_activityFactor_athlete()  { XCTAssertEqual(ActivityLevel.athlete.factor,   3.0) }

    // MARK: Dagligt kaloribehov

    func test_dailyCalories_friskMedel() {
        let dog = Dog(name: "Fido", weightKg: 10,
                      healthStatus: .healthy,
                      activityLevel: .moderate,
                      feedingGoal: .maintain)
        let expected = 70 * pow(10.0, 0.75) * 1.6 * 1.0 * 1.0
        XCTAssertEqual(dog.dailyCalories, expected, accuracy: 0.01)
    }

    func test_dailyCalories_puppy() {
        let dog = Dog(name: "Bamse", weightKg: 5,
                      healthStatus: .puppy,
                      activityLevel: .moderate,
                      feedingGoal: .maintain)
        let expected = 70 * pow(5.0, 0.75) * 1.6 * 1.8 * 1.0
        XCTAssertEqual(dog.dailyCalories, expected, accuracy: 0.01)
    }

    func test_dailyCalories_weightLoss() {
        let dog = Dog(name: "Ludde", weightKg: 15,
                      healthStatus: .healthy,
                      activityLevel: .moderate,
                      feedingGoal: .loseWeight)
        let expected = 70 * pow(15.0, 0.75) * 1.6 * 1.0 * 0.85
        XCTAssertEqual(dog.dailyCalories, expected, accuracy: 0.01)
    }

    func test_dailyCalories_weightGain() {
        let dog = Dog(name: "Slim", weightKg: 8,
                      healthStatus: .healthy,
                      activityLevel: .moderate,
                      feedingGoal: .gainWeight)
        let expected = 70 * pow(8.0, 0.75) * 1.6 * 1.0 * 1.15
        XCTAssertEqual(dog.dailyCalories, expected, accuracy: 0.01)
    }

    // MARK: Protein

    func test_dailyProtein_healthy() {
        let dog = Dog(name: "Fido", weightKg: 10,
                      healthStatus: .healthy,
                      activityLevel: .moderate,
                      feedingGoal: .maintain)
        let expected = (dog.dailyCalories * 0.25) / 4
        XCTAssertEqual(dog.dailyProteinGrams, expected, accuracy: 0.01)
    }

    func test_dailyProtein_weightLossHasHigherShare() {
        let dogLoss = Dog(name: "A", weightKg: 10, healthStatus: .healthy,
                          activityLevel: .moderate, feedingGoal: .loseWeight)
        let dogMaintain = Dog(name: "B", weightKg: 10, healthStatus: .healthy,
                              activityLevel: .moderate, feedingGoal: .maintain)
        let shareLoss     = (dogLoss.dailyProteinGrams * 4) / dogLoss.dailyCalories
        let shareMaintain = (dogMaintain.dailyProteinGrams * 4) / dogMaintain.dailyCalories
        XCTAssertGreaterThan(shareLoss, shareMaintain)
    }

    func test_dailyProtein_cappedAt40Percent() {
        let dog = Dog(name: "Test", weightKg: 10, healthStatus: .puppy,
                      activityLevel: .moderate, feedingGoal: .loseWeight)
        let share = (dog.dailyProteinGrams * 4) / dog.dailyCalories
        XCTAssertLessThanOrEqual(share, 0.40)
    }

    // MARK: Fett

    func test_dailyFat_healthy() {
        let dog = Dog(name: "Fido", weightKg: 10, healthStatus: .healthy,
                      activityLevel: .moderate)
        let expected = (dog.dailyCalories * 0.30) / 9
        XCTAssertEqual(dog.dailyFatGrams, expected, accuracy: 0.01)
    }

    // MARK: Vatten

    func test_dailyWater_healthy() {
        let dog = Dog(name: "Fido", weightKg: 10, healthStatus: .healthy)
        XCTAssertEqual(dog.dailyWaterMl, 500, accuracy: 0.01) // 10 × 50
    }

    func test_dailyWater_sick() {
        let dog = Dog(name: "Fido", weightKg: 10, healthStatus: .sick)
        XCTAssertEqual(dog.dailyWaterMl, 700, accuracy: 0.01) // 10 × 70
    }

    func test_dailyWater_puppy() {
        let dog = Dog(name: "Bamse", weightKg: 5, healthStatus: .puppy)
        XCTAssertEqual(dog.dailyWaterMl, 300, accuracy: 0.01) // 5 × 60
    }

    // MARK: FeedingGoal getter/setter

    func test_feedingGoal_getSet() {
        let dog = Dog(name: "Fido", weightKg: 10, feedingGoal: .loseWeight)
        XCTAssertEqual(dog.feedingGoal, .loseWeight)
        dog.feedingGoal = .gainWeight
        XCTAssertEqual(dog.feedingGoal, .gainWeight)
    }

    func test_feedingGoal_invalidRawValueDefaultsToMaintain() {
        let dog = Dog(name: "Fido", weightKg: 10)
        dog.feedingGoalRawValue = "ogiltigt_värde"
        XCTAssertEqual(dog.feedingGoal, .maintain)
    }
}

// MARK: - Food Tests

final class FoodTests: XCTestCase {

    private func makeChicken() -> Food {
        Food(name: "Kycklingfilé", category: .meat,
             caloriesPer100g: 110, proteinPer100g: 23,
             fatPer100g: 2, carbsPer100g: 0, fiberPer100g: 0)
    }

    func test_calories_forGrams() {
        XCTAssertEqual(makeChicken().calories(forGrams: 200), 220, accuracy: 0.001)
    }

    func test_protein_forGrams() {
        XCTAssertEqual(makeChicken().protein(forGrams: 150), 34.5, accuracy: 0.001)
    }

    func test_fat_forGrams() {
        let salmon = Food(name: "Lax", category: .fish,
                          caloriesPer100g: 206, proteinPer100g: 20,
                          fatPer100g: 14, carbsPer100g: 0, fiberPer100g: 0)
        XCTAssertEqual(salmon.fat(forGrams: 100), 14.0, accuracy: 0.001)
    }

    func test_zeroGrams_givesZeroNutrition() {
        let food = Food(name: "Morot", category: .vegetables,
                        caloriesPer100g: 41, proteinPer100g: 1,
                        fatPer100g: 0.2, carbsPer100g: 10, fiberPer100g: 3)
        XCTAssertEqual(food.calories(forGrams: 0), 0)
        XCTAssertEqual(food.protein(forGrams: 0), 0)
        XCTAssertEqual(food.fat(forGrams: 0), 0)
        XCTAssertEqual(food.carbs(forGrams: 0), 0)
        XCTAssertEqual(food.fiber(forGrams: 0), 0)
    }

    func test_100gMatchesPer100gProperties() {
        let egg = Food(name: "Ägg", category: .eggs,
                       caloriesPer100g: 155, proteinPer100g: 13,
                       fatPer100g: 11, carbsPer100g: 1, fiberPer100g: 0)
        XCTAssertEqual(egg.calories(forGrams: 100), egg.caloriesPer100g)
        XCTAssertEqual(egg.protein(forGrams: 100),  egg.proteinPer100g)
        XCTAssertEqual(egg.fat(forGrams: 100),      egg.fatPer100g)
    }

    // MARK: Farliga livsmedel

    func test_onion_isDangerous() {
        let onion = Food.seedData().first { $0.name == "Lök" }
        XCTAssertNotNil(onion)
        XCTAssertTrue(onion!.isDangerousForDogs)
        XCTAssertFalse(onion!.dangerNote.isEmpty)
    }

    func test_chicken_isNotDangerous() {
        let chicken = Food.seedData().first { $0.name == "Kycklingfilé" }
        XCTAssertFalse(chicken!.isDangerousForDogs)
    }

    // MARK: Seed-data

    func test_seedData_hasAtLeast20Items() {
        XCTAssertGreaterThanOrEqual(Food.seedData().count, 20)
    }

    func test_seedData_allCaloriesPositive() {
        let bad = Food.seedData().filter { $0.caloriesPer100g <= 0 }
        XCTAssertTrue(bad.isEmpty, "Ingredienser med noll/negativa kalorier: \(bad.map(\.name))")
    }
}

// MARK: - Meal Tests

final class MealTests: XCTestCase {

    private func makeFood(name: String = "Mat",
                          cal: Double = 100, protein: Double = 20,
                          fat: Double = 5, carbs: Double = 0) -> Food {
        Food(name: name, category: .meat,
             caloriesPer100g: cal, proteinPer100g: protein,
             fatPer100g: fat, carbsPer100g: carbs, fiberPer100g: 0)
    }

    // MARK: Tom måltid

    func test_emptyMeal_hasZeroTotals() {
        let meal = Meal(type: .dinner)
        XCTAssertEqual(meal.totalCalories, 0)
        XCTAssertEqual(meal.totalProtein, 0)
        XCTAssertEqual(meal.totalFat, 0)
        XCTAssertEqual(meal.totalGrams, 0)
    }

    // MARK: MealItem

    func test_mealItem_calculatesCaloriesCorrectly() {
        let item = MealItem(food: makeFood(cal: 110), grams: 200)
        XCTAssertEqual(item.calories, 220, accuracy: 0.001)
    }

    // MARK: Måltidssummering

    func test_meal_singleIngredient_totals() {
        let salmon = Food(name: "Lax", category: .fish,
                          caloriesPer100g: 206, proteinPer100g: 20,
                          fatPer100g: 14, carbsPer100g: 0, fiberPer100g: 0)
        let meal = Meal(type: .dinner)
        meal.items.append(MealItem(food: salmon, grams: 150))

        XCTAssertEqual(meal.totalCalories, 309.0, accuracy: 0.01)
        XCTAssertEqual(meal.totalProtein,   30.0, accuracy: 0.01)
        XCTAssertEqual(meal.totalFat,       21.0, accuracy: 0.01)
        XCTAssertEqual(meal.totalGrams,    150.0, accuracy: 0.01)
    }

    func test_meal_multipleIngredients_totals() {
        let meal = Meal(type: .dinner)
        meal.items.append(MealItem(food: makeFood(cal: 110), grams: 200)) // 220 kcal
        meal.items.append(MealItem(food: makeFood(cal:  41), grams: 100)) //  41 kcal
        XCTAssertEqual(meal.totalCalories, 261.0, accuracy: 0.01)
        XCTAssertEqual(meal.totalGrams,    300.0, accuracy: 0.01)
    }

    // MARK: DailyNutrition

    func test_dailyNutrition_sumsMeals() {
        let food = makeFood(cal: 100, protein: 20, fat: 5)
        let frukost = Meal(type: .breakfast)
        frukost.items.append(MealItem(food: food, grams: 100)) // 100 kcal, 20g protein

        let middag = Meal(type: .dinner)
        middag.items.append(MealItem(food: food, grams: 200)) // 200 kcal, 40g protein

        let daily = [frukost, middag].dailyNutrition()
        XCTAssertEqual(daily.calories, 300.0, accuracy: 0.01)
        XCTAssertEqual(daily.protein,   60.0, accuracy: 0.01)
    }

    func test_dailyNutrition_emptyList() {
        let daily = [Meal]().dailyNutrition()
        XCTAssertEqual(daily.calories, 0)
        XCTAssertEqual(daily.protein,  0)
    }

    // MARK: NutritionProgress

    func test_nutritionProgress_fullMet() {
        let dog = Dog(name: "Fido", weightKg: 10,
                      healthStatus: .healthy, activityLevel: .moderate)
        var daily = DailyNutrition()
        daily.calories = dog.dailyCalories
        daily.protein  = dog.dailyProteinGrams
        daily.fat      = dog.dailyFatGrams
        daily.carbs    = dog.dailyCarbGrams

        let p = daily.progress(for: dog)
        XCTAssertEqual(p.calories, 1.0, accuracy: 0.001)
        XCTAssertEqual(p.protein,  1.0, accuracy: 0.001)
        XCTAssertEqual(p.fat,      1.0, accuracy: 0.001)
    }

    func test_nutritionProgress_cappedAt1() {
        let dog = Dog(name: "Fido", weightKg: 10)
        var daily = DailyNutrition()
        daily.calories = dog.dailyCalories * 5
        daily.protein  = dog.dailyProteinGrams * 5
        daily.fat      = dog.dailyFatGrams * 5

        let p = daily.progress(for: dog)
        XCTAssertLessThanOrEqual(p.calories, 1.0)
        XCTAssertLessThanOrEqual(p.protein,  1.0)
        XCTAssertLessThanOrEqual(p.fat,      1.0)
    }

    func test_nutritionProgress_halfMet() {
        let dog = Dog(name: "Fido", weightKg: 10,
                      healthStatus: .healthy, activityLevel: .moderate)
        var daily = DailyNutrition()
        daily.calories = dog.dailyCalories / 2

        let p = daily.progress(for: dog)
        XCTAssertEqual(p.calories, 0.5, accuracy: 0.001)
    }
}
