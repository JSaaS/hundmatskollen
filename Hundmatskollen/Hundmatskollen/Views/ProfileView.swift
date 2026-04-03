import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var dogs: [Dog]

    @State private var dogPendingDeletion: Dog?

    var body: some View {
        NavigationStack {
            List {
                ForEach(dogs) { dog in
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
                .onDelete(perform: prepareDelete)
            }
            .navigationTitle("Profil")
            .toolbar {
                NavigationLink(destination: AddDogView()) {
                    Image(systemName: "plus")
                }

                if !dogs.isEmpty {
                    EditButton()
                }
            }
            .alert(
                "Ta bort hundprofil?",
                isPresented: isShowingDeleteAlert,
                presenting: dogPendingDeletion
            ) { dog in
                Button("Ta bort", role: .destructive) {
                    delete(dog)
                }
                Button("Avbryt", role: .cancel) {
                    dogPendingDeletion = nil
                }
            } message: { dog in
                Text("Profilen för \(dog.name) och tillhörande måltider och recept tas bort.")
            }
        }
    }

    private var isShowingDeleteAlert: Binding<Bool> {
        Binding(
            get: { dogPendingDeletion != nil },
            set: { isPresented in
                if !isPresented {
                    dogPendingDeletion = nil
                }
            }
        )
    }

    private func prepareDelete(at offsets: IndexSet) {
        guard let index = offsets.first else { return }
        dogPendingDeletion = dogs[index]
    }

    private func delete(_ dog: Dog) {
        modelContext.delete(dog)
        dogPendingDeletion = nil
    }
}
