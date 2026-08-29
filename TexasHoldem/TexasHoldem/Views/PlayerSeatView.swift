import SwiftUI

struct PlayerSeatView: View {
    let player: Player
    let isActive: Bool
    let isDealer: Bool
    let revealCards: Bool

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                CardView(card: player.holeCards.first, faceDown: !revealCards, cardBackID: player.cardBackID, width: 46)
                CardView(card: player.holeCards.count > 1 ? player.holeCards[1] : nil, faceDown: !revealCards, cardBackID: player.cardBackID, width: 46)
            }
            .opacity(player.isFolded ? 0.35 : 1)

            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    if isDealer {
                        Text("D")
                            .font(.system(size: 10, weight: .bold, design: .serif))
                            .padding(4)
                            .background(Circle().fill(PATheme.goldMaterial))
                            .foregroundColor(PATheme.ink)
                            .materialShadow(radius: 2, y: 1)
                    }
                    Image(systemName: AvatarPalette.symbol(for: player.avatarID))
                        .font(.system(size: 9))
                        .foregroundColor(PATheme.goldBright)
                    Text(player.name)
                        .font(.caption.bold())
                        .lineLimit(1)
                }
                Text("$\(player.chips)")
                    .font(.caption2)
                    .foregroundColor(PATheme.goldBright)
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
            .padding(.horizontal, 8).padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        LinearGradient(colors: [PATheme.feltDeep.opacity(0.92), PATheme.feltDeeper.opacity(0.92)],
                                       startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(isActive ? PATheme.goldBright : Color.white.opacity(0.08), lineWidth: isActive ? 2 : 1)
            )
            .materialShadow(radius: 4, y: 2)
        }
    }
}
