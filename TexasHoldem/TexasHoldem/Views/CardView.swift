import SwiftUI

struct CardView: View {
    let card: Card?
    var faceDown: Bool = false
    var cardBackID: String = CosmeticCatalog.defaultCardBack
    var width: CGFloat = 52

    var body: some View {
        RoundedRectangle(cornerRadius: width * 0.14)
            .fill(faceDown || card == nil ? cardBackColor : Color.white)
            .frame(width: width, height: width * 1.4)
            .overlay(
                RoundedRectangle(cornerRadius: width * 0.14)
                    .stroke(Color.black.opacity(0.25), lineWidth: 1)
            )
            .overlay {
                if !faceDown, let card {
                    VStack(spacing: 2) {
                        Text(card.rank.label)
                            .font(.system(size: width * 0.34, weight: .bold, design: .rounded))
                        Text(card.suit.symbol)
                            .font(.system(size: width * 0.34))
                    }
                    .foregroundColor(card.suit.isRed ? .red : .black)
                } else {
                    Image(systemName: "suit.club.fill")
                        .foregroundColor(.white.opacity(0.35))
                        .font(.system(size: width * 0.4))
                }
            }
            .shadow(radius: 1.5)
    }

    private var cardBackColor: Color { CardBackPalette.color(for: cardBackID) }
}

#Preview {
    HStack {
        CardView(card: Card(rank: .ace, suit: .spades))
        CardView(card: nil, faceDown: true)
    }
    .padding()
    .background(Color.green)
}
