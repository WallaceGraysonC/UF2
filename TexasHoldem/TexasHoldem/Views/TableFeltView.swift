import SwiftUI

/// Shared felt background + community card row, used by both the local
/// (bot) table and the online multiplayer table.
struct TableFeltView<Content: View>: View {
    let communityCards: [Card]
    let pot: Int
    let feltID: String
    let content: Content

    init(communityCards: [Card], pot: Int, feltID: String, @ViewBuilder content: () -> Content) {
        self.communityCards = communityCards
        self.pot = pot
        self.feltID = feltID
        self.content = content()
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 140)
                .fill(feltColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 140)
                        .stroke(Color.black.opacity(0.4), lineWidth: 10)
                )

            VStack(spacing: 12) {
                Text("Pot: $\(pot)")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.4)))

                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { i in
                        if i < communityCards.count {
                            CardView(card: communityCards[i], width: 44)
                        } else {
                            CardView(card: nil, faceDown: true, width: 44)
                                .opacity(0.25)
                        }
                    }
                }
            }

            content
        }
    }

    private var feltColor: Color {
        switch feltID {
        case "felt.royalBlue": return Color(red: 0.10, green: 0.22, blue: 0.55)
        case "felt.charcoal": return Color(red: 0.18, green: 0.18, blue: 0.2)
        case "felt.sunset": return Color(red: 0.55, green: 0.22, blue: 0.15)
        default: return Color(red: 0.05, green: 0.4, blue: 0.22)
        }
    }
}
