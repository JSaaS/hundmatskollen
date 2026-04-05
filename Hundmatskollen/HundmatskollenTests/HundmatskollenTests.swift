//
//  HundmatskollenTests.swift
//  HundmatskollenTests
//
//  Created by Joakim Schütt on 2026-04-03.
//

import Foundation
import SwiftData
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

    @Test("Ingrediens kan använda milliliter som föredragen enhet")
    func foodCanUseMillilitersAsPreferredUnit() {
        let customFood = Food(
            name: "Benbuljong",
            category: .other,
            caloriesPer100g: 15,
            proteinPer100g: 3,
            fatPer100g: 0,
            carbsPer100g: 0,
            fiberPer100g: 0,
            isCustom: true,
            preferredUnit: .milliliters
        )

        #expect(customFood.preferredUnit == .milliliters)
        #expect(customFood.quantityLabel == "ml")
        #expect(customFood.quantityFieldLabel == "Mängd (ml)")
    }

    @Test("Ogiltig enhetslagring faller tillbaka till gram")
    func invalidPreferredUnitDefaultsToGrams() {
        let food = Food(
            name: "Mjölk",
            category: .dairy,
            caloriesPer100g: 60,
            proteinPer100g: 3,
            fatPer100g: 3,
            carbsPer100g: 5,
            fiberPer100g: 0,
            isCustom: true
        )

        food.preferredUnitRawValue = "invalid"

        #expect(food.preferredUnit == .grams)
    }

    @Test("Befintlig Food-init faller tillbaka till nil för mikronäringsfält")
    func foodMicronutrientsDefaultToNil() {
        let food = Food(
            name: "Kyckling",
            category: .meat,
            caloriesPer100g: 110,
            proteinPer100g: 23,
            fatPer100g: 2,
            carbsPer100g: 0,
            fiberPer100g: 0
        )

        #expect(food.calcium == nil)
        #expect(food.phosphorus == nil)
        #expect(food.magnesium == nil)
        #expect(food.iron == nil)
        #expect(food.zinc == nil)
        #expect(food.sodium == nil)
        #expect(food.vitaminA == nil)
        #expect(food.vitaminD == nil)
        #expect(food.vitaminE == nil)
        #expect(food.vitaminB12 == nil)
    }

    @Test("Food kan spara och läsa mikronäringsfält korrekt")
    func foodStoresMicronutrients() {
        let food = Food(
            name: "Nötlever",
            category: .meat,
            caloriesPer100g: 135,
            proteinPer100g: 20,
            fatPer100g: 4,
            carbsPer100g: 3,
            fiberPer100g: 0,
            calcium: 6,
            phosphorus: 387,
            magnesium: 18,
            iron: 5.4,
            zinc: 4.0,
            sodium: 69,
            vitaminA: 4968,
            vitaminD: 1.2,
            vitaminE: 0.6,
            vitaminB12: 70.7
        )

        #expect(food.calcium == 6)
        #expect(food.phosphorus == 387)
        #expect(food.magnesium == 18)
        #expect(food.iron == 5.4)
        #expect(food.zinc == 4.0)
        #expect(food.sodium == 69)
        #expect(food.vitaminA == 4968)
        #expect(food.vitaminD == 1.2)
        #expect(food.vitaminE == 0.6)
        #expect(food.vitaminB12 == 70.7)
    }

    @Test("Ingrediensdetaljen bygger mikronäringsrader för värden som finns")
    func foodDetailMicronutrientEntriesIncludeOnlyAvailableValues() {
        let food = Food(
            name: "Sardin",
            category: .fish,
            caloriesPer100g: 150,
            proteinPer100g: 20,
            fatPer100g: 9,
            carbsPer100g: 0,
            fiberPer100g: 0,
            calcium: 250,
            zinc: 1.3,
            vitaminB12: 8.9
        )

        let entries = food.micronutrientEntries

        #expect(entries.count == 3)
        #expect(entries.map(\.title) == ["Kalcium", "Zink", "Vitamin B12"])
        #expect(entries[0].valueText == "250 mg")
        #expect(entries[1].valueText == "1,3 mg" || entries[1].valueText == "1.3 mg")
        #expect(entries[2].valueText == "8,9 µg" || entries[2].valueText == "8.9 µg")
    }

    @Test("Ingrediensdetaljen döljer mikronäringssektionen när alla värden saknas")
    func foodDetailMicronutrientEntriesAreEmptyWhenAllValuesAreMissing() {
        let food = Food(
            name: "Kyckling",
            category: .meat,
            caloriesPer100g: 110,
            proteinPer100g: 23,
            fatPer100g: 2,
            carbsPer100g: 0,
            fiberPer100g: 0
        )

        #expect(food.micronutrientEntries.isEmpty)
    }

    @Test("Mikronäringsmetoder skalar värden per gram korrekt")
    func micronutrientScalingUsesPerHundredGramValues() {
        let food = Food(
            name: "Sardin",
            category: .fish,
            caloriesPer100g: 150,
            proteinPer100g: 20,
            fatPer100g: 9,
            carbsPer100g: 0,
            fiberPer100g: 0,
            calcium: 250,
            phosphorus: 300,
            magnesium: 35,
            iron: 2.7,
            zinc: 1.3,
            sodium: 180,
            vitaminA: 45,
            vitaminD: 4.8,
            vitaminE: 2.1,
            vitaminB12: 8.9
        )

        #expect(food.calcium(forGrams: 40) == 100)
        #expect(food.phosphorus(forGrams: 40) == 120)
        #expect(food.magnesium(forGrams: 40) == 14)
        #expect(food.iron(forGrams: 40) == 1.08)
        #expect(food.zinc(forGrams: 40) == 0.52)
        #expect(food.sodium(forGrams: 40) == 72)
        #expect(food.vitaminA(forGrams: 40) == 18)
        #expect(food.vitaminD(forGrams: 40) == 1.92)
        #expect(food.vitaminE(forGrams: 40) == 0.84)
        #expect(food.vitaminB12(forGrams: 40) == 3.56)
    }

    @Test("Mikronäringsmetoder returnerar nil när värdet saknas")
    func micronutrientScalingReturnsNilWhenMissing() {
        let food = Food(
            name: "Kyckling",
            category: .meat,
            caloriesPer100g: 110,
            proteinPer100g: 23,
            fatPer100g: 2,
            carbsPer100g: 0,
            fiberPer100g: 0
        )

        #expect(food.calcium(forGrams: 50) == nil)
        #expect(food.vitaminD(forGrams: 50) == nil)
        #expect(food.vitaminB12(forGrams: 50) == nil)
    }

    @Test("ModelContainer startar med uppdaterad Food-modell")
    @MainActor
    func modelContainerStartsWithMicronutrientFields() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)

        let container = try ModelContainer(
            for: Dog.self,
            Food.self,
            Meal.self,
            MealItem.self,
            PlannedMeal.self,
            Recipe.self,
            RecipeItem.self,
            configurations: configuration
        )

        _ = container.mainContext
    }

    @Test("Dubblettnamn för ingrediens hittas skiftlägesokänsligt")
    func duplicateFoodNameDetectionIsCaseInsensitive() {
        let existingFoods = [
            Food(
                name: "Kycklingfilé",
                category: .meat,
                caloriesPer100g: 110,
                proteinPer100g: 23,
                fatPer100g: 2,
                carbsPer100g: 0,
                fiberPer100g: 0
            )
        ]

        #expect(Food.hasDuplicateName("kycklingfilé", in: existingFoods))
        #expect(Food.hasDuplicateName("  Kycklingfilé  ", in: existingFoods))
        #expect(!Food.hasDuplicateName("Torsk", in: existingFoods))
        #expect(!Food.hasDuplicateName("   ", in: existingFoods))
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

    @Test("Planerat mål använder receptnamn när recept är länkat")
    func plannedMealUsesRecipeNameWhenLinked() {
        let dog = Dog(name: "Fido", weightKg: 12)
        let recipe = Recipe(dog: dog, name: "Söndagsgryta")
        let plannedMeal = PlannedMeal(
            dog: dog,
            recipe: recipe,
            scheduledDate: Date(),
            type: .dinner
        )

        #expect(plannedMeal.displayTitle == "Söndagsgryta")
        #expect(plannedMeal.sourceLabel == "Recept")
    }

    @Test("Planerat mål faller tillbaka till eget namn eller måltidstyp")
    func plannedMealFallsBackToCustomTitleOrMealType() {
        let dog = Dog(name: "Fido", weightKg: 12)
        let freeMeal = PlannedMeal(
            dog: dog,
            scheduledDate: Date(),
            type: .lunch,
            title: "Lätt lunch"
        )
        let unnamedMeal = PlannedMeal(
            dog: dog,
            scheduledDate: Date(),
            type: .snack
        )

        #expect(freeMeal.displayTitle == "Lätt lunch")
        #expect(freeMeal.sourceLabel == "Eget mål")
        #expect(unnamedMeal.displayTitle == MealType.snack.displayTitle)
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

    @Test("DailyNutrition summerar mikronäring med blandade nil-värden")
    func dailyNutritionSumsMicronutrientsWithMixedValues() {
        let calciumRichFood = Food(
            name: "Benmjöl",
            category: .supplements,
            caloriesPer100g: 200,
            proteinPer100g: 0,
            fatPer100g: 0,
            carbsPer100g: 0,
            fiberPer100g: 0,
            calcium: 1200,
            phosphorus: 600
        )
        let plainFood = Food(
            name: "Ris",
            category: .grains,
            caloriesPer100g: 130,
            proteinPer100g: 2,
            fatPer100g: 0.3,
            carbsPer100g: 28,
            fiberPer100g: 0.4
        )
        let zincFood = Food(
            name: "Nötkött",
            category: .meat,
            caloriesPer100g: 250,
            proteinPer100g: 26,
            fatPer100g: 15,
            carbsPer100g: 0,
            fiberPer100g: 0,
            zinc: 4.0
        )

        let breakfast = Meal(type: .breakfast)
        breakfast.items.append(MealItem(food: calciumRichFood, grams: 10))
        breakfast.items.append(MealItem(food: plainFood, grams: 100))

        let dinner = Meal(type: .dinner)
        dinner.items.append(MealItem(food: zincFood, grams: 50))

        let daily = [breakfast, dinner].dailyNutrition()

        #expect(daily.calcium == 120)
        #expect(daily.phosphorus == 60)
        #expect(daily.zinc == 2)
        #expect(daily.magnesium == nil)
        #expect(daily.vitaminB12 == nil)
    }

    @Test("Vätska kan loggas utan ingredienser")
    func waterOnlyMealContributesToDailyNutrition() {
        let meal = Meal(type: .snack, waterMl: 275)

        let daily = [meal].dailyNutrition()

        #expect(daily.calories == 0)
        #expect(daily.waterMl == 275)
    }

    @Test("Ingredienser med ml-enhet räknas som vätska")
    func milliliterIngredientContributesToFluidGoal() {
        let broth = Food(
            name: "Benbuljong",
            category: .other,
            caloriesPer100g: 12,
            proteinPer100g: 2,
            fatPer100g: 0,
            carbsPer100g: 0,
            fiberPer100g: 0,
            isCustom: true,
            preferredUnit: .milliliters
        )

        let meal = Meal(type: .dinner)
        meal.items.append(MealItem(food: broth, grams: 50))

        let daily = [meal].dailyNutrition()

        #expect(meal.totalWaterMl == 50)
        #expect(daily.waterMl == 50)
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

    @Test("Vikt kan visas i pounds och konverteras tillbaka till kilo")
    func weightDisplayConversionUsesPounds() {
        let displayed = DisplayFormatter.weightText(fromKilograms: 10, unit: .pounds)
        let metric = DisplayFormatter.metricWeight(fromDisplayValue: 22.0462, unit: .pounds)

        #expect(displayed == "22.0 lb")
        #expect(abs(metric - 10) < 0.01)
    }

    @Test("Volym kan visas i fluid ounces och konverteras tillbaka till milliliter")
    func volumeDisplayConversionUsesFluidOunces() {
        let displayed = DisplayFormatter.volumeText(fromMilliliters: 100, unit: .fluidOunces)
        let metric = DisplayFormatter.metricFoodAmount(
            fromDisplayValue: 3.3814,
            foodUnit: .milliliters,
            weightUnit: .kilograms,
            volumeUnit: .fluidOunces
        )

        #expect(displayed == "3.4 fl oz")
        #expect(abs(metric - 100) < 0.2)
    }

    @Test("Makrovärden kan visas i ounces när viktinställningen är imperial")
    func massDisplayConversionUsesOunces() {
        let displayed = DisplayFormatter.massText(fromGrams: 56.699, unit: .pounds)

        #expect(displayed == "2 oz")
    }

    @Test("Gram-baserad ingrediens kan visas i ounces och konverteras tillbaka")
    func foodAmountConversionForGramBasedFoodUsesOunces() {
        let displayedValue = DisplayFormatter.displayFoodAmountValue(
            fromMetricAmount: 85.0485,
            foodUnit: .grams,
            weightUnit: .pounds,
            volumeUnit: .milliliters
        )
        let metricValue = DisplayFormatter.metricFoodAmount(
            fromDisplayValue: 3,
            foodUnit: .grams,
            weightUnit: .pounds,
            volumeUnit: .milliliters
        )

        #expect(abs(displayedValue - 3) < 0.01)
        #expect(abs(metricValue - 85.0485) < 0.01)
        #expect(DisplayFormatter.foodAmountUnitLabel(for: .grams, weightUnit: .pounds, volumeUnit: .milliliters) == "oz")
    }

    @Test("Milliliter-baserad ingrediens kan visas i fluid ounces och konverteras tillbaka")
    func foodAmountConversionForMilliliterFoodUsesFluidOunces() {
        let displayedValue = DisplayFormatter.displayFoodAmountValue(
            fromMetricAmount: 59.147,
            foodUnit: .milliliters,
            weightUnit: .kilograms,
            volumeUnit: .fluidOunces
        )
        let metricValue = DisplayFormatter.metricFoodAmount(
            fromDisplayValue: 2,
            foodUnit: .milliliters,
            weightUnit: .kilograms,
            volumeUnit: .fluidOunces
        )

        #expect(abs(displayedValue - 2) < 0.01)
        #expect(abs(metricValue - 59.147) < 0.01)
        #expect(DisplayFormatter.foodAmountUnitLabel(for: .milliliters, weightUnit: .kilograms, volumeUnit: .fluidOunces) == "fl oz")
    }
}
