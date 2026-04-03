import SwiftUI
import SwiftData
 
@main
struct HundmatskollenApp: App {
 
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Dog.self,
            Food.self,
            Meal.self,
            MealItem.self,
            Recipe.self,
            RecipeItem.self,
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
 
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
 
