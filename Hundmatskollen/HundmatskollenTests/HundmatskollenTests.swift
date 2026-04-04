//
//  HundmatskollenTests.swift
//  HundmatskollenTests
//
//  Created by Joakim Schütt on 2026-04-03.
//

import Foundation
import Testing
@testable import Hundmatskollen

struct HundmatskollenTests {

    @Test("RER beräknas korrekt för standardvikt")
    func rerForStandardWeight() {
        let dog = Dog(name: "Fido", weightKg: 10)
        let expected = 70 * pow(10.0, 0.75)
        #expect(abs(dog.rer - expected) < 0.01)
    }

    @Test("Aktivitetsnivå påverkar kaloribehovet")
    func activityLevelAffectsCalories() {
        let lowActivityDog = Dog(name: "Fido", weightKg: 10, activityLevel: .low)
        let highActivityDog = Dog(name: "Fido", weightKg: 10, activityLevel: .high)

        #expect(highActivityDog.dailyCalories > lowActivityDog.dailyCalories)
    }

    @Test("Mål för viktnedgång ger lägre kaloribehov än underhåll")
    func loseWeightGoalLowersCalories() {
        let maintainDog = Dog(
            name: "Fido",
            weightKg: 10,
            healthStatus: .healthy,
            activityLevel: .moderate,
            feedingGoal: .maintain
        )
        let loseWeightDog = Dog(
            name: "Fido",
            weightKg: 10,
            healthStatus: .healthy,
            activityLevel: .moderate,
            feedingGoal: .loseWeight
        )

        #expect(loseWeightDog.dailyCalories < maintainDog.dailyCalories)
    }

    @Test("Dagligt fibermål är positivt och påverkas av målval")
    func dailyFiberGoalIsPositiveAndAdjustsForGoal() {
        let maintainDog = Dog(name: "Fido", weightKg: 20, feedingGoal: .maintain)
        let loseWeightDog = Dog(name: "Fido", weightKg: 20, feedingGoal: .loseWeight)

        #expect(maintainDog.dailyFiberGrams > 0)
        #expect(loseWeightDog.dailyFiberGrams > maintainDog.dailyFiberGrams)
    }

    @Test("Ogiltigt feedingGoalRawValue faller tillbaka till underhåll")
    func invalidFeedingGoalDefaultsToMaintain() {
        let dog = Dog(name: "Fido", weightKg: 10)
        dog.feedingGoalRawValue = "ogiltigt_värde"

        #expect(dog.feedingGoal == .maintain)
    }

    @Test("Farliga livsmedel finns markerade i seed-data")
    func dangerousFoodsAreFlaggedInSeedData() {
        let onion = Food.seedData().first { $0.name == "Lök" }
        let chocolate = Food.seedData().first { $0.name == "Choklad" }
        let raisins = Food.seedData().first { $0.name == "Russin" }

        #expect(onion != nil)
        #expect(onion?.isDangerousForDogs == true)
        #expect(!(onion?.dangerNote.isEmpty ?? true))
        #expect(chocolate?.isDangerousForDogs == true)
        #expect(raisins?.isDangerousForDogs == true)
    }

    @Test("Seed-data innehåller minst 20 ingredienser")
    func seedDataContainsAtLeastTwentyFoods() {
        #expect(Food.seedData().count >= 20)
    }

    @Test("Egen ingrediens markeras som custom")
    func customFoodIsMarkedAsCustom() {
        let customFood = Food(
            name: "Grönläppad mussla",
            category: .supplements,
            caloriesPer100g: 320,
            proteinPer100g: 58,
            fatPer100g: 7,
            carbsPer100g: 12,
            fiberPer100g: 0,
            isCustom: true
        )

        #expect(customFood.isCustom == true)
        #expect(customFood.isDangerousForDogs == false)
    }

    @Test("Egen ingrediens fungerar i recept- och måltidssummering")
    func customFoodParticipatesInMealAndRecipeTotals() {
        let customFood = Food(
            name: "Hemgjord mix",
            category: .other,
            caloriesPer100g: 180,
            proteinPer100g: 12,
            fatPer100g: 8,
            carbsPer100g: 14,
            fiberPer100g: 3,
            isCustom: true
        )

        let meal = Meal(type: .dinner)
        meal.items.append(MealItem(food: customFood, grams: 150))

        let recipe = Recipe(name: "Kvällsmix")
        recipe.items.append(RecipeItem(food: customFood, grams: 200))

        #expect(abs(meal.totalCalories - 270) < 0.01)
        #expect(abs(meal.totalProtein - 18) < 0.01)
        #expect(abs(recipe.totalCalories - 360) < 0.01)
        #expect(abs(recipe.totalFiber - 6) < 0.01)
    }

