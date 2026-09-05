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
    /// Whether it's currently this player's turn to act on some hand.
    var isActive: Bool = false
    /// Which of the player's hands (relevant on a split) is the one
    /// currently acting -- only meaningful while `isActive` is true.
    var activeHandIndex: Int = 0
    /// This player's results from the round just finished, if any --
    /// drives the win glow and the per-hand outcome labels.
    var results: [RoundResult] = []
    /// Smaller rendering for full tables, so neighbouring seats don't run
    /// into each other.
    var compact: Bool = false

    private var cardWidth: CGFloat { compact ? 30 : 42 }
    private var avatarSize: CGFloat { compact ? 12 : 15 }
    private var nameFont: Font { compact ? .caption2.bold() : .caption.bold() }
    private var detailFont: Font { compact ? .system(size: 9) : .caption2 }

    private var isWinner: Bool { results.contains { $0.outcome == .win || $0.outcome == .blackjack } }

    var body: some View {
        VStack(spacing: compact ? 4 : 6) {
            if player.hands.isEmpty {
                CardView(card: nil, faceDown: true, width: cardWidth).opacity(0.15)
            } else {
                HStack(alignment: .top, spacing: compact ? 5 : 9) {
                    ForEach(Array(player.hands.enumerated()), id: \.element.id) { index, hand in
                        handColumn(hand: hand, index: index)
                    }
                }
            }

            HStack(spacing: 4) {
                AvatarBadge(avatarID: player.avatarID, size: avatarSize)
                    .overlay(Circle().strokeBorder(AvatarFramePalette.stroke(for: player.avatarFrameID), lineWidth: 1.5))
                Text(player.name)
                    .font(nameFont)
                    .lineLimit(1)
            }
            Text("$\(player.chips)")
                .font(detailFont)
                .foregroundColor(BJTheme.goldBright)
        }
        .padding(.horizontal, compact ? 6 : 8).padding(.vertical, compact ? 4 : 6)
        .background(
            RoundedRectangle(cornerRadius: 9)
                .fill(
                    LinearGradient(colors: [BJTheme.feltDeep.opacity(0.92), BJTheme.feltDeeper.opacity(0.92)],
                                   startPoint: .top, endPoint: .bottom)
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 9)
                .stroke(borderStyle, lineWidth: isWinner ? 2.5 : (isActive ? 2 : 1))
        )
        // Winners get a warm glow, so a win is obvious at a glance rather
        // than something you have to read off the seat's badges.
        .shadow(color: isWinner ? BJTheme.goldBright.opacity(0.75) : .clear, radius: 9)
        .materialShadow(radius: 4, y: 2)
        .animation(.easeOut(duration: 0.28), value: isWinner)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(voiceOverLabel)
    }

    private func handColumn(hand: BlackjackHand, index: Int) -> some View {
        let isHandActive = isActive && index == activeHandIndex
        let outcome = results.first { $0.handIndex == index }?.outcome
        return VStack(spacing: 2) {
            HStack(spacing: compact ? 2 : 3) {
                ForEach(Array(hand.cards.enumerated()), id: \.offset) { _, card in
                    CardView(card: card, cardBackID: player.cardBackID, cardFaceID: player.cardFaceID, width: cardWidth)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.35, dampingFraction: 0.75), value: hand.cards.count)
            if !hand.displayTotal.isEmpty {
                Text(hand.displayTotal)
                    .font(detailFont.bold())
                    .foregroundColor(totalColor(hand: hand))
            }
            Text("$\(hand.bet)")
                .font(detailFont)
                .foregroundColor(.green)
            if let outcome {
                Text(outcome.displayText)
                    .font(detailFont.bold())
                    .foregroundColor(outcomeColor(outcome))
            } else if hand.isSurrendered {
                Text("Surrender").font(detailFont).foregroundColor(.gray)
            }
        }
        .padding(.horizontal, 4).padding(.vertical, 3)
        .background(RoundedRectangle(cornerRadius: 7).fill(isHandActive ? Color.white.opacity(0.12) : Color.clear))
        .overlay(RoundedRectangle(cornerRadius: 7).stroke(isHandActive ? BJTheme.goldBright : Color.clear, lineWidth: 2))
    }

    private func totalColor(hand: BlackjackHand) -> Color {
        if hand.isBlackjack { return BJTheme.goldBright }
        if hand.isBusted { return .red }
        return .white
    }

    private func outcomeColor(_ outcome: HandOutcome) -> Color {
        switch outcome {
        case .blackjack, .win: return .green
        case .push: return .yellow
        case .lose, .bust, .surrender: return .red
        }
    }

    private var borderStyle: Color {
        if isWinner { return BJTheme.goldBright }
        return isActive ? BJTheme.goldBright : Color.white.opacity(0.08)
    }

    private var voiceOverLabel: String {
        var parts = [player.name, "\(player.chips) chips"]
        for (index, hand) in player.hands.enumerated() {
            var handDesc = "hand \(index + 1): \(hand.displayTotal.isEmpty ? "no cards" : hand.displayTotal), bet \(hand.bet)"
            if let outcome = results.first(where: { $0.handIndex == index })?.outcome {
                handDesc += ", \(outcome.displayText)"
            }
            parts.append(handDesc)
        }
        if isActive { parts.append("their turn") }
        return parts.joined(separator: ", ")
    }
}
