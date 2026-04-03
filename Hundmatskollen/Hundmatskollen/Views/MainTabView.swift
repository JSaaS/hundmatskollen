import SwiftUI

/// Fyra flikar: Idag, Vecka, Recept, Profil
struct MainTabView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Idag", systemImage: "fork.knife")
                }

            WeekView()
                .tabItem {
                    Label("Vecka", systemImage: "calendar")
                }

            StatisticsView()
                .tabItem {
                    Label("Statistik", systemImage: "chart.xyaxis.line")
                }

            RecipesView()
                .tabItem {
                    Label("Recept", systemImage: "book.closed")
                }

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "pawprint")
                }
        }
        .tint(.orange)
    }
}
