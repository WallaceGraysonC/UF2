import SwiftUI

struct PlayerSeatView: View {
    let player: Player
    let isActive: Bool
    let isDealer: Bool
    let revealCards: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                CardView(card: player.holeCards.first, faceDown: !revealCards, cardBackID: player.cardBackID, width: 54)
                CardView(card: player.holeCards.count > 1 ? player.holeCards[1] : nil, faceDown: !revealCards, cardBackID: player.cardBackID, width: 54)
            }
            .opacity(player.isFolded ? 0.35 : 1)

            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    if isDealer {
                        Text("D")
                            .font(.caption2.bold())
                            .padding(4)
                            .background(Circle().fill(Color.white))
                            .foregroundColor(.black)
                    }
                    Text(player.name)
                        .font(.caption.bold())
                        .lineLimit(1)
                }
                Text("$\(player.chips)")
                    .font(.caption2)
                    .foregroundColor(.yellow)
                if player.currentBet > 0 {
                    Text("bet \(player.currentBet)")
                        .font(.caption2)
                        .foregroundColor(.green)
                }
                if player.isFolded {
                    Text("Folded").font(.caption2).foregroundColor(.gray)
                } else if player.isAllIn {
                    Text("All In").font(.caption2).foregroundColor(.orange)
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.55))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? Color.yellow : Color.clear, lineWidth: 2)
            )
        }
    }
}