    @Test("Seed-data placerar ingredienser i rätt kategorier")
    func seedDataUsesExpectedCategories() {
        let salmon = Food.seedData().first { $0.name == "Lax" }
        let sweetPotato = Food.seedData().first { $0.name == "Sötpotatis" }
        let oats = Food.seedData().first { $0.name == "Havregryn" }

        #expect(salmon?.category == .fish)
        #expect(sweetPotato?.category == .vegetables)
        #expect(oats?.category == .grains)
    }

    @Test("Custom-ingrediens är inte farlig som standard")
    func customFoodIsNotDangerousByDefault() {
        let customFood = Food(
            name: "Eget tillskott",
            category: .supplements,
            caloriesPer100g: 100,
            proteinPer100g: 10,
            fatPer100g: 2,
            carbsPer100g: 5,
            fiberPer100g: 1,
            isCustom: true
        )

        #expect(customFood.isCustom == true)
        #expect(customFood.isDangerousForDogs == false)
        #expect(customFood.dangerNote.isEmpty)
    }

    @Test("Ändringar på egen ingrediens slår igenom i recept och måltider")
    func editingCustomFoodUpdatesRelatedTotals() {
        let customFood = Food(
            name: "Egen mix",
            category: .other,
            caloriesPer100g: 100,
            proteinPer100g: 10,
            fatPer100g: 5,
            carbsPer100g: 10,
            fiberPer100g: 2,
            isCustom: true
        )

        let meal = Meal(type: .dinner)
        meal.items.append(MealItem(food: customFood, grams: 100))

        let recipe = Recipe(name: "Mixrecept")
        recipe.items.append(RecipeItem(food: customFood, grams: 200))

        customFood.caloriesPer100g = 150
        customFood.proteinPer100g = 20
        customFood.isDangerousForDogs = true
        customFood.dangerNote = "Ny varning"

        #expect(abs(meal.totalCalories - 150) < 0.01)
        #expect(abs(meal.totalProtein - 20) < 0.01)
        #expect(abs(recipe.totalCalories - 300) < 0.01)
        #expect(recipe.dangerousItemCount == 1)
    }

    @Test("Meal summerar totalsiffror korrekt")
    func mealTotalsAreSummedCorrectly() {
        let salmon = Food(
            name: "Lax",
            category: .fish,
            caloriesPer100g: 206,
            proteinPer100g: 20,
            fatPer100g: 14,
            carbsPer100g: 0,
            fiberPer100g: 0
        )

        let meal = Meal(type: .dinner)
        meal.items.append(MealItem(food: salmon, grams: 150))

        #expect(abs(meal.totalCalories - 309) < 0.01)
        #expect(abs(meal.totalProtein - 30) < 0.01)
        #expect(abs(meal.totalFat - 21) < 0.01)
        #expect(abs(meal.totalGrams - 150) < 0.01)
    }

    @Test("DailyNutrition summerar flera måltider")
    func dailyNutritionSumsMultipleMeals() {
        let food = Food(
            name: "Kyckling",
            category: .meat,
            caloriesPer100g: 100,
            proteinPer100g: 20,
            fatPer100g: 5,
            carbsPer100g: 0,
            fiberPer100g: 0
        )

        let breakfast = Meal(type: .breakfast)
        breakfast.items.append(MealItem(food: food, grams: 100))
        breakfast.waterMl = 150

        let dinner = Meal(type: .dinner)
        dinner.items.append(MealItem(food: food, grams: 200))
        dinner.waterMl = 250

        let daily = [breakfast, dinner].dailyNutrition()

        #expect(abs(daily.calories - 300) < 0.01)
        #expect(abs(daily.protein - 60) < 0.01)
        #expect(abs(daily.waterMl - 400) < 0.01)
    }

    @Test("Vätska kan loggas utan ingredienser")
    func waterOnlyMealContributesToDailyNutrition() {
        let meal = Meal(type: .snack, waterMl: 275)

        let daily = [meal].dailyNutrition()

        #expect(daily.calories == 0)
        #expect(daily.waterMl == 275)
    }

    @Test("NutritionProgress begränsas till max 1.0")
    func nutritionProgressIsCappedAtOne() {
        let dog = Dog(name: "Fido", weightKg: 10)
        var daily = DailyNutrition()
        daily.calories = dog.dailyCalories * 5
        daily.protein = dog.dailyProteinGrams * 5
        daily.fat = dog.dailyFatGrams * 5
        daily.carbs = dog.dailyCarbGrams * 5
        daily.fiber = dog.dailyFiberGrams * 5
        daily.waterMl = dog.dailyWaterMl * 5

        let progress = daily.progress(for: dog)

        #expect(progress.calories <= 1.0)
        #expect(progress.protein <= 1.0)
        #expect(progress.fat <= 1.0)
        #expect(progress.carbs <= 1.0)
        #expect(progress.fiber <= 1.0)
        #expect(progress.water <= 1.0)
    }
}
