import SwiftUI

/// Tappable reference card showing every poker hand ranking, best to worst,
/// with a quick example. Presented as a translucent glass panel over the
/// table -- rendered with `.presentationBackground(.thinMaterial)` so the
/// felt and cards blur through behind it -- rather than an opaque system
/// sheet, to match the rest of the app's "special" material look.
struct HandRankingsGuideView: View {
    @Environment(\.dismiss) private var dismiss

    private struct Entry: Identifiable {
        let id = UUID()
        let category: HandCategory
        let example: [Card]
        let blurb: String
    }

    private let entries: [Entry] = [
        Entry(category: .straightFlush, example: Self.cards("9h", "8h", "7h", "6h", "5h"), blurb: "Five cards in a row, same suit."),
        Entry(category: .fourOfAKind, example: Self.cards("9c", "9d", "9h", "9s", "2c"), blurb: "Four cards of the same rank."),
        Entry(category: .fullHouse, example: Self.cards("kc", "kd", "kh", "4s", "4c"), blurb: "Three of a kind plus a pair."),
        Entry(category: .flush, example: Self.cards("2s", "6s", "9s", "js", "ks"), blurb: "Five cards of the same suit, any order."),
        Entry(category: .straight, example: Self.cards("5c", "6d", "7h", "8s", "9c"), blurb: "Five cards in a row, mixed suits."),
        Entry(category: .threeOfAKind, example: Self.cards("7c", "7d", "7h", "2s", "9c"), blurb: "Three cards of the same rank."),
        Entry(category: .twoPair, example: Self.cards("jc", "jd", "4h", "4s", "9c"), blurb: "Two separate pairs."),
        Entry(category: .pair, example: Self.cards("ac", "ad", "7h", "4s", "2c"), blurb: "Two cards of the same rank."),
        Entry(category: .highCard, example: Self.cards("ac", "jd", "8h", "5s", "2c"), blurb: "No combination -- highest card plays."),
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(entries) { entry in
                        row(for: entry)
                    }
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
                Text("Hand Rankings")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                Text("Best to worst")
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

    private func row(for entry: Entry) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(entry.category.displayName)
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
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(PATheme.gold.opacity(0.28), lineWidth: 1)
        )
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
