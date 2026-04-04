import SwiftUI

struct FoodSafetyInfoView: View {
    private let dangerousFoods: [FoodSafetyInfoItem] = [
        FoodSafetyInfoItem(
            title: "Lök och vitlök",
            detail: "Kan skada de röda blodkropparna och orsaka blodbrist."
        ),
        FoodSafetyInfoItem(
            title: "Choklad",
            detail: "Innehåller teobromin som är giftigt för hundar, särskilt i mörk choklad."
        ),
        FoodSafetyInfoItem(
            title: "Vindruvor och russin",
            detail: "Kan orsaka allvarlig njurpåverkan även i små mängder."
        ),
        FoodSafetyInfoItem(
            title: "Xylitol",
            detail: "Kan ge farligt lågt blodsocker och påverka levern."
        ),
        FoodSafetyInfoItem(
            title: "Deg och alkohol",
            detail: "Jäsande deg kan ge alkoholförgiftning och kraftig buksvullnad."
        ),
        FoodSafetyInfoItem(
            title: "Salt",
            detail: "Större mängder kan orsaka saltförgiftning med kräkningar, törst och kramper."
        ),
        FoodSafetyInfoItem(
            title: "Avokado",
            detail: "Innehåller persin som kan påverka mage, tarm och hjärta negativt."
        )
    ]

    private let cautionFoods: [FoodSafetyInfoItem] = [
        FoodSafetyInfoItem(
            title: "Mjölk och laktosrika mejerier",
            detail: "Många hundar tål inte laktos och kan få gaser, magknip eller diarré."
        ),
        FoodSafetyInfoItem(
            title: "Frukt i större mängder",
            detail: "Socker och syra kan irritera magen och är inget som bör ges fritt."
        ),
        FoodSafetyInfoItem(
            title: "Nötter och hårda små bitar",
            detail: "Kan orsaka stopp i mage eller tarm och är därför olämpliga."
        )
    ]

    var body: some View {
        List {
            Section {
                Text("Här hittar du en enkel översikt över livsmedel som är farliga eller olämpliga för hundar. Informationen är vägledande och ersätter inte veterinär rådgivning.")
                    .foregroundStyle(.secondary)
            }

            Section("Farligt") {
                ForEach(dangerousFoods) { item in
                    FoodSafetyRow(
                        item: item,
                        tint: .red,
                        systemImage: "exclamationmark.triangle.fill"
                    )
                }
            }

            Section("Olämpligt / Försiktighet") {
                ForEach(cautionFoods) { item in
                    FoodSafetyRow(
                        item: item,
                        tint: .orange,
                        systemImage: "exclamationmark.circle.fill"
                    )
                }
            }

            Section("Om du misstänker förgiftning") {
                Label("Kontakta veterinär omedelbart.", systemImage: "cross.case.fill")
                    .foregroundStyle(.red)
                Text("Försök inte själv framkalla kräkning om du inte uttryckligen fått den instruktionen av veterinär eller Giftinformation.")
                    .foregroundStyle(.secondary)
            }

            Section("Källor") {
                Link(
                    "Sveland: Farliga livsmedel för din hund",
                    destination: URL(string: "https://sveland.se/articles/hund/farliga-livsmedel-for-din-hund")!
                )
                Link(
                    "If: Vad får hundar inte äta?",
                    destination: URL(string: "https://www.if.se/privat/forsakringar/djurforsakring/hundforsakring/skydda-din-hund/vad-far-hundar-inte-ata")!
                )
                Link(
                    "AniCura: Vad är farligt för hunden att äta?",
                    destination: URL(string: "https://www.anicura.se/for-djuragare/hund/fakta-och-rad/farligt-for-hunden-att-ata/")!
                )
                Text("Sidan bygger på namngiven extern källa och är avsedd som lättillgänglig vägledning i appen.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Farliga livsmedel")
    }
}

private struct FoodSafetyInfoItem: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

private struct FoodSafetyRow: View {
    let item: FoodSafetyInfoItem
    let tint: Color
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(item.title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(tint)
            Text(item.detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
