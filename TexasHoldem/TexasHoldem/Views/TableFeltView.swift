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
            // Outer wooden rail
            RoundedRectangle(cornerRadius: 160)
                .fill(
                    LinearGradient(colors: [Color(red: 0.30, green: 0.18, blue: 0.09),
                                             Color(red: 0.18, green: 0.10, blue: 0.05)],
                                   startPoint: .top, endPoint: .bottom)
                )

            // Felt surface, inset from the rail
            RoundedRectangle(cornerRadius: 150)
                .fill(
                    RadialGradient(colors: [feltColor.opacity(0.85), feltColor],
                                   center: .center, startRadius: 10, endRadius: 420)
                )
                .padding(14)
                .overlay(
                    RoundedRectangle(cornerRadius: 138)
                        .stroke(Color.white.opacity(0.18), lineWidth: 2)
                        .padding(14)
                )
                .overlay(
                    // Faint suit watermark for texture
                    Image(systemName: "suit.spade.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 90)
                        .foregroundColor(.white.opacity(0.05))
                )
                .shadow(color: .black.opacity(0.5), radius: 20, x: 0, y: 10)

            VStack(spacing: 16) {
                Text("Pot: $\(pot)")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 16).padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.45)))
                    .overlay(Capsule().stroke(Color.yellow.opacity(0.4), lineWidth: 1))

                HStack(spacing: 10) {
                    ForEach(0..<5, id: \.self) { i in
                        if i < communityCards.count {
                            CardView(card: communityCards[i], width: 68)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            CardView(card: nil, faceDown: true, width: 68)
                                .opacity(0.2)
                        }
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: communityCards.count)
            }

            content
        }
    }

    private var feltColor: Color { FeltPalette.color(for: feltID) }
}
