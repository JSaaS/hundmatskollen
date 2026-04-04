import SwiftUI
import SwiftData

/// Appens rotnav – en TabView med de fyra huvudflikarna
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dogs: [Dog]
    @Query private var foods: [Food]

    var body: some View {
        Group {
            if dogs.isEmpty {
                // Ingen hund skapad ännu – visa onboarding
                NavigationStack {
                    WelcomeView()
                }
            } else {
                MainTabView()
            }
        }
        .task {
            seedFoodsIfNeeded()
        }
    }

    private func seedFoodsIfNeeded() {
        guard foods.isEmpty else { return }

        Food.seedData().forEach { food in
            modelContext.insert(food)
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Could not save seeded foods: \(error)")
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Dog.self, Food.self, Meal.self, MealItem.self, Recipe.self, RecipeItem.self], inMemory: true)
}
