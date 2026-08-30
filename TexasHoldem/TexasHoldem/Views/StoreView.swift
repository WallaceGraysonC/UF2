import SwiftUI

/// Cosmetics shop. Every item is purchased with the free virtual chip
/// currency earned at the table -- there is no real-money purchase path
/// anywhere in this screen. Pricier items also require having reached a
/// certain lifetime chip peak (won at the table, not just topped up) --
/// see `BankrollManager.isUnlocked(_:)`.
struct StoreView: View {
    @EnvironmentObject var bankroll: BankrollManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedKind: CosmeticKind = .cardBack

    var body: some View {
        NavigationView {
            VStack {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(CosmeticKind.allCases, id: \.self) { kind in
                            Button {
                                selectedKind = kind
                            } label: {
                                Text(kind.displayName)
                                    .font(.subheadline.bold())
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(selectedKind == kind ? AnyShapeStyle(PATheme.goldMaterial) : AnyShapeStyle(Color.white.opacity(0.08)))
                                    )
                                    .foregroundColor(selectedKind == kind ? PATheme.ink : .white)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 16)], spacing: 16) {
                        ForEach(CosmeticCatalog.items(of: selectedKind)) { item in
                            CosmeticCard(item: item)
                        }
                    }
                    .padding()
                }
            }
            .tint(PATheme.gold)
            .navigationTitle("Store")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Label("\(bankroll.chips)", systemImage: "dollarsign.circle.fill")
                        .foregroundColor(PATheme.goldBright)
                }
            }
        }
    }
}

private struct CosmeticCard: View {
    @EnvironmentObject var bankroll: BankrollManager
    let item: Cosmetic

    var owned: Bool { bankroll.owns(item) }
    var unlocked: Bool { bankroll.isUnlocked(item) }
    var equipped: Bool {
        switch item.kind {
        case .cardBack: return bankroll.equippedCardBack == item.id
        case .cardFace: return bankroll.equippedCardFace == item.id
        case .tableFelt: return bankroll.equippedFelt == item.id
        case .tableRail: return bankroll.equippedRail == item.id
        case .tableBackdrop: return bankroll.equippedBackdrop == item.id
        case .chipSet: return bankroll.equippedChips == item.id
        case .avatar: return bankroll.equippedAvatar == item.id
        case .avatarFrame: return bankroll.equippedAvatarFrame == item.id
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            swatch
                .frame(height: 70)
                .opacity(unlocked ? 1 : 0.4)
            Text(item.name).font(.subheadline.bold())

            if equipped {
                Text("Equipped")
                    .font(.caption).bold()
                    .foregroundColor(.green)
            } else if owned {
                Button("Equip") { bankroll.equip(item) }
                    .buttonStyle(.bordered)
                    .tint(PATheme.goldBright)
            } else if !unlocked {
                VStack(spacing: 3) {
                    Label("\(item.price)", systemImage: "lock.fill")
                        .font(.footnote.bold())
                        .foregroundColor(.secondary)
                    Text("Reach $\(item.unlockRequirement) to unlock")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                Button {
                    bankroll.purchase(item)
                } label: {
                    Label("\(item.price)", systemImage: "dollarsign.circle")
                }
                .buttonStyle(.borderedProminent)
                .tint(PATheme.gold)
                .foregroundStyle(PATheme.ink)
                .disabled(bankroll.chips < item.price)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(colors: [PATheme.feltGlow.opacity(0.5), PATheme.feltDeeper],
                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(equipped ? PATheme.goldBright.opacity(0.6) : Color.white.opacity(0.08), lineWidth: equipped ? 1.5 : 1)
        )
        .materialShadow(radius: 5, y: 3)
    }

    @ViewBuilder
    private var swatch: some View {
        switch item.kind {
        case .cardBack:
            CardView(card: nil, faceDown: true, cardBackID: item.id, width: 44)
        case .cardFace:
            CardView(card: Card(rank: .ace, suit: .spades), cardFaceID: item.id, width: 44)
        case .tableFelt:
            RoundedRectangle(cornerRadius: 10).fill(feltColor)
        case .tableRail:
            RoundedRectangle(cornerRadius: 10)
                .fill(RailPalette.gradient(for: item.id))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(RailPalette.seamColor(for: item.id), lineWidth: 2)
                        .padding(4)
                )
        case .tableBackdrop:
            RoundedRectangle(cornerRadius: 10)
                .fill(BackdropPalette.gradient(for: item.id))
        case .chipSet:
            HStack(spacing: -8) {
                Circle().fill(chipColor).frame(width: 30, height: 30)
                Circle().fill(chipColor.opacity(0.7)).frame(width: 30, height: 30)
            }
        case .avatar:
            Image(systemName: AvatarPalette.symbol(for: item.id))
                .font(.system(size: 34))
                .foregroundColor(.white)
        case .avatarFrame:
            ZStack {
                Circle().fill(Color.black.opacity(0.35))
                Image(systemName: "person.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white)
            }
            .frame(width: 48, height: 48)
            .overlay(Circle().strokeBorder(AvatarFramePalette.stroke(for: item.id), lineWidth: 3))
        }
    }

    private var feltColor: Color { FeltPalette.color(for: item.id) }

    private var chipColor: Color { ChipPalette.color(for: item.id) }
}
