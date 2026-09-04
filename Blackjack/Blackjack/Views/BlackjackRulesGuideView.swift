import SwiftUI

/// Tappable reference card covering payouts, actions, and dealer rules.
/// Presented as a translucent glass panel over the table -- rendered with
/// `.presentationBackground(.thinMaterial)` so the felt and cards blur
/// through behind it -- rather than an opaque system sheet, to match the
/// rest of the app's "special" material look.
struct BlackjackRulesGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private struct PayoutEntry: Identifiable {
        let id = UUID()
        let title: String
        let example: [Card]
        let blurb: String
    }

    private let payouts: [PayoutEntry] = [
        PayoutEntry(title: "Blackjack — pays 3:2", example: Self.cards("as", "kh"),
                    blurb: "An Ace plus a 10-value card as your first two cards."),
        PayoutEntry(title: "Win — pays 1:1", example: Self.cards("th", "9c", "kd"),
                    blurb: "Your total beats the dealer's without busting."),
        PayoutEntry(title: "Push — bet returned", example: Self.cards("9h", "9s"),
                    blurb: "You and the dealer land on the same total."),
        PayoutEntry(title: "Bust — hand lost", example: Self.cards("th", "9c", "5d"),
                    blurb: "Your total goes over 21."),
        PayoutEntry(title: "Insurance — pays 2:1", example: Self.cards("ah"),
                    blurb: "Offered when the dealer shows an Ace; wins only if the dealer has Blackjack."),
        PayoutEntry(title: "Surrender — half returned", example: Self.cards("th", "6c"),
                    blurb: "Give up before hitting; get half your bet back."),
    ]

    private struct ActionEntry: Identifiable {
        let id = UUID()
        let title: String
        let blurb: String
    }

    private let actions: [ActionEntry] = [
        ActionEntry(title: "Hit", blurb: "Take another card."),
        ActionEntry(title: "Stand", blurb: "Keep your total and end your turn."),
        ActionEntry(title: "Double Down", blurb: "Double your bet, take exactly one more card."),
        ActionEntry(title: "Split", blurb: "Split a pair into two hands, each with its own bet."),
        ActionEntry(title: "Surrender", blurb: "Forfeit the hand before hitting, keep half your bet."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(spacing: 12) {
                        ForEach(payouts) { entry in payoutRow(for: entry) }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Your Actions")
                            .font(.headline)
                            .foregroundColor(.white)
                        ForEach(actions) { entry in
                            HStack(alignment: .top, spacing: 8) {
                                Text(entry.title)
                                    .font(.subheadline.bold())
                                    .foregroundColor(BJTheme.goldBright)
                                    .frame(width: 108, alignment: .leading)
                                Text(entry.blurb)
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(BJTheme.gold.opacity(0.28), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dealer Rules")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("The dealer hits until reaching 17 or more, then stands on every 17 — hard or soft. The dealer's second card stays hidden until every player has finished acting.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(14)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
                    .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(BJTheme.gold.opacity(0.28), lineWidth: 1))
                }
                .padding(20)
            }
        }
        .background(Color.clear)
        .presentationBackground(.thinMaterial)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("How to Play")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text("Payouts and actions")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.footnote.bold())
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
        }
        .padding(20)
    }

    private func payoutRow(for entry: PayoutEntry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.headline)
                    .foregroundColor(.white)
                Text(entry.blurb)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.65))
            }
            Spacer()
            HStack(spacing: -12) {
                ForEach(entry.example) { card in
                    CardView(card: card, width: 32)
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(BJTheme.gold.opacity(0.28), lineWidth: 1))
    }

    private static func cards(_ codes: String...) -> [Card] {
        codes.compactMap { code in
            guard let rankChar = code.dropLast().first ?? code.first,
                  let suitChar = code.last else { return nil }
            let rank: Rank
            switch rankChar {
            case "2": rank = .two
            case "3": rank = .three
            case "4": rank = .four
            case "5": rank = .five
            case "6": rank = .six
            case "7": rank = .seven
            case "8": rank = .eight
            case "9": rank = .nine
            case "t": rank = .ten
            case "j": rank = .jack
            case "q": rank = .queen
            case "k": rank = .king
            case "a": rank = .ace
            default: return nil
            }
            let suit: Suit
            switch suitChar {
            case "c": suit = .clubs
            case "d": suit = .diamonds
            case "h": suit = .hearts
            case "s": suit = .spades
            default: return nil
            }
            return Card(rank: rank, suit: suit)
        }
    }
}
