import SwiftUI

struct CardView: View {
    let card: Card?
    var faceDown: Bool = false
    var cardBackID: String = CosmeticCatalog.defaultCardBack
    var width: CGFloat = 52

    var body: some View {
        RoundedRectangle(cornerRadius: width * 0.14, style: .continuous)
            .fill(faceDown || card == nil ? cardBackMaterial : PATheme.cardMaterial)
            .frame(width: width, height: width * 1.4)
            .overlay(
                RoundedRectangle(cornerRadius: width * 0.14, style: .continuous)
                    .stroke(Color.black.opacity(0.22), lineWidth: 1)
            )
            // Sheen strip near the top edge -- the detail that reads as
            // "real card stock catching light" instead of a flat fill.
            .overlay(alignment: .top) {
                RoundedRectangle(cornerRadius: width * 0.05)
                    .fill(Color.white.opacity(0.28))
                    .frame(width: width * 0.58, height: width * 0.09)
                    .offset(y: width * 0.12)
                    .blendMode(.plusLighter)
            }
            .overlay {
                if !faceDown, let card {
                    VStack(spacing: 2) {
                        Text(card.rank.label)
                            .font(.system(size: width * 0.34, weight: .bold, design: .serif))
                        Text(card.suit.symbol)
                            .font(.system(size: width * 0.34))
                    }
                    .foregroundColor(card.suit.isRed ? PATheme.crimsonDeep : PATheme.ink)
                } else {
                    Image(systemName: "suit.club.fill")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: width * 0.4))
                }
            }
            .materialShadow(radius: max(1.5, width * 0.05), y: max(1, width * 0.035))
    }

    private var cardBackMaterial: LinearGradient {
        PATheme.cardBackMaterial(base: CardBackPalette.color(for: cardBackID))
    }
}

#Preview {
    HStack {
        CardView(card: Card(rank: .ace, suit: .spades))
        CardView(card: nil, faceDown: true)
    }
    .padding()
    .background(PATheme.feltDeep)
}
