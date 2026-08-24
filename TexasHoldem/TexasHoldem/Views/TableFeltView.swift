import SwiftUI

/// Shared felt background + community card row, used by both the local
/// (bot) table and the online multiplayer table. Seat content is built from
/// the felt's *own* measured size (not the outer screen), so seat spacing
/// stays correct regardless of how big the caller sizes the table.
struct TableFeltView<Content: View>: View {
    let communityCards: [Card]
    let pot: Int
    let feltID: String
    let content: (CGSize) -> Content

    init(communityCards: [Card], pot: Int, feltID: String, @ViewBuilder content: @escaping (CGSize) -> Content) {
        self.communityCards = communityCards
        self.pot = pot
        self.feltID = feltID
        self.content = content
    }

    var body: some View {
        GeometryReader { geo in
        ZStack {
            // Outer wooden rail, with a gold piping seam where it meets the felt
            RoundedRectangle(cornerRadius: 160)
                .fill(
                    LinearGradient(colors: [Color(red: 0.32, green: 0.19, blue: 0.09),
                                             Color(red: 0.17, green: 0.10, blue: 0.05)],
                                   startPoint: .top, endPoint: .bottom)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 148)
                        .strokeBorder(PATheme.goldMaterial, lineWidth: 3)
                        .padding(10)
                        .opacity(0.55)
                )

            // Felt surface, inset from the rail
            RoundedRectangle(cornerRadius: 150)
                .fill(
                    RadialGradient(colors: [feltColor.opacity(0.9), feltColor, PATheme.feltDeeper.opacity(0.4)],
                                   center: UnitPoint(x: 0.4, y: 0.35), startRadius: 10, endRadius: 460)
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

            VStack(spacing: 12) {
                Text("Pot: $\(pot)")
                    .font(.title3.bold())
                    .foregroundColor(PATheme.ink)
                    .padding(.horizontal, 18).padding(.vertical, 7)
                    .background(Capsule().fill(PATheme.goldMaterial))
                    .overlay(Capsule().stroke(PATheme.goldBright.opacity(0.6), lineWidth: 1))
                    .materialShadow(radius: 6, y: 3)

                HStack(spacing: 7) {
                    ForEach(0..<5, id: \.self) { i in
                        if i < communityCards.count {
                            CardView(card: communityCards[i], width: 50)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            CardView(card: nil, faceDown: true, width: 50)
                                .opacity(0.2)
                        }
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: communityCards.count)
            }
            // Sit a bit above dead-center -- most seats (including the human's,
            // dead-bottom) cluster in the lower half of the oval, so shifting the
            // board up gives them more clearance instead of splitting it evenly.
            .position(x: geo.size.width / 2, y: geo.size.height * 0.40)

            content(geo.size)
        }
        }
    }

    private var feltColor: Color { FeltPalette.color(for: feltID) }
}
