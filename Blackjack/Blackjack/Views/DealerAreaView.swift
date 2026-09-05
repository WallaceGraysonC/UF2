import SwiftUI

/// Shared felt background + dealer's hand, used by both the local (bot)
/// table and the online multiplayer table. Seat content is built from the
/// felt's *own* measured size (not the outer screen), so seat spacing stays
/// correct regardless of how big the caller sizes the table.
struct DealerAreaView<Content: View>: View {
    let dealer: DealerHand
    let feltID: String
    let railID: String
    let cardBackID: String
    let cardFaceID: String
    let content: (CGSize) -> Content

    init(dealer: DealerHand, feltID: String, railID: String = CosmeticCatalog.defaultRail,
         cardBackID: String = CosmeticCatalog.defaultCardBack, cardFaceID: String = CosmeticCatalog.defaultCardFace,
         @ViewBuilder content: @escaping (CGSize) -> Content) {
        self.dealer = dealer
        self.feltID = feltID
        self.railID = railID
        self.cardBackID = cardBackID
        self.cardFaceID = cardFaceID
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
        ZStack {
            // Outer rail, with a seam where it meets the felt -- both
            // customizable via the Table Rail cosmetic slot.
            RoundedRectangle(cornerRadius: 160)
                .fill(CustomCosmeticFill.style(for: railID, kind: .tableRail, fallback: AnyShapeStyle(RailPalette.gradient(for: railID))))
                .overlay(
                    RoundedRectangle(cornerRadius: 148)
                        .strokeBorder(RailPalette.seamColor(for: railID), lineWidth: 3)
                        .padding(10)
                        .opacity(0.55)
                )

            // Felt surface, inset from the rail
            RoundedRectangle(cornerRadius: 150)
                .fill(
                    CustomCosmeticFill.style(
                        for: feltID, kind: .tableFelt,
                        fallback: AnyShapeStyle(
                            RadialGradient(colors: [feltColor.opacity(0.9), feltColor, BJTheme.feltDeeper.opacity(0.4)],
                                           center: UnitPoint(x: 0.4, y: 0.35), startRadius: 10, endRadius: 460)
                        )
                    )
                )
                .padding(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 136)
                        .stroke(Color.white.opacity(0.16), lineWidth: 1.5)
                        .padding(16)
                )
                .overlay(
                    // Faint suit watermark for texture
                    Image(systemName: "suit.spade.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90)
                        .foregroundColor(.white.opacity(0.05))
                )
                .shadow(color: .black.opacity(0.55), radius: 22, x: 0, y: 12)

            VStack(spacing: 10) {
                Text("Dealer")
                    .font(.caption.bold())
                    .tracking(1.2)
                    .foregroundColor(.white.opacity(0.55))

                HStack(spacing: 7) {
                    ForEach(Array(dealer.visibleCards.enumerated()), id: \.offset) { index, card in
                        CardView(card: card, cardFaceID: cardFaceID, width: 50)
                            .transition(.scale.combined(with: .opacity))
                    }
                    if !dealer.holeCardRevealed, dealer.cards.count > 1 {
                        CardView(card: nil, faceDown: true, cardBackID: cardBackID, width: 50)
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: dealer.cards.count)
                .animation(.easeInOut(duration: 0.3), value: dealer.holeCardRevealed)

                if !dealer.displayTotal.isEmpty {
                    Text(dealer.displayTotal)
                        .font(.title3.bold())
                        .foregroundColor(BJTheme.ink)
                        .padding(.horizontal, 18).padding(.vertical, 7)
                        .background(Capsule().fill(BJTheme.goldMaterial))
                        .overlay(Capsule().stroke(BJTheme.goldBright.opacity(0.6), lineWidth: 1))
                        .materialShadow(radius: 6, y: 3)
                        .transition(.scale.combined(with: .opacity))
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: dealer.displayTotal)
                }
            }
            // Sit a bit above dead-center -- most seats (including the human's,
            // dead-bottom) cluster in the lower half of the table, so shifting
            // the dealer up gives them more clearance instead of splitting it evenly.
            .position(x: geo.size.width / 2, y: geo.size.height * 0.38)

            content(geo.size)
        }
        }
    }

    private var feltColor: Color { FeltPalette.color(for: feltID) }
}
