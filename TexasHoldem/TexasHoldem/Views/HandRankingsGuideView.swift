import SwiftUI

/// Tappable reference card showing every poker hand ranking, best to worst,
/// with a quick example. Meant to help new players learn what beats what.
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
        NavigationView {
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(entries) { entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.category.displayName).font(.headline)
                                Text(entry.blurb).font(.caption).foregroundColor(.secondary)
                            }
                            Spacer()
                            HStack(spacing: -10) {
                                ForEach(entry.example) { card in
                                    CardView(card: card, width: 32)
                                }
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.secondarySystemBackground)))
                    }
                }
                .padding()
            }
            .navigationTitle("Hand Rankings")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
            }
        }
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
