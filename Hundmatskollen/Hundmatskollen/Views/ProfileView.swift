import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var dogs: [Dog]

    var body: some View {
        NavigationStack {
            List(dogs) { dog in
                NavigationLink {
                    EditDogView(dog: dog)
                } label: {
                    VStack(alignment: .leading) {
                        Text(dog.name)
                            .font(.headline)
                        Text("\(dog.breed) · \(String(format: "%.1f", dog.weightKg)) kg")
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle("Profil")
            .toolbar {
                NavigationLink(destination: AddDogView()) {
                    Image(systemName: "plus")
                }
            }
        }
    }
}
