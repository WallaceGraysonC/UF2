import SwiftUI
import UIKit

struct CardView: View {
    let card: Card?
    var faceDown: Bool = false
    var cardBackID: String = CosmeticCatalog.defaultCardBack
    var cardFaceID: String = CosmeticCatalog.defaultCardFace
    var width: CGFloat = 52

    var body: some View {
        RoundedRectangle(cornerRadius: width * 0.14, style: .continuous)
            .fill(faceDown || card == nil ? cardBackFill : cardFaceFill)
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
                            .font(.system(size: width * 0.34, weight: CardFacePalette.weight(for: cardFaceID), design: CardFacePalette.design(for: cardFaceID)))
                        Text(card.suit.symbol)
                            .font(.system(size: width * 0.34, design: CardFacePalette.design(for: cardFaceID)))
                    }
                    .foregroundColor(CardFacePalette.inkColor(isRed: card.suit.isRed, for: cardFaceID))
                    // A custom face photo can be any color, so give the
                    // rank/suit text a light backing plate to stay legible.
                    .padding(.horizontal, isCustomFace ? width * 0.08 : 0)
                    .background(isCustomFace ? Color.white.opacity(0.75) : Color.clear)
                    .cornerRadius(width * 0.08)
                } else {
                    Image(systemName: "suit.club.fill")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.system(size: width * 0.4))
                }
            }
            .materialShadow(radius: max(1.5, width * 0.05), y: max(1, width * 0.035))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        guard let card, !faceDown else { return card == nil ? "Empty card slot" : "Face-down card" }
        return card.spokenName
    }

    private var isCustomFace: Bool {
        cardFaceID == CustomCosmeticStore.customID(for: .cardFace) && CustomCosmeticStore.shared.hasImage(for: .cardFace)
    }

    private var cardBackFill: AnyShapeStyle {
        CustomCosmeticFill.style(
            for: cardBackID, kind: .cardBack,
            fallback: AnyShapeStyle(PATheme.cardBackMaterial(base: CardBackPalette.color(for: cardBackID)))
        )
    }

    private var cardFaceFill: AnyShapeStyle {
        CustomCosmeticFill.style(for: cardFaceID, kind: .cardFace, fallback: AnyShapeStyle(PATheme.cardMaterial))
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
