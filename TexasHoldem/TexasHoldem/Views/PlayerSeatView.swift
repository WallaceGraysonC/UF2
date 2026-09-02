import SwiftUI
import UIKit

/// Renders a player's avatar -- their uploaded photo if "Custom Photo" is
/// equipped and one has actually been uploaded, otherwise the built-in
/// SF Symbol icon for their equipped avatar.
struct AvatarBadge: View {
    let avatarID: String
    var size: CGFloat = 15

    var body: some View {
        ZStack {
            Circle().fill(Color.black.opacity(0.35))
            if avatarID == CustomCosmeticStore.customID(for: .avatar),
               let image = CustomCosmeticStore.shared.image(for: .avatar) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: size, height: size)
                    .clipShape(Circle())
            } else {
                Image(systemName: AvatarPalette.symbol(for: avatarID))
                    .font(.system(size: size * 0.55))
                    .foregroundColor(.white)
            }
        }
        .frame(width: size, height: size)
    }
}

struct PlayerSeatView: View {
    let player: Player
    let isActive: Bool
    let isDealer: Bool
    let revealCards: Bool
    /// Took (or split) the pot in the hand just finished.
    var isWinner: Bool = false
    /// Smaller rendering for crowded tables, so neighbouring seats around a
    /// full oval don't run into each other.
    var compact: Bool = false

    private var cardWidth: CGFloat { compact ? 34 : 46 }
    private var avatarSize: CGFloat { compact ? 12 : 15 }
    private var nameFont: Font { compact ? .caption2.bold() : .caption.bold() }
    private var detailFont: Font { compact ? .system(size: 9) : .caption2 }

    var body: some View {
        VStack(spacing: compact ? 4 : 6) {
            HStack(spacing: compact ? 3 : 4) {
                CardView(card: player.holeCards.first, faceDown: !revealCards, cardBackID: player.cardBackID, cardFaceID: player.cardFaceID, width: cardWidth)
                CardView(card: player.holeCards.count > 1 ? player.holeCards[1] : nil, faceDown: !revealCards, cardBackID: player.cardBackID, cardFaceID: player.cardFaceID, width: cardWidth)
            }
            .opacity(player.isFolded ? 0.35 : 1)

            VStack(spacing: 2) {
                HStack(spacing: 4) {
                    if isDealer {
                        Text("D")
                            .font(.system(size: compact ? 8 : 10, weight: .bold, design: .serif))
                            .padding(compact ? 3 : 4)
                            .background(Circle().fill(PATheme.goldMaterial))
                            .foregroundColor(PATheme.ink)
                            .materialShadow(radius: 2, y: 1)
                    }
                    AvatarBadge(avatarID: player.avatarID, size: avatarSize)
                        .overlay(Circle().strokeBorder(AvatarFramePalette.stroke(for: player.avatarFrameID), lineWidth: 1.5))
                    Text(player.name)
                        .font(nameFont)
                        .lineLimit(1)
                }
                Text("$\(player.chips)")
                    .font(detailFont)
                    .foregroundColor(PATheme.goldBright)
                if player.currentBet > 0 {
                    Text("bet \(player.currentBet)")
                        .font(detailFont)
                        .foregroundColor(.green)
                }
                if player.isFolded {
                    Text("Folded").font(detailFont).foregroundColor(.gray)
                } else if player.isAllIn {
                    Text("All In").font(detailFont).foregroundColor(.orange)
                }
            }
            .padding(.horizontal, compact ? 6 : 8).padding(.vertical, compact ? 4 : 6)
            .background(
                RoundedRectangle(cornerRadius: 9)
                    .fill(
                        LinearGradient(colors: [PATheme.feltDeep.opacity(0.92), PATheme.feltDeeper.opacity(0.92)],
                                       startPoint: .top, endPoint: .bottom)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9)
                    .stroke(borderStyle, lineWidth: isWinner ? 2.5 : (isActive ? 2 : 1))
            )
            // Winners get a warm glow, so the pot is obvious at a glance
            // rather than something you have to read off the action line.
            .shadow(color: isWinner ? PATheme.goldBright.opacity(0.75) : .clear, radius: 9)
            .materialShadow(radius: 4, y: 2)
        }
        .animation(.easeOut(duration: 0.28), value: isWinner)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voiceOverLabel)
    }

    private var borderStyle: Color {
        if isWinner { return PATheme.goldBright }
        return isActive ? PATheme.goldBright : Color.white.opacity(0.08)
    }

    private var voiceOverLabel: String {
        var parts = [player.name, "\(player.chips) chips"]
        if isDealer { parts.append("dealer") }
        if player.currentBet > 0 { parts.append("bet \(player.currentBet)") }
        if player.isFolded { parts.append("folded") }
        else if player.isAllIn { parts.append("all in") }
        if isActive { parts.append("their turn") }
        if isWinner { parts.append("won the pot") }
        if revealCards, !player.holeCards.isEmpty {
            parts.append("holding " + player.holeCards.map(\.spokenName).joined(separator: " and "))
        }
        return parts.joined(separator: ", ")
    }
}
