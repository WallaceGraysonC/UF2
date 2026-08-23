import SwiftUI

/// Cosmetics shop. Every item is purchased with the free virtual chip
/// currency earned at the table -- there is no real-money purchase path
/// anywhere in this screen.
struct StoreView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @State private var selectedKind: CosmeticKind = .cardBack

    var body: some View {
        NavigationView {
            VStack {
                Picker("Category", selection: $selectedKind) {
                    Text("Card Backs").tag(CosmeticKind.cardBack)
                    Text("Table Felt").tag(CosmeticKind.tableFelt)
                    Text("Chips").tag(CosmeticKind.chipSet)
                    Text("Avatars").tag(CosmeticKind.avatar)
                }
                .pickerStyle(.segmented)
                .padding()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                        ForEach(CosmeticCatalog.items(of: selectedKind)) { item in
                            CosmeticCard(item: item)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Store")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Label("\(bankroll.chips)", systemImage: "dollarsign.circle.fill")
                        .foregroundColor(.yellow)
                }
            }
        }
    }
}

private struct CosmeticCard: View {
    @EnvironmentObject var bankroll: BankrollManager
    let item: Cosmetic

    var owned: Bool { bankroll.owns(item) }
    var equipped: Bool {
        switch item.kind {
        case .cardBack: return bankroll.equippedCardBack == item.id
        case .tableFelt: return bankroll.equippedFelt == item.id
        case .chipSet: return bankroll.equippedChips == item.id
        case .avatar: return bankroll.equippedAvatar == item.id
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            swatch
                .frame(height: 70)
            Text(item.name).font(.subheadline.bold())

            if equipped {
                Text("Equipped")
                    .font(.caption).bold()
                    .foregroundColor(.green)
            } else if owned {
                Button("Equip") { bankroll.equip(item) }
                    .buttonStyle(.bordered)
            } else {
                Button {
                    bankroll.purchase(item)
                } label: {
                    Label("\(item.price)", systemImage: "dollarsign.circle")
                }
                .buttonStyle(.borderedProminent)
                .disabled(bankroll.chips < item.price)
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(.secondarySystemBackground)))
    }

    @ViewBuilder
    private var swatch: some View {
        switch item.kind {
        case .cardBack:
            CardView(card: nil, faceDown: true, cardBackID: item.id, width: 44)
        case .tableFelt:
            RoundedRectangle(cornerRadius: 10).fill(feltColor)
        case .chipSet:
            HStack(spacing: -8) {
                Circle().fill(chipColor).frame(width: 30, height: 30)
                Circle().fill(chipColor.opacity(0.7)).frame(width: 30, height: 30)
            }
        case .avatar:
            Image(systemName: avatarSymbol)
                .font(.system(size: 34))
                .foregroundColor(.white)
        }
    }

    private var feltColor: Color {
        switch item.id {
        case "felt.royalBlue": return Color(red: 0.10, green: 0.22, blue: 0.55)
        case "felt.charcoal": return Color(red: 0.18, green: 0.18, blue: 0.2)
        case "felt.sunset": return Color(red: 0.55, green: 0.22, blue: 0.15)
        default: return Color(red: 0.05, green: 0.4, blue: 0.22)
        }
    }

    private var chipColor: Color {
        switch item.id {
        case "chips.neon": return .green
        case "chips.marble": return .gray
        default: return .red
        }
    }

    private var avatarSymbol: String {
        switch item.id {
        case "avatar.shark": return "fish.fill"
        case "avatar.robot": return "faceid"
        case "avatar.crown": return "crown.fill"
        default: return "person.circle.fill"
        }
    }
}
